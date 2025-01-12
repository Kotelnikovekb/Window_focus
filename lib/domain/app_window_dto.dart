
/// A data transfer object representing the active window information.
///
/// On **Windows**:
/// - [windowTitle] contains the title of the active window.
/// - [appName] contains the name of the application associated with the active window.
///
/// On **macOS**:
/// - Both [windowTitle] and [appName] contain the application name, as macOS does not differentiate
///   between the window title and the application name.
///
/// Example:
/// ```dart
/// final activeWindow = AppWindowDto(appName: "chrome.exe", windowTitle: "Google - Chrome");
/// print(activeWindow); // Output: Window title: Google - Chrome. AppName chrome.exe
/// ```
class AppWindowDto{
  /// The name of the application associated with the active window.
  final String appName;
  /// The title of the active window.
  final String windowTitle;

  /// Constructs an instance of [AppWindowDto].
  AppWindowDto({required this.appName, required this.windowTitle});

  /// Returns a string representation of the active window details.
  @override
  String toString() {
    return 'Window title: $windowTitle. AppName $appName';
  }

  /// Checks if two [AppWindowDto] objects are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppWindowDto) return false;
    return other.appName == appName && other.windowTitle == windowTitle;
  }

  /// Returns a hash code for the [AppWindowDto] object.
  @override
  int get hashCode => Object.hash(appName, windowTitle);

}