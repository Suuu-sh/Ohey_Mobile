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

  init(frame: CGRect, arguments args: Any?) {
    mapView = MKMapView(frame: frame)
    super.init()
    mapView.overrideUserInterfaceStyle = .dark
    mapView.pointOfInterestFilter = .includingAll
    mapView.showsCompass = false
    mapView.showsScale = false
    configureAnnotations(args)
  }

  func view() -> UIView { mapView }

  private func configureAnnotations(_ args: Any?) {
    guard let params = args as? [String: Any],
          let annotations = params["annotations"] as? [[String: Any]] else { return }

    let pins = annotations.compactMap { item -> MKPointAnnotation? in
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

    mapView.addAnnotations(pins)
    guard !pins.isEmpty else { return }
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
