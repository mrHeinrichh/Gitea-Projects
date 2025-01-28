package com.luckyd.im.utils

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.Context
import android.content.CursorLoader
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.text.TextUtils
import android.util.Log
import com.luckyd.im.models.MediaData
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.lang.Long
import java.util.concurrent.TimeUnit
import kotlin.Array
import kotlin.Boolean
import kotlin.ByteArray
import kotlin.Exception
import kotlin.Int
import kotlin.String
import kotlin.also
import kotlin.arrayOf
import kotlin.let


object RealPathUtil {
    fun getRealPath(context: Context, fileUri: Uri): String? {
        // SDK >= 11 && SDK < 19
        return if (Build.VERSION.SDK_INT < 19) {
            getRealPathFromURIAPI11to18(context, fileUri)
        } else {
            getRealPathFromURIAPI19(context, fileUri)
        }// SDK > 19 (Android 4.4) and up
    }

    @SuppressLint("NewApi")
    fun getRealPathFromURIAPI11to18(context: Context, contentUri: Uri): String? {
        val proj = arrayOf(MediaStore.Images.Media.DATA)
        var result: String? = null

        val cursorLoader = CursorLoader(context, contentUri, proj, null, null, null)
        val cursor = cursorLoader.loadInBackground()

        if (cursor != null) {
            val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            cursor.moveToFirst()
            result = cursor.getString(columnIndex)
            cursor.close()
        }
        return result
    }

