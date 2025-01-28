package com.luckyd.im.helpers

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.luckyd.im.MainActivity
import com.luckyd.im.R
import com.luckyd.im.utils.NativeView
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.video.VideoCanvas
import io.agora.rtc2.video.VideoEncoderConfiguration
import io.flutter.plugin.common.MethodChannel

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
    var meCameraIsOn = false
    var remoteCameraIsOn = false

    private var dialingSoundPool: SoundPool? = null
    private var dialingSoundLoaded = false
    private var dialingSoundId: Int = 0
    private var dialingStreamId: Int = 0

    private var endSoundPool: SoundPool? = null
    private var endSoundLoaded = false
    private var endSoundId: Int = 0
    private var endStreamId: Int = 0

    private val playingStreams = mutableMapOf<Int, Boolean>()

    private val iRtcEngineEventHandler = object : IRtcEngineEventHandler() {

        override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
            super.onJoinChannelSuccess(channel, uid, elapsed)
            Log.v("RTCHelper", "Joined channel successfully $uid")
            if(isInviter){
                playRing()
            }
        }

        override fun onUserJoined(uid: Int, elapsed: Int) {
            Log.v("RTCHelper", "onUserJoined=======> $localUid-$uid")
            val map = hashMapOf(
                "uid" to uid.toString()
            )

            if (uid != localUid) {
                remoteUid = uid
                agoraEngine!!.muteRemoteVideoStream(uid, false)
            }

            stopRing()

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

            Log.v("onUserMuteVideo", "========> ${(context as MainActivity).isPipModeOn()}, $floatWindowIsMe, $meCameraIsOn, $remoteCameraIsOn")

            if(!context.isPipModeOn()){
                updateVideoStream("onUserMuteVideo")
            }else{
                nativeView?.let{ it.showAvatarView(activity, !remoteCameraIsOn) }
                floatNativeView?.let{ it.showAvatarView(activity, !remoteCameraIsOn) }
            }
        }

        override fun onUserOffline(uid: Int, reason: Int) {
            super.onUserOffline(uid, reason)
            Log.v("onUserOffline", "========> $uid")
            if (uid == localUid) {
                invokeMethod("CallEnd", null)
            } else {
                invokeMethod("CallOptEnd", null)
            }
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
            Log.v("onNativeFirstLocalVideoFrame", "native=====> $elapsed")
            invokeMethod("onFirstLocalVideoFrame",null)
        }

        override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
            super.onFirstRemoteVideoFrame(uid, width, height, elapsed)
            Log.v("onNativeFirstRemoteVideoFrame", "native=====> $elapsed")
            invokeMethod("onFirstLocalVideoFrame",null)
        }

        override fun onRemoteVideoStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
            super.onRemoteVideoStateChanged(uid, state, reason, elapsed)
            Log.v("onRemoteVideoStateChanged", "state=====> $state")
            remoteCameraIsOn = (state == 1 || state == 2)

            val map = hashMapOf(
                "uid" to uid.toString(),
                "cameraMuted" to !remoteCameraIsOn
            )
            invokeMethod("onRemoteVideoStateChanged", map)
        }

        override fun onLeaveChannel(stats: RtcStats?) {
            super.onLeaveChannel(stats)
            stopRing()
            playEndSound()
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
            agoraEngine?.enableLocalVideo(true)
            agoraEngine?.setVideoEncoderConfiguration(videoEncoderConfiguration)
            if (isVoiceCall) {
                agoraEngine?.setDefaultAudioRoutetoSpeakerphone(false)
                agoraEngine?.muteLocalVideoStream(true)
            } else {
                meCameraIsOn = true
                isVideoCalling = true
                floatWindowIsMe = false
                agoraEngine?.setDefaultAudioRoutetoSpeakerphone(true)
                agoraEngine?.setEnableSpeakerphone(true)
                agoraEngine?.muteLocalVideoStream(false)
                agoraEngine?.startPreview()
                updateVideoStream("setupAgoraEngine")
            }
            methodChannel.invokeMethod("callInited",null)
        } catch (e: Exception) {
            methodChannel.invokeMethod("CallInitFailed",null)
            return false
        }

        return true
    }

    private fun getFrameRateFromValue(value: Int): VideoEncoderConfiguration.FRAME_RATE {
        for (frameRate in VideoEncoderConfiguration.FRAME_RATE.values()) {
            if (frameRate.value == value) {
                return frameRate
            }
        }
        return VideoEncoderConfiguration.FRAME_RATE.FRAME_RATE_FPS_30
    }

    fun joinChannel(channelName: String, token: String?, uid: Int) {
        localUid = uid
        val options = ChannelMediaOptions()

        // For a Video/Voice call, set the channel profile as COMMUNICATION.
        options.channelProfile = Constants.CHANNEL_PROFILE_COMMUNICATION
        // Set the client role to broadcaster or audience
        options.clientRoleType = Constants.CLIENT_ROLE_BROADCASTER
        // Start local preview.
        agoraEngine?.startPreview()

        // Join the channel using a token.
        agoraEngine?.joinChannel(token, channelName, uid, options)

        isCalling = true
        if (isVideoCalling) {
            toggleLocalCam(isCameraOn = true, isInit = true)
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
        agoraEngine!!.setEnableSpeakerphone(isSpeaker)
    }

    fun toggleLocalCam(isCameraOn: Boolean, isInit: Boolean = false) {
        agoraEngine!!.muteLocalVideoStream(!isCameraOn)
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
        updateVideoStream("toggleLocalCam")
    }

    fun updateVideoStream(sender: String){
        Log.v("updateVideoStream", "=========> $sender, $floatWindowIsMe, $meCameraIsOn, $remoteCameraIsOn, ${nativeView?.surfaceView?.width}, ${floatNativeView?.surfaceView?.width}")
        (context as Activity).runOnUiThread {
            nativeView?.updateView()
            floatNativeView?.updateView()

            if(meCameraIsOn && remoteCameraIsOn){
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
            }else{
                nativeView?.let{
                    val videoCanvas = VideoCanvas(it.surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, remoteUid)
                    agoraEngine?.setupRemoteVideo(videoCanvas)
                }
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

        endSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        dialingSoundId = dialingSoundPool!!.load(context, R.raw.dialing_sound, 1)
        endSoundId = endSoundPool!!.load(context, R.raw.call_end_sound, 1)

        playingStreams[dialingSoundId] = false
        playingStreams[endSoundId] = false

        dialingSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            dialingSoundLoaded = true
        }

        endSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            endSoundLoaded = true
        }
    }

    fun isAnySoundPlaying(): Boolean{
        return (playingStreams[dialingSoundId] ?: false) or (playingStreams[endSoundId] ?: false) or isCalling
    }

    fun playRing(){
        if (dialingSoundLoaded) {
            dialingStreamId = dialingSoundPool?.play(dialingSoundId, 1.0f, 1.0f, 1, 10, 1f) ?: 0
            playingStreams[dialingSoundId] = true
            Log.v("RTCHelper", "playRing===========> $dialingStreamId")
        }
    }

    fun playEndSound(){
        Log.v("RTCHelper", "playEndSound===========> $endSoundLoaded, ${isUserJoined()}")
        if (endSoundLoaded && isUserJoined()) {
            endStreamId = endSoundPool?.play(endSoundId, 0.5f, 0.5f, 1, 0, 1f) ?: 0
            playingStreams[endSoundId] = true
            Handler(Looper.getMainLooper()).postDelayed({
                stopAllRing()
            }, 650)
        }
    }

    fun stopRing(){
        Log.v("RTCHelper", "stopRing=========> $dialingSoundId, $dialingStreamId")
        dialingSoundPool?.stop(dialingStreamId)
        playingStreams[dialingSoundId] = false
    }

    private fun stopEndSound(){
        Log.v("RTCHelper", "stopEnd=========> $endSoundId, $endStreamId")
        endSoundPool?.stop(endStreamId)
        playingStreams[endSoundId] = false
    }

    private fun stopAllRing(){
        stopRing()
        stopEndSound()
    }

    fun toggleFloat(isMe: Boolean) {
        floatWindowIsMe = isMe
        if(!(context as MainActivity).isPipModeOn()) {
            updateVideoStream("toggleFloat")
        }
    }

    fun switchCamera() {
        agoraEngine!!.switchCamera()
    }

    fun checkVideoCall() {
        isVideoCalling = !(!meCameraIsOn && !remoteCameraIsOn)
    }

    fun releaseEngine() {
        agoraEngine?.leaveChannel()
        agoraEngine = null
        isVideoCalling = false
        isCalling = false
        floatWindowIsMe = true
        meCameraIsOn = false
        remoteCameraIsOn = false
        isInviter = false
        nativeView = null
        floatNativeView = null
        remoteUid = 0
        RtcEngine.destroy()
    }

    fun onDestroy(){
        releaseEngine()
        dialingSoundPool?.release()
        endSoundPool?.release()
        playingStreams.clear()
    }
}