package com.jiangxia.im.push_services

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
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
import com.huawei.hms.push.constant.RemoteMessageConst.Notification.CHANNEL_ID
import com.jiangxia.im.MainActivity
import com.jiangxia.im.R
import com.jiangxia.im.utils.DecryptUtils
import io.sentry.Sentry
import java.sql.Date
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONObject
import java.security.MessageDigest
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken


class HCMService : HmsMessageService() {
    private val badgeNumber: Int
        get() = NotificationService.badgeNumber

    private fun resetBadgeNumber() {
        NotificationService.resetBadgeNumber()
    }

    private fun setBadgeToAppIcon(badgeNumber:Int) {
        NotificationService.setBadgeToAppIcon(badgeNumber)
    }

    override fun onNewToken(token: String, bundle: Bundle) {

        // 判断token是否为空
        if (token.isNotEmpty()) {
            Log.i("HMS Service ::", "have received refresh token:$token")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMessageReceived(message: RemoteMessage) {
        if (shouldDisableNotifications()) {
            // Don't show notification, just return
            return;
        }

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
            if (bodyValue != null) {
                val refType = dataMap["ref_typ"] as? String
                val json = dataMap["e2e"] as? String
                val chatId = dataMap["chat_id"] as? String
                if (json != null && chatId != null) {
                    try {
                        // Parse the JSON string into a Map (JSONObject)
                        val jsonData = json.toByteArray(Charsets.UTF_8)
                        val jsonMap = JSONObject(String(jsonData))

                        var userName = dataMap["sender_name"] as? String
                        var aMap: MutableMap<String, String> = mutableMapOf()

                        // Check if the value for "at_user" exists and is a String
                        val atUser = dataMap["at_user"] as? String

                        // If the value exists and can be parsed as a JSON object, process it
                        if (atUser != null) {
                            val atJson = JSONObject(atUser)

                            // Convert the JSONObject to a Map<String, String>
                            for (key in atJson.keys()) {
                                aMap[key] = atJson.getString(key)
                            }
                        }

                        // Extract fields from the parsed JSON
                        val messageRound = jsonMap.optInt("round", -1)
                        val encrypted = jsonMap.optString("data", "")
                        val rt = refType?.toIntOrNull()

                        val contentRt = jsonMap.optInt("ref_typ", -1)
                        val content = jsonMap.optString("content", "")

                        if (rt == 1 && messageRound != -1 && encrypted.isNotEmpty()) {
                            // Get the decryption key
                            val (key, texts, isSingle) = getCurrentChatKey(chatId, messageRound)
                            if (isSingle != null && isSingle == true) {
                                userName = null
                            }

//                                Log.i("FCMService ", "gotten key :: ${key}")
                            if (key != null) {
                                // Decrypt the data
                                val decrypted = DecryptUtils.decryptDataCTR(key, encrypted)
//                                    Log.i("FCMService ", "decrypted :: ${decrypted}")
                                if (decrypted != null) {
                                    val msgTyp = (dataMap["msg_typ"] as? String)?.toInt()
//                                        Log.i("FCMService ", "msgTyp :: ${msgTyp}")
                                    if (msgTyp != null) {
                                        val processedText =
                                            processText(msgTyp, decrypted, texts, userName, aMap)
                                        if (processedText != null) {
                                            bodyValue = processedText
                                        }
                                    }

                                }

                            }
                        } else if (contentRt == 1 && content.isNotEmpty()) {
                            val contentJsonData = content.toByteArray(Charsets.UTF_8)
                            val contentJsonMap = JSONObject(String(contentJsonData))
                            val contentMessageRound = contentJsonMap.optInt("round", -1)
                            val contentEncrypted = contentJsonMap.optString("data", "")

                            if (contentMessageRound != -1 && contentEncrypted.isNotEmpty()) {
                                val (key, texts, isSingle) = getCurrentChatKey(
                                    chatId,
                                    contentMessageRound
                                )
                                if (isSingle != null && isSingle == true) {
                                    userName = null
                                }

//                                Log.i("FCMService ", "gotten key :: ${key}")
                                if (key != null) {
                                    // Decrypt the data
                                    val decrypted =
                                        DecryptUtils.decryptDataCTR(key, contentEncrypted)
//                                    Log.i("FCMService ", "decrypted :: ${decrypted}")
                                    if (decrypted != null) {
                                        val msgTyp = (dataMap["msg_typ"] as? String)?.toInt()
//                                        Log.i("FCMService ", "msgTyp :: ${msgTyp}")
                                        if (msgTyp != null) {
                                            val processedText =
                                                processText(
                                                    msgTyp,
                                                    decrypted,
                                                    texts,
                                                    userName,
                                                    aMap
                                                )
                                            if (processedText != null) {
                                                bodyValue = processedText
                                            }
                                        }

                                    }

                                }
                            }
                        }
                    } catch (e: Exception) {
                        // If JSON parsing fails or any error occurs, fall back to original body
                        Log.i("HCMService ", "Error :: ${e.stackTrace}")
                    }
                }
            }

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
                val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val activeNotifications = notificationManager.activeNotifications.toList()
                for (notification in activeNotifications) {
                    if (notification.tag != null && notification.tag == editId) {
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
                    Sentry.captureException(e)
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
                            val notificationManager = NotificationManagerCompat.from(this)
                            if (ActivityCompat.checkSelfPermission(
                                    this,
                                    Manifest.permission.POST_NOTIFICATIONS
                                ) != PackageManager.PERMISSION_GRANTED
                            ) {
                                return
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val notificationChannel = NotificationChannel(
                                    "DEFAULT_NOTIFICATION",
                                    "CHANNEL_NAME",
                                    NotificationManager.IMPORTANCE_LOW
                                )

                                notificationChannel.setSound(null, null)
                                notificationChannel.enableVibration(false)
                                notificationManager.createNotificationChannel(notificationChannel)
                            }

                            val builder = NotificationCompat.Builder(this, "DEFAULT_NOTIFICATION")
                                .setSmallIcon(R.drawable.splash_logo)
                                .setContentTitle(message.dataOfMap["title"])
                                .setContentText(message.dataOfMap["body"])
                                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                                .setContentIntent(pendingIntent)
                                .setNumber(badgeNumber)

                            // badgeNumber > 1未重設為1，下次的number = badgeNumber + 1
                            resetBadgeNumber()
                            val notificationTag = System.currentTimeMillis().toString()
                            setBadgeToAppIcon(badgeNumber)
                            notificationManager.notify(notificationTag, 0, builder.build())
                        } catch (e: Exception) {
                            Sentry.captureException(e)
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
                        Sentry.captureException(e)
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
        setBadgeToAppIcon(badgeNumber)
        notificationManager.notify(tag, 0, builder.build())
    }

    private fun getCurrentChatKey(
        chatId: String,
        messageRound: Int
    ): Triple<String?, Map<String, Any>?, Boolean?> {
        val key = "flutter.ANDROID_CHAT_LIST_KEY"

        val context: Context = this
        // Access SharedPreferences (similar to UserDefaults in iOS)
        val sharedPreferences: SharedPreferences =
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val data = sharedPreferences.getString(key, null)

        // Return null if no data exists for the key
        if (data.isNullOrEmpty()) {
            return Triple(null, null, null)
        }

        val allMap = parseJsonToMap(data) ?: return Triple(null, null, null)

        val texts = allMap["encryption_language"] ?: return Triple(null, null, null)

        // Parse the data (assuming the data is stored as a JSON string)
        val chatMap = allMap[chatId] ?: return Triple(null, texts, null)

        val isSingle = chatMap["isSingle"] as? Boolean
        val round = (chatMap["round"] as? Double)?.toInt()
        val activeKeyRound = (chatMap["activeRound"] as? Double)?.toInt()
        var activeKey = chatMap["activeKey"] as? String

        if (round == null || activeKeyRound == null || activeKey == null) {
            return Triple(null, texts, isSingle)
        }

        // If activeKeyRound is more than the given messageRound, return null
        if (activeKeyRound > messageRound) {
            return Triple(null, texts, isSingle)
        }

        // If messageRound is greater than activeKeyRound, apply MD5 transformation
        if (messageRound > activeKeyRound) {
            var numberOfTimes = messageRound - activeKeyRound
            for (i in 0 until numberOfTimes) {
                activeKey = activeKey?.let { md5(it) }
            }
        }
        return Triple(activeKey, texts, isSingle)
    }

    // Utility function to parse JSON string to a map (to mimic Swift's dictionary parsing)
    private fun parseJsonToMap(json: String): Map<String, Map<String, Any>> {
        // Assuming you use a library like Gson or Moshi to parse the JSON
        val gson = Gson()
        val mapType = object : TypeToken<Map<String, Map<String, Any>>>() {}.type
        return gson.fromJson(json, mapType) as Map<String, Map<String, Any>>
    }

    // MD5 hash function
    private fun md5(input: String): String {
        val digest = MessageDigest.getInstance("MD5")
        val bytes = digest.digest(input.toByteArray())
        val sb = StringBuilder()
        for (byte in bytes) {
            sb.append(String.format("%02x", byte))
        }
        return sb.toString()
    }

    private fun processText(
        typ: Int,
        decryptedData: Map<String, Any>,
        texts: Map<String, Any>?,
        userName: String?,
        atUsers: Map<String, String>
    ): String? {

        var userNameText = ""
        if (userName != null) {
            userNameText = "$userName: "
        }

        val patternA = "⅏⦃"
        val patternB = "@jx❦⦄"
        val searchAllText = "⅏⦃0@jx❦⦄"

        if (texts == null) {
            val text = decryptedData["text"] as? String ?: return null

            var updatedText = text

            for (uid in atUsers.keys) {
                val pattern = patternA + uid + patternB  // Create the full pattern for each uid

                // Check if name exists for the uid
                val name = atUsers[uid]
                if (name != null) {
                    // Replace occurrences of the pattern in updatedText with @name
                    updatedText = updatedText.replace(pattern, "@$name")
                }
            }
            return userNameText + updatedText
        }

        when (typ) {
            2 -> {
                val result = texts["image"] as? String ?: return null
                return userNameText + result
            }

            4 -> {
                val result = texts["video"] as? String ?: return null
                return userNameText + result
            }

            24 -> {
                val result = texts["video"] as? String ?: return null
                return userNameText + result
            }

            8 -> {
                val album = texts["album"] as? String ?: return null
                val onlyVideo = texts["album_onlyVideo"] as? String ?: return null
                val onlyImage = texts["album_onlyImage"] as? String ?: return null

                val count = (decryptedData["count"] as? Double)?.toInt()
                val fType = (decryptedData["type"] as? Double)?.toInt()

                if (count != null && fType != null) {
                    var finalText = album
                    when (fType) {
                        0 -> finalText = album
                        1 -> finalText = onlyImage
                        2 -> finalText = onlyVideo
                        else -> finalText = album
                    }
                    if (fType != 0) {
                        finalText = finalText.replace("%1", count.toString())
                    }
                    return userNameText + finalText
                }

                val list = decryptedData["albumList"] as? List<Map<String, Any>> ?: return null
                var type: String? = null
                var finalText = album
                var hasDiffType = false

                for (dict in list) {
                    val t = dict["mimeType"] as? String
                    if (t != null) {
                        if (type != null && type != t) {
                            hasDiffType = true
                            break
                        }
                        type = t
                    }
                }

                if (!hasDiffType && type != null) {
                    val finalType: String = type
                    val imageString = "image"
                    finalText = if (finalType == imageString) onlyImage else onlyVideo
                    finalText = finalText.replace("%1", list.size.toString())
                }

                return userNameText + finalText
            }

            3 -> {
                val result = texts["voice"] as? String ?: return null
                return userNameText + result
            }

            6 -> {
                val icon = texts["file"] as? String ?: return null
                val fileName = decryptedData["file_name"] as? String ?: return null
                return userNameText + icon + fileName
            }

            25 -> {
                val result = texts["gif"] as? String ?: return null
                return userNameText + result
            }

            5 -> {
                val result = texts["sticker"] as? String ?: return null
                return userNameText + result
            }

            7 -> {
                val result = texts["location"] as? String ?: return null
                return userNameText + result
            }

            15 -> {
                val icon = texts["recommendFriend"] as? String ?: return null
                val nickName = decryptedData["nick_name"] as? String ?: return null
                return userNameText + icon + nickName
            }

            else -> {
                val text = decryptedData["text"] as? String ?: return null
                val allText = texts["all"] as? String ?: return null
                var updatedText = text

                if (text.contains(searchAllText)) {
                    updatedText = updatedText.replace(searchAllText, "@" + allText)
                }

                for (uid in atUsers.keys) {
                    val pattern = patternA + uid + patternB  // Create the full pattern for each uid

                    // Check if name exists for the uid
                    val name = atUsers[uid]
                    if (name != null) {
                        // Replace occurrences of the pattern in updatedText with @name
                        updatedText = updatedText.replace(pattern, "@$name")
                    }
                }


                return userNameText + updatedText
            }
        }
    }

    private fun shouldDisableNotifications(): Boolean {
        val key = "DISABLE_PUSH"
        val context: Context = this
        // Access SharedPreferences (similar to UserDefaults in iOS)
        val sharedPreferences: SharedPreferences =
            context.getSharedPreferences("notificationPreferences", Context.MODE_PRIVATE)
        return sharedPreferences.getBoolean(key, false)
    }
}