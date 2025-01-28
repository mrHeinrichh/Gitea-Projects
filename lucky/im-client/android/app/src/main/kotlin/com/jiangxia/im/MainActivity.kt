package com.luckyd.im

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioManager.OnAudioFocusChangeListener
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import androidx.lifecycle.ProcessLifecycleOwner
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.huawei.hms.aaid.HmsInstanceId
import com.luckyd.im.helpers.RTCHelper
import com.luckyd.im.helpers.ShareHelper
import com.luckyd.im.push_services.NotificationService
import com.luckyd.im.services.VoIPService
import com.luckyd.im.utils.NativeViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.*
import java.util.*


class MainActivity : FlutterActivity(), LifecycleObserver  {
    private lateinit var sensorManager: SensorManager
    private var proximitySensor: Sensor? = null
    private lateinit var sensorEventListener: SensorEventListener

    private val shareChannelKey: String = "jxim/share.extent"
    private val notificationChannel = "jxim/notification"
    private val rtcChannel = "jxim/rtc"
    private val installChannel = "jxim/install"
    private val generalChannel = "jxim/general"

    private var focusRequest: AudioFocusRequest? = null
    private lateinit var playbackAttributes: AudioAttributes
    private lateinit var audioManager: AudioManager
    private var musicVolume: Int = 0;

    var mUri: Uri? = null
    var mType: Int = 0
    private var mSourceType: String = ""

    private lateinit var powerManager: PowerManager
    private var lock: PowerManager.WakeLock? = null
    private lateinit var rtcHelper: RTCHelper

    private var floatingWindow: FloatingWindow? = null

