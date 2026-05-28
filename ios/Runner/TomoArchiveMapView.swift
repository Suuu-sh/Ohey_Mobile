import Flutter
import MapKit
import UIKit

final class TomoArchiveMapFactory: NSObject, FlutterPlatformViewFactory {
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
    TomoArchiveMapView(frame: frame, viewIdentifier: viewId, arguments: args, messenger: messenger)
  }
}

private final class TomoArchiveAnnotation: MKPointAnnotation {
  let identifier: String

  init(identifier: String) {
    self.identifier = identifier
    super.init()
  }
}

final class TomoArchiveMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
  private let mapView: MKMapView
  private let geocoder = CLGeocoder()
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    mapView = MKMapView(frame: frame)
    channel = FlutterMethodChannel(name: "tomo/archive_map_\(viewId)", binaryMessenger: messenger)
    super.init()
    mapView.delegate = self
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

    let coordinatePins = annotations.compactMap { item -> TomoArchiveAnnotation? in
      guard let lat = item["latitude"] as? CLLocationDegrees,
            let lng = item["longitude"] as? CLLocationDegrees else { return nil }
      return makeAnnotation(from: item, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
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

  private func makeAnnotation(
    from item: [String: Any],
    coordinate: CLLocationCoordinate2D
  ) -> TomoArchiveAnnotation {
    let fallbackId = item["title"] as? String ?? UUID().uuidString
    let annotation = TomoArchiveAnnotation(identifier: item["id"] as? String ?? fallbackId)
    annotation.coordinate = coordinate
    annotation.title = item["title"] as? String
    if let subtitle = item["subtitle"] as? String {
      annotation.subtitle = subtitle
    } else if let count = item["count"] as? Int, count > 1 {
      annotation.subtitle = "\(count)件の思い出"
    }
    return annotation
  }

  private func geocode(
    items: [[String: Any]],
    completion: @escaping ([TomoArchiveAnnotation]) -> Void
  ) {
    var results: [TomoArchiveAnnotation] = []
    let group = DispatchGroup()

    for item in items {
      let place = (item["place"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let title = (item["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let query = [place, title].compactMap({ $0 }).first(where: { !$0.isEmpty }) else { continue }
      group.enter()
      geocoder.geocodeAddressString(query) { placemarks, _ in
        defer { group.leave() }
        guard let coordinate = placemarks?.first?.location?.coordinate else { return }
        results.append(self.makeAnnotation(from: item, coordinate: coordinate))
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
          latitudinalMeters: 5_000,
          longitudinalMeters: 5_000
        ),
        animated: false
      )
      return
    }

    if pins.count == 1 {
      mapView.setRegion(
        MKCoordinateRegion(
          center: pins[0].coordinate,
          latitudinalMeters: 1_800,
          longitudinalMeters: 1_800
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
      edgePadding: UIEdgeInsets(top: 150, left: 60, bottom: 80, right: 60),
      animated: false
    )
  }

  func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
    guard let annotation = annotation as? TomoArchiveAnnotation else { return }
    channel.invokeMethod("annotationSelected", arguments: ["id": annotation.identifier])
    mapView.deselectAnnotation(annotation, animated: true)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is TomoArchiveAnnotation else { return nil }
    let identifier = "TomoArchiveAnnotation"
    let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
      ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    view.annotation = annotation
    view.markerTintColor = UIColor.systemPink
    view.glyphImage = UIImage(systemName: "photo.fill")
    view.canShowCallout = false
    return view
  }
}
