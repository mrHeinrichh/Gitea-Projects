#ifndef FLUTTER_PLUGIN_FLUTTER_FCONSOLE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_FCONSOLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_fconsole {

class FlutterFconsolePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterFconsolePlugin();

  virtual ~FlutterFconsolePlugin();

  // Disallow copy and assign.
  FlutterFconsolePlugin(const FlutterFconsolePlugin&) = delete;
  FlutterFconsolePlugin& operator=(const FlutterFconsolePlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_fconsole

#endif  // FLUTTER_PLUGIN_FLUTTER_FCONSOLE_PLUGIN_H_
