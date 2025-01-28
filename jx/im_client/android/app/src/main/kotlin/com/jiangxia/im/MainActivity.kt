package com.jiangxia.im

import android.Manifest
import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioManager
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
import androidx.core.app.ActivityCompat
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
import com.jiangxia.im.helpers.RTCHelper
import com.jiangxia.im.helpers.ShareHelper
import com.jiangxia.im.helpers.SoundHelper
import com.jiangxia.im.push_services.NotificationService
import com.jiangxia.im.services.VoIPService
import com.jiangxia.im.utils.NativeViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.sentry.Hint
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryLevel
import io.sentry.SentryOptions
import io.sentry.android.core.SentryAndroid
import java.io.File
import java.io.FileNotFoundException
import java.util.Locale

class MainActivity : FlutterActivity(), LifecycleObserver, BatteryLevelListener, BluetoothListener {

    private val REQUEST_CODE_POST_NOTIFICATIONS = 1
    private val REQUEST_CODE_BLUETOOTH_ACCESS = 1432

    private val shareChannelKey: String = "jxim/share.extent"
    private val notificationChannel = "jxim/notification"
    private val rtcChannel = "jxim/rtc"
    private val installChannel = "jxim/install"
    private val generalChannel = "jxim/general"
    private val batteryChannel = "jxim/battery"

    private lateinit var audioManager: AudioManager

    var mUri: Uri? = null
    var mType: Int = 0
    private var mSourceType: String = ""

    private lateinit var powerManager: PowerManager
    private var lock: PowerManager.WakeLock? = null
    private lateinit var rtcHelper: RTCHelper
    private var soundHelper: SoundHelper? = null

    private var floatingWindow: FloatingWindow? = null

    private val installRequestCode = 47324
    private var apkFile: File? = null
    private var installUnknownSourcePermissionAllowed: Boolean = false
    var isDestroying = false
    private var voipServiceStarted = false

    private lateinit var bluetoothReceiver: BluetoothReceiver
    private lateinit var batteryLevelReceiver: BatteryLevelReceiver

