#include "window_focus_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <Windows.h>


#include <iostream>
#include <memory>
#include <string>
#include <thread>
#include <codecvt>
#include <locale>
#include <optional>
#include <tlhelp32.h>
#include <psapi.h>
#include <chrono>
#include <sstream>
#include <vector>
#include <gdiplus.h>

#pragma comment(lib, "gdiplus.lib")

namespace window_focus {

WindowFocusPlugin* WindowFocusPlugin::instance_ = nullptr;
HHOOK WindowFocusPlugin::keyboardHook_ = nullptr;
HHOOK WindowFocusPlugin::mouseHook_ = nullptr;



using CallbackMethod = std::function<void(const std::wstring&)>;



LRESULT CALLBACK WindowFocusPlugin::KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_) {
    if (instance_->enableDebug_) {
      std::cout << "[WindowFocus] keyboard hook detected action" << std::endl;
    }
    // Обращаемся к нестатическим полям через instance_
    instance_->UpdateLastActivityTime();

    // Если пользователь числился неактивным, "пробуждаем" его
    if (!instance_->userIsActive_) {
      instance_->userIsActive_ = true;
      if (instance_->channel) {
        instance_->channel->InvokeMethod(
          "onUserActive",
          std::make_unique<flutter::EncodableValue>("User is active"));
      }
    }
  }
  return CallNextHookEx(keyboardHook_, nCode, wParam, lParam);
}

LRESULT CALLBACK WindowFocusPlugin::MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_) {
    if (instance_->enableDebug_) {
      std::cout << "[WindowFocus] mouse hook detected action" << std::endl;
    }
    instance_->UpdateLastActivityTime();
    if (!instance_->userIsActive_) {
      instance_->userIsActive_ = true;
      if (instance_->channel) {
        instance_->channel->InvokeMethod(
          "onUserActive",
          std::make_unique<flutter::EncodableValue>("User is active"));
      }
    }
  }
  return CallNextHookEx(mouseHook_, nCode, wParam, lParam);
}


void WindowFocusPlugin::SetHooks() {
 if (instance_ && instance_->enableDebug_) {
    std::cout << "[WindowFocus] SetHooks: start\n";
  }
  // Пример: глобальные LL-хуки
  HINSTANCE hInstance = GetModuleHandle(nullptr);

  keyboardHook_ = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, hInstance, 0);
  if (!keyboardHook_) {
    std::cerr << "[WindowFocus] Failed to install keyboard hook: " << GetLastError() << std::endl;
  } else {
    if (instance_ && instance_->enableDebug_) {
      std::cout << "[WindowFocus] Keyboard hook installed successfully\n";
    }
  }

  mouseHook_ = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, hInstance, 0);
  if (!mouseHook_) {
    std::cerr << "[WindowFocus] Failed to install mouse hook: " << GetLastError() << std::endl;
  } else {
    if (instance_ && instance_->enableDebug_) {
      std::cout << "[WindowFocus] Mouse hook installed successfully\n";
    }
  }
}

void WindowFocusPlugin::RemoveHooks() {
  if (keyboardHook_) {
    UnhookWindowsHookEx(keyboardHook_);
    keyboardHook_ = nullptr;
  }
  if (mouseHook_) {
    UnhookWindowsHookEx(mouseHook_);
    mouseHook_ = nullptr;
  }
}
void WindowFocusPlugin::UpdateLastActivityTime() {
  lastActivityTime = std::chrono::steady_clock::now();
}


std::string ConvertWindows1251ToUTF8(const std::string& windows1251_str) {
    int size_needed = MultiByteToWideChar(1251, 0, windows1251_str.c_str(), -1, NULL, 0);
    std::wstring utf16_str(size_needed, 0);
    MultiByteToWideChar(1251, 0, windows1251_str.c_str(), -1, &utf16_str[0], size_needed);

    size_needed = WideCharToMultiByte(CP_UTF8, 0, utf16_str.c_str(), -1, NULL, 0, NULL, NULL);
    std::string utf8_str(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, utf16_str.c_str(), -1, &utf8_str[0], size_needed, NULL, NULL);

    return utf8_str;
}
std::string ConvertWStringToUTF8(const std::wstring& wstr) {
    if (wstr.empty()) {
        return std::string();
    }
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}
/*void WindowFocusPlugin::SetMethodChannel(std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel) {
    channel = method_channel;
}*/
// static
void WindowFocusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {

  // Создаём канал
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(),
      "expert.kotelnikoff/window_focus",
      &flutter::StandardMethodCodec::GetInstance());

  // Создаём сам плагин
  auto plugin = std::make_unique<WindowFocusPlugin>();
  // Запоминаем канал в объекте
  plugin->channel = channel;

  // Если нужно: устанавливаем хуки
  plugin->SetHooks();

    plugin->CheckForInactivity();
    plugin->StartFocusListener();


  // Пример: метод-хендлер, обрабатывающий вызовы из Dart
  channel->SetMethodCallHandler(
    [plugin_pointer = plugin.get()](const auto& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      plugin_pointer->HandleMethodCall(call, std::move(result));
    }
  );

  // Если нужно, можно запустить поток: plugin->CheckForInactivity(); и т.д.

  // Регистрируем плагин в системе Flutter
  registrar->AddPlugin(std::move(plugin));
}

