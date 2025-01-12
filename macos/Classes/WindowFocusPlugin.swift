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
      case "setInactivityTimeOut":
        if let args = call.arguments as? [String: Any],
                   let threshold = args["inactivityTimeOut"] as? TimeInterval {
                    idleTracker?.setIdleThreshold(threshold / 1000.0)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected 'inactivityTimeOut' parameter", details: nil))
                }
        break;
    case "getIdleThreshold":
        if let threshold = idleTracker?.idleThreshold {
            result(Int(threshold * 1000))
        } else {
            result(0)
        }
    case "setDebugMode":
        if let args = call.arguments as? [String: Any],
           let debug = args["debug"] as? Bool {
            idleTracker?.setDebugMode(debug)
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected 'debug' parameter", details: nil))
        }
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
    public var idleThreshold: TimeInterval = 5
    private let channel: FlutterMethodChannel
    private var debugMode: Bool = false
    private var userIsActive: Bool = true


    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        startTracking()
    }

    private func startTracking() {
        // Загружаем сохраненный idleThreshold из UserDefaults, если он есть
        if let savedThreshold = UserDefaults.standard.object(forKey: "idleThreshold") as? TimeInterval {
            idleThreshold = savedThreshold
        }

        if debugMode {
            print("Debug: Started tracking with idleThreshold = \(idleThreshold)")
        }

        // Отслеживание взаимодействий пользователя
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { [weak self] event in
            if let self = self {
                if self.debugMode {
                    print("Debug: User interaction detected: \(event)")
                }
                self.userDidInteract()
            }
        }

        // Запуск таймера для проверки времени бездействия
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkIdleTime), userInfo: nil, repeats: true)
    }

    @objc private func checkIdleTime() {
            let idleTime = Date().timeIntervalSince(lastActivityTime)

            // Если пользователь превысил таймаут бездействия
            if idleTime > idleThreshold {
                if userIsActive {
                    userIsActive = false
                    if debugMode {
                        print("Debug: User became inactive. Idle time = \(idleTime)")
                    }
                    channel.invokeMethod("onUserInactivity", arguments: nil)
                }
            } else {
                // Если пользователь вновь стал активным
                if !userIsActive {
                    userIsActive = true
                    if debugMode {
                        print("Debug: User became active. Idle time reset.")
                    }
                    channel.invokeMethod("onUserActive", arguments: nil)
                }
            }
        }
    private func userDidInteract() {
        lastActivityTime = Date()
        if !userIsActive {
                    userIsActive = true
                    if debugMode {
                        print("Debug: User became active due to interaction.")
                    }
                    channel.invokeMethod("onUserActive", arguments: nil)
                }
    }

    func setIdleThreshold(_ threshold: TimeInterval) {
        self.idleThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: "idleThreshold")
        if debugMode {
                    print("Debug: Updated idleThreshold to \(threshold)")
                }
    }

    func setDebugMode(_ debug: Bool) {
        self.debugMode = debug
        if debugMode {
            print("Debug: Debug mode enabled")
        }
    }
    deinit {
        timer?.invalidate()
    }
}
