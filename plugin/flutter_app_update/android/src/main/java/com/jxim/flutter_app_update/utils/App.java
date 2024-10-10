package com.jxim.flutter_app_update.utils;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class App {
    /**
     * 获取当前app version code
     */
    public static long getAppVersionCode(Context context) {
        long appVersionCode = 0;
        try {
            PackageInfo packageInfo = context.getApplicationContext()
                    .getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                appVersionCode = packageInfo.getLongVersionCode();
            } else {
                appVersionCode = packageInfo.versionCode;
            }
        } catch (PackageManager.NameNotFoundException e) {
            Log.e("", e.getMessage());
        }
        return appVersionCode;
    }

    /**
     * 获取当前app version name
     */
    public static String getAppVersionName(Context context) {
        String appVersionName = "";
        try {
            PackageInfo packageInfo = context.getApplicationContext()
                    .getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0);
            appVersionName = packageInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            Log.e("", e.getMessage());
        }
        return appVersionName;
    }

    /**
     * 获取文件扩展名
     * @return
     */
    public static String getExt(String url) {
        int index = url.indexOf("?");
        if (index != -1) {
            url = url.substring(0, index);
        }
        index = url.lastIndexOf(".");
        if (index == -1) {
            return null;
        }
        return url.substring(index + 1);
    }

    /**
     * 下载文件
     * @return
     */
    public  static boolean downFile(String url, String savePath, DownCallback callback) {
        try {
            URL downUrl = new URL(url);
            HttpURLConnection connection = (HttpURLConnection) downUrl.openConnection();
            connection.connect();
            int code = connection.getResponseCode();
            if (code >= 400) {
                // 下载失败
                return false;
            }
            // 创建父级目录
            File parent = new File(savePath).getParentFile();
            if (!parent.exists() || !parent.isDirectory()) {
                parent.mkdirs();
            }
            // this will be useful so that you can show a typical 0-100% progress bar
            int totalSize = connection.getContentLength();
            // download the file
            InputStream input = new BufferedInputStream(connection.getInputStream());
            OutputStream output = new FileOutputStream(savePath);
            byte data[] = new byte[100];
            long downSize = 0;
            int count;
            while ((count = input.read(data)) != -1) {
                downSize += count;
                output.write(data, 0, count);
                if(callback != null){
                    callback.onProgress(downSize, totalSize);
                }
            }
            output.flush();
            output.close();
            input.close();
            if(callback != null){
                callback.onComplete();
            }
            return true;
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
}
