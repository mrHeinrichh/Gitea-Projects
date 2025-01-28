package com.jiangxia.im.helpers

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.jiangxia.im.MainActivity
import com.jiangxia.im.R
import com.jiangxia.im.utils.NativeView
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.video.VideoCanvas
import io.agora.rtc2.video.VideoEncoderConfiguration
import io.flutter.plugin.common.MethodChannel
import io.agora.rtc2.internal.EncryptionConfig
import io.sentry.Sentry

class RTCHelper(private val context: Context, private val activity: Activity, private val methodChannel: MethodChannel) {
    var agoraEngine: RtcEngine? = null
    var localUid: Int = 0 // UID of the local user
    var remoteUid: Int = 0
    var isVideoCalling = false
    var isCalling = false
    var isInviter = false
    var nativeView: NativeView? = null
    var floatNativeView: NativeView? = null
    var floatWindowIsMe: Boolean = true
    var isMinimized: Boolean = false
    var meCameraIsOn = false
    var remoteCameraIsOn = false
    var remoteCameraIsFreezed = false
    var onFirstRemoteVideoFrame = false
    var onFirstLocalVideoFrame = false
    var onUserMuteVideoCalled = false
    var toggleLocalCamCalled = false

    private var dialingSoundPool: SoundPool? = null
    private var dialingSoundLoaded = false
    private var dialingSoundId: Int = 0
    private var dialingStreamId: Int = 0

    private var pickedSoundPool: SoundPool? = null
    private var pickedSoundLoaded = false
    private var pickedSoundId: Int = 0
    private var pickedStreamId: Int = 0

    private var busySoundPool: SoundPool? = null
    private var busySoundLoaded = false
    private var busySoundId: Int = 0
    private var busyStreamId: Int = 0

    private var endSoundPool: SoundPool? = null
    private var endSoundLoaded = false
    private var endSoundId: Int = 0
    private var endStreamId: Int = 0

    private var end2SoundPool: SoundPool? = null
    private var end2SoundLoaded = false
    private var end2SoundId: Int = 0
    private var end2StreamId: Int = 0

    private var canResetSound: Boolean = true

    private val playingStreams = mutableMapOf<Int, Boolean>()

    private val iRtcEngineEventHandler = object : IRtcEngineEventHandler() {

        override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
            super.onJoinChannelSuccess(channel, uid, elapsed)
            Log.v("RTCHelper", "Joined channel successfully $uid")
        }

        override fun onUserJoined(uid: Int, elapsed: Int) {
            Log.v("RTCHelper", "onUserJoined=======> $localUid-$uid")
            val map = hashMapOf(
                "uid" to uid.toString()
            )

            if (uid != localUid) {
                remoteUid = uid
                agoraEngine?.muteRemoteVideoStream(uid, false)
            }

            stopDialing()

            invokeMethod("onUserJoined", map)
        }

        override fun onUserMuteVideo(uid: Int, muted: Boolean) {
            val map = hashMapOf(
                "uid" to uid.toString(),
                "cameraMuted" to muted
            )
            remoteCameraIsOn = !muted
            invokeMethod("onRemoteVideoStateChanged", map)
            checkVideoCall()

            var isInPIPMode = (context as MainActivity).isPipModeOn()
            if(isInPIPMode){
                if(floatNativeView == null){
                    agoraEngine?.setupLocalVideo(null)
                }
                nativeView?.let{ it.showAvatarView(activity, !remoteCameraIsOn) }
                floatNativeView?.let{ it.showAvatarView(activity, !remoteCameraIsOn) }
            }

            if(!onUserMuteVideoCalled){
                onUserMuteVideoCalled = true
                updateVideoStream("onUserMuteVideo", needUpdate = !isInPIPMode)
            }
        }

        override fun onUserOffline(uid: Int, reason: Int) {
            super.onUserOffline(uid, reason)
            Log.v("onUserOffline", "========> $uid")
//            if (uid == localUid) {
//                invokeMethod("CallEnd", null)
//            } else {
//                invokeMethod("CallOptEnd", null)
//            }
        }

