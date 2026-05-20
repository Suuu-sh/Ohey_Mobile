import ARKit
import AVFoundation
import Flutter
import SceneKit
import UIKit

final class NomoArAvatarCameraFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> (NSObjectProtocol & FlutterMessageCodec) {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NomoArAvatarCameraView(frame: frame, viewId: viewId, messenger: messenger, args: args)
  }
}

private final class NomoArAvatarCameraView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
  private let containerView: UIView
  private let sceneView: ARSCNView
  private let statusLabel = UILabel()
  private let channel: FlutterMethodChannel
  private var avatar: NomoNativeAvatar
  private var filterMode: NomoArCameraFilterMode
  private var faceOverlayNode: SCNNode?
  private var faceGeometryNode: SCNNode?
  private var didStartSession = false

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
    containerView = UIView(frame: frame)
    sceneView = ARSCNView(frame: frame)
    channel = FlutterMethodChannel(
      name: "nomo/ar_avatar_camera_\(viewId)",
      binaryMessenger: messenger
    )
    avatar = NomoNativeAvatar(arguments: (args as? [String: Any])?["avatar"] as? [String: Any])
    filterMode = NomoArCameraFilterMode(arguments: args as? [String: Any])
    super.init()

    configureView()
    configureChannel()
    startIfPossible()
  }

  func view() -> UIView {
    containerView
  }

  deinit {
    sceneView.session.pause()
  }

  private func configureView() {
    containerView.backgroundColor = .black

    sceneView.translatesAutoresizingMaskIntoConstraints = false
    sceneView.backgroundColor = .black
    sceneView.scene = SCNScene()
    sceneView.delegate = self
    sceneView.automaticallyUpdatesLighting = true
    sceneView.autoenablesDefaultLighting = true
    sceneView.preferredFramesPerSecond = 60
    containerView.addSubview(sceneView)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.numberOfLines = 0
    statusLabel.textAlignment = .center
    statusLabel.textColor = .white
    statusLabel.font = .systemFont(ofSize: 16, weight: .bold)
    statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.56)
    statusLabel.layer.cornerRadius = 18
    statusLabel.layer.masksToBounds = true
    statusLabel.isHidden = true
    containerView.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      sceneView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      sceneView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      sceneView.topAnchor.constraint(equalTo: containerView.topAnchor),
      sceneView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

      statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 32),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -32),
    ])
  }

  private func configureChannel() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "view_disposed", message: "AR camera view is no longer available.", details: nil))
        return
      }

      switch call.method {
      case "isSupported":
        result(ARFaceTrackingConfiguration.isSupported)
      case "setAvatar":
        let payload = call.arguments as? [String: Any]
        self.avatar = NomoNativeAvatar(arguments: payload)
        self.applyCurrentFilter()
        result(nil)
      case "setFilterMode":
        self.filterMode = NomoArCameraFilterMode(rawValue: call.arguments as? String)
        self.applyCurrentFilter()
        result(nil)
      case "capture":
        self.capture(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startIfPossible() {
    guard ARFaceTrackingConfiguration.isSupported else {
      showStatus("Nomo ARアバターは\nTrueDepthカメラ搭載の実機で使えます。")
      return
    }

    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      startSession()
    case .notDetermined:
      showStatus("カメラの使用許可を待っています…")
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          guard let self else { return }
          if granted {
            self.startSession()
          } else {
            self.showStatus("カメラへのアクセスを許可してください。")
          }
        }
      }
    case .denied, .restricted:
      showStatus("カメラへのアクセスを許可してください。")
    @unknown default:
      showStatus("カメラを起動できませんでした。")
    }
  }

  private func startSession() {
    hideStatus()
    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    if #available(iOS 13.0, *) {
      configuration.maximumNumberOfTrackedFaces = 1
    }
    sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    didStartSession = true
  }

  private func capture(result: @escaping FlutterResult) {
    guard ARFaceTrackingConfiguration.isSupported else {
      result(FlutterError(
        code: "face_tracking_unavailable",
        message: "Nomo ARアバターはTrueDepthカメラ搭載の実機で使えます。",
        details: nil
      ))
      return
    }
    guard didStartSession else {
      result(FlutterError(code: "camera_not_ready", message: "ARカメラの準備中です。", details: nil))
      return
    }

    let image = sceneView.snapshot()
    guard let data = image.jpegData(compressionQuality: 0.92) else {
      result(FlutterError(code: "snapshot_failed", message: "AR写真を書き出せませんでした。", details: nil))
      return
    }

    do {
      let fileName = "nomo_ar_avatar_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
      try data.write(to: url, options: .atomic)
      result(url.path)
    } catch {
      result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func showStatus(_ message: String) {
    statusLabel.text = "  \(message)  "
    statusLabel.isHidden = false
  }

  private func hideStatus() {
    statusLabel.isHidden = true
  }

  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    guard anchor is ARFaceAnchor else { return nil }

    let rootNode = SCNNode()
    if let device = sceneView.device,
       let faceGeometry = ARSCNFaceGeometry(device: device, fillMesh: true) {
      if let material = faceGeometry.firstMaterial {
        NomoArFilterRenderer.configureFaceMaterial(material, mode: filterMode, avatar: avatar)
      }

      let geometryNode = SCNNode(geometry: faceGeometry)
      rootNode.addChildNode(geometryNode)
      faceGeometryNode = geometryNode
    }

    let overlayNode = SCNNode(geometry: NomoArFilterRenderer.makeOverlayPlane(mode: filterMode, avatar: avatar))
    overlayNode.name = "nomo-avatar-face-overlay"
    overlayNode.position = NomoArFilterRenderer.overlayPosition(for: filterMode)
    overlayNode.eulerAngles = SCNVector3(0, 0, 0)
    rootNode.addChildNode(overlayNode)
    faceOverlayNode = overlayNode

    return rootNode
  }

  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let faceAnchor = anchor as? ARFaceAnchor else { return }
    if let faceGeometry = faceGeometryNode?.geometry as? ARSCNFaceGeometry {
      faceGeometry.update(from: faceAnchor.geometry)
    }

    let jawOpen = faceAnchor.blendShapes[.jawOpen]?.floatValue ?? 0
    let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft]?.floatValue ?? 0
    let smileRight = faceAnchor.blendShapes[.mouthSmileRight]?.floatValue ?? 0
    let expressionScale: CGFloat
    if filterMode == .avatar {
      expressionScale = 1.0 + CGFloat(min(0.08, (jawOpen + smileLeft + smileRight) * 0.035))
    } else {
      expressionScale = 1.0
    }
    faceOverlayNode?.scale = SCNVector3(Float(expressionScale), Float(expressionScale), 1)
  }

  private func applyCurrentFilter() {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let material = self.faceGeometryNode?.geometry?.firstMaterial {
        NomoArFilterRenderer.configureFaceMaterial(material, mode: self.filterMode, avatar: self.avatar)
      }
      self.faceOverlayNode?.geometry = NomoArFilterRenderer.makeOverlayPlane(
        mode: self.filterMode,
        avatar: self.avatar
      )
      self.faceOverlayNode?.position = NomoArFilterRenderer.overlayPosition(for: self.filterMode)
    }
  }
}

