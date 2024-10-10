package com.example.flutter_pasteboard;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterPasteboardPlugin */
public class FlutterPasteboardPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context;

  private String TAG = "FlutterPasteboardPlugin";
  private String packageName = "com.jiangxia.im";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "pasteboard");
    channel.setMethodCallHandler(this);
    this.context = flutterPluginBinding.getApplicationContext();
    packageName = this.context.getPackageName();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }else if (call.method.equals("writeImage")) {
      Log.d(TAG, "onMethodCall: "+call.arguments);
      writeImage(call.arguments);
      result.success(true);
    } else if (call.method.equals("image")) {
      Object uu = getImage();
      result.success(uu);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  //保存文件
  private String createFile(byte[] bytes){
    String fileName = "copyimg.jpg";
    String path = Environment.getExternalStorageDirectory().getPath() + "/Android/data/"+packageName+"/cache/image";
//    Log.d(TAG, "createFile: "+path);
    File file = new File(path);
    boolean isSucc = false;
    if(!file.exists()){
      isSucc = createFileDir(file);
    }
    else isSucc = true;
//    Log.d(TAG, "createFile111: "+isSucc);
    try {
      if(isSucc){
        File newFile = new File(path,fileName);
        if(!newFile.exists()){
          newFile.createNewFile();
        }
        FileOutputStream stram = new FileOutputStream(newFile);
        stram.write(bytes);
        stram.flush();
        stram.close();
        path = path +"/"+ fileName;
//        Log.d(TAG, "createFile222: "+path);
      }
    }
    catch (Exception e){
      Log.e(TAG, "createFile: fail "+e.getMessage() );
    }
    return path;
  }
  private Boolean createFileDir(File dirFile){
    if(dirFile == null) return true;
    if(dirFile.exists()){
      return true;
    }
    File parentFile = dirFile.getParentFile();
    if(parentFile != null && !parentFile.exists() ){
      return createFileDir(parentFile) && createFileDir(dirFile);
    }
    else {
      boolean mks = dirFile.mkdirs();
      boolean isSuss = mks || dirFile.exists();
      if (!isSuss) {
        Log.e(TAG, "createFileDir: fail " + dirFile);
      }
      return isSuss;
    }
  }

  /**
   * 复制到剪贴板
   * @param image
   */
  public void writeImage(Object image){
//    Log.d(TAG,"=========writeImage========");
    if(image == null) return;
//    Log.d(TAG,"=========writeImage========1111111");
    ClipboardManager clipboardManager = (ClipboardManager) this.context.getSystemService(Context.CLIPBOARD_SERVICE);
    ClipData clipData;
    if(image instanceof String){
      Uri uri = Uri.parse(image.toString());
      Log.d(TAG,"=========writeImage========Uri:"+uri);
      clipData = ClipData.newRawUri("Label", uri);
    }
    else if(image instanceof byte[]){
//      Log.d(TAG,"=========writeImage========byte:"+image.toString());
//      Intent intent = new Intent();
//      intent.putExtra("intent",((byte[]) image));
//      clipData = ClipData.newIntent("",intent);
      String path = createFile((byte[]) image);
      Uri uri = Uri.parse(path);
//      Log.d(TAG,"=========writeImage========byte:"+uri);
      clipData = ClipData.newRawUri("Label", uri);
    }
    else{
      clipData = ClipData.newPlainText("Label",image.toString());
    }
    if(clipData == null) return;
    clipboardManager.setPrimaryClip(clipData);
//    Log.d(TAG,"=========writeImage========22222222");
  }

  //获取图片
  public Object getImage(){
    ClipboardManager clipboardManager = (ClipboardManager) this.context.getSystemService(Context.CLIPBOARD_SERVICE);
    ClipData clipData = clipboardManager.getPrimaryClip();

    if(clipData != null){
      ClipData.Item dd = clipData.getItemAt(0);
      Uri uri = dd.getUri();
      if(uri != null){
//        Log.d(TAG, "==================getImage_uri: "+uri);
        return uri.getPath();
      }
      Intent intent = dd.getIntent();
      if(intent != null){
        byte[] bytes = intent.getByteArrayExtra("intent");
//        Log.d(TAG, "==================getImage_intent: "+bytes);
        return bytes;
      }
    }
    return null;
  }
}
