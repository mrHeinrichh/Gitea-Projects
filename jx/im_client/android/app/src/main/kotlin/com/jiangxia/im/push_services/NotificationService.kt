package com.jiangxia.im.push_services

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
import android.media.SoundPool
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.jiangxia.im.MainActivity
import com.jiangxia.im.R
import com.jiangxia.im.callVibration
import io.agora.base.internal.ContextUtils.getApplicationContext
import me.leolin.shortcutbadger.ShortcutBadger

class NotificationService : Service() {
    private val NOTIFICATION_ID = 34243
    private val NOTIFICATION_DURATION = 60000 // 60 seconds
    private val handler = Handler()
    private var wakeLock: PowerManager.WakeLock? = null

    private var ringPool: SoundPool? = null
    private var ringId: Int = -1
    private var ringSoundLoaded = false
    private var ringStreamId: Int = 0
    private var ringPlaying = false

    companion object {
        var isServiceRunning = false
        var currentChannelId = ""
        private set
        var badgeNumber: Int = 1

        ///不清楚用意，目前在每次設定badge時，都會重置，那就等於沒有設置
        fun resetBadgeNumber() {
//            badgeNumber = 1
//            ShortcutBadger.removeCount(getApplicationContext())
        }

        fun setBadgeToAppIcon(number: Int) {
            badgeNumber = number
            // serve进来上下文参数不对会崩
            // ShortcutBadger.applyCount(getApplicationContext(),badgeNumber)
        }
    }

    override fun onCreate() {
        super.onCreate()
        preloadSound()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.v("FCMService ", "onStartCommand===> ${intent?.action} | ${intent?.getStringExtra("rtc_channel_id")}")
        if (intent?.action == "start") {
            currentChannelId = intent.getStringExtra("rtc_channel_id") ?: ""
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, createPersistentNotification(intent.extras), FOREGROUND_SERVICE_TYPE_PHONE_CALL)
            } else {
                startForeground(NOTIFICATION_ID, createPersistentNotification(intent.extras))
            }
            isServiceRunning = true

            this.playRing()

            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "NotificationService::WakeLock"
            )
            wakeLock?.acquire()

            handler.postDelayed({
                this.stopService()
            }, NOTIFICATION_DURATION.toLong())
        } else if (intent?.action == "stop") {
            this.stopService()
            Log.i("NotificationService", "Stop Services................$currentChannelId")
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

        badgeNumber = extras?.getInt("badgeNumber", badgeNumber) ?: badgeNumber
        intent.putExtra("badgeNumber", badgeNumber)

        val contentIntent =
            PendingIntent.getActivity(
                this,
                234,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

        var notification: Notification = NotificationCompat.Builder(this, "phonecall_channel")
            .setContentTitle(extras?.getString("title"))
            .setContentText(extras?.getString("body"))
            .setSmallIcon(R.drawable.splash_logo)
            .setFullScreenIntent(contentIntent, true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setExtras(extras)
            .setVibrate(callVibration)
            .setNumber(badgeNumber)
            .build()
        notification.flags = Notification.FLAG_INSISTENT

        // badgeNumber > 1未重設為1，下次的number = badgeNumber + 1
        resetBadgeNumber()

        return notification
    }

    fun preloadSound(){
        val audioAttributes = AudioAttributes.Builder()
            .setLegacyStreamType(AudioManager.STREAM_VOICE_CALL)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        ringPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        ringId = ringPool!!.load(this, R.raw.call, 1)

        ringPool?.setOnLoadCompleteListener { _, _, _ ->
            ringSoundLoaded = true
            this.playRing()
        }
    }


    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun stopService(){
        isServiceRunning = false
        stopRing()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun playRing(){
        if(ringSoundLoaded && isServiceRunning && !ringPlaying){
            ringPlaying = true
            ringStreamId = ringPool?.play(ringId, 1.0f, 1.0f, 1, 20, 1f) ?: 0
        }
    }

    private fun stopRing(){
        ringPlaying = false
        ringPool?.stop(ringStreamId)
    }

    private fun releaseRing(){
        stopRing()
        ringPool = null
        ringId = -1
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
        releaseRing()
        isServiceRunning = false
        currentChannelId = ""
    }
}
