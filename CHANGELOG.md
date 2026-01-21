## [1.2.1] - 2026-01-22
### Changed
- **macOS Window Titles:**
    - Improved active window title tracking using `CGWindowListCopyWindowInfo`.
    - Added periodical (1s) check for window title changes within the same application.
    - Added fallback to application name if window title is unavailable.

### Fixed
- **macOS Idle Tracking:**
    - Fixed issue where user status could get stuck in "idle".
    - Implemented combined monitoring using system session timers, HID timers, and manual event tracking for maximum reliability.
- **Example App:**
    - Fixed idle timeout saving and loading from `UserDefaults` on macOS.
    - Fixed UI logic for displaying activity status.
    - Renamed internal state variables for better clarity (`isUserActive` instead of `userIdle`).

## [1.2.0] - 2026-01-22
### Added
- **Screenshot Capture:**
    - New method `takeScreenshot({bool activeWindowOnly})` to capture the entire screen or just the active window.
    - Added `checkScreenRecordingPermission()` and `requestScreenRecordingPermission()` for macOS 10.15+.
- **Global Keyboard Activity (macOS):**
    - Implemented global keyboard tracking via `CGEventTap` for more accurate idle detection.
    - Added detailed logs for event monitoring in debug mode.
- **Example App Enhancements:**
    - Added auto-screenshot feature with customizable intervals.
    - Added screenshot logging and preview in the UI.
    - Improved UI with app usage statistics and activity logs.

### Changed
- **Improved Active Window Capture:**
    - macOS: Now dynamically detects the frontmost application and its main window for screenshots.
    - Windows: Switched to `BitBlt` from screen context for more reliable capture of hardware-accelerated windows (e.g., Chrome).
- **Refined Idle Tracking:**
    - Expanded event mask on macOS to include system modifier keys (Shift, Cmd, etc.).
    - Improved resources cleanup and lifecycle management in native code.

### Fixed
- Fixed macOS compilation error related to `CFRunLoopSourceCreate`.
- Fixed various syntax errors and widget hierarchy issues in the example app.
- Fixed issue where screenshot was always capturing the app itself instead of the active window.

## [1.1.0] - 2025-01-12
### Added
- **Debug Mode:**
    - Added the ability to enable debug mode (`debug`) via the plugin constructor or the `setDebug(bool debug)` method. In debug mode, detailed logs of user activity and window changes are printed to the console.

- **Customizable Idle Timeout:**
    - You can now set the user idle timeout (`idleThreshold`) in the plugin constructor or using the `setIdleThreshold(Duration duration)` method.

### Changed
- **Improved Project Structure:**
    - Updated project structure to improve readability and support for new features.
    - Methods for tracking user activity and active windows now work correctly on the Windows platform.

- **Documentation Updates:**
    - Added detailed descriptions for methods and classes, including usage examples.

### Fixed
- Fixed issues with tracking user activity on the Windows platform.
- Improved error handling for invalid arguments passed to native methods.

### Template
- Updated the usage example in the `example/` folder. The example demonstrates:
    - How to use the debug mode.
    - How to set and retrieve the idle timeout.
    - How to track active windows and user activity.

## 1.0.0

* Initial release
