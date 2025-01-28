package com.jiangxia.im.utils

import android.app.Activity
import android.content.Context
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.SurfaceView
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import android.util.Log
import androidx.constraintlayout.widget.ConstraintLayout
import com.bumptech.glide.Glide
import com.jiangxia.im.R
import io.flutter.plugin.platform.PlatformView
import android.R.bool

class NativeView(
    private val context: Context,
    id: Int,
    private val creationParams: Map<String?, Any?>?,
) : PlatformView {
    private val themes = intArrayOf(
        R.drawable.background_red_placeholder,
        R.drawable.background_orange_placeholder,
        R.drawable.background_yellow_placeholder,
        R.drawable.background_green_placeholder,
        R.drawable.background_bluepurple_placeholder,
        R.drawable.background_blue_placeholder,
        R.drawable.background_blurgreen_placeholder,
        R.drawable.background_purple_placeholder)

    private val flutterWrapper: FrameLayout = FrameLayout(context)
    val contentView: FrameLayout = FrameLayout(context)
    var surfaceView: SurfaceView = SurfaceView(context)
    private val avatarView = LayoutInflater.from(context).inflate(R.layout.avatar_layout, null) as ConstraintLayout

    private var uid: Int = 0
    private var isBigScreen: Boolean = false
    private var avatarUrl: String = ""
    private var nickname: String = ""

    init {
        flutterWrapper.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
    }

    override fun getView(): View {
        uid = creationParams?.get("uid") as Int
        isBigScreen = creationParams?.get("isBigScreen") as? Boolean == true
        avatarUrl = creationParams?.get("remoteProfile") as String
        nickname = creationParams?.get("nickname") as String
        updateView()
        return flutterWrapper
    }

    fun updateView() {
        contentView.setBackgroundColor(context.getColor(R.color.colorBlack))

        val frameParent = contentView?.parent as? ViewGroup
        frameParent?.removeView(contentView)

        val imageView = avatarView.findViewById(R.id.iv_avatar) as ImageView
        val placeholder = avatarView.findViewById(R.id.fl_placeholder) as FrameLayout
        val letterView = avatarView.findViewById(R.id.tv_letter) as TextView
        if(avatarUrl.isNotBlank()){
            Glide.with(context).load(avatarUrl).circleCrop().into(imageView);
            placeholder.visibility = View.GONE
            imageView.visibility = View.VISIBLE
        }else{
            placeholder.visibility = View.VISIBLE
            imageView.visibility = View.GONE

            val index =  uid % 8  // colorThemeFromNickName(nickname)
            if(index < themes.size) {
                placeholder.setBackgroundResource(themes[index])
            }
            letterView.text = shortName(nickname)
        }

        surfaceView.setZOrderMediaOverlay(true);
        surfaceView.visibility = View.VISIBLE
        avatarView.visibility = View.GONE

        contentView.removeAllViews()

        contentView.addView(surfaceView)
        contentView.addView(avatarView)

        flutterWrapper.addView(contentView)
    }

    fun showAvatarView(activity: Activity, show: Boolean){
        activity.runOnUiThread {
            if(show){
                avatarView.visibility = View.VISIBLE
            }else{
                avatarView.visibility = View.GONE
            }
        }
    }

    fun isAvatarShowing(): Boolean {
        return avatarView.visibility == View.VISIBLE
    }

    fun shortName(nickname: String): String{
        if(nickname.isBlank()) return "-"

        var emojiStr = getEmojiString(nickname)
        var name: String = ""
        if(!emojiStr.isNullOrBlank()){
            name = emojiStr
        }else{
            val parts: List<String> = nickname.split(" ")
            if(parts.size > 1){
                name = "${parts.get(0).first()}${parts.get(1).first()}".uppercase()
            }else{
                name = nickname.substring(0, 1).uppercase()
            }
        }
        return name
    }

    private fun getEmojiString(displayName: String): String? {
        val nameLength = displayName.length
        for (i in 0 until nameLength) {
            val hs = displayName[i]
            if (hs.code in 0xd800..0xdbff) {
                val ls = displayName[i + 1]
                val uc = (hs.code - 0xd800) * 0x400 + (ls.code - 0xdc00) + 0x10000
                if (uc in 0x1d000..0x1f77f) {
                    return displayName.substring(i, i + 2)
                }
            } else if (Character.isHighSurrogate(hs)) {
                val ls = displayName[i + 1]
                if (ls.code == 0x20e3) {
                    return displayName.substring(i, i + 2)
                }
            } else {
                // non surrogate
                if (hs.code in 0x2100..0x27ff) {
                    return displayName.substring(i, i + 1)
                } else if (hs.code in 0x2B05..0x2b07) {
                    return displayName.substring(i, i + 1)
                } else if (hs.code in 0x2934..0x2935) {
                    return displayName.substring(i, i + 1)
                } else if (hs.code in 0x3297..0x3299) {
                    return displayName.substring(i, i + 1)
                } else if (hs.code == 0xa9 || hs.code == 0xae || hs.code == 0x303d || hs.code == 0x3030 ||
                    hs.code == 0x2b55 || hs.code == 0x2b1c || hs.code == 0x2b1b || hs.code == 0x2b50
                ) {
                    return displayName.substring(i, i + 1)
                }
            }
        }
        return null
    }

    open fun colorThemeFromNickName(nickName: String): Int {
        var md5: String = MD5().md5(nickName)
        var index: Int = md5.toByteArray().get(0) % 7
        Log.v("colorThemeFromNickName", "==========> $index")
        return index
    }

    override fun dispose() {}
}



















