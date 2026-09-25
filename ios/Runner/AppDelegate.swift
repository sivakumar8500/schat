import Flutter
import UIKit
import GoogleMaps
import AVKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVPictureInPictureControllerDelegate {
  private var pipController: AVPictureInPictureController?
  private var pipVideoCallViewController: AVPictureInPictureVideoCallViewController?
  private var pipSourceView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDzdftYEP9bbhXFHyjGSmydrvGKZSx6cSk")

    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
      try audioSession.setActive(true)
    } catch {
      print("AppDelegate: Error configuring AVAudioSession: \(error)")
    }

    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      setupPipChannel(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupPipChannel(messenger: FlutterBinaryMessenger) {
    let pipChannel = FlutterMethodChannel(name: "com.sdpi.schat/pip", binaryMessenger: messenger)
    pipChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "setCallActive":
        if let args = call.arguments as? [String: Any],
           let isActive = args["isActive"] as? Bool {
          self.handleCallActive(isActive: isActive)
          result(true)
        } else {
          result(false)
        }
      case "enterPip":
        let started = self.startPictureInPicture()
        result(started)
      case "isPipSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleCallActive(isActive: Bool) {
    if isActive {
      setupPictureInPicture()
    } else {
      stopPictureInPicture()
    }
  }

  private func setupPictureInPicture() {
    guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

    if #available(iOS 15.0, *) {
      if pipController == nil {
        if let rootVC = window?.rootViewController {
          let sourceView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
          sourceView.backgroundColor = .clear
          sourceView.isUserInteractionEnabled = false
          rootVC.view.addSubview(sourceView)
          self.pipSourceView = sourceView

          let callVC = AVPictureInPictureVideoCallViewController()
          callVC.preferredContentSize = CGSize(width: 9, height: 16)
          self.pipVideoCallViewController = callVC

          let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: sourceView,
            contentViewController: callVC
          )

          let pip = AVPictureInPictureController(contentSource: contentSource)
          pip.delegate = self
          pip.canStartPictureInPictureAutomaticallyFromInline = true
          self.pipController = pip
        }
      } else {
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
      }
    }
  }

  private func startPictureInPicture() -> Bool {
    guard let pip = pipController, pip.isPictureInPicturePossible else {
      return false
    }
    pip.startPictureInPicture()
    return true
  }

  private func stopPictureInPicture() {
    pipController?.stopPictureInPicture()
    if #available(iOS 15.0, *) {
      pipController?.canStartPictureInPictureAutomaticallyFromInline = false
    }
    pipSourceView?.removeFromSuperview()
    pipSourceView = nil
    pipVideoCallViewController = nil
    pipController = nil
  }
}