private enum NomoArCameraFilterMode: String {
  case avatar
  case natural

  init(arguments: [String: Any]?) {
    self.init(rawValue: arguments?["filterMode"] as? String)
  }

  init(rawValue: String?) {
    switch rawValue {
    case "natural":
      self = .natural
    default:
      self = .avatar
    }
  }
}

private struct NomoNativeAvatar: Equatable {
  let skin: Int
  let hair: Int
  let shirt: Int
  let eyes: Int
  let mouth: Int
  let accessory: Int
  let isAdmin: Bool

  init(arguments: [String: Any]?) {
    skin = NomoNativeAvatar.clamped(arguments?["skin"], max: NomoPalette.skinColors.count)
    hair = NomoNativeAvatar.clamped(arguments?["hair"], max: NomoPalette.hairColors.count)
    shirt = NomoNativeAvatar.clamped(arguments?["shirt"], max: NomoPalette.shirtColors.count)
    eyes = NomoNativeAvatar.clamped(arguments?["eyes"], max: 4)
    mouth = NomoNativeAvatar.clamped(arguments?["mouth"], max: 3)
    accessory = NomoNativeAvatar.clamped(arguments?["accessory"], max: 4)
    isAdmin = arguments?["isAdmin"] as? Bool ?? false
  }

  private static func clamped(_ value: Any?, max: Int) -> Int {
    let intValue: Int
    if let value = value as? Int {
      intValue = value
    } else if let value = value as? NSNumber {
      intValue = value.intValue
    } else {
      intValue = 0
    }
    return Swift.max(0, Swift.min(intValue, max - 1))
  }

