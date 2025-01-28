package com.jxim.flutter_app_update.handle;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;

import androidx.annotation.NonNull;

import com.jxim.flutter_app_update.FlutterAppUpdatePlugin;
import com.jxim.flutter_app_update.utils.App;
import com.jxim.flutter_app_update.utils.Download;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.CoreConnectionPNames;
import org.apache.http.util.EntityUtils;
import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.Date;
import java.util.HashMap;


public class VersionHandle {
    private static final int netTimeout = 10000;
    Context context;
    Context activity;
    FlutterAppUpdatePlugin plugin;
    // 更新类
    private Download download;

    public VersionHandle(Context context, FlutterAppUpdatePlugin plugin) {
        this.context = context;
        this.plugin = plugin;
    }

    public void initActive(Context activity) {
        this.activity = activity;
    }

    private static VersionHandle _instance;

    // 校验更新
    public void checkAppVersion(boolean useSystemUI, String lastVersionName, int lastVersionCode, @NonNull Result result) {
        String appVersionName = App.getAppVersionName(context);
        int v = compareVersion(appVersionName, lastVersionName);
        boolean isOlder = v < 0;
        if (v == 0) {
            long appVersionCode = App.getAppVersionCode(context);
            isOlder = appVersionCode < lastVersionCode;
        }
        HashMap<String, Object> data = new HashMap<String, Object>();
        data.put("isOlder", isOlder);
        result.success(data);
    }

    // 校验最低版本号
    public void checkLowMinVersion(String minVersionName, int minVersionCode, @NonNull Result result) {
        String appVersionName = App.getAppVersionName(context);
        int v = compareVersion(appVersionName, minVersionName);
        boolean isOlder = v < 0;
        if (v == 0) {
            long appVersionCode = App.getAppVersionCode(context);
            isOlder = appVersionCode < minVersionCode;
        }
        result.success(isOlder);
    }

    /**
     * 版本号比较
     *
     * @param version1
     * @param version2
     * @return
     */
    public static int compareVersion(String version1, String version2) {
        if (version1.equals(version2)) {
            return 0;
        }
        String[] version1Array = version1.split("\\.");
        String[] version2Array = version2.split("\\.");
        Log.d("HomePageActivity", "version1Array==" + version1Array.length);
        Log.d("HomePageActivity", "version2Array==" + version2Array.length);
        int index = 0;
        // 获取最小长度值
        int minLen = Math.min(version1Array.length, version2Array.length);
        int diff = 0;
        // 循环判断每位的大小
        Log.d("HomePageActivity", "verTag2=2222=" + version1Array[index]);
        while (index < minLen
                && (diff = Integer.parseInt(version1Array[index])
                - Integer.parseInt(version2Array[index])) == 0) {
            index++;
        }
        if (diff == 0) {
            // 如果位数不一致，比较多余位数
            for (int i = index; i < version1Array.length; i++) {
                if (Integer.parseInt(version1Array[i]) > 0) {
                    return 1;
                }
            }

            for (int i = index; i < version2Array.length; i++) {
                if (Integer.parseInt(version2Array[i]) > 0) {
                    return -1;
                }
            }
            return 0;
        } else {
            return diff > 0 ? 1 : -1;
        }
    }

    public int getDownProgress(){
        return download != null? download.progress : 0;
    }

    public void downAPK(String uri, String md5, boolean useSystemUI) {
        if (download == null) {
            download = new Download(activity);
        }
        download.downLoadApk(uri, md5, useSystemUI, plugin);
    }

    public void downCancel() {
        if (download == null) {
            return;
        }
        download.cancel(plugin);
        download = null;
    }

    public void installAPK(){
        if (download == null) {
            return;
        }
        download.installAPK();
    }
}
