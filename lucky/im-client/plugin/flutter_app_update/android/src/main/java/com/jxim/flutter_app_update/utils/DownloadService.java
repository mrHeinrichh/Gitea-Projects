package com.jxim.flutter_app_update.utils;

import android.app.IntentService;
import android.content.Intent;
import android.os.Bundle;
import android.os.ResultReceiver;

/**
 * 下载服务
 * Created by wuyue on 2017/1/19.
 */
public class DownloadService extends IntentService{
    public static final int UPDATE_PROGRESS = 8344;

    public DownloadService() {
        super("DownloadService");
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public void onStart(Intent intent, int startId) {
        super.onStart(intent, startId);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        String urlToDownload = intent.getStringExtra("url");
        String fileDestination = intent.getStringExtra("dest");
        final ResultReceiver receiver = intent.getParcelableExtra("receiver");
        DownloadManager.getInstance().download(urlToDownload, fileDestination, new DownLoadObserver() {
            @Override
            public void onNext(DownloadInfo value) {
                super.onNext(value);
                int progress = (int) (value.getProgress() / (double)value.getTotal() * 100);
                if (progress == 100) {
                    progress = 99;
                }
                Bundle resultData = new Bundle();
                resultData.putInt("progress", progress);
                receiver.send(UPDATE_PROGRESS, resultData);
            }

            @Override
            public void onError(Throwable e) {
                stopSelf();
            }

            @Override
            public void onComplete() {
                if(downloadInfo != null){
                    Bundle resultData = new Bundle();
                    resultData.putInt("progress", 100);
                    receiver.send(UPDATE_PROGRESS, resultData);
                    stopSelf();
                }
            }
        });

    }
}
