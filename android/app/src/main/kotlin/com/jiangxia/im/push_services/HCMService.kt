package com.jiangxia.im.push_services

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.huawei.hms.push.HmsMessageService
import com.huawei.hms.push.RemoteMessage
import com.jiangxia.im.R
import com.jiangxia.im.utils.DecryptUtils
import com.jiangxia.im.MainActivity
import java.sql.Date
import java.text.SimpleDateFormat
import java.util.*

class HCMService : HmsMessageService() {
    private val badgeNumber: Int
        get() = NotificationService.badgeNumber

    private fun resetBadgeNumber() {
        NotificationService.resetBadgeNumber()
    }

    override fun onNewToken(token: String, bundle: Bundle) {

        // 判断token是否为空
        if (token.isNotEmpty()) {
            Log.i("HMS Service ::", "have received refresh token:$token")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.i("HMS Service ::", "Message (Before):: ${message.data}")
        Log.i("HMS Service ::", "Message (Before):: ${message.data}")
        val encryptedText: String? = message.dataOfMap["cipher_data"]
        val secretKey: String = getString(R.string.aes_secret)
        if (encryptedText != null) {
            val dataMap = DecryptUtils.decryptData(secretKey, encryptedText)!!
            Log.i(
                "HMS Service ::",
                "Message (After):: ${dataMap}"
            )

            var bodyValue = dataMap["body"]?.toString() ?: "Messages"
            val titleValue = dataMap["title"]?.toString() ?: "Hey"
            val channelID = dataMap["channel_id"]?.toString() ?: "DEFAULT_NOTIFICATION"
            val icon = dataMap["icon"]?.toString() ?: "icon"
            val notificationType = dataMap["notification_type"]?.toString() ?: "1"
            val chatID = dataMap["chat_id"]?.toString() ?: "1"
            val transactionID = dataMap["transaction_id"]?.toString() ?: "1"
            val isMissCall = dataMap["is_missed_call"]?.toString()?.toBoolean() ?: false
            val isStopCall = dataMap["stop_call"]?.toString()?.toBoolean() ?: false
            var tag = dataMap["tag"]?.toString() ?: "empty"
            val groupExpiry = dataMap["group_expiry"]?.toString() ?: "0"
            val editId = dataMap["edit_id"]?.toString() ?: ""

            if (isMissCall || isStopCall) {
                val stopServiceIntent = Intent(this, NotificationService::class.java)
                stopServiceIntent.action = "stop"
                startService(stopServiceIntent)
            }

            if (groupExpiry.toLong() > 0) {
                val timestampInMilliseconds = groupExpiry.toLong() * 1000
                val date = Date(timestampInMilliseconds)
                val formatter = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
                val formattedDate = formatter.format(date)

                val newString = bodyValue.replace("_s", formattedDate)

                bodyValue = newString
            }

            if (editId != "") {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val activeNotifications = notificationManager.activeNotifications.toList()
                for (notification in activeNotifications) {
                    if(notification.tag != null && notification.tag == editId){
                        notificationManager.cancel(notification.tag, 0)
                    }
                }
                tag = editId
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
            Log.d("HMS Service Delete Tag", "${notificationManager.activeNotifications.toList()}")


            if (message.dataOfMap.containsKey("to_delete")) {
                val toDeleteList: List<String> =
                    parseStringToList(message.dataOfMap["to_delete"].toString())
                for (deleteTag in toDeleteList) {
                    Log.d("HMS Service Delete Tag", "$deleteTag")
                    notificationManager.cancel(deleteTag, 0)
                }
            }

            if (message.dataOfMap.containsKey("to_delete_chat")) {
                val toDeleteList: List<String> =
                    parseStringToList(message.dataOfMap["to_delete_chat"].toString())
                val activeNotifications = notificationManager.activeNotifications.toList()
                for (notification in activeNotifications) {
                    if (notification.tag != null) {
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

            if (message.dataOfMap.containsKey("is_missed_call") || message.dataOfMap.containsKey("stop_call")) {
                val isMissedCall: Boolean? = message.dataOfMap["is_missed_call"]?.toBoolean()
                val isStopCall: Boolean? = message.dataOfMap["stop_call"]?.toBoolean()
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
                        try {
                            var builder = NotificationCompat.Builder(this, "DEFAULT_NOTIFICATION")
                                .setSmallIcon(R.drawable.splash_logo)
                                .setContentTitle(message.dataOfMap["title"])
                                .setContentText(message.dataOfMap["body"])
                                .setPriority(NotificationCompat.PRIORITY_HIGH)
                                .setContentIntent(pendingIntent)
                                .setNumber(badgeNumber)

                            // badgeNumber > 1未重設為1，下次的number = badgeNumber + 1
                            resetBadgeNumber()

                            val notificationManager = NotificationManagerCompat.from(this)
                            if (ActivityCompat.checkSelfPermission(
                                    this,
                                    Manifest.permission.POST_NOTIFICATIONS
                                ) != PackageManager.PERMISSION_GRANTED
                            ) {
                                return
                            }
                            val notificationTag = System.currentTimeMillis().toString()
                            notificationManager.notify(notificationTag, 0, builder.build())
                        } catch (e: Exception) {
                            Log.d("HMS Service", "Error :$e")
                        }


                    }
                }
            } else {
                if (!MainActivity.isAppInForground) {
                    try {
                        println("start working in onMessageReceived")
                        if (message.dataOfMap["notification_type"] == "5") {
                            val notificationIntent = Intent(this, NotificationService::class.java)
                            notificationIntent.action = "start"

                            notificationIntent.putExtra("title", message.dataOfMap["title"])
                            notificationIntent.putExtra("body", message.dataOfMap["body"])
                            notificationIntent.putExtra(
                                "is_call_invite",
                                message.dataOfMap["is_call_invite"]
                            )
                            notificationIntent.putExtra(
                                "start_time",
                                message.dataOfMap["start_time"]
                            )
                            notificationIntent.putExtra(
                                "notification_type",
                                message.dataOfMap["notification_type"]
                            )
//                        notificationIntent.putExtra("notification_sound",message.data["notification_sound"])
                            notificationIntent.putExtra("caller", message.dataOfMap["caller"])
                            notificationIntent.putExtra("icon", message.dataOfMap["icon"])
                            notificationIntent.putExtra("mute", message.dataOfMap["mute"])
                            notificationIntent.putExtra(
                                "notification_priority",
                                message.dataOfMap["notification_priority"]
                            )
                            notificationIntent.putExtra("chat_id", message.dataOfMap["chat_id"])
                            notificationIntent.putExtra(
                                "notification_default",
                                message.dataOfMap["notification_default"]
                            )
                            notificationIntent.putExtra(
                                "rtc_channel_id",
                                message.dataOfMap["rtc_channel_id"]
                            )
                            notificationIntent.putExtra(
                                "transaction_id",
                                message.dataOfMap["transaction_id"]
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

    fun parseStringToList(inputString: String): List<String> {
        // Remove the square brackets, split the string by commas, and convert each element to an integer
        return inputString.trim('[', ']').split(" ").map { it.toString() }
    }

    fun showNotification(
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

        val builder = NotificationCompat.Builder(context, channelID)
            .setSmallIcon(R.drawable.splash_logo)
            .setContentTitle(titleValue)
            .setContentText(bodyValue)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setNumber(badgeNumber)

        // badgeNumber > 1未重設為1，下次的number = badgeNumber + 1
        resetBadgeNumber()

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