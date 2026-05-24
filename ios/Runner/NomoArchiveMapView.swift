import Flutter
import MapKit
import UIKit

final class NomoArchiveMapFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NomoArchiveMapView(frame: frame, arguments: args)
  }
}

final class NomoArchiveMapView: NSObject, FlutterPlatformView {
  private let mapView: MKMapView
  private let geocoder = CLGeocoder()

  init(frame: CGRect, arguments args: Any?) {
    mapView = MKMapView(frame: frame)
    super.init()
    mapView.overrideUserInterfaceStyle = .dark
    mapView.mapType = .standard
    mapView.pointOfInterestFilter = .includingAll
    mapView.showsCompass = false
    mapView.showsScale = false
    mapView.showsBuildings = true
    mapView.showsTraffic = false
    configureAnnotations(args)
  }

  func view() -> UIView { mapView }

  private func configureAnnotations(_ args: Any?) {
    guard let params = args as? [String: Any],
          let annotations = params["annotations"] as? [[String: Any]] else { return }

    let coordinatePins = annotations.compactMap { item -> MKPointAnnotation? in
      guard let lat = item["latitude"] as? CLLocationDegrees,
            let lng = item["longitude"] as? CLLocationDegrees else { return nil }
      let annotation = MKPointAnnotation()
      annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
      annotation.title = item["title"] as? String
      if let count = item["count"] as? Int, count > 1 {
        annotation.subtitle = "\(count)件の思い出"
      }
      return annotation
    }

    let unresolvedItems = annotations.filter { item in
      item["latitude"] == nil || item["longitude"] == nil
    }

    var pins = coordinatePins
    mapView.addAnnotations(pins)
    if !pins.isEmpty {
      setVisibleRegion(for: pins)
    }

    guard !unresolvedItems.isEmpty else { return }
    geocode(items: unresolvedItems) { [weak self] geocodedPins in
      guard let self else { return }
      pins.append(contentsOf: geocodedPins)
      self.mapView.addAnnotations(geocodedPins)
      self.setVisibleRegion(for: pins)
    }
  }

  private func geocode(
    items: [[String: Any]],
    completion: @escaping ([MKPointAnnotation]) -> Void
  ) {
    var results: [MKPointAnnotation] = []
    let group = DispatchGroup()

    for item in items {
      guard let title = item["title"] as? String, !title.isEmpty else { continue }
      group.enter()
      geocoder.geocodeAddressString(title) { placemarks, _ in
        defer { group.leave() }
        guard let coordinate = placemarks?.first?.location?.coordinate else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        if let count = item["count"] as? Int, count > 1 {
          annotation.subtitle = "\(count)件の思い出"
        }
        results.append(annotation)
      }
    }

    group.notify(queue: .main) {
      completion(results)
    }
  }

  private func setVisibleRegion(for pins: [MKPointAnnotation]) {
    guard !pins.isEmpty else {
      mapView.setRegion(
        MKCoordinateRegion(
          center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
          latitudinalMeters: 5000,
          longitudinalMeters: 5000
        ),
        animated: false
      )
      return
    }

    if pins.count == 1 {
      mapView.setRegion(
        MKCoordinateRegion(
          center: pins[0].coordinate,
          latitudinalMeters: 1800,
          longitudinalMeters: 1800
        ),
        animated: false
      )
      return
    }

    let rect = pins.reduce(MKMapRect.null) { partial, pin in
      let point = MKMapPoint(pin.coordinate)
      let rect = MKMapRect(x: point.x, y: point.y, width: 1, height: 1)
      return partial.union(rect)
    }
    mapView.setVisibleMapRect(
      rect,
      edgePadding: UIEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
      animated: false
    )
  }
}
