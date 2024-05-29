import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'data/app_window_dto.dart';
import 'window_focus_method_channel.dart';

abstract class WindowFocusPlatform extends PlatformInterface {
  /// Constructs a WindowFocusPlatform.
  WindowFocusPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowFocusPlatform _instance = MethodChannelWindowFocus();

  /// The default instance of [WindowFocusPlatform] to use.
  ///
  /// Defaults to [MethodChannelWindowFocus].
  static WindowFocusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WindowFocusPlatform] when
  /// they register themselves.
  static set instance(WindowFocusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void addFocusChangeListener(Function(AppWindowDto) listener){
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  void removeFocusChangeListener(Function(AppWindowDto) listener){
    throw UnimplementedError('platformVersion() has not been implemented.');

  }

}
