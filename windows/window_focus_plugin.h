#ifndef FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace window_focus {

class WindowFocusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
  void SetMethodChannel(std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel);

  WindowFocusPlugin();

  virtual ~WindowFocusPlugin();

  // Disallow copy and assign.
  WindowFocusPlugin(const WindowFocusPlugin&) = delete;
  WindowFocusPlugin& operator=(const WindowFocusPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
private:

    std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
    void CheckForInactivity();
    void StartFocusListener();

    //void StartFocusListener(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>> &flutter_channel_);


};

}  // namespace window_focus

#endif  // FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_
