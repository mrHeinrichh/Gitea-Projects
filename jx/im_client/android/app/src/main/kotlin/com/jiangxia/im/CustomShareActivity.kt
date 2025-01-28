package com.jiangxia.im

import android.content.Intent
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import io.sentry.Sentry
import java.io.*
import java.util.*

class CustomShareActivity : AppCompatActivity(), View.OnClickListener {
    private val key = "default_lang"

    private lateinit var sendFriendCL: ConstraintLayout

    private lateinit var sendDynamicCL: ConstraintLayout

    private lateinit var backTV: TextView

    private lateinit var imageView: ImageView

    private lateinit var coverCL: ConstraintLayout

    private lateinit var fileCL: ConstraintLayout

    private lateinit var fileImageView: ImageView

    private lateinit var fileNameTV: TextView

    private lateinit var fileSizeTV: TextView

    private lateinit var firstLine: View

    private var _uri: Uri? = null

    private var mSourceType: String = ""

    private var fileName: String = ""
    private var suffix = ""

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mPrefs = getSharedPreferences("FlutterSharedPreferences", 0)
        val language = mPrefs.getString("flutter.$key", "")
        if (language != null && language != "") {
            val string = language.substring(0, 2)
            changeLocale(string)
        }

        setContentView(R.layout.custom_share_activity)
        backTV = findViewById(R.id.tv_back)
        sendFriendCL = findViewById(R.id.cl_friend)
        sendDynamicCL = findViewById(R.id.cl_dynamic)
        imageView = findViewById(R.id.iv_share)
        coverCL = findViewById(R.id.cl_share)
        fileCL = findViewById(R.id.cl_file)
        fileImageView = findViewById(R.id.iv_file)
        fileNameTV = findViewById(R.id.tv_file_name)
        fileSizeTV = findViewById(R.id.tv_file_size)
        firstLine = findViewById(R.id.v_first)


        backTV.setOnClickListener(this)
        sendFriendCL.setOnClickListener(this)
        sendDynamicCL.setOnClickListener(this)

