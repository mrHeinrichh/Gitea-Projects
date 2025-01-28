#ifndef FLUTTER_PLUGIN_FLUTTER_YUN_CENG_KIWI_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_YUN_CENG_KIWI_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_yun_ceng_kiwi {

class FlutterYunCengKiwiPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterYunCengKiwiPlugin();

  virtual ~FlutterYunCengKiwiPlugin();

  // Disallow copy and assign.
  FlutterYunCengKiwiPlugin(const FlutterYunCengKiwiPlugin&) = delete;
  FlutterYunCengKiwiPlugin& operator=(const FlutterYunCengKiwiPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_yun_ceng_kiwi

#endif  // FLUTTER_PLUGIN_FLUTTER_YUN_CENG_KIWI_PLUGIN_H_
