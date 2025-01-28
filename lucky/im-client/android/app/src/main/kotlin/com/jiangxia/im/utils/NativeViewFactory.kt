package com.luckyd.im.utils

import android.content.Context
import android.view.ViewGroup
import com.luckyd.im.helpers.RTCHelper
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.util.Log

class NativeViewFactory(private val rtcHelper: RTCHelper) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        Log.v("NativeViewFactory1", "========> ${creationParams?.get("isBigScreen")}")
        if (creationParams?.get("isBigScreen") as Boolean) {
            if(rtcHelper.nativeView == null){
                val nativeView = NativeView(context, viewId, creationParams)
                rtcHelper.nativeView = nativeView
                rtcHelper.updateVideoStream("NativeViewFactory")
            }else if (rtcHelper.nativeView!!.getView().parent != null){
                val parent = rtcHelper.nativeView!!.getView().parent as? ViewGroup
                parent?.removeView(rtcHelper.nativeView!!.getView())
            }
            return rtcHelper.nativeView!!
        } else {
            if(rtcHelper.floatNativeView == null){
                val nativeView = NativeView(context, viewId, creationParams)
                rtcHelper.floatNativeView = nativeView
                rtcHelper.updateVideoStream("NativeViewFactory")
            }else if(rtcHelper.floatNativeView!!.getView().parent != null){
                val parent = rtcHelper.floatNativeView!!.getView().parent as? ViewGroup
                parent?.removeView(rtcHelper.floatNativeView!!.getView())
            }
            return rtcHelper.floatNativeView!!
        }
    }
}
