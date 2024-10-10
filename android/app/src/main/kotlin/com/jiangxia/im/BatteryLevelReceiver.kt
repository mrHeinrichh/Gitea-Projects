package com.jiangxia.im

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.util.Log

class BatteryLevelReceiver : BroadcastReceiver() {

    private lateinit var batteryLevelListener: BatteryLevelListener
    private var currentLevel = -1;

    fun setBatteryLevelListener(listener: BatteryLevelListener){
        this.batteryLevelListener = listener
    }
    override fun onReceive(context: Context, intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)

        if(level != currentLevel) {
            currentLevel = level
            batteryLevelListener?.let {
                it.batteryLevelChanged(level)
            }
            Log.v("BatteryLevelReceiver", "Battery level changed: $level")
        }
    }
}

interface BatteryLevelListener {
    fun batteryLevelChanged(level: Int)
}