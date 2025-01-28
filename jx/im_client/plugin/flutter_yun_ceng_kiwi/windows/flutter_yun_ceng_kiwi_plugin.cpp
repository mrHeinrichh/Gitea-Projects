#include "flutter_yun_ceng_kiwi_plugin.h"

#include "include/kiwi_plus/kiwi_plus_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <stdio.h>
#include <string.h>

#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>

const int kiwi_init_default = -999;
int kiwi_init_value = kiwi_init_default;

void initCallback(int result) { kiwi_init_value = result; }

namespace flutter_yun_ceng_kiwi {
using namespace std;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// static
void FlutterYunCengKiwiPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_yun_ceng_kiwi",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterYunCengKiwiPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

FlutterYunCengKiwiPlugin::FlutterYunCengKiwiPlugin() {}

FlutterYunCengKiwiPlugin::~FlutterYunCengKiwiPlugin() {}

void FlutterYunCengKiwiPlugin::HandleMethodCall(
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
    } else if (method_call.method_name().compare("initEx") == 0) {
        const auto *arguments = get_if<EncodableMap>(method_call.arguments());
        if (arguments) {
            auto appkey_arg = arguments->find(EncodableValue("appKey"));
            if (appkey_arg == arguments->end()) {
                result->Error("app key is nul");
            }

            string appkey = get<string>(appkey_arg->second);
            kiwi_init_value = KiwiInit(appkey.c_str());
            result->Success(EncodableValue(kiwi_init_value));
            return;
        }
        result->Error("bad args");
    } else if (method_call.method_name().compare("initAsync") == 0) {
        const auto *arguments = get_if<EncodableMap>(method_call.arguments());
        if (arguments) {
            auto appkey_arg = arguments->find(EncodableValue("appKey"));
            if (appkey_arg == arguments->end()) {
                result->Error("app key is nul");
            }
            
            string appkey = get<string>(appkey_arg->second);
            KiwiInitWithListner(appkey.c_str(), initCallback);
            result->Success(EncodableValue(0));
            return;
        }
        result->Error("bad args");
    } else if (method_call.method_name().compare("isInitDone") == 0) {
        if (kiwi_init_value != kiwi_init_default) {
            result->Success(EncodableValue(0));
        } else {
            result->Success(EncodableValue(-1));
        }
    } else if (method_call.method_name().compare("getProxyTcpByDomain") == 0) {
        const auto *arguments = get_if<EncodableMap>(method_call.arguments());
        if (arguments) {
            int ret = 1000;
            EncodableMap map;
            auto domain_arg = arguments->find(EncodableValue("group_name"));
            if (domain_arg == arguments->end()) {
                result->Error("domain is nil");
            }

            string domain = get<string>(domain_arg->second);
            char ip[64] = {0};
            char port[16] = {0};

            ret = KiwiServerToLocal(domain.c_str(), ip, sizeof(ip), port,
                                    sizeof(port));
            map[EncodableValue("code")] = std::to_string(ret);
            map[EncodableValue("target_port")] = string(port);
            map[EncodableValue("target_ip")] = string(ip);
            result->Success(EncodableValue(map));
            return;
        }
        result->Error("bad args");
    } else if (method_call.method_name().compare("onNetworkOn") == 0) {
        KiwiOnNetworkOn();
        result->Success(EncodableValue(0));
    } else {
        result->NotImplemented();
    }
}

}  // namespace flutter_yun_ceng_kiwi
