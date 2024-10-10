package com.jiangxia.im.helpers

import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Parcelable
import android.util.Log
import androidx.annotation.RequiresApi
import com.jiangxia.im.MainActivity
import com.jiangxia.im.models.MediaData
import com.jiangxia.im.utils.RealPathUtil
import java.io.File
import java.io.FileNotFoundException
import java.nio.file.Files


class ShareHelper private constructor() {

    companion object {
        @Volatile
        private var instance: ShareHelper? = null

        fun getInstance(): ShareHelper {
            if (instance == null) {
                synchronized(this) {
                    if (instance == null) {
                        instance = ShareHelper()
                    }
                }
            }
            return instance!!
        }
    }

    var shareDataList = mutableListOf<Any>()

    @RequiresApi(Build.VERSION_CODES.O)
    fun handleIntent(intent: Intent, context: Context) {
        Log.v("handleIntent", "handleIntent======> type = ${intent.type} and action = ${intent.action} is true = ${intent.action == Intent.ACTION_SEND_MULTIPLE}")
        when (intent.action) {
            Intent.ACTION_SEND -> {
                Log.v("handleIntent", "handleIntent======> intent type = ${intent.type}")
                intent.type?.let {
                    when {
                        it.startsWith("image/") -> {
                            Log.v("handleReceiveShareData", "ShareMgr======> image")
                            handleSendImage(context, intent)
                        }
                        it.startsWith("video/") -> {
                            Log.v("handleReceiveShareData", "ShareMgr======> video")
                            handleSendVideo(context, intent)
                        }
                        it.startsWith("text/") -> {
                            Log.v("handleReceiveShareData", "ShareMgr======> text")
                            handleSendText(intent)
                        }
                        else -> {
                            Log.v("handleReceiveShareData", "ShareMgr======> file")
                            handleSendFile(context, intent)
                        }
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                Log.v("handleReceiveShareData", "ShareMgr======> multiple")
                handleSendMultipleImages(context,intent) // Handle multiple images being sent
            }
            else -> {
                handleSendFile(context, intent)
            }
        }

        notifiyMainShareMediaReady(context)
    }
    private fun handleSendImage(context: Context, intent: Intent) {
        Log.v("handleReceiveShareData", "Image========> $intent")
        (intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri)?.let {
            handleImageUri(context, it)
        }
    }

    private fun handleSendVideo(context: Context, intent: Intent){
        Log.v("handleReceiveShareData", "Video========> $intent")
        (intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri)?.let {
            handleVideoUri(context, it)
        }
    }

    private fun handleSendText(intent: Intent) {
        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        Log.v("handleReceiveShareData", "Text========> extra => $sharedText")
        var sharedData = mutableMapOf<String, Any>()
        sharedData["text"] = sharedText!!
        shareDataList.add(sharedData)
    }

    private fun getVideoInfo(context: Context, contentUri: Uri?): MediaData?{
        return RealPathUtil.getVideoInfo(context, contentUri)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun handleSendFile(context: Context, intent: Intent) {
        Log.v("handleReceiveShareData", "File========> $intent")
        (intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri)?.let {
            handleFileUri(context, it)
        }
    }

    private fun handleSendMultipleImages(context: Context, intent: Intent) {
        Log.v("handleReceiveShareData", "Multiple========> $intent")
        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        uris?.forEach { uri ->
            val mimeType = context.contentResolver.getType(uri)
            when {
                mimeType?.startsWith("image/") == true -> {
                    handleImageUri(context, uri)
                }
                mimeType?.startsWith("video/") == true -> {
                    handleVideoUri(context, uri)
                }
                else -> {
                    handleFileUri(context, uri)
                }
            }
        }
    }

    private fun handleImageUri(context: Context, uri: Uri) {
        if(uri.path != null){
            var imageWidth = 0
            var imageHeight = 0
            try {
                var options: BitmapFactory.Options? = BitmapFactory.Options()
                options?.inJustDecodeBounds = true
                context.contentResolver.openInputStream(uri).use { inputStream ->
                    BitmapFactory.decodeStream(inputStream, null, options)
                    imageWidth = options?.outWidth ?: 0
                    imageHeight = options?.outHeight ?: 0
                }
            }catch ( e: FileNotFoundException){
                e.printStackTrace()
            }

            RealPathUtil.getRealPath(context, uri)?.let {
                val exif = ExifInterface(it)
                when (exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
                    ExifInterface.ORIENTATION_ROTATE_90,
                    ExifInterface.ORIENTATION_ROTATE_270,
                    ExifInterface.ORIENTATION_TRANSPOSE,
                    ExifInterface.ORIENTATION_TRANSVERSE -> {
                        val temp = imageWidth
                        imageWidth = imageHeight
                        imageHeight = temp
                    }
                }
                var sharedData = mutableMapOf<String, Any>()
                sharedData["image_to_path"] = it
                sharedData["width"] = imageWidth
                sharedData["height"] = imageHeight
                shareDataList.add(sharedData)
                Log.v("handleSendImage", "========> image after process $sharedData")
            }
        }
    }

    private fun handleVideoUri(context: Context, uri: Uri) {
        if(uri.path != null){
            getVideoInfo(context, uri)?.let {
                Log.v("ShareHelper", "=========> $it")
                var sharedData = mutableMapOf<String, Any>()
                sharedData["video_to_path"] = it.localPath
                sharedData["video_width"] = it.width
                sharedData["video_height"] = it.height
                sharedData["video_size"] = it.size
                sharedData["video_duration"] = it.duration

                shareDataList.add(sharedData)
            }
        }
    }

    private fun handleFileUri(context: Context, uri: Uri) {
        RealPathUtil.getRealPath(context, uri)?.let {
            val fileName = it.substring(it.lastIndexOf("/") + 1)
            val suffix = it.substring(it.lastIndexOf(".") + 1)
            val bytes: Long = Files.size(kotlin.io.path.Path(it))
            Log.v("handleSendFile", "=====> $it | $fileName | $suffix")

            var sharedData = mutableMapOf<String, Any>()
            sharedData["file_to_path"] = it
            sharedData["file_name"] = fileName
            sharedData["suffix"] = suffix
            sharedData["length"] = bytes
            shareDataList.add(sharedData)
        }
    }

    private fun notifiyMainShareMediaReady(context: Context){
        if(shareDataList.size > 0 && context is MainActivity){
            MainActivity.shareMethod.invokeMethod("share_data_ready", shareDataList)
        }
    }

    fun getFileFromMediaUri(context: Context, uri: Uri): File? {
        if (uri.scheme.toString().compareTo("content") == 0) {
            val cursor: Cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
            // 根据Uri从数据库中找
            cursor.moveToFirst()
            cursor.getColumnIndex("_data")
            val cursorRange = cursor.getColumnIndex("_data");
            if (cursorRange >= 0) {
                val filePath: String = cursor.getString(cursorRange) // 获取图片路径
                cursor.close()
                return File(filePath)
            }
        } else if (uri.scheme.toString().compareTo("file") == 0) {
            return File(uri.toString().replace("file://", ""))
        }
        return null
    }

    fun clear(){
        shareDataList.clear()
    }
}