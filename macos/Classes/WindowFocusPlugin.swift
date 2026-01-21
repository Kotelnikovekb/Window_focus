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
    case "takeScreenshot":
      if let args = call.arguments as? [String: Any],
         let activeWindowOnly = args["activeWindowOnly"] as? Bool {
        takeScreenshot(activeWindowOnly: activeWindowOnly, result: result)
      } else {
        takeScreenshot(activeWindowOnly: false, result: result)
      }
    case "checkScreenRecordingPermission":
      result(checkScreenRecordingPermission())
    case "requestScreenRecordingPermission":
      requestScreenRecordingPermission()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func checkScreenRecordingPermission() -> Bool {
    if #available(macOS 10.15, *) {
      return CGPreflightScreenCaptureAccess()
    }
    return true
  }

  private func requestScreenRecordingPermission() {
    if #available(macOS 10.15, *) {
      CGRequestScreenCaptureAccess()
    } else {
      let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording")!
      NSWorkspace.shared.open(url)
    }
  }

  private func takeScreenshot(activeWindowOnly: Bool, result: @escaping FlutterResult) {
    let displayID = CGMainDisplayID()
    var image: CGImage?

    if activeWindowOnly {
      // Пытаемся получить актуальное активное приложение и его окно прямо сейчас
      let activeApp = NSWorkspace.shared.frontmostApplication
      let activePID = activeApp?.processIdentifier
      let activeName = activeApp?.localizedName ?? "Unknown"
      
      print("[WindowFocus] Active App: \(activeName), PID: \(String(describing: activePID))")

      // Используем .optionOnScreenOnly для поиска видимых окон
      let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
      if let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
        
        // Сначала ищем окна АКТИВНОГО приложения
        for info in infoList {
          if let windowOwnerPID = info[kCGWindowOwnerPID as String] as? pid_t, windowOwnerPID == activePID {
            if let windowID = info[kCGWindowNumber as String] as? CGWindowID {
               let windowLayer = info[kCGWindowLayer as String] as? Int ?? 0
               let windowName = info[kCGWindowName as String] as? String ?? "No Name"
               let windowBounds = info[kCGWindowBounds as String] as? [String: Any] ?? [:]
               
               print("[WindowFocus] Potential window: \(windowName), ID: \(windowID), Layer: \(windowLayer), Bounds: \(windowBounds)")
               
               // На macOS 0 - это обычный уровень окон. 
               // Но иногда приложения (как Chrome) могут иметь несколько окон. 
               // Мы берем первое подходящее окно на уровне 0.
               if windowLayer == 0 {
                 // Захватываем именно это окно
                 image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, .bestResolution)
                 if image != nil {
                     print("[WindowFocus] Successfully captured active app window ID: \(windowID)")
                     break
                 }
               }
            }
          }
        }
      }
      
      // Если по какой-то причине не нашли окно активного приложения, но хотим только активное окно,
      // можно попробовать взять САМОЕ ВЕРХНЕЕ окно вообще (кроме десктопа и меню)
      if image == nil {
          print("[WindowFocus] Active app window not found, trying top-most window")
          if let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
              for info in infoList {
                  let windowLayer = info[kCGWindowLayer as String] as? Int ?? 0
                  if windowLayer == 0 {
                      if let windowID = info[kCGWindowNumber as String] as? CGWindowID {
                          print("[WindowFocus] Capturing top-most window ID: \(windowID)")
                          image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, .bestResolution)
                          if image != nil { break }
                      }
                  }
              }
          }
      }
    }

    if image == nil {
      // Захват всего экрана
      print("[WindowFocus] Capturing full screen")
      image = CGDisplayCreateImage(displayID)
    }

    guard let cgImage = image else {
      result(FlutterError(code: "SCREENSHOT_ERROR", message: "Failed to capture screenshot", details: nil))
      return
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let imageData = bitmapRep.representation(using: .png, properties: [:]) else {
      result(FlutterError(code: "CONVERSION_ERROR", message: "Failed to convert image to PNG", details: nil))
      return
    }

    result(FlutterStandardTypedData(bytes: imageData))
  }


}

class WindowFocusObserver {

    private var focusedAppPID: pid_t = -1
        internal var focusedWindowID: CGWindowID = 0
        private let sendMessage: (String) -> Void

        init(sendMessage: @escaping (String) -> Void) {
            self.sendMessage = sendMessage

        // Добавляем наблюдателя за изменением активного приложения (глобально)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(focusedAppChanged(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc private func focusedAppChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let application = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            let pid = application.processIdentifier
            if pid != focusedAppPID {
                focusedAppPID = pid
                let message = "\(application.localizedName ?? "Unknown")"
                sendMessage(message)
                
                // Сбрасываем ID окна, так как приложение сменилось
                focusedWindowID = 0
                // Можно попробовать сразу найти главное окно нового приложения
                updateFocusedWindowID()
            }
        }
    }

    private func updateFocusedWindowID() {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        if let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for info in infoList {
                if let windowOwnerPID = info[kCGWindowOwnerPID as String] as? pid_t, windowOwnerPID == focusedAppPID {
                    if let windowID = info[kCGWindowNumber as String] as? CGWindowID {
                        let windowLayer = info[kCGWindowLayer as String] as? Int ?? 0
                        if windowLayer == 0 {
                            focusedWindowID = windowID
                            break
                        }
                    }
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


    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        startTracking()
        setupEventTap()
    }

    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | 
                         (1 << CGEventType.keyUp.rawValue) | 
                         (1 << CGEventType.flagsChanged.rawValue) | 
                         (1 << CGEventType.mouseMoved.rawValue) | 
                         (1 << CGEventType.leftMouseDown.rawValue) | 
                         (1 << CGEventType.rightMouseDown.rawValue)
        
        print("[WindowFocus] Creating event tap with mask: \(eventMask)")

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap, // Попробуем другой тип тапа
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let tracker = Unmanaged<IdleTracker>.fromOpaque(refcon).takeUnretainedValue()
                    if tracker.debugMode {
                        print("[WindowFocus] EventTap detected event type: \(type.rawValue)")
                    }
                    tracker.userDidInteract()
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("[WindowFocus] Failed to create event tap with .cgAnnotatedSessionEventTap. Trying .cghidEventTap...")
            
            // Fallback to .cghidEventTap
            if let eventTapHid = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: CGEventMask(eventMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    if let refcon = refcon {
                        let tracker = Unmanaged<IdleTracker>.fromOpaque(refcon).takeUnretainedValue()
                        if tracker.debugMode {
                            print("[WindowFocus] EventTap (HID) detected event type: \(type.rawValue)")
                        }
                        tracker.userDidInteract()
                    }
                    return Unmanaged.passUnretained(event)
                },
                userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            ) {
                self.eventTap = eventTapHid
                setupRunLoopSource(eventTapHid)
                print("[WindowFocus] Event tap (HID) created successfully")
            } else {
                print("[WindowFocus] Failed to create event tap. Check Accessibility permissions.")
            }
            return
        }

        self.eventTap = eventTap
        setupRunLoopSource(eventTap)
        print("[WindowFocus] Event tap created successfully")
    }

    private func setupRunLoopSource(_ eventTap: CFMachPort) {
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
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
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown, .flagsChanged]) { [weak self] event in
            if let self = self {
                if self.debugMode {
                    print("[WindowFocus] NSEvent monitor detected: \(event.type) (rawValue: \(event.type.rawValue))")
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
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        timer?.invalidate()
    }
}
