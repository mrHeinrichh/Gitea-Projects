package com.jxim.flutter_app_update;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import com.jxim.flutter_app_update.handle.VersionHandle;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterAppUpdatePlugin */
public class FlutterAppUpdatePlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private Context context;
  private Activity active;
  private VersionHandle versionHandle;

  public void init(Context context) {
    this.context = context;
    versionHandle = new VersionHandle(context, this);
  }

  public void event(String type, HashMap<String, Object> data) {
    this.channel.invokeMethod(type, data);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_app_update");
    channel.setMethodCallHandler(this);
    this.init(flutterPluginBinding.getApplicationContext());
  }


  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("checkAppVersion")) {
      boolean useSystemUI = call.argument("useSystemUI");
      String lastVersionName = call.argument("lastVersionName");
      int lastVersionCode = call.argument("lastVersionCode");
      versionHandle.checkAppVersion(useSystemUI, lastVersionName, lastVersionCode, result);
    } else if (call.method.equals("checkLowMinVersion")) {
      String minVersion = call.argument("minVersion");
      String[] value = minVersion.split("\\+");
      String minVersionName = value[0];
      int minVersionCode = Integer.parseInt(value[1]);
      versionHandle.checkLowMinVersion(minVersionName, minVersionCode, result);

    } else if (call.method.equals("downloadAPK")) {
      String url = call.argument("url");
      String md5 = call.hasArgument("md5") ? call.argument("md5") : "";
      boolean useSystemUI = call.hasArgument("useSystemUI") ? call.argument("useSystemUI") : true;
      versionHandle.downAPK(url, md5, useSystemUI);
      result.success(versionHandle.getDownProgress());
    } else if (call.method.equals("getDownProgress")) {
      result.success(versionHandle.getDownProgress());
    } else if (call.method.equals("downloadCancel")) {
      versionHandle.downCancel();
      result.success("true");
    } else if (call.method.equals("installAPK")) {
      versionHandle.installAPK();
      result.success("true");
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.active = binding.getActivity();
    versionHandle.initActive(this.active);
  }

  @Override
  public void onDetachedFromActivity() {
    this.active = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
  }
}
