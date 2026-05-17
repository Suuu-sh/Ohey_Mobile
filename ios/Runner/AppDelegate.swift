import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var qrSaverChannel: FlutterMethodChannel?
  private var instagramStoryChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      registerQrSaverChannel(on: controller.binaryMessenger)
      registerInstagramStoryChannel(on: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NomoQrSaver") {
      registerQrSaverChannel(on: registrar.messenger())
      registerInstagramStoryChannel(on: registrar.messenger())
    }
  }

  private func registerInstagramStoryChannel(on messenger: FlutterBinaryMessenger) {
    instagramStoryChannel = FlutterMethodChannel(name: "nomo/instagram_story", binaryMessenger: messenger)
    instagramStoryChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.shareImageToInstagramStory(call.arguments, result: result)
    }
  }

  private func shareImageToInstagramStory(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let args = arguments as? [String: Any],
      let path = args["path"] as? String,
      let image = UIImage(contentsOfFile: path),
      let imageData = image.pngData()
    else {
      result(FlutterError(code: "invalid_image", message: "Invalid story image.", details: nil))
      return
    }

    guard let url = URL(string: "instagram-stories://share") else {
      result(false)
      return
    }

    DispatchQueue.main.async {
      guard UIApplication.shared.canOpenURL(url) else {
        result(false)
        return
      }

      let pasteboardItems: [[String: Any]] = [[
        "com.instagram.sharedSticker.backgroundImage": imageData
      ]]
      let options: [UIPasteboard.OptionsKey: Any] = [
        .expirationDate: Date().addingTimeInterval(60 * 5)
      ]
      UIPasteboard.general.setItems(pasteboardItems, options: options)
      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
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
