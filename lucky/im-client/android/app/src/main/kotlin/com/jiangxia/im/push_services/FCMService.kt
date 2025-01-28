package com.luckyd.im.push_services

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.luckyd.im.MainActivity
import com.luckyd.im.R

import com.luckyd.im.utils.DecryptUtils
import java.io.File

class FCMService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.i("FCMService ", "Refreshed token :: $token")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.i("FCMService ", "Message id:: ${message.messageId}")
        Log.i("FCMService ", "Message (Before):: ${message.data}")

        val encryptedText: String? = message.data["cipher_data"]

        if (encryptedText != null) {
            val secretKey: String = getString(R.string.aes_secret)

            val dataMap = DecryptUtils.decryptData(secretKey, encryptedText)!!
            Log.i("FCMService ", "Message (After):: ${dataMap}-$secretKey")

            val bodyValue = dataMap["body"]?.toString() ?: "Messages"
            val titleValue = dataMap["title"]?.toString() ?: "Hey"
            val channelID = dataMap["channel_id"]?.toString() ?: "DEFAULT_NOTIFICATION"
            val icon = dataMap["icon_path"]?.toString() ?: "icon"
            val notificationType = dataMap["notification_type"]?.toString() ?: "1"
            val chatID = dataMap["chat_id"]?.toString() ?: "1"
            val transactionID = dataMap["transaction_id"]?.toString() ?: "1"
            val isMissCall = dataMap["is_missed_call"]?.toString()?.toBoolean() ?: false
            val isStopCall = dataMap["stop_call"]?.toString()?.toBoolean() ?: false
            val tag = dataMap["tag"]?.toString() ?: "empty"

            if (isMissCall || isStopCall) {
                val stopServiceIntent = Intent(this, NotificationService::class.java)
                stopServiceIntent.action = "stop"
                startService(stopServiceIntent)
            }

            if (!MainActivity.isAppInForground) {
                try {
                    if (notificationType == "5") {
                        val notificationIntent = Intent(this, NotificationService::class.java)
                        notificationIntent.action = "start"

                        notificationIntent.putExtra("title", titleValue)
                        notificationIntent.putExtra("body", bodyValue)
                        notificationIntent.putExtra("notification_type", notificationType)
                        notificationIntent.putExtra("icon", icon)
                        notificationIntent.putExtra("chat_id", chatID)

                        startForegroundService(notificationIntent)
                    } else {
                        showNotification(
                            this,
                            tag,
                            titleValue,
                            bodyValue,
                            channelID,
                            icon,
                            notificationType,
                            chatID,
                            transactionID,
                            isMissCall,
                            isStopCall
                        )
                    }
                } catch (e: Exception) {
                    Log.i("FCMService ", "Error :: ${e.stackTrace}")
                }
            }
        } else {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            Log.d("FCMService Delete Tag", "${notificationManager.activeNotifications.toList()}")


            if (message.data.containsKey("to_delete")) {
                val toDeleteList: List<String> =
                    parseStringToList(message.data["to_delete"].toString())
                for (deleteTag in toDeleteList) {
                    Log.d("FCMService Delete Tag", "$deleteTag")
                    notificationManager.cancel(deleteTag, 0)
                }
            }

            if (message.data.containsKey("to_delete_chat")) {
                val toDeleteList: List<String> =
                    parseStringToList(message.data["to_delete_chat"].toString())
                val activeNotifications = notificationManager.activeNotifications.toList()
                for (notification in activeNotifications) {
                    if(notification.tag != null){
                        val parts = notification.tag.split('-')
                        if (parts.size == 3) {
                            val middleValue = parts[1]
                            Log.d("FCMService Delete Tag", middleValue)
                            if (toDeleteList.contains(middleValue)) {
                                notificationManager.cancel(notification.tag, 0)
                            }
                        }
                    }
                }
            }

            if (message.data.containsKey("is_missed_call") || message.data.containsKey("stop_call")) {
                val isMissedCall: Boolean? = message.data["is_missed_call"]?.toBoolean()
                val isStopCall: Boolean? = message.data["stop_call"]?.toBoolean()
                if (isMissedCall == true || isStopCall == true) {
                    val stopServiceIntent = Intent(this, NotificationService::class.java)
                    stopServiceIntent.action = "stop"
                    startService(stopServiceIntent)
                    if (!MainActivity.isAppInForground) {
                        val intent = Intent(this, MainActivity::class.java).apply {
                            if (isMissedCall == true) {
                                putExtra(
                                    "is_missed_call",
                                    true
                                ) // Add any extra data you want to pass
                            } else {
                                putExtra("stop_call", true)
                            }
                        }
                        val pendingIntent = PendingIntent.getActivity(
                            this,
                            0,
                            intent,
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                        )

                        var builder = NotificationCompat.Builder(this, "DEFAULT_NOTIFICATION")
                            .setSmallIcon(R.drawable.splash_logo)
                            .setContentTitle(message.data["title"])
                            .setContentText(message.data["body"])
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setContentIntent(pendingIntent)

                        val notificationManager = NotificationManagerCompat.from(this)
                        if (ActivityCompat.checkSelfPermission(
                                this,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            return
                        }
                        notificationManager.notify(1, builder.build())
                    }
                }
            } else {
                if (!MainActivity.isAppInForground) {
                    try {
                        println("start working in onMessageReceived")
                        if (message.data["notification_type"] == "5") {
                            val notificationIntent = Intent(this, NotificationService::class.java)
                            notificationIntent.action = "start"

                            notificationIntent.putExtra("title", message.data["title"])
                            notificationIntent.putExtra("body", message.data["body"])
                            notificationIntent.putExtra(
                                "is_call_invite",
                                message.data["is_call_invite"]
                            )
                            notificationIntent.putExtra("start_time", message.data["start_time"])
                            notificationIntent.putExtra(
                                "notification_type",
                                message.data["notification_type"]
                            )
//                        notificationIntent.putExtra("notification_sound",message.data["notification_sound"])
                            notificationIntent.putExtra("caller", message.data["caller"])
                            notificationIntent.putExtra("icon", message.data["icon"])
                            notificationIntent.putExtra("mute", message.data["mute"])
                            notificationIntent.putExtra(
                                "notification_priority",
                                message.data["notification_priority"]
                            )
                            notificationIntent.putExtra("chat_id", message.data["chat_id"])
                            notificationIntent.putExtra(
                                "notification_default",
                                message.data["notification_default"]
                            )
                            notificationIntent.putExtra(
                                "rtc_channel_id",
                                message.data["rtc_channel_id"]
                            )
                            notificationIntent.putExtra(
                                "transaction_id",
                                message.data["transaction_id"]
                            )

                            startForegroundService(notificationIntent)
                        }

                    } catch (e: Exception) {
                        println(e.stackTrace)
                    }
                }
            }
        }
    }

    fun isGooglePlayServicesAvailable(activity: Activity?): Boolean {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val status = googleApiAvailability.isGooglePlayServicesAvailable(activity!!)
        if (status != ConnectionResult.SUCCESS) {
            if (googleApiAvailability.isUserResolvableError(status)) {
                googleApiAvailability.getErrorDialog(activity, status, 2404)!!.show()
            }
            return false
        }
        return true
    }

    private fun parseStringToList(inputString: String): List<String> {
        // Remove the square brackets, split the string by commas, and convert each element to an integer
        return inputString.trim('[', ']').split(", ").map { it }
    }

    private fun showNotification(
        context: Context,
        tag: String,
        titleValue: String,
        bodyValue: String,
        channelID: String,
        icon: String,
        notificationType: String,
        chatID: String,
        transactionID: String,
        isMissCall: Boolean,
        isStopCall: Boolean,
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("notification_type", notificationType)
            putExtra("icon", icon)
            putExtra("chat_id", chatID)
            putExtra("transaction_id", transactionID)
            putExtra("is_missed_call", isMissCall)
            putExtra("stop_call", isStopCall)
        }

        val pendingIntent =
            PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

//        val notificationId = System.currentTimeMillis().toInt()
        val baseDir = File(context.filesDir.parentFile, "app_flutter/download")
        val fullPath = File(baseDir, icon).absolutePath
        val bitmap = BitmapFactory.decodeFile(fullPath)

        val builder = NotificationCompat.Builder(context, channelID)
            .setSmallIcon(R.drawable.splash_logo)
            .setContentTitle(titleValue)
            .setContentText(bodyValue)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent).setLargeIcon(bitmap)

        val notificationManager = NotificationManagerCompat.from(context)
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        notificationManager.notify(tag, 0, builder.build())
    }
}