import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_focus/window_focus_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWindowFocus platform = MethodChannelWindowFocus();
  const MethodChannel channel = MethodChannel('window_focus');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    //expect(await platform.getPlatformVersion(), '42');
  });
}
