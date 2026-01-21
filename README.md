# Window focus plugin

## Language Versions

- [English](README.md)
- [Русский](README_ru.md)

![Usage_example](image/screenshot.png)

[![Pub](https://img.shields.io/pub/v/window_focus)](https://pub.dev/packages/window_focus)

**Window Focus** is a Flutter plugin that allows you to track user activity and focus on the active window for Windows and macOS platforms. The plugin provides features such as detecting user inactivity, identifying the active application, and enabling debug mode for enhanced logging.
## Key Features:

### User Inactivity Tracking:
The plugin enables you to detect periods of user inactivity within your Flutter application. You can customize the inactivity threshold and handle inactivity events according to your needs.

### Active Window Title Retrieval:
Provides the ability to retrieve the title of the active window of the operating system. For Mac OS, this is the application name, and for Windows, it's the window title.
### Debug Mode
Enable detailed logs for troubleshooting during development.
### Set Custom Idle Threshold
Define the timeout period after which the user is considered inactive.

### Screenshot Capture
Capture the entire screen or just the active window. This is useful for time tracking applications.

# Plugin Installation
## Windows
No action required.
## Mac OS
### Setup for window focus tracking
You need to add the following code to the Info.plist file for MacOS:
```xml
<key>NSApplicationSupportsSecureRestorableState</key>
<true/>
```

### Setup for screen recording (screenshots)
To use the screenshot functionality on macOS 10.15+, you must request screen recording permission. You can check the permission status using `checkScreenRecordingPermission()` and request it using `requestScreenRecordingPermission()`.

The user must manually enable this in:
**System Preferences > Security & Privacy > Privacy > Screen Recording**

### Setup for Global Keyboard Tracking (macOS)
To track keyboard activity globally (outside the app) on macOS, the application requires **Accessibility** permissions. 
**Crucial:** Without these permissions, the plugin will only detect mouse movements and clicks outside the app, but **keyboard events will be ignored** for security reasons.

The user must manually enable this in:
**System Preferences > Security & Privacy > Privacy > Accessibility**
(Or **System Settings > Privacy & Security > Accessibility** on macOS Ventura and newer).

# Plugin Usage
## Import the plugin:
```dart
import 'package:window_focus/window_focus.dart';
```
## Example
```dart
  void main() {
  final windowFocus = WindowFocus(debug: true, duration: Duration(seconds: 10));

  // Add focus change listener
  windowFocus.addFocusChangeListener((appWindow) {
    print('Active window: ${appWindow.appName}, Title: ${appWindow.windowTitle}');
  });

  // Add user activity listener
  windowFocus.addUserActiveListener((isActive) {
    if (isActive) {
      print('User is active');
    } else {
      print('User is inactive');
    }
  });
}
```

# API Reference
## Constructor
```dart
WindowFocus({bool debug = false, Duration duration = const Duration(seconds: 1)})
```

- **debug** (optional): Enables debug mode for detailed logs.
- **duration** (optional): Sets the user inactivity timeout. Default is 1 second.

## Methods

### Future<void> setIdleThreshold(Duration duration)

Sets the threshold for detecting user inactivity.
- **Parameters:**
  - `duration`: The duration after which the user is considered inactive.
  ```dart
  await windowFocus.setIdleThreshold(Duration(seconds: 15));
  ```

### Future<Duration> getIdleThreshold()
Gets the current idle threshold.
- **Returns**: `Duration` - The currently set idle threshold.
```dart
final threshold = await windowFocus.getIdleThreshold();
print('Idle threshold: ${threshold.inSeconds} seconds');
 ```

### void addFocusChangeListener(Function(AppWindowDto) listener)
Adds a listener for changes in the focused window.

- **Parameters:**
  - `listener`: A callback function that receives an AppWindowDto object containing:
      - `appName`: The name of the active application.
      - `windowTitle`: The title of the active window.

**Platform-specific Details**
- Windows:
  - appName is the name of the executable file (e.g., chrome.exe).
  - windowTitle is the title of the active window (e.g., Flutter Documentation).
- macOS:
  - appName and windowTitle are the same and represent the name of the active application (e.g., Safari).
```dart
windowFocus.addFocusChangeListener((appWindow) {
  print('Active application: ${appWindow.appName}, Window title: ${appWindow.windowTitle}');
});
```
### void addUserActiveListener(Function(bool) listener)
Adds a listener for user activity changes.
- **Parameters:**
  - `listener`: A callback function that receives a bool indicating user activity (true for active, false for inactive).

```dart
windowFocus.addUserActiveListener((isActive) {
  if (isActive) {
    print('User is active');
  } else {
    print('User is inactive');
  }
});
```
### Future<void> setDebug(bool value)
Enables or disables debug mode.
- **Parameters:**
  - `value`: true to enable debug mode, false to disable it.
```dart
await windowFocus.setDebug(true);
```

### Future<Uint8List?> takeScreenshot({bool activeWindowOnly = false})
Takes a screenshot of the entire screen or just the active window.
- **Parameters:**
  - `activeWindowOnly`: If true, captures only the currently focused window.
- **Returns**: `Future<Uint8List?>` - PNG image data.

```dart
Uint8List? screenshot = await windowFocus.takeScreenshot(activeWindowOnly: true);
```

### Future<bool> checkScreenRecordingPermission()
Checks if screen recording permission is granted (macOS).

### Future<void> requestScreenRecordingPermission()
Requests screen recording permission (macOS).

## DTO: AppWindowDto
Represents the active application and window information.

**Properties**
- `appName`: String - The name of the active application.
- `windowTitle`: String - The title of the active window.

**Example**

```dart
final appWindow = AppWindowDto(appName: "Chrome", windowTitle: "Flutter Documentation");
print(appWindow); // Output: Window title: Flutter Documentation. AppName: Chrome
```
# About the author
My telegram channel - [@kotelnikoff_dev](https://t.me/kotelnikoff_dev)
Contributions

Contributions are welcome! Feel free to open issues or create pull requests on the [GitHub repository](https://github.com/Kotelnikovekb/Window_focus).
