
import 'data/app_window_dto.dart';
import 'window_focus_platform_interface.dart';

class WindowFocus {

  void addFocusChangeListener(Function(AppWindowDto) listener){
    return WindowFocusPlatform.instance.addFocusChangeListener(listener);
  }
  void removeFocusChangeListener(Function(AppWindowDto) listener){
    return WindowFocusPlatform.instance.removeFocusChangeListener(listener);
  }
  void addActivityListener(){

  }
}