    /**
     * Get a file path from a Uri. This will get the the path for Storage Access
     * Framework Documents, as well as the _data field for the MediaStore and
     * other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri     The Uri to query.
     * @author Niks
     */
    @SuppressLint("NewApi")
    fun getRealPathFromURIAPI19(context: Context, uri: Uri): String? {

        val isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT

        Log.v("RealPathUtil", "==========> $isKitKat | ${uri.scheme!!} | ${DocumentsContract.isDocumentUri(context, uri)} | ${isExternalStorageDocument(uri)} | ${isDownloadsDocument(uri)} | ${isMediaDocument(uri)}")

        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                if ("primary".equals(type, ignoreCase = true)) {
                    return Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                }
            } else if (isDownloadsDocument(uri)) {
                var cursor: Cursor? = null
                try {
                    cursor = context.contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
                    cursor!!.moveToNext()
                    val fileName = cursor.getString(0)
                    val path = Environment.getExternalStorageDirectory().toString() + "/Download/" + fileName
                    if (!TextUtils.isEmpty(path)) {
                        return path
                    }
                } finally {
                    cursor?.close()
                }
                val id = DocumentsContract.getDocumentId(uri)
                if (id.startsWith("raw:")) {
                    return id.replaceFirst("raw:".toRegex(), "")
                }
                val contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads"), Long.valueOf(id))

                return getDataColumn(context, contentUri, null, null)
            } else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                var contentUri: Uri? = null
                when (type) {
                    "image" -> contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])

                return getDataColumn(context, contentUri, selection, selectionArgs)
            }// MediaProvider
            // DownloadsProvider
        } else if ("content".equals(uri.scheme!!, ignoreCase = true)) {
            // Return the remote address
            return if (isGooglePhotosUri(uri)) uri.lastPathSegment else getDataColumn(context, uri, null, null)
        } else if ("file".equals(uri.scheme!!, ignoreCase = true)) {
            return uri.path
        }// File
        // MediaStore (and general)

        return null
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context       The context.
     * @param uri           The Uri to query.
     * @param selection     (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     * @author Niks
     */
    private fun getDataColumn(context: Context, uri: Uri?, selection: String?,
                              selectionArgs: Array<String>?): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)

        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(index)
            }
        } catch (e: Exception){
            Log.v("getDataColumn", "========> $e")
            return getFilePathForN(uri, context)!!.localPath
        } finally {
            cursor?.close()
        }
        return null
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    private fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    private fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    private fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is Google Photos.
     */
    private fun isGooglePhotosUri(uri: Uri): Boolean {
        return "com.google.android.apps.photos.content" == uri.authority
    }


    fun getVideoInfo(context: Context, contentUri: Uri?): MediaData?{
        var mediaData: MediaData? = null
        var cursor: Cursor? = null
        var retriever = MediaMetadataRetriever()
        retriever.setDataSource(context, contentUri!!)
        var widthStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH) ?: "0"
        var heightStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT) ?: "0"

        val rotationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION) ?: "0"
        val rotation = rotationStr.toInt()

        var width = widthStr.toInt()
        var height = heightStr.toInt()
        Log.v("getVideoInfo", "=======> rotation = $rotation")
        if (rotation == 90 || rotation == 270) {
            val temp = width
            width = height
            height = temp
        }

        try {
            val proj = arrayOf<String?>(
                MediaStore.Images.Media.DATA,
                MediaStore.Video.Media.DURATION,
                OpenableColumns.SIZE
            )
            context.contentResolver.query(contentUri!!, proj, null, null, null)?.let {
                cursor = it
                if (it.moveToFirst()){
                    var durationColumnIndex: Int = it.getColumnIndex(MediaStore.Video.Media.DURATION)
                    var duration = it.getLong(durationColumnIndex)
                    val durationInSeconds = TimeUnit.MILLISECONDS.toSeconds(duration)
                    val sizeIndex: Int = it.getColumnIndex(OpenableColumns.SIZE)
                    var size = it.getLong(sizeIndex) ?: 0

                    val dataIndex: Int = it.getColumnIndex(MediaStore.Images.Media.DATA)
                    var realVideoPath = it.getString(dataIndex) ?: ""

                    mediaData = MediaData(realVideoPath, durationInSeconds, size, width, height)
                    Log.v("ShareHelper", "=======> $realVideoPath | $durationInSeconds | $size | $width | $height")
                }
            }
        } catch (e: Exception){
            mediaData = getFilePathForN(contentUri!!, context)
            mediaData?.width = width
            mediaData?.height = height
            mediaData?.duration = getDuration(context, mediaData!!.localPath)
            Log.v("ShareHelper", "=======> Exception ${mediaData!!.localPath} | ${mediaData?.duration} | $width | $height")

            return mediaData
        } finally {
            cursor?.close()
        }

        return mediaData
    }

    // Use Below Method Working fine for Android N
    private fun getFilePathForN(
        uri: Uri?,
        context: Context?
    ): MediaData? {
        var returnUri: Uri? = uri
        context!!.contentResolver.query(returnUri!!, null, null, null, null)?.let {
            var nameIndex: Int = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            var sizeIndex: Int = it.getColumnIndex(OpenableColumns.SIZE)

            it.moveToFirst()
            var name: String? = it.getString(nameIndex)
            var size = it.getLong(sizeIndex)
            var file: File? = File(context!!.filesDir, name!!)

            if (file != null) {
                try {
                    var inputStream: InputStream? = context.contentResolver.openInputStream(uri!!)
                    var outputStream: FileOutputStream? = FileOutputStream(file!!)
                    var read: Int
                    var maxBufferSize: Int = 1 * 1024 * 1024
                    var bytesAvailable: Int = inputStream!!.available()

                    var bufferSize: Int = Math.min(bytesAvailable, maxBufferSize)
                    val buffers: ByteArray? = ByteArray(bufferSize)
                    while ((inputStream.read(buffers).also({ read = it })) != -1) {
                        outputStream!!.write(buffers!!, 0, read)
                    }

                    inputStream!!.close()
                    outputStream!!.close()
                } catch (e: java.lang.Exception) {
                    Log.e("Exception", e.message!!)
                }
            }

            return MediaData(file!!.path, 0, size, 0, 0)
        }
        return null
    }

    private fun getDuration(context: Context?, path: String?): kotlin.Long {
        var mMediaPlayer: MediaPlayer? = null
        var duration: kotlin.Long = 0
        try {
            mMediaPlayer = MediaPlayer()
            mMediaPlayer.setDataSource(context!!, Uri.parse(path))
            mMediaPlayer.prepare()
            duration = mMediaPlayer.duration.toLong()
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
        } finally {
            if (mMediaPlayer != null) {
                mMediaPlayer.reset()
                mMediaPlayer.release()
            }
        }
        return TimeUnit.MILLISECONDS.toSeconds(duration)
    }
}