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
  private var pipChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDzdftYEP9bbhXFHyjGSmydrvGKZSx6cSk")

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    configureAudioSession()

    if let registrar = self.registrar(forPlugin: "com.sdpi.schat/pip") {
      setupPipChannel(messenger: registrar.messenger())
    } else if let controller = window?.rootViewController as? FlutterViewController {
      setupPipChannel(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
      try audioSession.setActive(true)
    } catch {
      print("AppDelegate: Error configuring AVAudioSession: \(error)")
    }
  }

  private var activeRootViewController: UIViewController? {
    if let window = self.window, let root = window.rootViewController {
      return root
    }
    if #available(iOS 13.0, *) {
      for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene {
          for window in windowScene.windows where window.isKeyWindow || window.rootViewController != nil {
            if let root = window.rootViewController {
              return root
            }
          }
        }
      }
    }
    return nil
  }

  private func setupPipChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.sdpi.schat/pip", binaryMessenger: messenger)
    self.pipChannel = channel
    channel.setMethodCallHandler { [weak self] (call, result) in
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
      case "exitPip":
        self.stopPictureInPicture()
        result(true)
      case "isPipSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleCallActive(isActive: Bool) {
    if isActive {
      configureAudioSession()
      setupPictureInPicture()
    } else {
      stopPictureInPicture()
    }
  }

  private func setupPictureInPicture() {
    guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

    if #available(iOS 15.0, *) {
      if pipController == nil {
        guard let rootVC = activeRootViewController else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupPictureInPicture()
          }
          return
        }

        let sourceView = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 240))
        sourceView.backgroundColor = .clear
        sourceView.isUserInteractionEnabled = false
        sourceView.layer.cornerRadius = 16
        sourceView.clipsToBounds = true
        rootVC.view.addSubview(sourceView)
        self.pipSourceView = sourceView

        let callVC = AVPictureInPictureVideoCallViewController()
        callVC.preferredContentSize = CGSize(width: 480, height: 640)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 480, height: 640))
        container.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)

        let iconView = UIImageView(image: UIImage(systemName: "video.fill"))
        iconView.tintColor = UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1.0)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        let label = UILabel()
        label.text = "Call in Progress"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
          iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
          iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -20),
          iconView.widthAnchor.constraint(equalToConstant: 48),
          iconView.heightAnchor.constraint(equalToConstant: 48),
          label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
          label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        callVC.view.addSubview(container)
        self.pipVideoCallViewController = callVC

        let contentSource = AVPictureInPictureController.ContentSource(
          activeVideoCallSourceView: sourceView,
          contentViewController: callVC
        )

        let pip = AVPictureInPictureController(contentSource: contentSource)
        pip.delegate = self
        pip.canStartPictureInPictureAutomaticallyFromInline = true
        self.pipController = pip
      } else {
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
      }
    }
  }

  private func startPictureInPicture() -> Bool {
    guard let pip = pipController else {
      setupPictureInPicture()
      guard let pip = pipController, pip.isPictureInPicturePossible else { return false }
      pip.startPictureInPicture()
      return true
    }
    if pip.isPictureInPicturePossible {
      pip.startPictureInPicture()
      return true
    }
    return false
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

  // MARK: - AVPictureInPictureControllerDelegate

  public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: ["isInPip": true])
  }

  public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: ["isInPip": true])
  }

  public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: ["isInPip": false])
  }

  public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: ["isInPip": false])
  }

  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    print("AppDelegate: Failed to start PiP: \(error.localizedDescription)")
    pipChannel?.invokeMethod("onPipModeChanged", arguments: ["isInPip": false])
  }
}
