# Window focus plugin

## Language Versions

- [English](README.md)
- [Русский](README_ru.md)

![Usage_example](image/screenshot.png)

[![Pub](https://img.shields.io/pub/v/window_focus)](https://pub.dev/packages/window_focus)

Window Focus is a convenient plugin for Flutter that allows you to track user inactivity and obtain information about the title of the active window on Mac OS and Windows.

## Key Features:

### User Inactivity Tracking:
The plugin enables you to detect periods of user inactivity within your Flutter application. You can customize the inactivity threshold and handle inactivity events according to your needs.

### Active Window Title Retrieval:
Provides the ability to retrieve the title of the active window of the operating system. For Mac OS, this is the application name, and for Windows, it's the window title.

# Plugin Installation
## Windows
No action required.
## Mac OS
You need to add the following code to the Info.plist file for MacOS:
```xml
<key>NSApplicationSupportsSecureRestorableState</key>
<true/>
```
# Plugin Usage
```dart
  final _windowFocusPlugin = WindowFocus();
  
  /// Listener for user's active window change events
  _windowFocusPlugin.addFocusChangeListener((p0) {
    setState(() {
      activeWindowTitle='${p0.windowTitle}';
      /// activeWindowTitle - contains 2 fields windowTitle = window title, appName = Application name.
      /// On Mac OS, these names are the same. On Windows, appName is the name of the process in which the window is running.
    });
  });
  /// Listener for user activity. Works with true if the user is active and false if the user is inactive.
  _windowFocusPlugin.addUserActiveListener((p0) {
    setState(() {
      userIdle=p0;
    });
  });
  /// Setting the user inactivity threshold. Default is 5 seconds.
  _windowFocusPlugin.setIdleThreshold(duration: duration);

  /// Returns the current inactivity threshold
  Duration duration = await _windowFocusPlugin.idleThreshold;

```

# About the author
My telegram channel - [@kotelnikoff_dev](https://t.me/kotelnikoff_dev)
