#ifndef FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <chrono>
#include <memory>
#include <windows.h>

namespace window_focus {

class WindowFocusPlugin : public flutter::Plugin {
 public:
  // Метод для регистрации плагина
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  // Конструктор / деструктор
  WindowFocusPlugin();
  virtual ~WindowFocusPlugin();
    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // == 1) Указатель на «единственный» экземпляр (singleton-like).
  // Статические хуки будут обращаться к instance_->...
  static WindowFocusPlugin* instance_;

  // == 2) Статические хуки и статические переменные-хуки.
  static HHOOK keyboardHook_;
  static HHOOK mouseHook_;
  static LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam);
  static LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam);

  // == 3) Ваши обычные (нестатические) поля
  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
  bool userIsActive_ = true;
  int inactivityThreshold_ = 1000;
  bool enableDebug_ = false;
  std::chrono::steady_clock::time_point lastActivityTime;

  // == 4) Внутренние методы
  void SetHooks();
  void RemoveHooks();

  // При вводе с клавиатуры/мыши обновляем время
  void UpdateLastActivityTime();

  // Пример: метод обработки вызовов из Dart


  // Доп. методы: CheckForInactivity(), StartFocusListener() и т.д. по желанию

  void CheckForInactivity();
  void StartFocusListener();

  std::optional<std::vector<uint8_t>> TakeScreenshot(bool activeWindowOnly);
};

}  // namespace window_focus

#endif  // FLUTTER_PLUGIN_WINDOW_FOCUS_PLUGIN_H_
