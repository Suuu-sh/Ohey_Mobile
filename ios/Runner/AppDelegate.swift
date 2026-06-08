import Flutter
import CoreLocation
import MapKit
import Photos
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private var qrSaverChannel: FlutterMethodChannel?
  private var placeSearchChannel: FlutterMethodChannel?
  private var instagramShareChannel: FlutterMethodChannel?
  private var placeSearchLocationManager: CLLocationManager?
  private var placeSearchLocationCompletion: ((CLLocation?, FlutterError?) -> Void)?
  private var didRequestPlaceSearchLocation = false
  private let yuruboNativeAdFactory = OheyYuruboNativeAdFactory()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerYuruboNativeAdFactory(in: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerQrSaverChannel(on: controller.binaryMessenger)
      registerPlaceSearchChannel(on: controller.binaryMessenger)
      registerInstagramShareChannel(on: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerYuruboNativeAdFactory(in: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OheyQrSaver") {
      registerQrSaverChannel(on: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OheyPlaceSearch") {
      registerPlaceSearchChannel(on: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OheyInstagramShare") {
      registerInstagramShareChannel(on: registrar.messenger())
    }
  }

  private func registerYuruboNativeAdFactory(in registry: FlutterPluginRegistry) {
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registry,
      factoryId: "ohey_yurubo_native_ad",
      nativeAdFactory: yuruboNativeAdFactory
    )
  }

  private func registerQrSaverChannel(on messenger: FlutterBinaryMessenger) {
    qrSaverChannel = FlutterMethodChannel(name: "ohey/qr_saver", binaryMessenger: messenger)
    qrSaverChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "savePngToPhotos" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.savePngToPhotos(call.arguments, result: result)
    }
  }

  private func registerPlaceSearchChannel(on messenger: FlutterBinaryMessenger) {
    placeSearchChannel = FlutterMethodChannel(name: "ohey/place_search", binaryMessenger: messenger)
    placeSearchChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "searchNearby":
        self?.searchNearbyPlaces(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerInstagramShareChannel(on messenger: FlutterBinaryMessenger) {
    instagramShareChannel = FlutterMethodChannel(name: "ohey/instagram_share", binaryMessenger: messenger)
    instagramShareChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "shareStory":
        self?.shareInstagramStory(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func searchNearbyPlaces(_ arguments: Any?, result: @escaping FlutterResult) {
    let payload = arguments as? [String: Any]
    let query = (payload?["query"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let searchQuery = query.isEmpty ? "スポット" : query
    let radiusMeters = payload?["radiusMeters"] as? CLLocationDistance ?? 2500
    let limit = payload?["limit"] as? Int ?? 20

    currentPlaceSearchLocation { [weak self] location, error in
      if let error = error {
        DispatchQueue.main.async { result(error) }
        return
      }
      guard let location = location else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "location_unavailable",
            message: "No current location.",
            details: nil
          ))
        }
        return
      }
      self?.performNearbyPlaceSearch(
        query: searchQuery,
        near: location,
        radiusMeters: radiusMeters,
        limit: limit,
        result: result
      )
    }
  }

  private func currentPlaceSearchLocation(
    completion: @escaping (CLLocation?, FlutterError?) -> Void
  ) {
    guard CLLocationManager.locationServicesEnabled() else {
      completion(nil, FlutterError(
        code: "location_unavailable",
        message: "Location services are disabled.",
        details: nil
      ))
      return
    }

    let manager = CLLocationManager()
    placeSearchLocationManager = manager
    placeSearchLocationCompletion = completion
    didRequestPlaceSearchLocation = false
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

    let status = manager.authorizationStatus
    switch status {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      requestPlaceSearchLocationIfNeeded()
    case .denied, .restricted:
      finishPlaceSearchLocation(error: FlutterError(
        code: "permission_denied",
        message: "Location permission denied.",
        details: nil
      ))
    @unknown default:
      finishPlaceSearchLocation(error: FlutterError(
        code: "location_unavailable",
        message: "Unknown location authorization status.",
        details: nil
      ))
    }
  }

  private func requestPlaceSearchLocationIfNeeded() {
    guard !didRequestPlaceSearchLocation else { return }
    guard let manager = placeSearchLocationManager else { return }
    didRequestPlaceSearchLocation = true
    manager.requestLocation()
  }

  private func finishPlaceSearchLocation(location: CLLocation? = nil, error: FlutterError? = nil) {
    guard let completion = placeSearchLocationCompletion else { return }
    placeSearchLocationCompletion = nil
    placeSearchLocationManager?.delegate = nil
    placeSearchLocationManager = nil
    didRequestPlaceSearchLocation = false
    completion(location, error)
  }

  private func performNearbyPlaceSearch(
    query: String,
    near location: CLLocation,
    radiusMeters: CLLocationDistance,
    limit: Int,
    result: @escaping FlutterResult
  ) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.region = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: radiusMeters,
      longitudinalMeters: radiusMeters
    )
    if #available(iOS 13.0, *) {
      request.resultTypes = .pointOfInterest
    }

    MKLocalSearch(request: request).start { response, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "search_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
        return
      }

      let places = (response?.mapItems ?? [])
        .compactMap { item -> [String: Any]? in
          guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty else { return nil }
          let placeLocation = item.placemark.location
          let distance = placeLocation.map { location.distance(from: $0) } ?? 0
          return [
            "name": name,
            "subtitle": self.subtitle(for: item),
            "distanceMeters": distance,
            "latitude": item.placemark.coordinate.latitude,
            "longitude": item.placemark.coordinate.longitude,
          ]
        }
        .sorted {
          let lhs = $0["distanceMeters"] as? CLLocationDistance ?? 0
          let rhs = $1["distanceMeters"] as? CLLocationDistance ?? 0
          return lhs < rhs
        }
        .prefix(max(1, min(limit, 50)))

      DispatchQueue.main.async {
        result(Array(places))
      }
    }
  }

  private func subtitle(for item: MKMapItem) -> String {
    let placemark = item.placemark
    let parts = [
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    if !parts.isEmpty {
      return parts.joined(separator: " ")
    }
    return placemark.title ?? ""
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handlePlaceSearchAuthorization(manager.authorizationStatus)
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    handlePlaceSearchAuthorization(status)
  }

  private func handlePlaceSearchAuthorization(_ status: CLAuthorizationStatus) {
    guard placeSearchLocationCompletion != nil else { return }
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      requestPlaceSearchLocationIfNeeded()
    case .denied, .restricted:
      finishPlaceSearchLocation(error: FlutterError(
        code: "permission_denied",
        message: "Location permission denied.",
        details: nil
      ))
    case .notDetermined:
      break
    @unknown default:
      finishPlaceSearchLocation(error: FlutterError(
        code: "location_unavailable",
        message: "Unknown location authorization status.",
        details: nil
      ))
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      finishPlaceSearchLocation(error: FlutterError(
        code: "location_unavailable",
        message: "No current location.",
        details: nil
      ))
      return
    }
    finishPlaceSearchLocation(location: location)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishPlaceSearchLocation(error: FlutterError(
      code: "location_unavailable",
      message: error.localizedDescription,
      details: nil
    ))
  }

  private func savePngToPhotos(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let typedData = arguments as? FlutterStandardTypedData,
      let image = UIImage(data: typedData.data)
    else {
      result(FlutterError(code: "invalid_image", message: "Invalid PNG data.", details: nil))
      return
    }

    requestPhotoAddPermission { status in
      let isAllowed: Bool
      if #available(iOS 14, *) {
        isAllowed = status == .authorized || status == .limited
      } else {
        isAllowed = status == .authorized
      }
      guard isAllowed else {
        DispatchQueue.main.async {
          result(FlutterError(code: "permission_denied", message: "Photo add permission denied.", details: nil))
        }
        return
      }

      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }, completionHandler: { success, error in
        DispatchQueue.main.async {
          if success {
            result(nil)
          } else {
            result(FlutterError(
              code: "save_failed",
              message: error?.localizedDescription ?? "Failed to save QR image.",
              details: nil
            ))
          }
        }
      })
    }
  }

  private func requestPhotoAddPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: completion)
    } else {
      PHPhotoLibrary.requestAuthorization(completion)
    }
  }

  private func shareInstagramStory(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let payload = arguments as? [String: Any],
      let imagePath = payload["imagePath"] as? String,
      !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(FlutterError(code: "invalid_payload", message: "Invalid Instagram share payload.", details: nil))
      return
    }

    guard let instagramUrl = URL(string: "instagram-stories://share") else {
      result(FlutterError(code: "invalid_url", message: "Invalid Instagram URL.", details: nil))
      return
    }

    guard UIApplication.shared.canOpenURL(instagramUrl) else {
      result(FlutterError(code: "instagram_unavailable", message: "Instagram app is not installed.", details: nil))
      return
    }

    do {
      let imageData = try Data(contentsOf: URL(fileURLWithPath: imagePath))
      let pasteboardItems: [[String: Any]] = [[
        "com.instagram.sharedSticker.backgroundImage": imageData
      ]]
      let options: [UIPasteboard.OptionsKey: Any] = [
        .expirationDate: Date().addingTimeInterval(300)
      ]
      UIPasteboard.general.setItems(pasteboardItems, options: options)
      UIApplication.shared.open(instagramUrl, options: [:]) { success in
        DispatchQueue.main.async {
          if success {
            result(nil)
          } else {
            result(FlutterError(code: "open_failed", message: "Failed to open Instagram.", details: nil))
          }
        }
      }
    } catch {
      result(FlutterError(code: "image_read_failed", message: error.localizedDescription, details: nil))
    }
  }
}