  var skinColor: UIColor {
    NomoPalette.skinColors[skin]
  }

  var hairColor: UIColor {
    NomoPalette.hairColors[hair % NomoPalette.hairColors.count]
  }

  var shirtColor: UIColor {
    NomoPalette.shirtColors[shirt]
  }
}

private enum NomoPalette {
  static let skinColors = [
    UIColor(hex: 0xFFD8C2), UIColor(hex: 0xE9A985), UIColor(hex: 0xB96B54),
    UIColor(hex: 0x7B3F36), UIColor(hex: 0x4A2824), UIColor(hex: 0xFFC08A),
  ]

  static let hairColors = [
    UIColor(hex: 0x2A1715), UIColor(hex: 0x4E2A20), UIColor(hex: 0x8A4B2E),
    UIColor(hex: 0xD8A24C), UIColor(hex: 0x111820), UIColor(hex: 0xEFE8D8),
  ]

  static let shirtColors = [
    UIColor(hex: 0xB777D9), UIColor(hex: 0x2EA8FF), UIColor(hex: 0x39C7D7),
    UIColor(hex: 0x65B96B), UIColor(hex: 0xFFD25B), UIColor(hex: 0xFF9B38),
    UIColor(hex: 0xFF6666), UIColor(hex: 0xFF9FC7), UIColor(hex: 0xF8F8F8),
    UIColor(hex: 0x3D4850),
  ]
}

private enum NomoArFilterRenderer {
  static func configureFaceMaterial(
    _ material: SCNMaterial,
    mode: NomoArCameraFilterMode,
    avatar: NomoNativeAvatar
  ) {
    switch mode {
    case .avatar:
      material.colorBufferWriteMask = .all
      material.diffuse.contents = avatar.skinColor
      material.emission.contents = avatar.skinColor
      material.lightingModel = .constant
      material.transparency = 1
      material.blendMode = .replace
      material.writesToDepthBuffer = true
      material.readsFromDepthBuffer = true
      material.metalness.contents = 0
      material.roughness.contents = 1
      material.specular.contents = UIColor.clear
    case .natural:
      material.colorBufferWriteMask = []
      material.diffuse.contents = UIColor.clear
      material.emission.contents = UIColor.clear
      material.lightingModel = .constant
      material.transparency = 0
      material.blendMode = .alpha
      material.writesToDepthBuffer = true
      material.readsFromDepthBuffer = true
      material.metalness.contents = 0
      material.roughness.contents = 1
      material.specular.contents = UIColor.clear
    }
    material.isDoubleSided = true
  }

  static func makeOverlayPlane(mode: NomoArCameraFilterMode, avatar: NomoNativeAvatar) -> SCNPlane {
    let image: UIImage
    switch mode {
    case .avatar:
      image = makeFeatureImage(for: avatar)
    case .natural:
      image = makeNaturalRetouchImage(for: avatar)
    }
    let size = overlaySize(for: mode)
    let plane = SCNPlane(width: size.width, height: size.height)
    let material = SCNMaterial()
    material.diffuse.contents = image
    material.isDoubleSided = true
    material.lightingModel = .constant
    material.blendMode = .alpha
    material.writesToDepthBuffer = false
    material.readsFromDepthBuffer = true
    plane.firstMaterial = material
    return plane
  }

  static func overlayPosition(for mode: NomoArCameraFilterMode) -> SCNVector3 {
    switch mode {
    case .avatar:
      SCNVector3(0, 0.008, 0.064)
    case .natural:
      SCNVector3(0, 0.002, 0.066)
    }
  }