        override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
            // 0: The network quality is unknown.
            // 1: The network quality is excellent.
            // 2: The network quality is quite good, but the bitrate may be slightly lower than excellent.
            // 3: Users can feel the communication is slightly impaired.
            // 4: Users cannot communicate smoothly.
            // 5: The quality is so bad that users can barely communicate.
            // 6: The network is down and users cannot communicate at all.
            // 7: Users cannot detect the network quality (not in use).
            // 8: Detecting the network quality.

            Log.v("networkQuality", "======> $txQuality, $rxQuality")

            invokeMethod("onNetworkQuality",hashMapOf(
                    "uid" to uid,
                    "txQuality" to txQuality,
                    "rxQuality" to rxQuality,
                )
            )
        }

        override fun onFirstLocalVideoFrame(
            source: Constants.VideoSourceType?,
            width: Int,
            height: Int,
            elapsed: Int
        ) {
            Log.v("onNativeFirstLocalVideoFrame", "onFirstLocalVideoFrame=====> $elapsed")
            onFirstLocalVideoFrame = true
            invokeMethod("onFirstLocalVideoFrame", null)
        }

        override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
            super.onFirstRemoteVideoFrame(uid, width, height, elapsed)
            Log.v(
                "onNativeFirstRemoteVideoFrame",
                "onFirstRemoteVideoFrame=====> $uid, $floatWindowIsMe"
            )
            onFirstRemoteVideoFrame = true

            if (!(context as MainActivity).isPipModeOn()) {
                updateVideoStream("onFirstRemoteVideoFrame")
            }

            invokeMethod("onFirstRemoteVideoFrame", null)
        }

        override fun onFirstLocalVideoFramePublished(source: Constants.VideoSourceType?, elapsed: Int) {
            super.onFirstLocalVideoFramePublished(source, elapsed)
            Log.v(
                "onNativeFirstRemoteVideoFrame",
                "onFirstLocalVideoFramePublished=====> $source"
            )
        }

        override fun onFirstLocalAudioFramePublished(elapsed: kotlin.Int) {
            super.onFirstLocalAudioFramePublished(elapsed)
            Log.v("MainActivity", "onFirstLocalAudioFramePublished=====> $elapsed")
        }

        override fun onFirstRemoteAudioFrame(uid: Int, elapsed: Int) {
             super.onFirstRemoteAudioFrame(uid, elapsed)
            invokeMethod("firstRemoteAudioReceived",hashMapOf(
                "uid" to uid
            ))
        }

        override fun onUserMuteAudio(uid: Int, muted: Boolean) {
            super.onUserMuteAudio(uid, muted)
            Log.v("MainActivity", "onUserMuteAudio=====> $uid, $muted")
            invokeMethod("audioMuted",hashMapOf(
                "uid" to uid,
                "muted" to muted
            ))
        }

        override fun onRemoteVideoStats(stats: RemoteVideoStats?) {
            super.onRemoteVideoStats(stats)
            if (stats != null && stats.receivedBitrate > 0 && remoteCameraIsFreezed) {
                remoteCameraIsFreezed= false
                invokeMethod("iosCallInBackground", hashMapOf(
                    "isIosCallInBackground" to false,
                ))
                Log.v("onRemoteVideoStats", "isIosCallInBackground to false")
            }
        }

        override fun onRemoteVideoStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
            super.onRemoteVideoStateChanged(uid, state, reason, elapsed)
            if(uid == remoteUid){
                var isInPIPMode = (context as MainActivity).isPipModeOn()
                Log.v("onRemoteVideoStateChanged", "state=====> $uid, $state, $reason, $floatWindowIsMe, $isInPIPMode")
                if(state == 3 && reason == 12 || state == 0 && reason == 5){ // 对方iOS切后台
                    remoteCameraIsFreezed = true
                    if(isInPIPMode){
                        if(floatWindowIsMe){
                            nativeView?.let{
                                if(!it.isAvatarShowing()){
                                    it.showAvatarView(activity, true)
                                }
                            }
                        }else{
                            floatNativeView?.let{
                                if(!it.isAvatarShowing()){
                                    it.showAvatarView(activity, true)
                                }
                            }
                        }
                    }
                    invokeMethod("iosCallInBackground", hashMapOf(
                        "isIosCallInBackground" to true,
                    ))
                }else if(state == 1 || state == 2){ // 对方iOS从后台切换回前台
                    remoteCameraIsFreezed = false
                    if(isInPIPMode){
                        if(floatWindowIsMe){
                            nativeView?.let{
                                if(it.isAvatarShowing()){
                                    it.showAvatarView(activity, false)
                                }
                            }
                        }else{
                            floatNativeView?.let{
                                if(it.isAvatarShowing()){
                                    it.showAvatarView(activity, false)
                                }
                            }
                        }
                    }
                    invokeMethod("iosCallInBackground", hashMapOf(
                        "isIosCallInBackground" to false,
                    ))
                }
            }
        }

        override fun onLeaveChannel(stats: RtcStats?) {
            super.onLeaveChannel(stats)

        }
    }
    fun setupAgoraEngine(appId: String, isInviter: Boolean, isVoiceCall: Boolean, fps: Int, width: Int, height: Int): Boolean {
        this.remoteUid = 0
        this.isInviter = isInviter
        try {
            // Set the engine configuration
            val config = RtcEngineConfig()
            config.mContext = context
            config.mAppId = appId
            config.mEventHandler = iRtcEngineEventHandler

            val videoEncoderConfiguration = VideoEncoderConfiguration(
                VideoEncoderConfiguration.VideoDimensions(width,height),
                getFrameRateFromValue(fps),
                0,
                VideoEncoderConfiguration.ORIENTATION_MODE.ORIENTATION_MODE_ADAPTIVE
            )

            agoraEngine = RtcEngine.create(config)
            agoraEngine?.setAINSMode(true,1)
            agoraEngine?.setAudioProfile(1)
            agoraEngine?.enableVideo()
//            agoraEngine?.enableLocalAudio(false)
            agoraEngine?.setChannelProfile(Constants.CHANNEL_PROFILE_COMMUNICATION)
            
//            agoraEngine?.setLogFile("/data/data/com.jiangxia.im/app_flutter/agorasdk.log")

            agoraEngine?.setVideoEncoderConfiguration(videoEncoderConfiguration)
            if (isVoiceCall) {
                agoraEngine?.enableLocalVideo(false)
                agoraEngine?.setDefaultAudioRoutetoSpeakerphone(false)
                agoraEngine?.setEnableSpeakerphone(false)
                agoraEngine?.muteLocalVideoStream(true)
            } else {
                meCameraIsOn = true
                isVideoCalling = true
                floatWindowIsMe = false
                agoraEngine?.enableLocalVideo(true)
                agoraEngine?.setDefaultAudioRoutetoSpeakerphone(true)
                agoraEngine?.setEnableSpeakerphone(true)
                agoraEngine?.muteLocalVideoStream(false)

                if(isInviter){
                    agoraEngine?.startPreview()
                }

                updateVideoStream("setupAgoraEngine")
            }

            methodChannel.invokeMethod("callInited",null)
        } catch (e: Exception) {
            Sentry.captureException(e)
            methodChannel.invokeMethod("CallInitFailed",null)
            return false
        }

        return true
    }

    private fun setEncryption(encryptionSecret: String){
        var encryptionKdfSalt = byteArrayOf(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
            0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F)

        var config = EncryptionConfig()
        config.encryptionMode = EncryptionConfig.EncryptionMode.AES_128_GCM2
        config.encryptionKey = encryptionSecret
        java.lang.System.arraycopy(
            encryptionKdfSalt,
            0,
            config.encryptionKdfSalt,
            0,
            config.encryptionKdfSalt.size
        )
        var result = agoraEngine?.enableEncryption(true, config) ?: -1
        Log.v("MainAvtivity", "setEncryption=====> $result")
    }

    private fun getFrameRateFromValue(value: Int): VideoEncoderConfiguration.FRAME_RATE {
        for (frameRate in VideoEncoderConfiguration.FRAME_RATE.values()) {
            if (frameRate.value == value) {
                return frameRate
            }
        }
        return VideoEncoderConfiguration.FRAME_RATE.FRAME_RATE_FPS_30
    }

    fun openSoundPermission(attempts: Int?){
        var num = attempts ?: 0
        var result = agoraEngine?.enableLocalAudio(true) ?: -1
        Log.v("RTCHelper", "openSoundPermission====>1 $attempts， $result")
        if(result < 0){
            num = num!! + 1
            if(num < 2){
                openSoundPermission(num)
            }else{
                methodChannel.invokeMethod("enableAudioFailed", null)
            }
        }
    }

    fun joinChannel(channelName: String, token: String?, uid: Int, encryptKey: String?) {
        localUid = uid
        val options = ChannelMediaOptions()
        options.channelProfile = Constants.CHANNEL_PROFILE_COMMUNICATION

        if(!encryptKey.isNullOrBlank()){
            setEncryption(encryptKey!!)
        }

        agoraEngine?.joinChannel(token, channelName, uid, options)

        isCalling = true
        if (isVideoCalling) {
            toggleLocalCam(isCameraOn = true, isInit = true)

            if(!isInviter){
                agoraEngine?.startPreview()
            }
        }

        methodChannel.invokeMethod("joinChannelSuccess", null)
    }

    fun isUserJoined(): Boolean{
        Log.v("RTCHelper", "isUserJoin=======> $remoteUid")
        return remoteUid > 0
    }
    fun invokeMethod(methodName:String, arguments: Any?) {
        activity.runOnUiThread{
            methodChannel.invokeMethod(methodName, arguments)
        }
    }

    fun toggleMic(isMute: Boolean) {
        agoraEngine!!.muteLocalAudioStream(isMute)
    }

    fun toggleSpeaker(isSpeaker: Boolean) {
//        if(localUid == 0){
//            agoraEngine?.setDefaultAudioRoutetoSpeakerphone(isSpeaker)
//        }else {
//            agoraEngine?.setEnableSpeakerphone(isSpeaker)
//        }
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        Log.v("MainActivity", "audioManager======> ${audioManager.isBluetoothScoOn}")
        if(!audioManager.isBluetoothScoOn){
            if(isSpeaker){
                (activity as MainActivity).setAudioToSpeaker()
            }else{
                (activity as MainActivity).setAudioToEarpiece()
            }
        }
    }

    fun toggleLocalCam(isCameraOn: Boolean, isInit: Boolean = false) {
        agoraEngine?.enableLocalVideo(isCameraOn)
        agoraEngine?.muteLocalVideoStream(!isCameraOn)
        if (isCameraOn) {
            meCameraIsOn = true
            toggleSpeaker(true)
            if (isInit) {
                methodChannel.invokeMethod("cameraIsInit",null)
            }
        } else {
            meCameraIsOn = false
        }
        checkVideoCall()

        // 这里只需要跑一次updateVideoStream就可以了，因为语音通话开视频的时候是不会生成原声视频view的，跑一下就是为了初始化显视频的本地view
        if(!toggleLocalCamCalled){
            toggleLocalCamCalled = true
            agoraEngine?.startPreview()
            updateVideoStream("toggleLocalCam")
        }
    }

    fun updateVideoStream(sender: String, needUpdate: Boolean = true){
        Log.v("updateVideoStream", "updateVideoStream===> sender:$sender, floatWindowIsMe:$floatWindowIsMe, " +
                "meCameraIsOn:$meCameraIsOn, remoteCameraIsOn:$remoteCameraIsOn, isMinimized:${this.isMinimized}, " +
                "nW:${nativeView?.surfaceView?.width}, fW${floatNativeView?.surfaceView?.width}")
        (context as Activity).runOnUiThread {
            if(needUpdate){
                nativeView?.updateView()
                floatNativeView?.updateView()
            }

            if(meCameraIsOn && remoteCameraIsOn){
                if(floatWindowIsMe){
                    if(this.isMinimized){
                        nativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                            agoraEngine?.setupLocalVideo(videoCanvas)
                        }

                        floatNativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                            agoraEngine?.setupRemoteVideo(videoCanvas)
                        }
                    }else{
                        nativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                            agoraEngine?.setupRemoteVideo(videoCanvas)
                        }

                        floatNativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                            agoraEngine?.setupLocalVideo(videoCanvas)
                        }
                    }
                }else{
                    nativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                        agoraEngine?.setupLocalVideo(videoCanvas)
                    }

                    floatNativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                        agoraEngine?.setupRemoteVideo(videoCanvas)
                    }
                }
            }else if(meCameraIsOn){
                if(floatWindowIsMe){
                    floatNativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                        agoraEngine?.setupLocalVideo(videoCanvas)
                    }

                    nativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                        agoraEngine?.setupRemoteVideo(videoCanvas)
                    }
                }else{
                    nativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                        agoraEngine?.setupLocalVideo(videoCanvas)
                    }

                    floatNativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                        agoraEngine?.setupRemoteVideo(videoCanvas)
                    }
                }
            }else if(remoteCameraIsOn){
                if(this.isMinimized){
                    floatNativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                        agoraEngine?.setupRemoteVideo(videoCanvas)
                    }

                    nativeView?.let{
                        val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                        agoraEngine?.setupLocalVideo(videoCanvas)
                    }
                }else{
                    if(floatWindowIsMe){
                        nativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                            agoraEngine?.setupRemoteVideo(videoCanvas)
                        }

                        floatNativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                            agoraEngine?.setupLocalVideo(videoCanvas)
                        }
                    }else{
                        floatNativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                            agoraEngine?.setupRemoteVideo(videoCanvas)
                        }

                        nativeView?.let{
                            val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                            agoraEngine?.setupLocalVideo(videoCanvas)
                        }
                    }
                }
            }else{
                updateCallingView()
            }
        }
    }

    fun updateCallingView(){
        if(floatWindowIsMe){
            nativeView?.let{
                val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                agoraEngine?.setupRemoteVideo(videoCanvas)
            }

            floatNativeView?.let{
                val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                agoraEngine?.setupLocalVideo(videoCanvas)
            }
        }else{
            nativeView?.let{
                val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, 0)
                agoraEngine?.setupLocalVideo(videoCanvas)
            }

            floatNativeView?.let{
                val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                agoraEngine?.setupRemoteVideo(videoCanvas)
            }
        }
    }

    fun preloadSound(){
        val audioAttributes = AudioAttributes.Builder()
            .setLegacyStreamType(AudioManager.STREAM_VOICE_CALL)
            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        dialingSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        pickedSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        busySoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        endSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        end2SoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        dialingSoundId = dialingSoundPool!!.load(context, R.raw.voip_ringback, 1)
        pickedSoundId = pickedSoundPool!!.load(context, R.raw.voip_connecting, 1)
        busySoundId = busySoundPool!!.load(context, R.raw.voip_busy, 1)
        endSoundId = endSoundPool!!.load(context, R.raw.voip_end, 1)
        end2SoundId = end2SoundPool!!.load(context, R.raw.voip_end2, 1)

        playingStreams[dialingSoundId] = false
        playingStreams[pickedSoundId] = false
        playingStreams[busySoundId] = false
        playingStreams[endSoundId] = false
        playingStreams[end2SoundId] = false

        dialingSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            dialingSoundLoaded = true
        }

        pickedSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            pickedSoundLoaded = true
        }

        busySoundPool?.setOnLoadCompleteListener { _, _, _ ->
            busySoundLoaded = true
        }

        endSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            endSoundLoaded = true
        }

        end2SoundPool?.setOnLoadCompleteListener { _, _, _ ->
            end2SoundLoaded = true
        }
    }

    fun isAnySoundPlaying(): Boolean{
        return (playingStreams[dialingSoundId] ?: false) or
                (playingStreams[endSoundId] ?: false) or
                (playingStreams[pickedSoundId] ?: false) or
                (playingStreams[busySoundId] ?: false) or
                (playingStreams[end2SoundId] ?: false) or isCalling
    }

    fun playDialing(){
        if (dialingSoundLoaded) {
            dialingStreamId = dialingSoundPool?.play(dialingSoundId, 1.0f, 1.0f, 1, 20, 1f) ?: 0
            playingStreams[dialingSoundId] = true
            Log.v("RTCHelper", "playDialing===========> $dialingStreamId")
        }
    }

    fun playPicked(){
        stopDialing()

        if (pickedSoundLoaded) {
            pickedStreamId = pickedSoundPool?.play(pickedSoundId, 0.1f, 0.1f, 1, 0, 1f) ?: 0
            playingStreams[pickedSoundId] = true
            Log.v("RTCHelper", "playPicked===========> $pickedStreamId")
        }
    }

    fun playBusy(){
        if (busySoundLoaded) {
            canResetSound = false
            busyStreamId = busySoundPool?.play(busySoundId, 1.0f, 1.0f, 1, 0, 1f) ?: 0
            playingStreams[busySoundId] = true
            Handler(Looper.getMainLooper()).postDelayed({
                canResetSound = true
                stopAllRing()
            }, 1000)
        }
    }

    fun playEndSound(){
        Log.v("RTCHelper", "playEndSound===========> $endSoundLoaded")
        if (endSoundLoaded) {
            stopDialing()

            canResetSound = false
            endStreamId = endSoundPool?.play(endSoundId, 1.0f, 1.0f, 1, 0, 1f) ?: 0
            playingStreams[endSoundId] = true
            Handler(Looper.getMainLooper()).postDelayed({
                canResetSound = true
                stopAllRing()
            }, 1000)
        }
    }

    fun playEnd2Sound(){
        Log.v("RTCHelper", "playEnd2Sound===========> $end2SoundLoaded")
        if (end2SoundLoaded) {
            canResetSound = false
            end2StreamId = end2SoundPool?.play(end2SoundId, 1.0f, 1.0f, 1, 0, 1f) ?: 0
            playingStreams[end2SoundId] = true
            Handler(Looper.getMainLooper()).postDelayed({
                canResetSound = true
                stopAllRing()
            }, 1000)
        }
    }

    fun stopDialing(){
        Log.v("RTCHelper", "stopRing=========> $dialingSoundId, $dialingStreamId")
        dialingSoundPool?.stop(dialingStreamId)
        playingStreams[dialingSoundId] = false
    }

    fun stopPicked(){
        Log.v("RTCHelper", "stopPicked=========> $pickedSoundId, $pickedStreamId")
        pickedSoundPool?.stop(pickedStreamId)
        playingStreams[pickedSoundId] = false
    }

    fun stopBusy(){
        Log.v("RTCHelper", "stopBusy=========> $busySoundId, $busyStreamId")
        busySoundPool?.stop(busyStreamId)
        playingStreams[busySoundId] = false
    }

    private fun stopEndSound(){
        Log.v("RTCHelper", "stopEnd=========> $endSoundId, $endStreamId")
        endSoundPool?.stop(endStreamId)
        playingStreams[endSoundId] = false
    }

    private fun stopEnd2Sound(){
        Log.v("RTCHelper", "stop2End=========> $end2SoundId, $end2StreamId")
        end2SoundPool?.stop(end2StreamId)
        playingStreams[end2SoundId] = false
    }

    fun stopAllRing(){
        stopDialing()
        stopPicked()
        if(canResetSound){
            stopBusy()
            stopEndSound()
            stopEnd2Sound()
        }
    }

    fun toggleFloat(isMe: Boolean) {
        if(floatWindowIsMe != isMe){
            floatWindowIsMe = isMe
            if(!(context as MainActivity).isPipModeOn()) {
                updateVideoStream("toggleFloat")
            }
        }
    }

    fun switchCamera() {
        agoraEngine!!.switchCamera()
    }

    fun onMinimized(isMinimized: Boolean){
        this.isMinimized = isMinimized
    }

    fun checkVideoCall() {
        isVideoCalling = !(!meCameraIsOn && !remoteCameraIsOn)
    }

    fun releaseEngine() {
        stopAllRing()

        agoraEngine?.leaveChannel()
        agoraEngine = null
        isVideoCalling = false
        isCalling = false
        floatWindowIsMe = true
        isMinimized = false
        meCameraIsOn = false
        remoteCameraIsOn = false
        isInviter = false
        onFirstRemoteVideoFrame = false
        onFirstLocalVideoFrame = false
        toggleLocalCamCalled = false
        onUserMuteVideoCalled = false
        resetNativeViews()
        remoteUid = 0
        localUid = 0
        RtcEngine.destroy()
    }

    fun resetNativeViews(){
        nativeView = null
        floatNativeView = null
    }

    fun onDestroy(){
        releaseEngine()
        dialingSoundPool?.release()
        pickedSoundPool?.release()
        busySoundPool?.release()
        endSoundPool?.release()
        end2SoundPool?.release()
        playingStreams.clear()
    }
}