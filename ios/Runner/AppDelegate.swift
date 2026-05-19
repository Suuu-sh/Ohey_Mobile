import Flutter
import Photos
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var qrSaverChannel: FlutterMethodChannel?
  private var widgetSyncChannel: FlutterMethodChannel?
  private var didRegisterArAvatarCameraViewFactory = false
  private let widgetAppGroupIdentifier = "group.app.nomo.nomo"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerArAvatarCameraViewFactory()
    if let controller = window?.rootViewController as? FlutterViewController {
      registerQrSaverChannel(on: controller.binaryMessenger)
      registerWidgetSyncChannel(on: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NomoQrSaver") {
      registerQrSaverChannel(on: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NomoWidgetSync") {
      registerWidgetSyncChannel(on: registrar.messenger())
    }
    if !didRegisterArAvatarCameraViewFactory,
       let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NomoArAvatarCamera") {
      registerArAvatarCameraViewFactory(with: registrar)
    }
  }

  private func registerArAvatarCameraViewFactory() {
    guard !didRegisterArAvatarCameraViewFactory else { return }
    guard let registrar = registrar(forPlugin: "NomoArAvatarCamera") else { return }
    registerArAvatarCameraViewFactory(with: registrar)
  }

  private func registerArAvatarCameraViewFactory(with registrar: FlutterPluginRegistrar) {
    guard !didRegisterArAvatarCameraViewFactory else { return }
    didRegisterArAvatarCameraViewFactory = true
    registrar.register(
      NomoArAvatarCameraFactory(messenger: registrar.messenger()),
      withId: "nomo/ar_avatar_camera"
    )
  }

  private func registerQrSaverChannel(on messenger: FlutterBinaryMessenger) {
    qrSaverChannel = FlutterMethodChannel(name: "nomo/qr_saver", binaryMessenger: messenger)
    qrSaverChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "savePngToPhotos" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.savePngToPhotos(call.arguments, result: result)
    }
  }

  private func registerWidgetSyncChannel(on messenger: FlutterBinaryMessenger) {
    widgetSyncChannel = FlutterMethodChannel(name: "nomo/widget_sync", binaryMessenger: messenger)
    widgetSyncChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "updateSnapshot":
        self?.updateWidgetSnapshot(call.arguments, result: result)
      case "reloadAllTimelines":
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func updateWidgetSnapshot(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let payload = arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_payload", message: "Invalid widget snapshot payload.", details: nil))
      return
    }

    let defaults = UserDefaults(suiteName: widgetAppGroupIdentifier) ?? .standard
    defaults.set(payload["statusKey"] as? String, forKey: "statusKey")
    defaults.set(payload["statusLabel"] as? String, forKey: "statusLabel")
    defaults.set(payload["statusDescription"] as? String, forKey: "statusDescription")
    defaults.set(payload["availableFriendsCount"] as? Int, forKey: "availableFriendsCount")
    defaults.set(payload["availableFriendNames"] as? [String] ?? [], forKey: "availableFriendNames")

    if let updatedAtMillis = payload["updatedAtMillis"] as? Double {
      defaults.set(updatedAtMillis, forKey: "updatedAtMillis")
    } else if let updatedAtMillis = payload["updatedAtMillis"] as? Int {
      defaults.set(Double(updatedAtMillis), forKey: "updatedAtMillis")
    }
    defaults.synchronize()

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    result(nil)
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
}
