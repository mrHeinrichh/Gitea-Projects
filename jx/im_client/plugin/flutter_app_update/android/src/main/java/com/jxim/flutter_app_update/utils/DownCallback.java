package com.jxim.flutter_app_update.utils;

public interface DownCallback {
    public void onProgress(long downSize, long totalSize);
    public void onComplete();
}
