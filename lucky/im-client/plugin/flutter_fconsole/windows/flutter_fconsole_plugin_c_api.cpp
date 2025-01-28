#include "include/flutter_fconsole/flutter_fconsole_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_fconsole_plugin.h"

void FlutterFconsolePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_fconsole::FlutterFconsolePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
