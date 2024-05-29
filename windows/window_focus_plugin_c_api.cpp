#include "include/window_focus/window_focus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "window_focus_plugin.h"

void WindowFocusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_focus::WindowFocusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
