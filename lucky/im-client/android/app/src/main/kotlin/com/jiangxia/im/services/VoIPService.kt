package com.luckyd.im.services

import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.lifecycle.MutableLiveData
import com.luckyd.im.MainActivity
import java.util.Random

class VoIPService : Service() {
    private val CHANNEL_ID = "HeyTalkVoIPChannel"
    private val voipBinder: IBinder = VoIpBinder()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val chatId = intent!!.getStringExtra("chatId")
        createNotificationChannel(chatId!!)
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0, notificationIntent, 0
        )

        val notification: Notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("正在通话中")
//            .setContentText("来电通话")
            .setSmallIcon(R.drawable.stat_sys_speakerphone)
            .setContentIntent(pendingIntent)
            .setOngoing(false)
            .build()

        startForeground(chatId.toInt(), notification)

        Log.v("VoIPService", "Service started")

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent): IBinder {
        return voipBinder;
    }

    private fun createNotificationChannel(chatId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                chatId,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    inner class VoIpBinder : Binder() {
        val service: VoIPService
            get() = this@VoIPService
    }
}