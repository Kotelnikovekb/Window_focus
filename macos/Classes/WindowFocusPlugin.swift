import Cocoa
import FlutterMacOS
import AppKit
import ApplicationServices
import Foundation



public class WindowFocusPlugin: NSObject, FlutterPlugin {
  var channel: FlutterMethodChannel?
  var windowFocusObserver: WindowFocusObserver?
  var idleTracker: IdleTracker?




  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "expert.kotelnikoff/window_focus", binaryMessenger: registrar.messenger)
    let instance = WindowFocusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)


    instance.windowFocusObserver = WindowFocusObserver { (message) in
                channel.invokeMethod("onFocusChange", arguments: ["appName": message, "windowTitle": message]) { (result) in

                }
            }
    instance.idleTracker = IdleTracker(channel: channel)



  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      break
      case "setIdleThreshold":
        if let args = call.arguments as? [String: Any],
           let threshold = args["threshold"] as? TimeInterval {
            idleTracker?.setIdleThreshold(threshold)
        }
        result(nil)
        break;
        case "getIdleThreshold":
            result(idleTracker?.idleThreshold)
            break;
    default:
      result(FlutterMethodNotImplemented)
    }
  }


}

class WindowFocusObserver {

    private var focusedAppPID: pid_t = -1
        private var focusedWindowID: CGWindowID = 0
        private let sendMessage: (String) -> Void

        init(sendMessage: @escaping (String) -> Void) {
            self.sendMessage = sendMessage

            // Добавляем наблюдателя за изменением активного приложения
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(focusedAppChanged(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)

            // Добавляем наблюдателя за изменением фокуса окна
            NotificationCenter.default.addObserver(self, selector: #selector(focusedWindowChanged), name: NSApplication.didBecomeActiveNotification, object: nil)
        }

        @objc private func focusedAppChanged(_ notification: Notification) {
            if let userInfo = notification.userInfo,
               let application = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let pid = application.processIdentifier
                if pid != focusedAppPID {
                    focusedAppPID = pid
                    let message = "\(application.localizedName ?? "Unknown")"
                    print(message)
                    sendMessage(message)
                }
            }
        }

        @objc private func focusedWindowChanged() {
            let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
            if let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
                for info in infoList {
                    if let windowOwnerPID = info[kCGWindowOwnerPID as String] as? pid_t, windowOwnerPID == focusedAppPID,
                       let windowID = info[kCGWindowNumber as String] as? CGWindowID, windowID != focusedWindowID {
                        focusedWindowID = windowID
                        let message = "\(info[kCGWindowName as String] ?? "Unknown")"
                        sendMessage(message)
                    }
                }
            }
        }

        deinit {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            NotificationCenter.default.removeObserver(self)
        }
}
public class IdleTracker: NSObject {
    private var lastActivityTime: Date = Date()
    private var timer: Timer?
    public var idleThreshold: TimeInterval = 5 // Default to 5 seconds
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        startTracking()
    }

    private func startTracking() {
        let idleThreshold = UserDefaults.standard.double(forKey: "idleThreshold")
        print("idleThreshold: \(idleThreshold)")
        if(idleThreshold > 0) {
            self.idleThreshold = idleThreshold
        }

        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { [weak self] event in
            self?.userDidInteract()
        }

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkIdleTime), userInfo: nil, repeats: true)
    }

    @objc private func checkIdleTime() {
        let idleTime = Date().timeIntervalSince(lastActivityTime)
        if idleTime > idleThreshold {
            channel.invokeMethod("onUserActiveChange", arguments: false)
        } else {
            channel.invokeMethod("onUserActiveChange", arguments: true)
        }
    }

    private func userDidInteract() {
        lastActivityTime = Date()
    }

    func setIdleThreshold(_ threshold: TimeInterval) {
        self.idleThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: "idleThreshold")
    }

    deinit {
        timer?.invalidate()
    }
}