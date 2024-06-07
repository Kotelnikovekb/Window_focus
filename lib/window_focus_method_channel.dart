import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_focus/event_bus.dart';

import 'data/app_window_dto.dart';
import 'window_focus_platform_interface.dart';

class MethodChannelWindowFocus extends WindowFocusPlatform {
  final _eventBus = EventBus();
  bool userActive = true;

  MethodChannelWindowFocus() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFocusChange') {
        _eventBus.fireEvent<AppWindowDto>(AppWindowDto(
            appName: call.arguments['appName'],
            windowTitle: call.arguments['windowTitle']));
      } else if (call.method == 'onUserActiveChange') {
        userActive = call.arguments;
        _eventBus.fireEvent<bool>(userActive);
      } else {
        print(call.method);
      }
    });
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('expert.kotelnikoff/window_focus');


  @override
  void addFocusChangeListener(Function(AppWindowDto) listener){
    _eventBus.addListener(listener);
  }
  @override
  void removeFocusChangeListener(Function(AppWindowDto) listener){
    _eventBus.removeListener(listener);
  }

  @override
  void setIdleThreshold(Duration duration) {
    methodChannel.invokeMethod('setIdleThreshold', duration.inSeconds);
  }

  @override
  bool get isUserActive {
    return userActive;
  }

  @override
  void removeUserActiveListener(Function(bool) listener) {
    _eventBus.removeListener(listener);
  }

  @override
  void addUserActiveListener(Function(bool) listener) {
    _eventBus.addListener(listener);
  }

  @override
  Future<Duration> get idleThreshold async{
    try{
      final res=await methodChannel.invokeMethod<int>('getIdleThreshold');
      return Duration(seconds: res??10);
    }catch(e){
      return Duration(seconds: 10);
    }
  }
}
