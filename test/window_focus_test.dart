import 'package:flutter_test/flutter_test.dart';
import 'package:window_focus/data/app_window_dto.dart';
import 'package:window_focus/window_focus.dart';
import 'package:window_focus/window_focus_platform_interface.dart';
import 'package:window_focus/window_focus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWindowFocusPlatform
    with MockPlatformInterfaceMixin
    implements WindowFocusPlatform {



  @override
  void addFocusChangeListener(Function(AppWindowDto p1) listener) {
    // TODO: implement addFocusChangeListener
  }

  @override
  void removeFocusChangeListener(Function(AppWindowDto p1) listener) {
    // TODO: implement removeFocusChangeListener
  }
}

void main() {
  final WindowFocusPlatform initialPlatform = WindowFocusPlatform.instance;

  test('$MethodChannelWindowFocus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWindowFocus>());
  });

  test('getPlatformVersion', () async {
    WindowFocus windowFocusPlugin = WindowFocus();
    MockWindowFocusPlatform fakePlatform = MockWindowFocusPlatform();
    WindowFocusPlatform.instance = fakePlatform;

//    expect(await windowFocusPlugin.getPlatformVersion(), '42');
  });
}