std::string GetFocusedWindowTitle() {
    HWND hwnd = GetForegroundWindow();
    if (hwnd == NULL) {
        return "";
    }

    int length = GetWindowTextLength(hwnd);
    if (length == 0) {
        return "";
    }

    char* buffer = new char[length + 1];
    GetWindowTextA(hwnd, buffer, length + 1);

    std::string windowTitle(buffer);

    delete[] buffer;

    return windowTitle;
}

WindowFocusPlugin::WindowFocusPlugin() {
 instance_ = this;

  // Инициализируем момент времени (для отслеживания активности)
  lastActivityTime = std::chrono::steady_clock::now();
  }

WindowFocusPlugin::~WindowFocusPlugin() {
  instance_ = nullptr;
}

void WindowFocusPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  const auto& method_name = method_call.method_name();


  if (method_name == "setDebugMode") {
      // Извлекаем аргументы
      if (const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments())) {
        auto it = args->find(flutter::EncodableValue("debug"));
        if (it != args->end()) {
          if (std::holds_alternative<bool>(it->second)) {
            bool newDebugValue = std::get<bool>(it->second);
            enableDebug_ = newDebugValue;
            std::cout << "[WindowFocus] C++: enableDebug_ set to " << (enableDebug_ ? "true" : "false") << std::endl;
            result->Success();
            return;
          }
        }
      }
      result->Error("Invalid argument", "Expected a bool for 'debug'.");
      return;
    }

  // Пример: установить таймаут
  if (method_name == "setInactivityTimeOut") {
    if (const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments())) {
      auto it = args->find(flutter::EncodableValue("inactivityTimeOut"));
      if (it != args->end()) {
        if (std::holds_alternative<int>(it->second)) {
          inactivityThreshold_ = std::get<int>(it->second);
          std::cout << "Updated inactivityThreshold_ to " << inactivityThreshold_ << std::endl;
          result->Success(flutter::EncodableValue(inactivityThreshold_));
          return;
        }
      }
    }
    result->Error("Invalid argument", "Expected an integer argument.");
  } else if (method_name == "getPlatformVersion") {
    result->Success(flutter::EncodableValue("Windows: example"));
  } else if (method_name == "getIdleThreshold") {
    result->Success(flutter::EncodableValue(inactivityThreshold_));
  } else if (method_name == "takeScreenshot") {
    bool activeWindowOnly = false;
    if (const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments())) {
      auto it = args->find(flutter::EncodableValue("activeWindowOnly"));
      if (it != args->end() && std::holds_alternative<bool>(it->second)) {
        activeWindowOnly = std::get<bool>(it->second);
      }
    }
    auto screenshot = TakeScreenshot(activeWindowOnly);
    if (screenshot.has_value()) {
      result->Success(flutter::EncodableValue(screenshot.value()));
    } else {
      result->Error("SCREENSHOT_ERROR", "Failed to take screenshot");
    }
  } else if (method_name == "checkScreenRecordingPermission") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "requestScreenRecordingPermission") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

std::string GetProcessName(DWORD processID) {
    std::wstring processName = L"<unknown>";

    HANDLE hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap != INVALID_HANDLE_VALUE) {
        PROCESSENTRY32W pe32;
        pe32.dwSize = sizeof(PROCESSENTRY32W);

        if (Process32FirstW(hProcessSnap, &pe32)) {
            do {
                if (pe32.th32ProcessID == processID) {
                    processName = pe32.szExeFile;
                    break;
                }
            } while (Process32NextW(hProcessSnap, &pe32));
        }
        CloseHandle(hProcessSnap);
    }

    return ConvertWStringToUTF8(processName);
}
std::string GetFocusedWindowAppName() {
    HWND hwnd = GetForegroundWindow();
    if (hwnd == NULL) {
        return "<no window in focus>";
    }

    DWORD processID;
    GetWindowThreadProcessId(hwnd, &processID);

    return GetProcessName(processID);
}