        val action: String? = intent.action
        val type: String? = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            val uri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
            if (uri != null) {
                _uri = uri
                if (type.contains("video")) {
                    mSourceType = "video"
                    val mMMR = MediaMetadataRetriever()
                    mMMR.setDataSource(this, _uri)
                    val bmp = mMMR.frameAtTime
                    fileCL.visibility = View.GONE
                    coverCL.visibility = View.VISIBLE
                    imageView.visibility = View.VISIBLE
                    imageView.setImageBitmap(bmp)
                } else if (type.contains("image")) {
                    mSourceType = "image"
                    fileCL.visibility = View.GONE
                    coverCL.visibility = View.GONE
                    imageView.visibility = View.VISIBLE
//                    val bmp = BitmapFactory.decodeFile(uri.path)
//                    val byteArrayOutputStream = ByteArrayOutputStream()
//                    bmp.compress(Bitmap.CompressFormat.JPEG, 10, byteArrayOutputStream)
                    val bm = comImag()
                    if (bm != null) {
                        imageView.setImageBitmap(bm)
                    }

                } else {
                    if (uri.path != null) {
                        fileCL.visibility = View.VISIBLE
                        coverCL.visibility = View.GONE
                        imageView.layoutParams.height = dp2px(68)!!
                        imageView.visibility = View.INVISIBLE
                        sendDynamicCL.visibility = View.GONE
                        _uri = uri
                        mSourceType = "file"
                        val filePath = uri.path!!
                        fileName = filePath.substring(filePath.lastIndexOf("/") + 1)
                        suffix = filePath.substring(filePath.lastIndexOf(".") + 1)
                        fileSizeTV.text = suffix
                        fileNameTV.text = fileName
                        fileImageView.setImageResource(showFileIcon())
                    }
                }
            }
        } else if (Intent.ACTION_VIEW == action && type != null) {
            val uri: Uri? = intent.data
            if (uri != null) {
                if (uri.path != null) {
                    fileCL.visibility = View.VISIBLE
                    coverCL.visibility = View.GONE
                    imageView.layoutParams.height = dp2px(68)!!
                    imageView.visibility = View.INVISIBLE
                    sendDynamicCL.visibility = View.GONE
                    _uri = uri
                    mSourceType = "file"
                    val filePath = uri.path!!
                    fileName = filePath.substring(filePath.lastIndexOf("/") + 1)
                    suffix = filePath.substring(filePath.lastIndexOf(".") + 1)
                    fileSizeTV.text = suffix
                    fileNameTV.text = fileName
                    fileImageView.setImageResource(showFileIcon())
                }
            }
        }

    }

    private fun changeLocale(language: String) {
        val locale = Locale(language)
        val config = resources.configuration
        config.setLocale(locale)
        resources.updateConfiguration(config, resources.displayMetrics)
    }

    private fun dp2px(dp: Int): Int? {
        return resources?.displayMetrics?.density?.let { (dp * it + 0.5).toInt() }
    }

    private fun showFileIcon(): Int {
        if (suffix == "doc" || suffix == "docx" || suffix == "txt") {
            return R.mipmap.ic_file_doc
        } else if (suffix == "xls" || suffix == "xlsx") {
            return R.mipmap.ic_file_xls
        } else if (suffix == "ppt" || suffix == "pptx") {
            return R.mipmap.ic_file_ppt
        } else if (suffix == "pdf") {
            return R.mipmap.ic_file_pdf
        }
        return R.mipmap.ic_file_unknow
    }


    private fun comImag(): Bitmap? {

        //将图片转换为bitmap
        val bitmapImg = BitmapFactory.decodeStream(contentResolver.openInputStream(_uri!!))

        val baos = ByteArrayOutputStream()
        bitmapImg.compress(Bitmap.CompressFormat.JPEG, 100, baos)
        if (baos.toByteArray().size / 1024 > 1024) { //判断如果图片大于1M,进行压缩避免在生成图片（BitmapFactory.decodeStream）时溢出
            baos.reset() //重置baos即清空baos
            bitmapImg.compress(Bitmap.CompressFormat.JPEG, 50, baos) //这里压缩50%，把压缩后的数据存放到baos中
        }
        var isBm: ByteArrayInputStream? = ByteArrayInputStream(baos.toByteArray())
        val newOpts = BitmapFactory.Options()
        //开始读入图片，此时把options.inJustDecodeBounds 设回true了
        newOpts.inJustDecodeBounds = true
        var bitmap = BitmapFactory.decodeStream(isBm, null, newOpts)
        newOpts.inJustDecodeBounds = false
        val w = newOpts.outWidth
        val h = newOpts.outHeight

        val hh = 800f //这里设置高度为800f
        val ww = 480f //这里设置宽度为480f
        //缩放比。由于是固定比例缩放，只用高或者宽其中一个数据进行计算即可
        var be = 1 //be=1表示不缩放
        if (w > h && w > ww) { //如果宽度大的话根据宽度固定大小缩放
            be = (newOpts.outWidth / ww).toInt()
        } else if (w < h && h > hh) { //如果高度高的话根据宽度固定大小缩放
            be = (newOpts.outHeight / hh).toInt()
        }
        if (be <= 0) be = 1
        newOpts.inSampleSize = be //设置缩放比例
        //重新读入图片，注意此时已经把options.inJustDecodeBounds 设回false了
        isBm = ByteArrayInputStream(baos.toByteArray())
        bitmap = BitmapFactory.decodeStream(isBm, null, newOpts)
        if (bitmap != null) {
            val f: File? = getFileFromMediaUri(_uri!!)
            if (f != null) {
                val bb = rotateBitmapByDegree(bitmap, getBitmapDegree(f.absolutePath))
                if (bb != null) {
                    return bb
                }
            }

        }
        return bitmap//压缩好比例大小后再进行质量压缩
    }

    fun getFileFromMediaUri(uri: Uri): File? {
        if (uri.scheme.toString().compareTo("content") == 0) {
            //val cr: ContentResolver = this.getContentResolver()
            val cursor: Cursor = contentResolver.query(uri, null, null, null, null) ?: return null
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

    fun getBitmapDegree(path: String): Int {
        var degree = 0
        try {
            // 从指定路径下读取图片，并获取其EXIF信息
            val exifInterface = ExifInterface(path)

            // 获取图片的旋转信息
            val orientation: Int = exifInterface.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> degree = 90
                ExifInterface.ORIENTATION_ROTATE_180 -> degree = 180
                ExifInterface.ORIENTATION_ROTATE_270 -> degree = 270
            }
        } catch (e: IOException) {
            Sentry.captureException(e)
            e.printStackTrace()
        }
        return degree
    }

    fun rotateBitmapByDegree(bm: Bitmap, degree: Int): Bitmap? {
        var returnBm: Bitmap? = null
        // 根据旋转角度，生成旋转矩阵
        val matrix = Matrix()
        matrix.postRotate(degree.toFloat())
        try {
            // 将原始图片按照旋转矩阵进行旋转，并得到新的图片
            returnBm = Bitmap.createBitmap(bm, 0, 0, bm.width, bm.height, matrix, true)
        } catch (e: OutOfMemoryError) {
            Sentry.captureException(e)
        }
        if (returnBm == null) {
            returnBm = bm
        }
        if (bm != returnBm) {
            bm.recycle()
        }
        return returnBm
    }

    override fun onClick(v: View?) {
        when (v!!.id) {
            R.id.tv_back -> {
                finish()
            }
            R.id.cl_friend -> {
                if (_uri != null) {
                    //val launchIntent: Intent? = packageManager.getLaunchIntentForPackage("com.jiangxia.im")
                    val launchIntent = Intent(this, MainActivity::class.java)
                    launchIntent.putExtra("share_uri", _uri)
                    launchIntent.putExtra("share_typ", 1)
                    launchIntent.putExtra("share_source_type", mSourceType)
                    if (mSourceType == "file") {
                        launchIntent.putExtra("suffix", suffix)
                        launchIntent.putExtra("file_name", fileName)
                    }
                    startActivity(launchIntent)
                }
            }
            R.id.cl_dynamic -> {
                if (_uri != null) {
                    val launchIntent = Intent(this, MainActivity::class.java)
                    launchIntent.putExtra("share_uri", _uri)
                    launchIntent.putExtra("share_typ", 2)
                    launchIntent.putExtra("share_source_type", mSourceType)
                    startActivity(launchIntent)
                }
            }
        }
    }

}