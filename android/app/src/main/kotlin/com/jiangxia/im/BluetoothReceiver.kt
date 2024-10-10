package com.jiangxia.im

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioDeviceInfo
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel


class BluetoothReceiver : BroadcastReceiver() {
    private lateinit var bluetoothListener: BluetoothListener
    private var blueTooth: String = ""

    var hasBluetooth: Boolean = false

    fun setBluetoothListener(listener: BluetoothListener){
        this.bluetoothListener = listener
    }

    @SuppressLint("MissingPermission")
    @RequiresApi(Build.VERSION_CODES.S)
    override fun onReceive(context: Context?, intent: Intent) {

        if(context == null){
            return
        }

        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val deviceType = if (audioManager.isSpeakerphoneOn()) "speaker" else "earpiece"

        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

        val action = intent.action
        val deviceName = device?.name ?: "";
        val dataMap = hashMapOf<String, Any>()
        Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>111111: ${action}")
        when (action) {
            BluetoothAdapter.ACTION_STATE_CHANGED -> {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>state: $state")

                when (state) {
                    BluetoothAdapter.STATE_ON,
                    BluetoothAdapter.STATE_TURNING_ON -> {
                        Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>STATE_TURNING_ON: $deviceName")
                        dataMap["deviceName"] = deviceName
                        dataMap["isOn"] = true
                        dataMap["type"] = "bluetooth"

                        hasBluetooth = true
                    }
                    BluetoothAdapter.STATE_OFF,
                    BluetoothAdapter.STATE_TURNING_OFF -> {
                        Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>STATE_TURNING_OFF: $deviceName")
                        dataMap["deviceName"] = deviceName
                        dataMap["isOn"] = false
                        dataMap["type"] = deviceType

                        hasBluetooth = false
                    }

                    else -> {}
                }
            }
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>connected: $deviceName")
                dataMap["deviceName"] = deviceName
                dataMap["isOn"] = true
                dataMap["type"] = "bluetooth"

                hasBluetooth = true
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED,
            BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED -> {
                Log.v("BluetoothReceiver", "getCurrentAudioOutputDevice====>disconnected: $deviceName}")
                dataMap["deviceName"] = deviceName
                dataMap["isOn"] = false
                dataMap["type"] = deviceType

                hasBluetooth = false
            }

            else -> {}
        }

        this.bluetoothListener.bluetoothChanged(dataMap)
    }
}

interface BluetoothListener {
    fun bluetoothChanged(data: Map<String, Any>)
}