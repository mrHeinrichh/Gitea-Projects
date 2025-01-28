package com.luckyd.im.push_services

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.luckyd.im.MainActivity
import com.luckyd.im.R
import com.luckyd.im.callVibration

class NotificationService : Service() {

    private val NOTIFICATION_ID = 1
    private val NOTIFICATION_DURATION = 30000 // 30 seconds

    private val handler = Handler()

    private var wakeLock: PowerManager.WakeLock? = null


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "start") {
            startForeground(NOTIFICATION_ID, createPersistentNotification(intent.extras))
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "NotificationService::WakeLock"
            )
            wakeLock?.acquire()
            handler.postDelayed({
                stopForeground(true)
                stopSelf()
            }, NOTIFICATION_DURATION.toLong())
        } else if (intent?.action == "stop") {
            stopForeground(true)
            stopSelf()
            Log.i("NotificationService", "Stop Services................")

        }
        return START_NOT_STICKY
    }

    private fun createPersistentNotification(extras: Bundle?): Notification {
        val intent = Intent(this, MainActivity::class.java)
        intent.putExtra("title", extras?.getString("title"))
        intent.putExtra("body", extras?.getString("body"))
        intent.putExtra("is_call_invite", extras?.getString("is_call_invite"))
        intent.putExtra("start_time", extras?.getString("start_time"))
        intent.putExtra("notification_type", extras?.getString("notification_type"))
        intent.putExtra("notification_sound", extras?.getString("notification_sound"))
        intent.putExtra("caller", extras?.getString("caller"))
        intent.putExtra("icon", extras?.getString("icon"))
        intent.putExtra("mute", extras?.getString("mute"))
        intent.putExtra("notification_priority", extras?.getString("notification_priority"))
        intent.putExtra("chat_id", extras?.getString("chat_id"))
        intent.putExtra("notification_default", extras?.getString("notification_default"))
        intent.putExtra("rtc_channel_id", extras?.getString("rtc_channel_id"))
        intent.putExtra("transaction_id", extras?.getString("transaction_id"))
        val contentIntent =
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

        Log.i("FCM DATA", extras?.getString("data").toString())


        return NotificationCompat.Builder(this, "DEFAULT_CALL")
            .setContentTitle(extras?.getString("title"))
            .setContentText(extras?.getString("body"))
            .setSmallIcon(R.drawable.splash_logo)
            .setFullScreenIntent(contentIntent, true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setExtras(extras)
            .setVibrate(callVibration)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
    }
}