    private val installRequestCode = 47324
    private var apkFile: File? = null
    private var installUnknownSourcePermissionAllowed: Boolean = false
    var isDestroying = false
//    private lateinit var appLifecycleObserver : AppLifecycleObserver
    companion object {
        lateinit var notificationMethodChannel: MethodChannel
        lateinit var rtcMethodChannel: MethodChannel
        lateinit var shareMethod: MethodChannel
        lateinit var installMethod: MethodChannel
        lateinit var generalMethod: MethodChannel

        var isOpen: Boolean = false
        var isAppInForground: Boolean = false

        //渠道Id
        const val CHANNEL_ID = "custom_channel"

        //渠道名
        const val CHANNEL_NAME = "JXTalk_Channel"

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannel)
        rtcMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, rtcChannel)
        shareMethod = MethodChannel(flutterEngine!!.dartExecutor, shareChannelKey)
        rtcHelper = RTCHelper(this, this.activity, rtcMethodChannel)
        installMethod = MethodChannel(flutterEngine!!.dartExecutor, installChannel)
        generalMethod = MethodChannel(flutterEngine!!.dartExecutor, generalChannel)

        // Disable the default activity transition animation
        window.enterTransition = null
        window.exitTransition = null
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "native_video_widget",
                NativeViewFactory(rtcHelper)
            )
    }

    override fun onStart() {
        super.onStart()
        for (channel in NChannel.values()) {
            createNotificationChannel(
                channel.toString(),
                channel.channelName,
                NotificationManager.IMPORTANCE_HIGH,
                channel.vibrationPattern,
                channel.soundFile
            )
        }
        createNotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH)
        createNotificationChannel(
            "call_channel", "Call Channel", NotificationManager.IMPORTANCE_HIGH,
            callVibration, R.raw.call
        )
    }

    override fun onPause() {
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
    }

    fun isPipModeOn(): Boolean {
        return floatingWindow != null
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
    fun onAppBackgrounded() {
        isAppInForground = false
        if(hasOverlayPermission() && !isDestroying){
            startVideoFloatingWindow()
        }
    }

    private fun startVideoFloatingWindow(){
        Log.v("startVideoFloatingWindow", "=======> ${rtcHelper.isCalling}, ${rtcHelper.meCameraIsOn}, ${rtcHelper.remoteCameraIsOn}")
        if (rtcHelper.isCalling) {
            if(rtcHelper.meCameraIsOn && rtcHelper.remoteCameraIsOn){
                if(rtcHelper.floatWindowIsMe){
                    rtcHelper.nativeView?.let{
                        it.showAvatarView(this, false)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }else{
                    rtcHelper.floatNativeView?.let{
                        it.showAvatarView(this, false)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }
            }else if(rtcHelper.meCameraIsOn){
                if(rtcHelper.floatWindowIsMe){
                    rtcHelper.nativeView?.let{
                        it.showAvatarView(this, true)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }else{
                    rtcHelper.floatNativeView?.let{
                        it.showAvatarView(this, true)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }
            }else if(rtcHelper.remoteCameraIsOn){
                if(rtcHelper.floatWindowIsMe){
                    rtcHelper.nativeView?.let{
                        it.showAvatarView(this, false)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }else{
                    rtcHelper.floatNativeView?.let{
                        it.showAvatarView(this, false)
                        floatingWindow = FloatingWindow(context, it.contentView)
                    }
                }
            }else{
                rtcHelper.updateVideoStream("startVideoFloatingWindow")

                rtcHelper.nativeView?.let {
                    it.showAvatarView(this, true)
                    floatingWindow = FloatingWindow(context, it.contentView)
                }
            }
        }
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    fun onAppForegrounded() {
        Log.v("onEnterForeround", "==========>")
        isAppInForground = true
        stopVideoFloatingWindow()
    }

    private fun stopVideoFloatingWindow(){
        if (floatingWindow != null) {
            rtcHelper.updateVideoStream("onResume")
            floatingWindow!!.dismiss()
            floatingWindow = null
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isDestroying = false

        // 初始化传感器管理器
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        if(proximitySensor!=null && audioManager !=null){
            sensorEventListener = object : SensorEventListener {
                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                    // Do nothing
                }

                override fun onSensorChanged(event: SensorEvent) {
                    /// 在拨打电话的铃声或者通话时不允许改变声道
                    if(rtcHelper.isAnySoundPlaying()) return

                    if (event != null) {
                        if (event.sensor.type == Sensor.TYPE_PROXIMITY) {
                            if (event.values[0] < (proximitySensor?.maximumRange ?: 0f)) {
                                // 检测到物体接近
                                audioManager.mode = AudioManager.MODE_IN_CALL
                                audioManager.isSpeakerphoneOn = false

                                Log.v("MainActivity","kkkkkk ======> 靠近");
                            } else {
                                // 检测到物体远离
                                audioManager.mode = AudioManager.MODE_NORMAL
                                audioManager.isSpeakerphoneOn = true
                                Log.v("MainActivity","kkkkkk ======> 远离");
                            }
                        }
                    }
                }
            }
        }
        sensorManager.registerListener(sensorEventListener, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL)

        handleIntent(intent)
        if (isHuaweiDevice()) {
            getToken()
        } else {
            FirebaseApp.initializeApp(this)
            FirebaseMessaging.getInstance().token.addOnCompleteListener(OnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.w("FCM Services", "Fetching FCM registration token failed", task.exception)
                    return@OnCompleteListener
                }

                // Get new FCM registration token
                val token = task.result
                val data = mutableMapOf<String, String>()

                if (token != null) {
                    data["registrationId"] = token
                    data["platform"] = "1"
                    data["source"] = "5"
                    data["voipToken"] = ""
                    notificationMethodChannel.invokeMethod("registerJPush", data)
                }

                Log.d("FCM Token :", token)
            })
        }

        val isMissedCall = intent.getBooleanExtra("is_missed_call", false)
        var notificationType = (intent.extras?.getString("notification_type")
            ?.toInt()
            ?: 0)
        Log.v("OnNotificationClick", "RecievedFromFCM===> ${intent.extras}")
        if (isMissedCall) {
            notificationType = 6
        }

        val map = hashMapOf(
            "notification_type" to notificationType,
            "chat_id" to intent.extras?.getString("chat_id")?.toInt(),
            "rtc_channel_id" to intent.extras?.getString("rtc_channel_id"),
        )

        try {
            Log.i("OnNotificationClick", "onCreate: notification is click when app is kill")

            notificationMethodChannel.invokeMethod(
                "initMessage",
                map
            )
        } catch (e: Exception) {
            Log.i("Main ActivityTAG", "onNewIntent: ${e.stackTrace}")
        }

        ProcessLifecycleOwner.get().lifecycle.addObserver(this)

        val uri: Uri? = intent.getParcelableExtra("share_uri")
        if (uri != null) {
            mUri = uri
            mType = intent.getIntExtra("share_typ", 1)
            mSourceType = intent.getStringExtra("share_source_type")!!
        }

        shareMethod.setMethodCallHandler { call, result ->
            if (call.method == "getShareFilePath") {
                val shareDataList = ShareHelper.getInstance().shareDataList
                Log.v("getShareFilePath", "==========> 1 $shareDataList")
                if(shareDataList.isNotEmpty()){
                    val resultData = mapOf("asset" to shareDataList, "chatId" to 0)
                    result.success(resultData)
                }else{
                    result.success(null)
                }
            } else if (call.method == "RecentFilePaths") {
                val dataList = recentFileList()
                result.success(dataList)
            } else if (call.method == "clearShare") {
                ShareHelper.getInstance().clear();
                Log.v("getShareFilePath", "==========> 1 ${ShareHelper.getInstance().shareDataList.isNotEmpty()}")
            }
        }
        rtcMethodChannel.setMethodCallHandler { call, result ->
            if (call.method == "setupAgoraEngine") {
                val appID = call.argument<String>("appID")
                val isVoiceCall = call.argument<Boolean>("isVoiceCall")
                val fps = call.argument<Int>("fps")
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                val isInviter = call.argument<Boolean>("isInviter") ?: false
                if (appID != null) {
                    rtcHelper.setupAgoraEngine(appID, isInviter, isVoiceCall!!,fps!!,width!!,height!!)
                }
            } else if (call.method == "joinChannel") {
                val token = call.argument<String>("token")
                val channelId = call.argument<String>("channelId")
                val uid = call.argument<Int>("uid")
                if (channelId != null) {
                    rtcHelper.joinChannel(channelId, token, uid!!)
                }
            } else if (call.method == "releaseEngine") {
                stopVoIPService()
                rtcHelper.releaseEngine()
            } else if (call.method == "toggleMic") {
                val isMute = call.argument<Boolean>("isMute")
                rtcHelper.toggleMic(isMute!!)
            } else if (call.method == "toggleSpeaker") {
                val isSpeaker = call.argument<Boolean>("isSpeaker")
                rtcHelper.toggleSpeaker(isSpeaker!!)
            } else if (call.method == "toggleFloat") {
                val isMe = call.argument<Boolean>("isMe")
                rtcHelper.toggleFloat(isMe!!)
            } else if (call.method == "muteLocalVideoStream") {
                val isCameraOn = call.argument<Boolean>("selfCameraOn")
                rtcHelper.toggleLocalCam(isCameraOn!!)
            } else if (call.method == "switchCamera") {
                rtcHelper.switchCamera()
            } else if (call.method == "requestAudioFocus") {
                val resultNum = obtainAudioFocus()
                result.success(resultNum)
            } else if (call.method == "releaseAudioFocus") {
                abandonAudioFocus()
                if (lock?.isHeld == true) lock?.release()
            } else if (call.method == "toggleProximity") {
                toggleProximity()
            } else if (call.method == "hasOverlayPermission") {
                val res = hasOverlayPermission()
                result.success(res)
            } else if (call.method == "requestOverlayPermission") {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, Activity.RESULT_OK)
            } else if (call.method == "closeFloatWindow") {
                if (floatingWindow != null) {
                    floatingWindow!!.dismiss()
                    floatingWindow = null
                }
            } else if (call.method == "startVoIPService") {
                val chatId = call.argument<String>("chatId")
                if (chatId != null) {
                    startVoIPService(chatId)
                }
            } else if (call.method == "stopVoIPService") {
                stopVoIPService()
            }
        }

        notificationMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isOpen" -> {
                    isOpen = call.argument<String>("isOpen") == "true"
                }

                "stopCall" -> {
                    val stopServiceIntent = Intent(this, NotificationService::class.java)
                    stopServiceIntent.action = "stop"
                    startService(stopServiceIntent)
                }

                "getVoipToken" -> {
                    result.success("")
                }

                "getAppState" -> {
                    result.success(isAppInForground)
                }

            }
        }

        installMethod.setMethodCallHandler { call, result ->
            if (call.method == "startInstallApk") {
                val filePath = call.argument<String>("filePath")
                Log.v("InstallApk", "filepath======> ${filePath}")
                try {
                    installApk(filePath)
                    result.success("Success")
                } catch (e: Throwable) {
                    Log.v("InstallApk", "failed======> ${e.message}")
                    result.error(e.javaClass.simpleName, e.message, null)
                }
            }
        }

        generalMethod.setMethodCallHandler { call, result ->
            if (call.method == "isBackgroundAudioPlaying") {
                val res = isBackgroundAudioPlaying()
                result.success(res)
            }

        }

        rtcHelper.preloadSound()
    }

    private fun isBackgroundAudioPlaying(): Boolean {
        return audioManager.isMusicActive
    }
    private fun isHuaweiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER
        val brand = Build.BRAND
        return manufacturer.lowercase(Locale.getDefault()).contains("huawei") || brand.lowercase(
            Locale.getDefault()
        ).contains("huawei")
    }

    private fun getToken() {
        val data = mutableMapOf<String, String>()

        object : Thread() {
            override fun run() {
                try {
                    // 从agconnect-services.json文件中读取APP_ID
                    val appId =
                        "DAEDAOI40HBeye7CtmUpZrzjUmFn4BozovVhD5WLw2cRfvE4LzZ8QT8pttT0WT2QDtgWGoGE4h1VyDk50hOYTJlxgmMJQHBJOwXLkg==";

                    // 输入token标识"HCM"
                    val tokenScope = "HCM"
                    val token =
                        HmsInstanceId.getInstance(this@MainActivity).getToken(appId, tokenScope)
                    Log.i("HMS Service ::", "get token:$token")

                    // 判断token是否为空
                    if (!TextUtils.isEmpty(token)) {
                        data["registrationId"] = token
                        data["platform"] = "1"
                        data["source"] = "6"
                        data["voipToken"] = ""

                        // Call invokeMethod on the main thread
                        runOnUiThread {
                            notificationMethodChannel.invokeMethod("registerJPush", data)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("HMS Service", "get token failed, $e")
                }
            }
        }.start()
    }

    private fun startVoIPService(chatId: String) {
        val serviceIntent = Intent(this, VoIPService::class.java)
        serviceIntent.putExtra("chatId", chatId)
        ContextCompat.startForegroundService(this, serviceIntent)
        Log.v("startVoIPService", "voip service started")
    }

    private fun stopVoIPService() {
        val serviceIntent = Intent(this, VoIPService::class.java)
        stopService(serviceIntent)
        Log.v("stopVoIPService", "voip service stopped")
    }

    private fun obtainAudioFocus(): Int {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        playbackAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
            .build()

        if (Build.VERSION.SDK_INT >= 26) {
            focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setWillPauseWhenDucked(true)
                .setOnAudioFocusChangeListener(focusChangeListener, Handler(Looper.getMainLooper()))
                .build()
            val result = audioManager.requestAudioFocus(focusRequest!!);

            when (result) {
                AudioManager.AUDIOFOCUS_REQUEST_FAILED -> {
                    Log.v("obtainAudioFocus", "AudioManager.AUDIOFOCUS_REQUEST_FAILED");
                }

                AudioManager.AUDIOFOCUS_REQUEST_GRANTED -> {
                    musicVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    if (musicVolume > 0) {
                        stopMusicVolume()
                    }
                    Log.v("obtainAudioFocus", "AudioManager.AUDIOFOCUS_REQUEST_GRANTED");
                }
            }
            return result
        } else {
            val result = audioManager.requestAudioFocus(
                focusChangeListener,  // Use the music stream.
                AudioManager.STREAM_VOICE_CALL,  // Request permanent focus.
                AudioManager.AUDIOFOCUS_GAIN
            )
            Log.v("obtainAudioFocus", "2Result======> $result");
            return result
        }
    }

    private fun stopMusicVolume() {
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
    }

    private fun resumeMusicVolume() {
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, musicVolume, 0)
    }

    private fun toggleProximity() {
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        lock = powerManager.newWakeLock(
            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
            "myapp:wakelocktag"
        )
        if (lock?.isHeld == false) lock?.acquire()
    }

    private fun abandonAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                if (focusRequest != null) {
                    audioManager.abandonAudioFocusRequest(focusRequest!!)
                }
            } else {
                audioManager.abandonAudioFocus(focusChangeListener)
            }

            Log.v("abandonAudioFocus", "Volume=======> $musicVolume")
            if (musicVolume > 0) {
                resumeMusicVolume()
            }
        } catch (e: Exception) {
            Log.i("abandonAudioFocus", "Failed: ${e.stackTrace}")
        }
    }

    private var focusChangeListener: OnAudioFocusChangeListener =
        OnAudioFocusChangeListener { focusChange ->
            when (focusChange) {
                AudioManager.AUDIOFOCUS_GAIN -> Log.v(
                    "MainActivity",
                    "AudioManager.AUDIOFOCUS_GAIN"
                )

                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> Log.v(
                    "MainActivity",
                    "AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK"
                )

                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> Log.v(
                    "MainActivity",
                    "AudioManager.AUDIOFOCUS_LOSS_TRANSIENT"
                )

                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> Log.v(
                    "MainActivity",
                    "AudioManager.AUDIOFOCUS_LOSS_TRANSIENT"
                )

                AudioManager.AUDIOFOCUS_LOSS -> Log.v(
                    "MainActivity",
                    "AudioManager.AUDIOFOCUS_LOSS"
                )
            }
        }

    private fun recentFileList(): List<Map<String, String>> {
        var dataList: List<Map<String, String>> = mutableListOf()

        val internalUri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projections = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.RELATIVE_PATH,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.SIZE
        )

        val sortOrder = MediaStore.Files.FileColumns.DATE_ADDED + " DESC";
        context.contentResolver.query(internalUri, projections, null, null, sortOrder)
            .use { cursor ->
                if (cursor != null && cursor.count > 0) {
                    val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                    val dateAddedIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
                    val displayNameIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                    val pathIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
                    val typeIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
                    val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)

                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(idIndex)
                        val dateAdded = cursor.getLong(dateAddedIndex)
                        val displayName = cursor.getString(displayNameIndex)
                        val path = "${Environment.getExternalStorageDirectory()}/${
                            cursor.getString(pathIndex)
                        }/$displayName"
                        val type = cursor.getString(typeIndex)
                        val size = cursor.getLong(sizeIndex)

                        val fileData = mapOf(
                            "dateAdded" to "$dateAdded",
                            "name" to displayName,
                            "path" to path,
                            "type" to type,
                            "size" to "$size"
                        )
                        dataList += fileData
                        Log.d("RecentFile======> ", "$dateAdded, $displayName, $path, $type")
                    }
                } else if (cursor == null)
                    Log.d("RecentFile", "cursor is nUll")
                else
                    Log.d("RecentFile", "Cursor count is ${cursor.count}")
            }
        return dataList
    }
    @RequiresApi(Build.VERSION_CODES.O)
    private fun handleIntent(intent: Intent) {
        if (Intent.ACTION_SEND == intent.action || Intent.ACTION_SEND_MULTIPLE == intent.action) {
            ShareHelper.getInstance().handleIntent(intent,activity)
            if (intent.flags != (Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)) {
                Log.v("handleIntent","finish")
                val newIntent = Intent(this, MainActivity::class.java)
                newIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                newIntent.putExtras(intent)
                Log.v("handleIntent","intent ${intent.extras}")
                startActivity(newIntent)
                finish()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // in app receive intent
        ShareHelper.getInstance().handleIntent(intent,activity)
        Log.i(
            "OnNotificationClick",
            "onNewIntent: notification is click Transaction:${intent.extras?.getString("transaction_id")}"
        )
        val isMissedCall = intent.getBooleanExtra("is_missed_call", false)
        var notificationType = (intent.extras?.getString("notification_type")
            ?.toInt()
            ?: 0)
        if (isMissedCall) {
            notificationType = 6
        }

        val map = hashMapOf(
            "notification_type" to notificationType,
            "chat_id" to intent.extras?.getString("chat_id")?.toInt(),
            "transaction_id" to intent.extras?.getString("transaction_id"),
            "rtc_channel_id" to intent.extras?.getString("rtc_channel_id"),
        )

        try {
            Log.i("OnNotificationClick", "onNewIntent: notification is click")

            notificationMethodChannel.invokeMethod(
                "notificationRouting",
                map
            )
        } catch (e: Exception) {
            Log.i("Main ActivityTAG", "onNewIntent: ${e.stackTrace}")
        }


        setIntent(intent)
        val uri: Uri? = intent.getParcelableExtra("share_uri")
        if (uri != null) {
            mUri = uri
            mType = intent.getIntExtra("share_typ", 1)
            mSourceType = intent.getStringExtra("share_source_type")!!
        }
    }

    private fun getDataFromUri(uri: Uri, result: MethodChannel.Result) {
        val parcelFile: InputStream? = contentResolver.openInputStream(uri)
        if (parcelFile != null) {
            val bytes: ByteArray = parcelFile.readBytes()
            var path: String = getExternalFilesDir(null)!!.path + "/" + System.currentTimeMillis()
            if (mSourceType == "video") {
                path += ".mp4"
            } else if (mSourceType == "image") {
                path += ".png"
            } else {
                path += "." + intent.getStringExtra("suffix")!!
            }
            val realFile: File? = fileToBytes(bytes, path)
            if (realFile != null) {
                if (mSourceType == "video") {
                    val mMMR = MediaMetadataRetriever()
                    mMMR.setDataSource(context, Uri.fromFile(realFile))
                    val bmp = mMMR.frameAtTime
                    if (bmp != null) {
                        val byteArrayOutputStream = ByteArrayOutputStream()
                        bmp.compress(Bitmap.CompressFormat.JPEG, 10, byteArrayOutputStream)
                        val cupBytes: ByteArray = byteArrayOutputStream.toByteArray()
                        result.success(
                            mapOf(
                                "video_to_path" to realFile.path,
                                "type" to mType,
                                "width" to bmp.width,
                                "height" to bmp.height,
                                "image" to cupBytes
                            )
                        )
                    }

                } else if (mSourceType == "image") {
                    val bmp = BitmapFactory.decodeFile(path)
                    if (bmp != null) {
                        result.success(
                            mapOf(
                                "image_to_path" to realFile.path,
                                "type" to mType,
                                "width" to bmp.width,
                                "height" to bmp.height
                            )
                        )
                    }
                } else {
                    result.success(
                        mapOf(
                            "file_to_path" to realFile.path,
                            "type" to mType,
                            "file_name" to intent.getStringExtra("file_name")!!,
                            "suffix" to intent.getStringExtra("suffix")!!,
                            "length" to realFile.length(),
                        )
                    )
                }
            }
        }
    }

    private fun fileToBytes(bytes: ByteArray, filePath: String): File? {
        var bos: BufferedOutputStream? = null
        var fos: FileOutputStream? = null
        var file: File? = null

        try {
            file = File(filePath)
            if (!file.parentFile!!.exists()) {
                file.parentFile!!.mkdirs()
            }
            fos = FileOutputStream(file)
            bos = BufferedOutputStream(fos)
            bos.write(bytes)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            if (bos != null) {
                try {
                    bos.close()
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
            if (fos != null) {
                try {
                    fos.close()
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
        }
        return file
    }

    private fun createNotificationChannel(
        channelId: String,
        channelName: String,
        importance: Int,
        vibrationPattern: LongArray? = null,
        soundFile: Int? = null
    ) {
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, importance)
            if (vibrationPattern != null) {
                channel.vibrationPattern = vibrationPattern
            }

            if (soundFile != null) {
                channel.setSound(
                    Uri.parse("android.resource://$packageName/$soundFile"),
                    audioAttributes
                )
            } else if (soundFile == 9999) {
            } else {
                channel.setSound(null, null)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun hasOverlayPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.canDrawOverlays(context)
        }
        // For versions below Android M, overlay permission is granted by default
        return true
    }

    private fun installApk(filePath: String?) {
        if (filePath == null) throw NullPointerException("fillPath is null!")

        val file = File(filePath)
        Log.v("InstallApk", "fileExist======> ${file.exists()}")
        if (!file.exists()) throw FileNotFoundException("$filePath is not exist! or check permission")
        apkFile = file
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
            install24(file)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (canRequestPackageInstalls()) {
                install24(file)
            } else {
                showSettingPackageInstall()
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            install24(file)
        } else {
            installBelow24(file)
        }
    }

    private fun showSettingPackageInstall() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("SettingPackageInstall", ">= Build.VERSION_CODES.O")
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:" + this.packageName)
            startActivityForResult(intent, installRequestCode)
        } else {
            throw RuntimeException("VERSION.SDK_INT < O")
        }

    }

    private fun canRequestPackageInstalls(): Boolean {
        return Build.VERSION.SDK_INT <= Build.VERSION_CODES.O || this.packageManager.canRequestPackageInstalls()
    }

    private fun install24(file: File?) {
        if (file == null) throw NullPointerException("file is null!")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            installUnknownSourcePermissionAllowed = Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.INSTALL_NON_MARKET_APPS
            ) == 1

            val intent = Intent(Intent.ACTION_VIEW)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val uri: Uri = FileProvider.getUriForFile(this, "${this.packageName}.fileProvider.install", file)
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            startActivityForResult(intent, 333)
        } else {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val uri: Uri =
                FileProvider.getUriForFile(this, "${this.packageName}.installFileProvider.install", file)
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            startActivityForResult(intent, 111)
        }

        Log.v("InstallApk", "fileExistInstalling======> ${this.packageName}")
    }

    private fun installBelow24(file: File?) {
        installUnknownSourcePermissionAllowed = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.INSTALL_NON_MARKET_APPS
        ) == 1

        val intent = Intent(Intent.ACTION_VIEW)
        intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
        intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        val uri = Uri.fromFile(file)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        startActivityForResult(intent, 333)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.v("InstallApk", "onActivityResult======> ${requestCode} | ${resultCode}")
        when (requestCode) {
            installRequestCode -> {
                if (resultCode == RESULT_OK) {
                    installApk(apkFile.toString())
                }
            }
            111 -> {
                if (resultCode == RESULT_OK) {
                    installApk(apkFile.toString())
                }
            }
            333 -> {
                if (installUnknownSourcePermissionAllowed) {
                    if (resultCode == RESULT_OK) {
                        installApk(apkFile.toString())
                    }
                } else {
                    val isNonPlayAppAllowed = Settings.Secure.getInt(
                        contentResolver, Settings.Secure.INSTALL_NON_MARKET_APPS
                    ) == 1
                    if (isNonPlayAppAllowed) {
                        installApk(apkFile.toString())
                    }
                }
            }
        }
    }


    override fun onDestroy() {
        // 注销传感器监听器
        sensorManager.unregisterListener(sensorEventListener)
        isDestroying = true
        if(rtcHelper != null){
            rtcHelper.onDestroy()
        }
        abandonAudioFocus()
        stopVoIPService()
        stopVideoFloatingWindow()
        super.onDestroy()
    }
}

val callVibration = longArrayOf(
    500, 1000, 500, 1000, 500, 1000,
    500, 1000, 500, 1000, 500, 1000,
    500, 1000, 500, 1000, 500, 1000,
    500, 1000, 500, 1000, 500, 1000,
    500, 1000, 500, 1000, 500, 1000,
    500, 1000, 500, 1000
)

enum class NChannel(
    val channelName: String = "",
    val vibrationPattern: LongArray? = null,
    val soundFile: Int? = null
) {
    DEFAULT_CALL("Default Call", callVibration, R.raw.call),
    SILENCE_CALL("Silence Call"),
    VIBRATE_CALL("Vibrate Call", callVibration),
    SOUND_CALL("Sound Call", null, R.raw.call),
    DEFAULT_NOTIFICATION("Default Notification", longArrayOf(300, 500), 9999),
    SILENCE_NOTIFICATION("Silence Notification"),
    VIBRATE_NOTIFICATION("Vibrate Notification", longArrayOf(300, 500)),
    SOUND_NOTIFICATION("Sound Notification", null, 9999),

}