    companion object {
        lateinit var notificationMethodChannel: MethodChannel
        lateinit var rtcMethodChannel: MethodChannel
        lateinit var shareMethod: MethodChannel
        lateinit var installMethod: MethodChannel
        lateinit var generalMethod: MethodChannel
        lateinit var batteryMethod: MethodChannel

        var isOpen: Boolean = false
        var isAppInForground: Boolean = false

        // 渠道Id
        const val CHANNEL_ID = "custom_channel"

        // 渠道名
        const val CHANNEL_NAME = "JXTalk_Channel"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationMethodChannel =
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannel)
        rtcMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, rtcChannel)
        shareMethod = MethodChannel(flutterEngine.dartExecutor, shareChannelKey)
        rtcHelper = RTCHelper(this, this.activity, rtcMethodChannel)
        soundHelper = SoundHelper(this.activity)
        installMethod = MethodChannel(flutterEngine.dartExecutor, installChannel)
        generalMethod = MethodChannel(flutterEngine.dartExecutor, generalChannel)
        batteryMethod = MethodChannel(flutterEngine.dartExecutor, batteryChannel)

        // Disable the default activity transition animation
        window.enterTransition = null
        window.exitTransition = null
        flutterEngine.platformViewsController.registry.registerViewFactory(
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
                "phonecall_channel",
                "Phone Call Channel",
                NotificationManager.IMPORTANCE_MAX,
                callVibration
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
        if (hasOverlayPermission() && !isDestroying) {
            startVideoFloatingWindow()
        }
    }

    private fun startVideoFloatingWindow() {
        if (rtcHelper.isCalling) {
            if (rtcHelper.isUserJoined()) {
                Log.v(
                        "MainActivity",
                        "startVideoFloatingWindow===> ${rtcHelper.floatWindowIsMe}, ${rtcHelper.meCameraIsOn}, ${rtcHelper.remoteCameraIsOn}, ${rtcHelper.remoteCameraIsFreezed}"
                )
                if (rtcHelper.meCameraIsOn && rtcHelper.remoteCameraIsOn) {
                    if (rtcHelper.floatWindowIsMe) {
                        rtcHelper.nativeView?.let {
                            it.showAvatarView(this, rtcHelper.remoteCameraIsFreezed)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    } else {
                        rtcHelper.floatNativeView?.let {
                            it.showAvatarView(this, rtcHelper.remoteCameraIsFreezed)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    }
                } else if (rtcHelper.meCameraIsOn) {
                    if (rtcHelper.floatWindowIsMe) {
                        rtcHelper.nativeView?.let {
                            it.showAvatarView(this, true)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    } else {
                        rtcHelper.floatNativeView?.let {
                            it.showAvatarView(this, true)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    }
                } else if (rtcHelper.remoteCameraIsOn) {
                    if (rtcHelper.floatWindowIsMe) {
                        rtcHelper.nativeView?.let {
                            it.showAvatarView(this, rtcHelper.remoteCameraIsFreezed)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    } else {
                        rtcHelper.floatNativeView?.let {
                            it.showAvatarView(this, rtcHelper.remoteCameraIsFreezed)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    }
                } else {
                    Log.v(
                            "MainActivity",
                            "updateCallingView===>1 ${rtcHelper.floatWindowIsMe}, ${rtcHelper.floatNativeView}"
                    )
                    rtcHelper.agoraEngine?.setupRemoteVideo(null)
                    rtcHelper.agoraEngine?.setupLocalVideo(null)
                    rtcHelper.updateCallingView()
                    if (rtcHelper.floatWindowIsMe) {
                        rtcHelper.nativeView?.let {
                            it.showAvatarView(this, true)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    } else {
                        rtcHelper.floatNativeView?.let {
                            it.showAvatarView(this, true)
                            floatingWindow = FloatingWindow(context, it.contentView)
                        }
                    }
                }
            } else {
                Log.v("MainActivity", "updateCallingView===>2 ${rtcHelper.floatWindowIsMe}")
                rtcHelper.agoraEngine?.setupLocalVideo(null)
                rtcHelper.agoraEngine?.setupRemoteVideo(null)
                rtcHelper.updateCallingView()
                //                if(rtcHelper.floatWindowIsMe){
                rtcHelper.nativeView?.let {
                    it.showAvatarView(this, true)
                    floatingWindow = FloatingWindow(context, it.contentView)
                }
                //                }else{
                //                    rtcHelper.floatNativeView?.let {
                //                        it.showAvatarView(this, true)
                //                        floatingWindow = FloatingWindow(context, it.contentView)
                //                    }
                //                }
            }
        }
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    fun onAppForegrounded() {
        isAppInForground = true
        stopVideoFloatingWindow()
    }

    private fun stopVideoFloatingWindow() {
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

        initSentry()

        soundHelper?.preloadSounds()
        setupAudioManager()
        handleIntent(intent)

        val isMissedCall = intent.getBooleanExtra("is_missed_call", false)
        var notificationType = (intent.extras?.getString("notification_type")?.toInt() ?: 0)
        Log.v("OnNotificationClick", "RecievedFromFCM===> ${intent.extras}")
        if (isMissedCall) {
            notificationType = 6
        }

        val map =
                hashMapOf(
                        "notification_type" to notificationType,
                        "chat_id" to intent.extras?.getString("chat_id")?.toInt(),
                        "rtc_channel_id" to intent.extras?.getString("rtc_channel_id"),
                )

        try {
            Log.i("OnNotificationClick", "onCreate: notification is click when app is kill")

            notificationMethodChannel.invokeMethod("initMessage", map)
        } catch (e: Exception) {
            Sentry.captureException(e)
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
                if (shareDataList.isNotEmpty()) {
                    val resultData = mapOf("asset" to shareDataList, "chatId" to 0)
                    result.success(resultData)
                } else {
                    result.success(null)
                }
            } else if (call.method == "RecentFilePaths") {
                val dataList = recentFileList()
                result.success(dataList)
            } else if (call.method == "clearShare") {
                ShareHelper.getInstance().clear()
            }
        }
        rtcMethodChannel.setMethodCallHandler { call, result ->
            if (call.method == "setupAgoraEngine") {
                val appID = call.argument<String>("appID")
                val isVoiceCall = call.argument<Boolean>("isVoiceCall") ?: true
                val fps = call.argument<Int>("fps")
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                val isInviter = call.argument<Boolean>("isInviter") ?: false
                if (appID != null) {
                    if (!isInviter) {
                        if (isVoiceCall) {
                            setAudioToEarpiece()
                        } else {
                            setAudioToSpeaker()
                        }
                    }

                    rtcHelper.setupAgoraEngine(
                            appID,
                            isInviter,
                            isVoiceCall,
                            fps!!,
                            width!!,
                            height!!
                    )
                }
            } else if (call.method == "joinChannel") {
                val token = call.argument<String>("token")
                val channelId = call.argument<String>("channelId")
                val uid = call.argument<Int>("uid") ?: -1
                val encryptKey = call.argument<String>("encryptKey")
                if (channelId != null) {
                    rtcHelper.joinChannel(channelId, token, uid, encryptKey)
                }
            } else if (call.method == "releaseEngine") {
                stopVoIPService()
                //                setAudioToEarpiece()
                rtcHelper.releaseEngine()
            } else if (call.method == "toggleMic") {
                val isMute = call.argument<Boolean>("isMute") ?: true
                rtcHelper.toggleMic(isMute)
            } else if (call.method == "toggleAudioRoute") {
                val device = call.argument<String>("device") ?: ""
                if (device == "speaker") {
                    setAudioToSpeaker()
                } else if (device == "bluetooth") {
                    setAudioToBluetooth()
                } else {
                    setAudioToEarpiece()
                }
                result.success(true)
            } else if (call.method == "toggleFloat") {
                val isMe = call.argument<Boolean>("isMe")
                rtcHelper.toggleFloat(isMe!!)
            } else if (call.method == "muteLocalVideoStream") {
                val isCameraOn = call.argument<Boolean>("selfCameraOn")
                rtcHelper.toggleLocalCam(isCameraOn!!)
            } else if (call.method == "switchCamera") {
                rtcHelper.switchCamera()
            } else if (call.method == "toggleProximity") {
                val enable = call.argument<Boolean>("enable") ?: false
                if (enable) {
                    enableProximity()
                } else {
                    disableProximity()
                }
            } else if (call.method == "callViewDismiss") {
                val isMinimized = call.argument<Boolean>("isExit") ?: false
                rtcHelper.onMinimized(isMinimized)
            } else if (call.method == "hasOverlayPermission") {
                val res = hasOverlayPermission()
                result.success(res)
            } else if (call.method == "requestOverlayPermission") {
                val intent =
                        Intent(
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
            } else if (call.method == "enableAgoraAudio") {
                rtcHelper.openSoundPermission(null)
            } else if (call.method == "playRingSound") {
                if (!NotificationService.isServiceRunning && isAppInForground) {
                    soundHelper?.playRing()
                }
            } else if (call.method == "NotificationServiceRunning") {
                result.success(NotificationService.isServiceRunning)
            } else if (call.method == "stopRingSound") {
                soundHelper?.stopRing()
            } else if (call.method == "stopDialingSound") {
                rtcHelper.stopDialing()
            } else if (call.method == "playDialingSound") {
                if (getCurBluetoothDevices().isNotEmpty()) {
                    setAudioToBluetooth()
                } else if (!rtcHelper.isVideoCalling) {
                    setAudioToEarpiece()
                } else {
                    setAudioToSpeaker()
                }
                rtcHelper.playDialing()
            } else if (call.method == "playPickedSound") {
                rtcHelper.playPicked()
                //                result.success(true)
            } else if (call.method == "playEndSound") {
                // 延迟一段时间，因为agoraEngine释放资源导致声音变大一下
                Handler(Looper.getMainLooper()).postDelayed({ rtcHelper.playEndSound() }, 50)
                result.success(true)
            } else if (call.method == "playEnd2Sound") {
                rtcHelper.playEnd2Sound()
                result.success(true)
            } else if (call.method == "playBusySound") {
                rtcHelper.playBusy()
                result.success(true)
            } else if (call.method == "isDeviceLocked") {
                var isLocked = isDeviceLocked()
                result.success(isLocked)
            } else if (call.method == "curBlueDevices") {
                result.success(getCurBluetoothDevices())
            } else if (call.method == "getAndroidVersion") {
                result.success(Build.VERSION.SDK_INT)
            } else if (call.method == "getAndroidTargetVersion") {
                result.success(getApplicationContext().getApplicationInfo().targetSdkVersion)
            } else if (call.method == "resetNativeView") {
                rtcHelper?.resetNativeViews()
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

                    soundHelper?.stopRing()
                }
                "getVoipToken" -> {
                    result.success("")
                }
                "getAppState" -> {
                    result.success(isAppInForground)
                }
                "updateBadgeNumber" -> {
                    if (call.arguments is Int) {
                        val number = call.arguments as Int
                        NotificationService.setBadgeToAppIcon(number)
                    }
                }

                "enablePush" -> {
                    enablePush()
                    result.success(true)
                }

                "disablePush" -> {
                    disablePush()
                    result.success(true)
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
                    Sentry.captureException(e)
                    Log.v("InstallApk", "failed======> ${e.message}")
                    result.error(e.javaClass.simpleName, e.message, null)
                }
            }
        }

        generalMethod.setMethodCallHandler { call, result ->
            if (call.method == "isBackgroundAudioPlaying") {
                val res = isBackgroundAudioPlaying()
                result.success(res)
            } else if (call.method == "isMicrophoneInUse") {
                result.success(isMicrophoneInUse())
            }
        }

        rtcHelper.preloadSound()

        setupFirebasePush()
        requestNotificationPermission()

        // 电池电量监听
        batteryLevelReceiver = BatteryLevelReceiver()
        batteryLevelReceiver.setBatteryLevelListener(this)
        registerReceiver(batteryLevelReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

        // 蓝牙监听
        bluetoothReceiver = BluetoothReceiver()
        bluetoothReceiver.setBluetoothListener(this)
        val filter =
                IntentFilter().apply {
                    addAction(BluetoothDevice.ACTION_ACL_CONNECTED) // Device connected
                    addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED) // Device disconnected
                    addAction(BluetoothAdapter.ACTION_STATE_CHANGED) // Bluetooth state changed
                }
        registerReceiver(bluetoothReceiver, filter)

        val bleDevices: List<String> = getBlueDeviceBySystem()
        Log.v("MainActivity", "blueDevices======> ${bleDevices}")
        bluetoothReceiver.setInitCachedDevices(bleDevices)
    }

    fun isMicrophoneInUse(): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val modes =
                arrayOf(
                        AudioManager.MODE_IN_CALL,
                        AudioManager.MODE_IN_COMMUNICATION,
                        AudioManager.MODE_RINGTONE
                )
        for (mode in modes) {
            if (audioManager.mode == mode) {
                return true
            }
        }
        return false
    }

    private fun initSentry() {
        SentryAndroid.init(this) { options ->
            val dsn = "http://d4e8216b0eeb4920927716f54139d19d@sentry.uutalk.io:9000/7"
            options.dsn = dsn
            options.tracesSampleRate = 1.0
            options.environment = packageName
            options.profilesSampleRate = 0.5
            options.beforeSend =
                    SentryOptions.BeforeSendCallback { event: SentryEvent, hint: Hint ->
                        Log.v(
                                "getBlueDeviceBySystem",
                                "Sentry Exception 11111===> ${event.message}"
                        )
                        if (SentryLevel.DEBUG == event.level) {
                            null
                        } else {
                            event
                        }
                    }
        }
    }

    private fun getCurBluetoothDevices(): List<String> {
        try {
            if (bluetoothReceiver != null) {
                Log.v(
                        "curAvailableDevice",
                        "getCurBluetoothDevices===>2: ${bluetoothReceiver.getAvailableBluetooth()}"
                )
                return bluetoothReceiver.getAvailableBluetooth()
            } else {
                return getBlueDeviceBySystem()
            }
        } catch (e: Throwable) {
            Log.v("getBlueDeviceBySystem", "curBlueTooth failed===> ${e.message}")
        }
        return listOf()
    }

    private fun getBlueDeviceBySystem(): List<String> {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val connectedDevices =
                    devices
                            .filter {
                                (it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                                        it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP) &&
                                        it.productName != Build.MODEL
                            }
                            .toSet()
            if (connectedDevices.isNotEmpty()) {
                val list = connectedDevices.map { it.productName.toString() }.toList()
                return list.distinct()
            }
        } catch (e: Throwable) {
            Sentry.captureException(e)
            throw e
        }
        return listOf()
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        REQUEST_CODE_POST_NOTIFICATIONS
                )
            }
        }
    }

    private fun setupFirebasePush() {
        Log.v("MainActivity", "setupFirebasePush========> granted")
        if (isHuaweiDevice()) {
            getToken()
        } else {
            FirebaseApp.initializeApp(this)
            FirebaseMessaging.getInstance()
                    .token
                    .addOnCompleteListener(
                            OnCompleteListener { task ->
                                if (!task.isSuccessful) {
                                    Log.w(
                                            "FCM Services",
                                            "Fetching FCM registration token failed",
                                            task.exception
                                    )
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

                                Log.v("FCMService:", "FCM Token: $token")
                            }
                    )
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.S)
    fun setCommunicationDevice(targetDeviceType: Int) {
        audioManager.availableCommunicationDevices
                .firstOrNull { it.type == targetDeviceType }
                ?.let {
                    val result = audioManager.setCommunicationDevice(it)
                    Log.v("setCommunicationDevice: ", result.toString())
                }
    }

    private fun setupAudioManager() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        //        audioManager.isBluetoothScoOn = true
    }

    fun setAudioToSpeaker() {
        Log.v("MainActivity", "ChangeAudioRoute======> Speaker")
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isBluetoothScoOn = false
        audioManager.stopBluetoothSco()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            setCommunicationDevice(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER)
        } else {
            audioManager.isSpeakerphoneOn = true
        }
    }

    fun setAudioToEarpiece() {
        Log.v("MainActivity", "ChangeAudioRoute======> Earpiece")
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isBluetoothA2dpOn = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            setCommunicationDevice(AudioDeviceInfo.TYPE_BUILTIN_EARPIECE)
        } else {
            audioManager.isSpeakerphoneOn = false
        }
    }

    fun setAudioToBluetooth(): Boolean {
        val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter?.isEnabled == true) {
            if (audioManager.isBluetoothScoAvailableOffCall) {
                Log.v("MainActivity", "ChangeAudioRoute======> Bluetooth")
                audioManager.isSpeakerphoneOn = false
                audioManager.startBluetoothSco()
                audioManager.isBluetoothScoOn = true
                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setCommunicationDevice(AudioDeviceInfo.TYPE_BLUETOOTH_SCO)
                }
                return true
            } else {
                Log.d("Bluetooth", "Bluetooth SCO is not available.")
                return false
            }
        }
        return false
    }

    private fun isBackgroundAudioPlaying(): Boolean {
        return audioManager.isMusicActive
    }

    private fun isDeviceLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    private fun isHuaweiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER
        val brand = Build.BRAND
        return manufacturer.lowercase(Locale.getDefault()).contains("huawei") ||
                brand.lowercase(Locale.getDefault()).contains("huawei")
    }

    private fun getToken() {
        val data = mutableMapOf<String, String>()

        object : Thread() {
                    override fun run() {
                        try {
                            // 从agconnect-services.json文件中读取APP_ID
                            val appId: String = getString(R.string.hcm_key)
                            // 输入token标识"HCM"
                            val tokenScope = "HCM"
                            val token =
                                    HmsInstanceId.getInstance(this@MainActivity)
                                            .getToken(appId, tokenScope)
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
                            Sentry.captureException(e)
                            Log.e("HMS Service", "get token failed, $e")
                        }
                    }
                }
                .start()
    }

    private fun startVoIPService(chatId: String) {
        Log.v("startVoIPService", "voip service started ${voipServiceStarted}")
        if (!voipServiceStarted) {
            val serviceIntent = Intent(this, VoIPService::class.java)
            serviceIntent.putExtra("chatId", chatId)
            ContextCompat.startForegroundService(this, serviceIntent)
            voipServiceStarted = true
        }
    }

    private fun stopVoIPService() {
        Log.v("stopVoIPService", "voip service stopped ${voipServiceStarted}")
        val serviceIntent = Intent(this, VoIPService::class.java)
        if (voipServiceStarted) {
            stopService(serviceIntent)
            voipServiceStarted = false
        }
    }

    private fun enableProximity() {
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        lock =
                powerManager.newWakeLock(
                        PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                        "myapp:wakelocktag"
                )
        if (lock?.isHeld == false) lock?.acquire()
    }

    private fun disableProximity() {
        if (lock?.isHeld == true) lock?.release()
    }

    override fun batteryLevelChanged(level: Int) {
        batteryMethod.invokeMethod("batteryLevel", mapOf("level" to level))
    }

    override fun bluetoothChanged(data: Map<String, Any>) {
        if (data != null) {
            rtcMethodChannel.invokeMethod("callRouteChange", data)
        }
    }

    private fun recentFileList(): List<Map<String, String>> {
        var dataList: List<Map<String, String>> = mutableListOf()

        val internalUri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projections =
                arrayOf(
                        MediaStore.Files.FileColumns._ID,
                        MediaStore.Files.FileColumns.DATE_ADDED,
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        MediaStore.Files.FileColumns.RELATIVE_PATH,
                        MediaStore.Files.FileColumns.MIME_TYPE,
                        MediaStore.Files.FileColumns.SIZE
                )

        val sortOrder = MediaStore.Files.FileColumns.DATE_ADDED + " DESC"
        context.contentResolver.query(internalUri, projections, null, null, sortOrder).use { cursor
            ->
            if (cursor != null && cursor.count > 0) {
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val dateAddedIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
                val displayNameIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val pathIndex =
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
                val typeIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idIndex)
                    val dateAdded = cursor.getLong(dateAddedIndex)
                    val displayName = cursor.getString(displayNameIndex)
                    val path =
                            "${Environment.getExternalStorageDirectory()}/${
                            cursor.getString(pathIndex)
                        }/$displayName"
                    val type = cursor.getString(typeIndex)
                    val size = cursor.getLong(sizeIndex)

                    val fileData =
                            mapOf(
                                    "dateAdded" to "$dateAdded",
                                    "name" to displayName,
                                    "path" to path,
                                    "type" to type,
                                    "size" to "$size"
                            )
                    dataList += fileData
                    Log.d("RecentFile======> ", "$dateAdded, $displayName, $path, $type")
                }
            } else if (cursor == null) Log.d("RecentFile", "cursor is nUll")
            else Log.d("RecentFile", "Cursor count is ${cursor.count}")
        }
        return dataList
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun handleIntent(intent: Intent) {
        if (Intent.ACTION_SEND == intent.action || Intent.ACTION_SEND_MULTIPLE == intent.action) {
            ShareHelper.getInstance().handleIntent(intent, activity)
            if (intent.flags != (Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            ) {
                Log.v("handleIntent", "finish")
                val newIntent = Intent(this, MainActivity::class.java)
                newIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                newIntent.putExtras(intent)
                Log.v("handleIntent", "intent ${intent.extras}")
                startActivity(newIntent)
                finish()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // in app receive intent
        ShareHelper.getInstance().handleIntent(intent, activity)
        Log.i(
                "OnNotificationClick",
                "onNewIntent: notification is click Transaction:${intent.extras?.getString("transaction_id")}"
        )
        val isMissedCall = intent.getBooleanExtra("is_missed_call", false)
        var notificationType = (intent.extras?.getString("notification_type")?.toInt() ?: 0)
        if (isMissedCall) {
            notificationType = 6
        }

        val map =
                hashMapOf(
                        "notification_type" to notificationType,
                        "chat_id" to intent.extras?.getString("chat_id")?.toInt(),
                        "transaction_id" to intent.extras?.getString("transaction_id"),
                        "rtc_channel_id" to intent.extras?.getString("rtc_channel_id"),
                )

        try {
            Log.i("OnNotificationClick", "onNewIntent: notification is click")

            notificationMethodChannel.invokeMethod("notificationRouting", map)
        } catch (e: Exception) {
            Sentry.captureException(e)
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

    private fun createNotificationChannel(
            channelId: String,
            channelName: String,
            importance: Int,
            vibrationPattern: LongArray? = null,
            soundFile: Int? = null
    ) {
        val audioAttributes =
                AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
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
            } else if (soundFile == 9999) {} else {
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
        if (!file.exists())
                throw FileNotFoundException("$filePath is not exist! or check permission")
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
        return Build.VERSION.SDK_INT <= Build.VERSION_CODES.O ||
                this.packageManager.canRequestPackageInstalls()
    }

    private fun install24(file: File?) {
        if (file == null) throw NullPointerException("file is null!")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            installUnknownSourcePermissionAllowed =
                    Settings.Secure.getInt(
                            contentResolver,
                            Settings.Secure.INSTALL_NON_MARKET_APPS
                    ) == 1

            val intent = Intent(Intent.ACTION_VIEW)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val uri: Uri =
                    FileProvider.getUriForFile(
                            this,
                            "${this.packageName}.fileProvider.install",
                            file
                    )
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            startActivityForResult(intent, 333)
        } else {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val uri: Uri =
                    FileProvider.getUriForFile(
                            this,
                            "${this.packageName}.installFileProvider.install",
                            file
                    )
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            startActivityForResult(intent, 111)
        }

        Log.v("InstallApk", "fileExistInstalling======> ${this.packageName}")
    }

    private fun installBelow24(file: File?) {
        installUnknownSourcePermissionAllowed =
                Settings.Secure.getInt(contentResolver, Settings.Secure.INSTALL_NON_MARKET_APPS) ==
                        1

        val intent = Intent(Intent.ACTION_VIEW)
        intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
        intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        val uri = Uri.fromFile(file)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        startActivityForResult(intent, 333)
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_POST_NOTIFICATIONS) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {}
        } else if (requestCode == REQUEST_CODE_BLUETOOTH_ACCESS) {
            val isGranted: Boolean =
                    grantResults.isNotEmpty() &&
                            grantResults[0] == PackageManager.PERMISSION_GRANTED
            val map = mapOf("isGranted" to isGranted)
            rtcMethodChannel.invokeMethod("bluetoothPermission", map)
        }
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
                    val isNonPlayAppAllowed =
                            Settings.Secure.getInt(
                                    contentResolver,
                                    Settings.Secure.INSTALL_NON_MARKET_APPS
                            ) == 1
                    if (isNonPlayAppAllowed) {
                        installApk(apkFile.toString())
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        isDestroying = true
        isAppInForground = false
        if (rtcHelper != null) {
            rtcHelper.onDestroy()
        }
        stopVoIPService()
        stopVideoFloatingWindow()
        if (this::batteryLevelReceiver.isInitialized) {
            unregisterReceiver(batteryLevelReceiver)
        }
        if (this::bluetoothReceiver.isInitialized) {
            unregisterReceiver(bluetoothReceiver)
        }
        super.onDestroy()
    }

    fun enablePush() {
        val sharedPreferences =
            getSharedPreferences("notificationPreferences", Context.MODE_PRIVATE)

        // Step 2: Write data to SharedPreferences
        with(sharedPreferences.edit()) {
            remove("DISABLE_PUSH")
            apply() // Use apply() for asynchronous saving
        }
    }

    fun disablePush() {
        val sharedPreferences =
            getSharedPreferences("notificationPreferences", Context.MODE_PRIVATE)

        // Step 2: Write data to SharedPreferences
        with(sharedPreferences.edit()) {
            putBoolean("DISABLE_PUSH", true)
            apply() // Use apply() for asynchronous saving
        }
    }
}

val callVibration =
        longArrayOf(
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000
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
    SILENCE_NOTIFICATION("Silence Notification"),
    VIBRATE_NOTIFICATION("Vibrate Notification", longArrayOf(300, 500)),
    DEFAULT_NOTIFICATION("Default Notification", longArrayOf(300, 500), 9999),
    DEFAULT_NOTIFICATION1(
            "Default Notification",
            longArrayOf(300, 500),
            R.raw.noti_f970414c3e2d6583afefecd166e3471b
    ),
    DEFAULT_NOTIFICATION2(
            "Default Notification",
            longArrayOf(300, 500),
            R.raw.noti_946e5d27d1e1cc21ec153e4b40d727c1
    ),
    DEFAULT_NOTIFICATION3(
            "Default Notification",
            longArrayOf(300, 500),
            R.raw.noti_6d45aff37ab94f8e77140bd632dc43f0
    ),
    DEFAULT_NOTIFICATION4(
            "Default Notification",
            longArrayOf(300, 500),
            R.raw.noti_edff799234b001de7189f98f49819808
    ),
    DEFAULT_NOTIFICATION5(
            "Default Notification",
            longArrayOf(300, 500),
            R.raw.noti_2c181bdff2fb757710cb2642794e5190
    ),
    SOUND_NOTIFICATION("Sound Notification", null, 9999),
    SOUND_NOTIFICATION1("Sound Notification", null, R.raw.noti_f970414c3e2d6583afefecd166e3471b),
    SOUND_NOTIFICATION2("Sound Notification", null, R.raw.noti_946e5d27d1e1cc21ec153e4b40d727c1),
    SOUND_NOTIFICATION3("Sound Notification", null, R.raw.noti_6d45aff37ab94f8e77140bd632dc43f0),
    SOUND_NOTIFICATION4("Sound Notification", null, R.raw.noti_edff799234b001de7189f98f49819808),
    SOUND_NOTIFICATION5("Sound Notification", null, R.raw.noti_2c181bdff2fb757710cb2642794e5190),
}
