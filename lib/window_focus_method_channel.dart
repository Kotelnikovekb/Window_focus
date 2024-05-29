import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_focus/event_bus.dart';

import 'data/app_window_dto.dart';
import 'window_focus_platform_interface.dart';

class MethodChannelWindowFocus extends WindowFocusPlatform {
  final _eventBus = EventBus();

  MethodChannelWindowFocus(){
    methodChannel.setMethodCallHandler((call)  async{
      if(call.method=='onFocusChange'){
        _eventBus.fireEvent<AppWindowDto>(AppWindowDto(
            appName: call.arguments['appName'],
            windowTitle: call.arguments['windowTitle']));
      }
      print(call.method);
      print(call.arguments);
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
}