  private static func overlaySize(for mode: NomoArCameraFilterMode) -> CGSize {
    switch mode {
    case .avatar:
      CGSize(width: 0.172, height: 0.222)
    case .natural:
      CGSize(width: 0.192, height: 0.232)
    }
  }

  private static func makeFeatureImage(for avatar: NomoNativeAvatar) -> UIImage {
    let size = CGSize(width: 512, height: 512)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { context in
      let cg = context.cgContext
      cg.clear(CGRect(origin: .zero, size: size))
      cg.translateBy(x: 0, y: 0)
      let scale = size.width / 180
      cg.scaleBy(x: scale, y: scale)

      if avatar.isAdmin {
        drawAdminMascot(includeSkin: true, in: cg)
      } else {
        drawFace(avatar, includeSkin: true, in: cg)
      }
    }
  }

  private static func makeNaturalRetouchImage(for avatar: NomoNativeAvatar) -> UIImage {
    let size = CGSize(width: 512, height: 512)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { context in
      let cg = context.cgContext
      cg.clear(CGRect(origin: .zero, size: size))
      let scale = size.width / 180
      cg.scaleBy(x: scale, y: scale)
      drawNaturalRetouchOverlay(skin: avatar.skinColor, in: cg)
    }
  }

  private static func drawNaturalRetouchOverlay(skin: UIColor, in cg: CGContext) {
    // Lightweight beauty pass without a visible white face film:
    // warm skin tone, under-eye light, cheek color, V-line contour, and lip tint.
    let warm = skin.mixed(with: UIColor(hex: 0xFFE0C7), amount: 0.52)
    drawSoftEllipse(center: CGPoint(x: 90, y: 82), radius: CGSize(width: 56, height: 66), color: warm, alpha: 0.08, in: cg)
    drawSoftEllipse(center: CGPoint(x: 90, y: 76), radius: CGSize(width: 10, height: 34), color: .white, alpha: 0.16, in: cg)

    drawSoftEllipse(center: CGPoint(x: 66, y: 74), radius: CGSize(width: 21, height: 12), color: .white, alpha: 0.11, in: cg)
    drawSoftEllipse(center: CGPoint(x: 114, y: 74), radius: CGSize(width: 21, height: 12), color: .white, alpha: 0.11, in: cg)

    let blush = UIColor(hex: 0xFF7FA7)
    drawSoftEllipse(center: CGPoint(x: 62, y: 94), radius: CGSize(width: 24, height: 18), color: blush, alpha: 0.18, in: cg)
    drawSoftEllipse(center: CGPoint(x: 118, y: 94), radius: CGSize(width: 24, height: 18), color: blush, alpha: 0.18, in: cg)

    let contour = UIColor(hex: 0x4B241C)
    strokeFaceContour(left: true, color: contour.withAlphaComponent(0.12), lineWidth: 18, inset: 0, in: cg)
    strokeFaceContour(left: false, color: contour.withAlphaComponent(0.12), lineWidth: 18, inset: 0, in: cg)
    strokeFaceContour(left: true, color: contour.withAlphaComponent(0.16), lineWidth: 8, inset: 8, in: cg)
    strokeFaceContour(left: false, color: contour.withAlphaComponent(0.16), lineWidth: 8, inset: 8, in: cg)

    let jaw = UIBezierPath()
    jaw.move(to: CGPoint(x: 65, y: 125))
    jaw.addQuadCurve(to: CGPoint(x: 115, y: 125), controlPoint: CGPoint(x: 90, y: 138))
    contour.withAlphaComponent(0.11).setStroke()
    jaw.lineWidth = 10
    jaw.lineCapStyle = .round
    jaw.stroke()

    let lip = UIBezierPath()
    lip.move(to: CGPoint(x: 74, y: 111))
    lip.addQuadCurve(to: CGPoint(x: 106, y: 111), controlPoint: CGPoint(x: 90, y: 118))
    UIColor(hex: 0xD85C78).withAlphaComponent(0.14).setStroke()
    lip.lineWidth = 5
    lip.lineCapStyle = .round
    lip.stroke()
  }

