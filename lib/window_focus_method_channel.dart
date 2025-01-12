import 'dart:async';
import 'package:flutter/services.dart';
import 'domain/domain.dart';



/// The WindowFocus plugin provides functionality for tracking user activity
/// and the currently active window on the Windows platform. It is useful for applications
/// that need to monitor user interaction with the system.
class WindowFocus{
  /// Creates an instance of `WindowFocus` for tracking user activity and window focus.
  ///
  /// The constructor allows enabling debug mode and setting the user inactivity timeout
  /// when creating an instance.
  ///
  /// - [debug]: If `true`, the plugin will output debug messages to the console.
  ///   Useful for diagnosing plugin behavior during development.
  /// - [duration]: The user inactivity timeout after which the plugin sends an event
  ///   indicating that the user is inactive. Default is 1 second.
  ///
  /// Example usage:
  ///
  /// Enable debug mode:
  /// ```dart
  /// final windowFocus = WindowFocus(debug: true);
  /// ```
  ///
  /// Set a custom inactivity timeout:
  /// ```dart
  /// final windowFocus = WindowFocus(duration: Duration(seconds: 30));
  /// ```
  ///
  /// Enable debug mode and set a custom timeout:
  /// ```dart
  /// final windowFocus = WindowFocus(
  ///   debug: true,
  ///   duration: Duration(seconds: 10),
  /// );
  /// ```
  WindowFocus({bool debug = false,Duration duration=const Duration(seconds: 1)}) {
    _debug = debug;
    _channel.setMethodCallHandler(_handleMethodCall);
    if (_debug) {
      setDebug(_debug);
    }
    setIdleThreshold(duration: duration);
  }





  static const MethodChannel _channel = MethodChannel('expert.kotelnikoff/window_focus');
  bool _debug = false;
  bool _userActive = true;

  final _focusChangeController = StreamController<AppWindowDto>.broadcast();
  final _userActiveController = StreamController<bool>.broadcast();



  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onFocusChange':
        final String appName = call.arguments['appName'] ?? '';
        final String windowTitle = call.arguments['windowTitle'] ?? '';
        final dto = AppWindowDto(appName: appName, windowTitle: windowTitle);
        _focusChangeController.add(dto);
        break;
      case 'onUserActiveChange':
        final bool active = call.arguments == true;
        _userActive = active;
        _userActiveController.add(_userActive);
        break;
      case 'onUserActive':
        _userActiveController.add(true);
        break;
      case 'onUserInactivity':
        _userActiveController.add(false);
        break;
      default:
        print('Unknown method from native: ${call.method}');
        break;
    }
    return null;
  }

  bool get isUserActive => _userActive;

  Stream<AppWindowDto> get onFocusChanged => _focusChangeController.stream;
  Stream<bool> get onUserActiveChanged => _userActiveController.stream;

  /// Sets the user inactivity timeout.
  ///
  /// If the user is inactive for the specified duration, the plugin sends an event
  /// indicating user inactivity.
  ///
  /// - [duration]: The time in milliseconds after which the user is considered inactive.
  ///
  /// ```dart
  /// await _windowFocus.setIdleThreshold(Duration(seconds: 10));
  /// ```
  Future<void> setIdleThreshold({required Duration duration}) async {
    await _channel.invokeMethod('setInactivityTimeOut',  {
      'inactivityTimeOut': duration.inMilliseconds,
    });
  }
  /// Returns the currently set inactivity timeout.
  ///
  /// Returns: A `Duration` that specifies the time after which the user is considered inactive.
  ///
  /// ```dart
  /// final timeout = await _windowFocus.getIdleThreshold();
  /// print('Inactivity timeout: ${timeout.inSeconds} seconds');
  /// ```
  Future<Duration> get idleThreshold async {
    final res = await _channel.invokeMethod<int>('getIdleThreshold');
    print(res);
    return Duration(milliseconds: res ?? 60);
  }

  /// Enables or disables debug mode for the plugin.
  ///
  /// When debug mode is enabled, additional logs are printed to the console,
  /// allowing developers to observe the internal behavior of the plugin, such as
  /// user activity changes or active window updates.
  ///
  /// - [value]: A `bool` that determines whether debug mode is enabled (`true`) or disabled (`false`).
  ///
  /// ```dart
  /// await _windowFocus.setDebug(true);
  /// print('Debug mode enabled');
  /// ```
  Future<void> setDebug(bool value) async {
    _debug = value;
    await _channel.invokeMethod('setDebugMode', {
      'debug': value,
    });
  }
  /// Adds a listener for active window changes.
  ///
  /// The callback is triggered whenever the user switches to a different window.
  ///
  /// - [listener]: A function that accepts an `AppWindowDto` object, which contains
  ///   information about the currently active application.
  ///
  /// ```dart
  /// _windowFocus.addFocusChangeListener((appWindow) {
  ///   print('Active window: ${appWindow.appName}');
  /// });
  /// ```
  StreamSubscription<AppWindowDto> addFocusChangeListener(
      void Function(AppWindowDto) listener) {
    return onFocusChanged.listen(listener);
  }

  /// Adds a listener for user activity changes.
  ///
  /// The listener is called when the user becomes active (`true`) or inactive (`false`).
  ///
  /// - [listener]: A function that accepts a `bool` indicating the user's activity status.
  ///
  /// ```dart
  /// _windowFocus.addUserActiveListener((isActive) {
  ///   if (isActive) {
  ///     print('User is active');
  ///   } else {
  ///     print('User is inactive');
  ///   }
  /// });
  /// ```
  StreamSubscription<bool> addUserActiveListener(
      void Function(bool) listener) {
    return onUserActiveChanged.listen(listener);
  }

  void dispose() {
    _focusChangeController.close();
    _userActiveController.close();
  }
}