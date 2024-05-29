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

namespace window_focus {

HHOOK keyboardHook;
HHOOK mouseHook;
std::chrono::steady_clock::time_point lastActivityTime;
using CallbackMethod = std::function<void(const std::wstring&)>;
void UpdateLastActivityTime() {
    lastActivityTime = std::chrono::steady_clock::now();
}


LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        UpdateLastActivityTime();
    }
    return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
}

LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        UpdateLastActivityTime();
    }
    return CallNextHookEx(mouseHook, nCode, wParam, lParam);
}

void SetHooks() {
    keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, NULL, 0);
    mouseHook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, NULL, 0);
}

void RemoveHooks() {
    UnhookWindowsHookEx(keyboardHook);
    UnhookWindowsHookEx(mouseHook);
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
void WindowFocusPlugin::SetMethodChannel(std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel) {
    channel = method_channel;
}
// static
void WindowFocusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "expert.kotelnikoff/window_focus",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowFocusPlugin>();
  plugin->SetMethodChannel(channel);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
        SetHooks();

        plugin->CheckForInactivity();
        plugin->StartFocusListener();
        //z plugin->StartFocusListener(std::move(channel));



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

WindowFocusPlugin::WindowFocusPlugin() {}

WindowFocusPlugin::~WindowFocusPlugin() {}

void WindowFocusPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
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


            int inactivityThreshold = 1000;//1000 * 60 * 3;

            /*channel.SetMethodCallHandler(
                    [&inactivityThreshold](const flutter::MethodCall<flutter::EncodableValue>& call,
                                           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
                        if (call.method_name() == "setInactivityTimeOut") {
                            const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
                            if (args) {
                                auto it = args->find(flutter::EncodableValue("inactivityTimeOut"));
                                if (it != args->end()) {
                                    const flutter::EncodableValue& value = it->second;
                                    if (std::holds_alternative<int>(value)) {
                                        int intValue = std::get<int>(value);
                                        inactivityThreshold = intValue;
                                        std::cout << "Received int parameter: " << intValue << std::endl;
                                        result->Success(flutter::EncodableValue(intValue));
                                        return;
                                    }
                                }
                            }
                            result->Error("Invalid argument", "Expected an integer argument.");
                        }
                        else {
                            result->NotImplemented();
                        }
                    });
*/


            while (true) {
                std::this_thread::sleep_for(std::chrono::seconds(1));
                auto now = std::chrono::steady_clock::now();
                auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastActivityTime).count();

                if (duration > inactivityThreshold) {

                    std::cout << "User: " << "User is inactive" << std::endl;
                    std::cout << "TimeOut: " << inactivityThreshold << std::endl;


                    flutter::EncodableValue args("User is inactive");
                    flutter::EncodableValue method_name("onUserInactivity");
                    channel->InvokeMethod("onUserInactivity", std::make_unique<flutter::EncodableValue>(args));

                    UpdateLastActivityTime();
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

                std::cout << "Current window title: " << window_title << std::endl;
                std::cout << "Current window name: " << windowTitle << std::endl;
                std::cout << "Current window appName: " << appName << std::endl;

                std::string utf8_output = ConvertWindows1251ToUTF8(window_title);
                std::string utf8_windowTitle = ConvertWindows1251ToUTF8(windowTitle);
                flutter::EncodableMap data;

                data[flutter::EncodableValue("title")] = flutter::EncodableValue(utf8_output);
                data[flutter::EncodableValue("appName")] = flutter::EncodableValue(appName);
                data[flutter::EncodableValue("windowTitle")] = flutter::EncodableValue(utf8_windowTitle);
                channel->InvokeMethod("onFocusChange", std::make_unique<flutter::EncodableValue>(data));


            }
            /*std::string current_title = GetFocusedWindowTitle();
            if(last_title!=current_title){
                std::string windowTitle = GetFocusedWindowTitle();
                std::cout << "Изменение заголовка: " << windowTitle << std::endl;

            }*/
            Sleep(100);
        }
    }).detach();
}




}  // namespace window_focus