  private static func strokeFaceContour(left: Bool, color: UIColor, lineWidth: CGFloat, inset: CGFloat, in cg: CGContext) {
    let edgeX: CGFloat = left ? 41 + inset : 139 - inset
    let path = UIBezierPath()
    path.move(to: CGPoint(x: edgeX, y: 48))
    path.addCurve(
      to: CGPoint(x: edgeX + (left ? 16 : -16), y: 122),
      controlPoint1: CGPoint(x: edgeX + (left ? -8 : 8), y: 70),
      controlPoint2: CGPoint(x: edgeX + (left ? -3 : 3), y: 104)
    )
    color.setStroke()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.stroke()
  }

  private static func drawFace(_ avatar: NomoNativeAvatar, includeSkin: Bool, in cg: CGContext) {
    let skin = avatar.skinColor
    let hair = avatar.hairColor
    let outline = UIColor(hex: 0x1B2027).withAlphaComponent(0.22)

    if includeSkin {
      fillEllipse(CGRect(x: 37, y: 70, width: 25, height: 20), color: skin, in: cg)
      fillEllipse(CGRect(x: 118, y: 70, width: 25, height: 20), color: skin, in: cg)

      let head = UIBezierPath(roundedRect: CGRect(x: 38, y: 38, width: 104, height: 92), cornerRadius: 30)
      cg.saveGState()
      cg.translateBy(x: 0, y: 2)
      outline.setFill()
      head.fill()
      cg.restoreGState()
      skin.setFill()
      head.fill()
    }

    drawHair(style: avatar.hair, skin: skin, color: hair, featureOnly: !includeSkin, in: cg)
    drawEyes(style: avatar.eyes, in: cg)
    drawNose(skin: skin, in: cg)
    drawMouth(style: avatar.mouth, in: cg)
    drawAccessory(style: avatar.accessory, in: cg)
  }

  private static func drawAdminMascot(includeSkin: Bool, in cg: CGContext) {
    if includeSkin {
      fillEllipse(CGRect(x: 36, y: 28, width: 108, height: 116), color: UIColor(hex: 0xFFC08A), in: cg)
    }
    let hairPath = UIBezierPath(roundedRect: CGRect(x: 44, y: 26, width: 92, height: 38), cornerRadius: 22)
    UIColor(hex: 0xEFE8D8).setFill()
    hairPath.fill()
    drawEyes(style: 2, in: cg)
    drawNose(skin: UIColor(hex: 0xFFC08A), in: cg)
    drawMouth(style: 1, in: cg)
    drawAccessory(style: 1, in: cg)
  }

