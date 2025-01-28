package com.jiangxia.im.helpers

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.jiangxia.im.R
import com.jiangxia.im.callVibration


class SoundHelper(private val activity: Activity) {
    private var ringSoundPool: SoundPool? = null
    private var ringSoundLoaded = false
    private var ringSoundId: Int = 0
    private var ringStreamId: Int = 0

    private val playingStreams = mutableMapOf<Int, Boolean>()

    private var vibrator: Vibrator? = null
    fun preloadSounds(){
        val audioAttributes = AudioAttributes.Builder()
            .setLegacyStreamType(AudioManager.STREAM_VOICE_CALL)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        ringSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        ringSoundId = ringSoundPool!!.load(activity, R.raw.call, 1)

        ringSoundPool?.setOnLoadCompleteListener { _, _, _ ->
            ringSoundLoaded = true
        }
    }

    fun playRing(){
        if (ringSoundLoaded) {
            ringStreamId = ringSoundPool?.play(ringSoundId, 1.0f, 1.0f, 1, 20, 1f) ?: 0
            startVibrate()
            playingStreams[ringSoundId] = true
        }
    }


    private fun startVibrate() {
        if(vibrator == null){
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // S = API level 31
                val vibratorManager =
                    activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                activity.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
        }

        if (vibrator != null && vibrator?.hasVibrator() == true) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(callVibration,-1));
            } else {
                vibrator?.vibrate(callVibration, -1) // -1 means don't repeat the pattern
            }
        }
    }

    private fun stopVibration() {
        vibrator?.cancel()
    }

    fun stopRing(){
        stopVibration()
        ringSoundPool?.stop(ringStreamId)
        playingStreams[ringSoundId] = false
    }

    fun stopAllSound(){
        stopRing()
    }
}