import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var isScreenRecordingActive = false
  private var screenRecordingChannel: FlutterMethodChannel?
  private var secureView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Enable screenshot protection immediately
    enableScreenshotProtection()

    let controller = window?.rootViewController as! FlutterViewController

    // Screenshot prevention channel
    let screenshotChannel = FlutterMethodChannel(
      name: "security/screenshots",
      binaryMessenger: controller.binaryMessenger
    )

    screenshotChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "preventScreenshots":
        if let prevent = call.arguments as? Bool {
          self?.preventScreenshots(prevent: prevent)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Screen recording prevention channel
    screenRecordingChannel = FlutterMethodChannel(
      name: "security/screen_recording",
      binaryMessenger: controller.binaryMessenger
    )

    screenRecordingChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "preventScreenRecording":
        if let prevent = call.arguments as? Bool {
          self?.preventScreenRecording(prevent: prevent)
        }
        result(nil)
      case "isScreenRecordingActive":
        let isRecording = self?.checkScreenRecording() ?? false
        result(isRecording)
      case "startMonitoring":
        self?.startScreenRecordingMonitoring()
        result(nil)
      case "showRecordingWarning":
        self?.showRecordingWarning()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func enableScreenshotProtection() {
    DispatchQueue.main.async {
      self.preventScreenshots(prevent: true)
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Re-enable screenshot protection when app becomes active
    enableScreenshotProtection()
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    // Keep protection active even when app goes to background
    enableScreenshotProtection()
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    // Ensure protection remains active in background
    enableScreenshotProtection()
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    // Re-enable protection when coming back to foreground
    enableScreenshotProtection()
  }

  private func preventScreenshots(prevent: Bool) {
    DispatchQueue.main.async {
      if prevent {
        self.addSecureView()
      } else {
        self.removeSecureView()
      }
    }
  }

  private func addSecureView() {
    guard secureView == nil else { return }

    // Method 1: Create a secure text field that prevents screenshots
    let textField = UITextField()
    textField.isSecureTextEntry = true
    textField.isUserInteractionEnabled = false
    textField.backgroundColor = UIColor.clear
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.alpha = 0.01 // Nearly invisible but still functional

    // Method 2: Add additional security layer
    let secureContainer = UIView()
    secureContainer.backgroundColor = UIColor.clear
    secureContainer.translatesAutoresizingMaskIntoConstraints = false
    secureContainer.isUserInteractionEnabled = false

    // Add both to window
    window?.addSubview(secureContainer)
    secureContainer.addSubview(textField)
    window?.sendSubviewToBack(secureContainer)

    // Set constraints to cover entire window
    NSLayoutConstraint.activate([
      secureContainer.topAnchor.constraint(equalTo: window!.topAnchor),
      secureContainer.bottomAnchor.constraint(equalTo: window!.bottomAnchor),
      secureContainer.leadingAnchor.constraint(equalTo: window!.leadingAnchor),
      secureContainer.trailingAnchor.constraint(equalTo: window!.trailingAnchor),

      textField.topAnchor.constraint(equalTo: secureContainer.topAnchor),
      textField.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
      textField.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
      textField.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor)
    ])

    secureView = secureContainer
  }

  private func removeSecureView() {
    secureView?.removeFromSuperview()
    secureView = nil
  }

  private func preventScreenRecording(prevent: Bool) {
    // iOS doesn't allow preventing screen recording directly
    // But we can detect it and take action
    if prevent {
      startScreenRecordingMonitoring()
    }
  }

  private func checkScreenRecording() -> Bool {
    if #available(iOS 11.0, *) {
      return UIScreen.main.isCaptured
    }
    return false
  }

  private func startScreenRecordingMonitoring() {
    if #available(iOS 11.0, *) {
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        let isRecording = UIScreen.main.isCaptured
        self?.isScreenRecordingActive = isRecording

        self?.screenRecordingChannel?.invokeMethod(
          "screenRecordingStatusChanged",
          arguments: ["isRecording": isRecording]
        )
      }
    }
  }

  private func showRecordingWarning() {
    DispatchQueue.main.async {
      let alert = UIAlertController(
        title: "Screen Recording Detected",
        message: "Screen recording is not allowed during quiz sessions for security reasons.",
        preferredStyle: .alert
      )

      alert.addAction(UIAlertAction(title: "OK", style: .default))

      if let controller = self.window?.rootViewController {
        controller.present(alert, animated: true)
      }
    }
  }
}

// Extension removed - using improved implementation in AppDelegate
