package com.jxim.flutter_app_update.utils;

/**
 * Created by 陈丰尧 on 2017/2/2.
 * 下载信息
 */

public class DownloadInfo {
    public static final long TOTAL_ERROR = -1;//获取进度失败
    private String url;
    private long total;
    private long progress;
    private String fileName;
    private String savePath;

    public DownloadInfo(String url, String savePath) {
        this.url = url;
        this.savePath = savePath;
    }

    public String getUrl() {
        return url;
    }

    public String getSavePath() {
        return savePath;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public long getTotal() {
        return total;
    }

    public void setTotal(long total) {
        this.total = total;
    }

    public long getProgress() {
        return progress;
    }

    public void setProgress(long progress) {
        this.progress = progress;
    }
}