  private static func drawHair(style: Int, skin: UIColor, color: UIColor, featureOnly: Bool, in cg: CGContext) {
    color.setFill()
    switch style {
    case 0:
      return
    case 1:
      for index in 0..<8 {
        fillEllipse(
          CGRect(x: 35 + index * 12, y: 27 + (index.isMultiple(of: 2) ? 0 : -5), width: 26, height: 26),
          color: color,
          in: cg
        )
      }
    case 2:
      UIBezierPath(roundedRect: CGRect(x: 46, y: 28, width: 88, height: 34), cornerRadius: 28).fill()
    case 3:
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 43, y: 49))
      path.addQuadCurve(to: CGPoint(x: 135, y: 48), controlPoint: CGPoint(x: 86, y: 10))
      path.addLine(to: CGPoint(x: 132, y: 70))
      path.addQuadCurve(to: CGPoint(x: 45, y: 70), controlPoint: CGPoint(x: 86, y: 40))
      path.close()
      path.fill()
    case 4:
      fillEllipse(CGRect(x: 70, y: 8, width: 40, height: 40), color: color, in: cg)
      UIBezierPath(roundedRect: CGRect(x: 48, y: 36, width: 84, height: 24), cornerRadius: 22).fill()
    case 5:
      UIColor(hex: 0x21313E).setFill()
      UIBezierPath(roundedRect: CGRect(x: 46, y: 28, width: 88, height: 30), cornerRadius: 20).fill()
      UIColor(hex: 0x2EA8FF).setFill()
      UIBezierPath(roundedRect: CGRect(x: 62, y: 20, width: 56, height: 18), cornerRadius: 16).fill()
    case 6:
      UIBezierPath(roundedRect: CGRect(x: 40, y: 36, width: 100, height: 68), cornerRadius: 28).fill()
      fillSkinCutout(
        UIBezierPath(roundedRect: CGRect(x: 48, y: 56, width: 84, height: 42), cornerRadius: 24),
        skin: skin,
        featureOnly: featureOnly,
        in: cg
      )
    case 7:
      UIBezierPath(roundedRect: CGRect(x: 36, y: 32, width: 108, height: 108), cornerRadius: 34).fill()
      fillSkinCutout(
        UIBezierPath(roundedRect: CGRect(x: 46, y: 50, width: 88, height: 76), cornerRadius: 28),
        skin: skin,
        featureOnly: featureOnly,
        in: cg
      )
    default:
      UIBezierPath(roundedRect: CGRect(x: 34, y: 50, width: 30, height: 82), cornerRadius: 18).fill()
      UIBezierPath(roundedRect: CGRect(x: 116, y: 50, width: 30, height: 82), cornerRadius: 18).fill()
      fillEllipse(CGRect(x: 41, y: 17, width: 34, height: 34), color: color, in: cg)
      fillEllipse(CGRect(x: 105, y: 17, width: 34, height: 34), color: color, in: cg)
    }
  }

  private static func fillSkinCutout(_ path: UIBezierPath, skin: UIColor, featureOnly: Bool, in cg: CGContext) {
    if featureOnly {
      cg.saveGState()
      cg.setBlendMode(.clear)
      UIColor.clear.setFill()
      path.fill()
      cg.restoreGState()
    } else {
      skin.setFill()
      path.fill()
    }
  }

  private static func drawEyes(style: Int, in cg: CGContext) {
    let dark = UIColor(hex: 0x24313A)
    switch style {
    case 1:
      strokeArc(CGRect(x: 60, y: 72, width: 24, height: 16), start: .pi, end: .pi * 2, color: dark, width: 5, in: cg)
      strokeArc(CGRect(x: 98, y: 72, width: 24, height: 16), start: .pi, end: .pi * 2, color: dark, width: 5, in: cg)
    case 2:
      for x in [70.0, 108.0] {
        fillEllipse(CGRect(x: x - 12, y: 61, width: 24, height: 34), color: .white, in: cg)
        fillEllipse(CGRect(x: x - 6, y: 74, width: 16, height: 16), color: dark, in: cg)
        fillEllipse(CGRect(x: x - 6, y: 72, width: 6, height: 6), color: .white, in: cg)
      }
    case 3:
      for x in [70.0, 108.0] {
        fillEllipse(CGRect(x: x - 13, y: 60, width: 26, height: 36), color: .white, in: cg)
        fillEllipse(CGRect(x: x - 7, y: 74, width: 16, height: 16), color: dark, in: cg)
        strokeLine(from: CGPoint(x: x - 14, y: 65), to: CGPoint(x: x - 20, y: 60), color: dark, width: 3, in: cg)
        strokeLine(from: CGPoint(x: x + 14, y: 65), to: CGPoint(x: x + 20, y: 60), color: dark, width: 3, in: cg)
      }
    default:
      for x in [70.0, 108.0] {
        fillEllipse(CGRect(x: x - 12, y: 61, width: 24, height: 34), color: .white, in: cg)
        UIColor(hex: 0x24313A).setFill()
        UIBezierPath(roundedRect: CGRect(x: x - 2, y: 65, width: 10, height: 25), cornerRadius: 8).fill()
      }
    }
  }

  private static func drawNose(skin: UIColor, in cg: CGContext) {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 90, y: 84))
    path.addQuadCurve(to: CGPoint(x: 82, y: 102), controlPoint: CGPoint(x: 102, y: 102))
    path.addQuadCurve(to: CGPoint(x: 90, y: 84), controlPoint: CGPoint(x: 86, y: 90))
    skin.mixed(with: .black, amount: 0.22).setFill()
    path.fill()
  }

  private static func drawMouth(style: Int, in cg: CGContext) {
    let color = UIColor(hex: 0x2A1715).withAlphaComponent(0.72)
    switch style {
    case 1:
      strokeArc(CGRect(x: 70, y: 94, width: 38, height: 24), start: 0, end: .pi, color: color, width: 5, in: cg)
    case 2:
      strokeLine(from: CGPoint(x: 78, y: 106), to: CGPoint(x: 101, y: 106), color: color, width: 5, in: cg)
    default:
      strokeArc(CGRect(x: 70, y: 88, width: 42, height: 28), start: 0.2, end: .pi * 0.9, color: color, width: 5, in: cg)
    }
  }

  private static func drawAccessory(style: Int, in cg: CGContext) {
    switch style {
    case 1:
      let dark = UIColor(hex: 0x151D24)
      strokeRoundedRect(CGRect(x: 54, y: 66, width: 32, height: 28), radius: 10, color: dark, width: 4, in: cg)
      strokeRoundedRect(CGRect(x: 94, y: 66, width: 32, height: 28), radius: 10, color: dark, width: 4, in: cg)
      strokeLine(from: CGPoint(x: 86, y: 78), to: CGPoint(x: 94, y: 78), color: dark, width: 4, in: cg)
    case 2:
      UIColor.white.withAlphaComponent(0.86).setFill()
      UIBezierPath(roundedRect: CGRect(x: 62, y: 94, width: 56, height: 24), cornerRadius: 14).fill()
    case 3:
      let blush = UIColor(hex: 0xFF7CA8).withAlphaComponent(0.62)
      fillEllipse(CGRect(x: 48, y: 86, width: 18, height: 18), color: blush, in: cg)
      fillEllipse(CGRect(x: 114, y: 86, width: 18, height: 18), color: blush, in: cg)
    default:
      break
    }
  }

  private static func fillEllipse(_ rect: CGRect, color: UIColor, in cg: CGContext) {
    color.setFill()
    cg.fillEllipse(in: rect)
  }

  private static func drawSoftEllipse(
    center: CGPoint,
    radius: CGSize,
    color: UIColor,
    alpha: CGFloat,
    in cg: CGContext
  ) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(
      colorsSpace: colorSpace,
      colors: [
        color.withAlphaComponent(alpha).cgColor,
        color.withAlphaComponent(alpha * 0.36).cgColor,
        color.withAlphaComponent(0).cgColor,
      ] as CFArray,
      locations: [0, 0.46, 1]
    ) else {
      return
    }

    cg.saveGState()
    cg.translateBy(x: center.x, y: center.y)
    cg.scaleBy(x: radius.width, y: radius.height)
    cg.drawRadialGradient(
      gradient,
      startCenter: .zero,
      startRadius: 0,
      endCenter: .zero,
      endRadius: 1,
      options: [.drawsAfterEndLocation]
    )
    cg.restoreGState()
  }

  private static func strokeLine(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat, in cg: CGContext) {
    color.setStroke()
    cg.setLineWidth(width)
    cg.setLineCap(.round)
    cg.move(to: from)
    cg.addLine(to: to)
    cg.strokePath()
  }

  private static func strokeArc(_ rect: CGRect, start: CGFloat, end: CGFloat, color: UIColor, width: CGFloat, in cg: CGContext) {
    let path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: start, endAngle: end, clockwise: true)
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.stroke()
  }

  private static func strokeRoundedRect(_ rect: CGRect, radius: CGFloat, color: UIColor, width: CGFloat, in cg: CGContext) {
    let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
    color.setStroke()
    path.lineWidth = width
    path.stroke()
  }
}

private extension UIColor {
  convenience init(hex: Int) {
    self.init(
      red: CGFloat((hex >> 16) & 0xff) / 255,
      green: CGFloat((hex >> 8) & 0xff) / 255,
      blue: CGFloat(hex & 0xff) / 255,
      alpha: 1
    )
  }

  func mixed(with other: UIColor, amount: CGFloat) -> UIColor {
    var r1: CGFloat = 0
    var g1: CGFloat = 0
    var b1: CGFloat = 0
    var a1: CGFloat = 0
    var r2: CGFloat = 0
    var g2: CGFloat = 0
    var b2: CGFloat = 0
    var a2: CGFloat = 0
    getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    return UIColor(
      red: r1 + (r2 - r1) * amount,
      green: g1 + (g2 - g1) * amount,
      blue: b1 + (b2 - b1) * amount,
      alpha: a1 + (a2 - a1) * amount
    )
  }
}
