package com.jiangxia.im.utils

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import com.jiangxia.im.R
import java.text.SimpleDateFormat
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Calendar
import java.util.Date
import java.util.Locale

object TimeUtils {
    fun formatTimeFun(context: Context,createTime: Long?, useOnline: Boolean = true): String {
        if (createTime == null) return ""

        var time = ""
        // 时间戳转时间
        val cdate = Calendar.getInstance().apply {
            timeInMillis = createTime * 1000
        }

        val now = Calendar.getInstance()
        val nowYear = now.get(Calendar.YEAR)

        val differenceMillis = now.timeInMillis - cdate.timeInMillis
        val differenceSeconds = (differenceMillis / 1000).toInt()
        val differenceMinutes = differenceSeconds / 60
        val differenceHours = differenceMinutes / 60

        time = when {
            differenceSeconds < 60 -> {
                if (differenceSeconds<30) {
                    context.getString(R.string.now)
                } else {
                    context.getString(R.string.justNow)
                }
            }
            differenceSeconds in 60 until 3600 -> {

                "$differenceMinutes${context.getString(R.string.myChatMinutes)}"
            }
            differenceSeconds in 3600 until 24 * 3600 -> {
                "$differenceHours${context.getString(R.string.myChatHours)}"
            }
            differenceHours >= 24 -> {
                if (nowYear == cdate.get(Calendar.YEAR)) {
                    String.format(
                        Locale.getDefault(), "%02d/%02d",
                        cdate.get(Calendar.MONTH) + 1, cdate.get(Calendar.DAY_OF_MONTH))
                } else {
                    String.format(Locale.getDefault(), "%02d/%02d/%04d",
                        cdate.get(Calendar.MONTH) + 1, cdate.get(Calendar.DAY_OF_MONTH), cdate.get(Calendar.YEAR))
                }
            }
            else -> ""
        }

        return time
    }



    fun getCurrentTimeInCurrentTimeZone(): String {
        // 获取当前时区的当前时间
        val currentTime = ZonedDateTime.now()

        // 格式化时间为字符串
        val formatter = DateTimeFormatter.ofPattern("HH:mm")
        return currentTime.format(formatter)
    }
}