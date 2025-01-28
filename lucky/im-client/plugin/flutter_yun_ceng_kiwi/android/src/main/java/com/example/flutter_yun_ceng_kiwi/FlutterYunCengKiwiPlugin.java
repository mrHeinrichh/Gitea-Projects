package com.example.flutter_yun_ceng_kiwi;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.kiwi.sdk.Kiwi;
import com.kiwi.sdk.KiwiListener;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterYunCengPlugin */
public class FlutterYunCengKiwiPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  final int kiwi_init_default = -999;
  int kiwi_init_value = kiwi_init_default;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_yun_ceng_kiwi");
    channel.setMethodCallHandler(this);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_yun_ceng_kiwi");
    channel.setMethodCallHandler(new FlutterYunCengKiwiPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("initEx")){
      try {
        HashMap<String, String> args = (HashMap) call.arguments;
        int code = Kiwi.Init(args.get("appKey"));
        kiwi_init_value = code;
        result.success(code);
      }catch (Exception e){
        result.error("-1", e.getMessage(),e.getStackTrace());
      }
    } else if(call.method.equals("initAsync")){
      try {
        kiwi_init_value = kiwi_init_default;
        HashMap<String, String> args = (HashMap) call.arguments;
        int code = Kiwi.InitWithListener(args.get("appKey"), new KiwiListener() {
          public void onKiwiInit(int result) {
            kiwi_init_value = result;
          }
        });
        result.success(code);
      }catch (Exception e){
        result.error("-1", e.getMessage(),e.getStackTrace());
      }
    }
    else if(call.method.equals("isInitDone")){
      if (kiwi_init_value != kiwi_init_default) {
        result.success(0);
      } else {
        result.success(-1);
      }
    }
    else if(call.method.equals("restartAllServer")){
      try {
        Kiwi.RestartAllServer();
        result.success(0);
      }catch (Exception e){
        result.error("-1", e.getMessage(),e.getStackTrace());
      }
    } 
    else if(call.method.equals("onNetworkOn")){
      try {
        Kiwi.OnNetworkOn();
        result.success(0);
      }catch (Exception e){
        result.error("-1", e.getMessage(),e.getStackTrace());
      }
    } 
    // else if(call.method.equals("initExWithCallback")){
    //   try {
    //     HashMap<String, String> args = (HashMap) call.arguments;
    //     YunCeng.initExWithCallback(args.get("appKey"), args.get("token"), new YunCengInitExListener() {
    //       @Override
    //       public void OnInitExFinished(final int i) {
    //         Handler handler = new Handler(Looper.getMainLooper());
    //         handler.post(new Runnable() {
    //           @Override
    //           public void run() {

    //             channel.invokeMethod("initExWithCallbackResult", i);
    //           }
    //         });
    //       }
    //     });
    //     result.success(null);
    //   }catch (Exception e){
    //     result.error("-1", e.getMessage(),e.getStackTrace());
    //   }
    // }
    else if (call.method.equals("getProxyTcpByDomain")) {
      try {
        HashMap<String, String> args = (HashMap) call.arguments;
        String token = args.get("token");
        String group_name = args.get("group_name");
        String ddomain = args.get("ddomain");
        String dport = args.get("dport");

        //调用接口并返回
        StringBuffer target_ip = new StringBuffer();
        StringBuffer target_port = new StringBuffer();
        int code = Kiwi.ServerToLocal(group_name, target_ip, target_port);

        //组织返回数据
        HashMap<String, String> map = new HashMap<>();
        map.put("target_ip", target_ip.toString());
        map.put("target_port", target_port.toString());
        map.put("code", String.valueOf(code));

        result.success(map);
      }catch (Exception e){
        result.error("-2", e.getMessage(),e.getStackTrace());
      }
    } else {
      //没有对应方法
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
