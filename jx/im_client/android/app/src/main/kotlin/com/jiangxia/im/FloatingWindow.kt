package com.jiangxia.im

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Point
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout

@SuppressLint("ClickableViewAccessibility", "UseCompatLoadingForDrawables")
class FloatingWindow(context: Context, contentView: View) {
    private val context: Context
    private val windowManager: WindowManager
    private val floatingView: FrameLayout
    private val params: WindowManager.LayoutParams
    private var initialY: Int = 0

    init {
        this.context = context
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        floatingView = LayoutInflater.from(context).inflate(R.layout.floating_window_layout, null) as FrameLayout

        val screenWidth = context.resources.displayMetrics.widthPixels
        val desiredWidth = screenWidth / 3
        val desiredHeight = (desiredWidth.toFloat() * 16 / 9).toInt()

        params = WindowManager.LayoutParams(
            desiredWidth,
            desiredHeight,
            screenWidth - desiredWidth,
            initialY,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.RGBA_8888
        )

        params.gravity = Gravity.START or Gravity.TOP

        val parent = contentView.parent
        if (parent is ViewGroup) {
            parent.removeView(contentView)
        }

        floatingView.addView(contentView)
        windowManager.addView(floatingView, params)

        floatingView.registerDraggableTouchListener(
            initialPosition = { Point(params.x, params.y) },
            positionListener = { x, y -> setPosition(x, y) }
        )

        floatingView.setOnClickListener {
            val intent = Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    private fun setPosition(x: Int, y: Int) {
        params.x = x
        params.y = y
        windowManager.updateViewLayout(floatingView, params)
    }

    fun dismiss() {
        windowManager.removeView(floatingView)
    }
}
