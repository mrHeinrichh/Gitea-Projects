package com.jxim.flutter_app_update.utils;

import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.ResultReceiver;
import android.util.Log;

import androidx.core.content.FileProvider;

import com.jxim.flutter_app_update.FlutterAppUpdatePlugin;

import java.io.File;
import java.util.HashMap;

/**
 * 下载器
 * Created by wuyue on 2017/1/19.
 */
public class Download {

    private static final String TAG = "Download";
    private Context mContext;
    // 下载apk的对话框
    private ProgressDialog mProgressDialog;
    // 下载的url
    private String downloadUrl;
    // 下载进度
    public int progress = 0;
    // 下载保存的apk文件
    private File apkFile;

    public Download(Context context) {
        mContext = context;
    }

    private static final String HUAWEI_MANUFACTURER = "Huawei";

    public void downLoadApk(String apkUrl, String md5, boolean useSystemUI, FlutterAppUpdatePlugin plugin) {
        downloadUrl = apkUrl;
        progress = 0;
        if (useSystemUI) {
            mProgressDialog = new ProgressDialog(mContext);
            mProgressDialog.setMax(100);
            mProgressDialog.setMessage("正在下载，请稍候...");
            mProgressDialog.setIndeterminate(false);
            mProgressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
            mProgressDialog.setCancelable(false);
            mProgressDialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
                @Override
                public void onCancel(DialogInterface dialog) {
                    mProgressDialog = null;
                }
            });
            mProgressDialog.setOnDismissListener(new DialogInterface.OnDismissListener() {
                @Override
                public void onDismiss(DialogInterface dialog) {
                    mProgressDialog = null;
                }
            });
            mProgressDialog.show();
        }

        String dir = mContext.getExternalFilesDir("apk").getAbsolutePath();
        String filename = md5;
        if(filename.isEmpty()){
            filename = apkUrl;
            int idx = apkUrl.lastIndexOf("?");
            if(idx != -1){
                filename = filename.substring(0, idx);
            }
            idx = filename.lastIndexOf("/");
            if(idx != -1){
                filename = filename.substring(idx+1);
            }
        }
        String destinationFilePath = dir + "/" + filename;
        apkFile = new File(destinationFilePath);
        Log.d(TAG, "downLoadApk: " + apkUrl);
        Log.d(TAG, "destinationFilePath: " + destinationFilePath);
        Intent intent = new Intent(mContext, DownloadService.class);
        intent.putExtra("url", apkUrl);
        intent.putExtra("dest", destinationFilePath);
        intent.putExtra("receiver", new ResultReceiver(new Handler()) {
            @Override
            protected void onReceiveResult(int resultCode, Bundle resultData) {
                super.onReceiveResult(resultCode, resultData);
                if (resultCode == DownloadService.UPDATE_PROGRESS) {
                    progress = resultData.getInt("progress");
                    HashMap<String, Object> data = new HashMap();
                    data.put("progress", progress);
                    plugin.event("downProgressChange", data);
                    if (mProgressDialog != null) {
                        mProgressDialog.setProgress(progress);
                    }

                    if (progress == 100) {
                        if (mProgressDialog != null) {
                            mProgressDialog.dismiss();
                        }
//                        FileUtil.requestWritePermission(this);
                        //如果没有设置SDCard写权限，或者没有sdcard,apk文件保存在内存中，需要授予权限才能安装
//                        installAPK();
                    }
                }
            }
        });
        mContext.startService(intent);
    }

    public void installAPK(){
        try {
            String command = "chmod " + "777" + " " + apkFile.toString();
            Runtime runtime = Runtime.getRuntime();
            runtime.exec(command);
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.putExtra("name", "");
            intent.addCategory("android.intent.category.DEFAULT");
            Uri apkUri;
            if (Build.VERSION.SDK_INT >= 24) {
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                if (HUAWEI_MANUFACTURER.equalsIgnoreCase(Build.MANUFACTURER)) {
                    try {
                        apkUri = FileProvider.getUriForFile(mContext, mContext.getApplicationContext().getPackageName() + ".fileProvider", apkFile);
                    } catch (IllegalArgumentException e) {
                        final File cacheFolder = new File(mContext.getCacheDir(), HUAWEI_MANUFACTURER);
                        if (!cacheFolder.exists()) cacheFolder.mkdirs();
                        final File cacheLocation = new File(cacheFolder,apkFile.getName());
                        if (cacheLocation.exists()) cacheLocation.delete();
                        try {
                            FileHelps.copy(apkFile.getPath(), cacheLocation.getAbsolutePath());
                            apkUri = FileProvider.getUriForFile(mContext, mContext.getApplicationContext().getPackageName() + ".fileProvider", cacheLocation);
                        } catch (Exception e1) {
                            throw new IllegalArgumentException("Huawei devices are unsupported for Android N", e1);
                        }
                    }
                } else {
                    apkUri = FileProvider.getUriForFile(mContext, mContext.getApplicationContext().getPackageName() + ".fileProvider", apkFile);
                }

            } else {
                apkUri = Uri.fromFile(apkFile);
            }
            intent.setDataAndType(apkUri, "application/vnd.android.package-archive");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void cancel(FlutterAppUpdatePlugin plugin){
        DownloadManager.getInstance().cancel(downloadUrl);
        downloadUrl = null;
        progress = 0;
        apkFile = null;
    }
}
