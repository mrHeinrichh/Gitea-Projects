#include "include/flutter_yun_ceng_kiwi/flutter_yun_ceng_kiwi_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_yun_ceng_kiwi_plugin.h"

void FlutterYunCengKiwiPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_yun_ceng_kiwi::FlutterYunCengKiwiPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