void WindowFocusPlugin::CheckForInactivity() {
  std::thread([this]() {
   while (true) {
     std::this_thread::sleep_for(std::chrono::seconds(1));
     auto now = std::chrono::steady_clock::now();
     auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastActivityTime).count();



     if (duration > inactivityThreshold_ && userIsActive_) {
       userIsActive_ = false;
        if (instance_ && instance_->enableDebug_) {
           std::cout << "[WindowFocus] User is inactive. Duration: " << duration << "ms, Threshold: " << inactivityThreshold_ << "ms" << std::endl;
         }
       if (channel) {
         channel->InvokeMethod("onUserInactivity",
           std::make_unique<flutter::EncodableValue>("User is inactive"));
       }
     }
   }
  }).detach();
}
void WindowFocusPlugin::StartFocusListener(){
    std::thread([this]() {
        HWND last_focused = nullptr;
//        std::string last_title = nullptr;
        while (true) {
            HWND current_focused = GetForegroundWindow();
            if (current_focused != last_focused) {
                last_focused = current_focused;
                char title[256];
                GetWindowTextA(current_focused, title, sizeof(title));
                std::string appName = GetFocusedWindowAppName();
                std::string windowTitle = GetFocusedWindowTitle();
                std::string window_title(title);

                if (instance_ && instance_->enableDebug_) {
                 std::cout << "Current window title: " << window_title << std::endl;
                                std::cout << "Current window name: " << windowTitle << std::endl;
                                std::cout << "Current window appName: " << appName << std::endl;
                         }



                std::string utf8_output = ConvertWindows1251ToUTF8(window_title);
                std::string utf8_windowTitle = ConvertWindows1251ToUTF8(windowTitle);
                flutter::EncodableMap data;

                data[flutter::EncodableValue("title")] = flutter::EncodableValue(utf8_output);
                data[flutter::EncodableValue("appName")] = flutter::EncodableValue(appName);
                data[flutter::EncodableValue("windowTitle")] = flutter::EncodableValue(utf8_windowTitle);
                channel->InvokeMethod("onFocusChange", std::make_unique<flutter::EncodableValue>(data));

/*                registrar_->GetTaskRunner()->PostTask([this]() {
                    channel->InvokeMethod("onFocusChange",
                        std::make_unique<flutter::EncodableValue>(data));
                  });*/


            }
            Sleep(100);
        }
    }).detach();
}

int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
    UINT num = 0;
    UINT size = 0;
    Gdiplus::GetImageEncodersSize(&num, &size);
    if (size == 0) return -1;
    Gdiplus::ImageCodecInfo* pImageCodecInfo = (Gdiplus::ImageCodecInfo*)(malloc(size));
    if (pImageCodecInfo == NULL) return -1;
    Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);
    for (UINT j = 0; j < num; ++j) {
        if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0) {
            *pClsid = pImageCodecInfo[j].Clsid;
            free(pImageCodecInfo);
            return j;
        }
    }
    free(pImageCodecInfo);
    return -1;
}

std::optional<std::vector<uint8_t>> WindowFocusPlugin::TakeScreenshot(bool activeWindowOnly) {
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

    HWND hwnd = activeWindowOnly ? GetForegroundWindow() : GetDesktopWindow();
    if (hwnd == NULL) hwnd = GetDesktopWindow();

    HDC hdcScreen = GetDC(NULL);
    HDC hdcWindow = GetDC(hwnd);
    HDC hdcMemDC = CreateCompatibleDC(hdcWindow);

    RECT rc;
    GetWindowRect(hwnd, &rc);
    int width = rc.right - rc.left;
    int height = rc.bottom - rc.top;

    HBITMAP hbmScreen = CreateCompatibleBitmap(hdcWindow, width, height);
    SelectObject(hdcMemDC, hbmScreen);

    if (activeWindowOnly) {
        // Для активного окна используем BitBlt с координатами окна, так как PrintWindow может не работать для некоторых приложений (например, Chrome с аппаратным ускорением)
        // Но BitBlt тоже может вернуть черный экран для некоторых приложений (Chrome, Discord и т.д.)
        // Самый надежный способ - BitBlt с hdcScreen, но только нужной области
        BitBlt(hdcMemDC, 0, 0, width, height, hdcScreen, rc.left, rc.top, SRCCOPY);
    } else {
        BitBlt(hdcMemDC, 0, 0, width, height, hdcScreen, rc.left, rc.top, SRCCOPY);
    }

    Gdiplus::Bitmap* bitmap = new Gdiplus::Bitmap(hbmScreen, NULL);
    IStream* stream = NULL;
    CreateStreamOnHGlobal(NULL, TRUE, &stream);

    CLSID pngClsid;
    GetEncoderClsid(L"image/png", &pngClsid);
    bitmap->Save(stream, &pngClsid, NULL);

    STATSTG statstg;
    stream->Stat(&statstg, STATFLAG_DEFAULT);
    ULONG fileSize = (ULONG)statstg.cbSize.QuadPart;

    std::vector<uint8_t> data(fileSize);
    LARGE_INTEGER liZero = { 0 };
    stream->Seek(liZero, STREAM_SEEK_SET, NULL);
    ULONG bytesRead = 0;
    stream->Read(data.data(), fileSize, &bytesRead);

    stream->Release();
    delete bitmap;
    DeleteObject(hbmScreen);
    DeleteDC(hdcMemDC);
    ReleaseDC(hwnd, hdcWindow);
    ReleaseDC(NULL, hdcScreen);

    Gdiplus::GdiplusShutdown(gdiplusToken);

    if (bytesRead > 0) {
        return data;
    }
    return std::nullopt;
}

}  // namespace window_focus
