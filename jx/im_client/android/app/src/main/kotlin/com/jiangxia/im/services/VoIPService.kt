package com.jiangxia.im.services

import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import androidx.annotation.RequiresApi
import com.jiangxia.im.MainActivity

class VoIPService : Service() {
    private val CHANNEL_ID = "HeyTalkVoIPChannel"
    private val voipBinder: IBinder = VoIpBinder()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val chatId = intent!!.getStringExtra("chatId")
        createNotificationChannel(chatId!!)
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent: PendingIntent? = PendingIntent.getService(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("正在通话中")
            .setSmallIcon(R.drawable.stat_sys_speakerphone)
            .setContentIntent(pendingIntent)
            .setOngoing(false)
            .setSound(null)
            .build()

        startForeground(chatId.toInt(), notification)
        Log.v("VoIPService", "Service started")

        return START_NOT_STICKY
    }

    private var windowManager: WindowManager? = null
    private var invisibleView: View? = null

    override fun onCreate() {
        super.onCreate()

        try {
            if (!hasOverlayPermission()) {
                return
            }

            // 创建WindowManager实例
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

            // 创建一个不可见的View
            invisibleView = View(this)

            // 设置LayoutParams，应用 FLAG_KEEP_SCREEN_ON
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                resources.displayMetrics.widthPixels,
                0,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.RGBA_8888
            )

            // 添加视图到 WindowManager
            windowManager!!.addView(invisibleView, params)
        } catch (e: Exception) {
            Log.v("VoIPService", "Create Window error", e)
        }

        Log.v("VoIPService", "Service onCreate")
    }

    override fun onBind(intent: Intent): IBinder {
        return voipBinder;
    }

    private fun createNotificationChannel(chatId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                chatId,
                NotificationManager.IMPORTANCE_LOW
            )
            serviceChannel.setSound(null, null)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()

        try {
            if (invisibleView != null) {
                windowManager!!.removeView(invisibleView);
            }
        } catch (e: Exception) {
            Log.v("VoIPService", "Service onDestroy error", e)
        }

        Log.v("VoIPService", "Service onDestroy")
    }

    // 判断是否有悬浮窗权限
    private fun hasOverlayPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(
            this
        )
    }

    inner class VoIpBinder : Binder() {
        val service: VoIPService
            get() = this@VoIPService
    }
}