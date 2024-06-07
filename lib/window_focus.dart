
import 'data/app_window_dto.dart';
import 'window_focus_platform_interface.dart';

class WindowFocus {

  void addFocusChangeListener(Function(AppWindowDto) listener){
    return WindowFocusPlatform.instance.addFocusChangeListener(listener);
  }
  void removeFocusChangeListener(Function(AppWindowDto) listener){
    return WindowFocusPlatform.instance.removeFocusChangeListener(listener);
  }
  void setIdleThreshold({Duration duration=const Duration(seconds: 10)}){
    return WindowFocusPlatform.instance.setIdleThreshold(duration);
  }
  void addUserActiveListener(Function(bool) listener){
    return WindowFocusPlatform.instance.addUserActiveListener(listener);
  }
  void removeUserActiveListener(Function(bool) listener){
    return WindowFocusPlatform.instance.removeUserActiveListener(listener);
  }
  bool get isUserActive{
    return WindowFocusPlatform.instance.isUserActive;
  }
  Future<Duration> get idleThreshold async{
    return WindowFocusPlatform.instance.idleThreshold;
  }
}
