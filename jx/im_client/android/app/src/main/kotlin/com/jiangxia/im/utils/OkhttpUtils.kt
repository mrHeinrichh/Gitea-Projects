package com.jiangxia.im.utils

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.IOException

class OkhttpUtils {

    companion object {
        private fun downloadImageAsBytes(url: String): ByteArray? {
            val client = OkHttpClient()

            val request = Request.Builder()
                .url(url)
                .build()

            try {
                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    // Return the byte array from the response body
                    return response.body?.bytes()
                } else {
                    println("Failed to download data. HTTP code: ${response.code}")
                }
            } catch (e: IOException) {
                e.printStackTrace()
                println("Error downloading data: ${e.message}")
            }

            return null
        }

        fun parseAndDownloadImage(imageUrl: String, context: Context): String? {
            if (imageUrl.isNotEmpty()) {
                if (imageUrl.contains("secret/")) {
                    val decodeStr = DecryptUtils.getDecodeKey(imageUrl, context)
                    if (decodeStr.isNotEmpty()) {
                        ///解析数据
                        val imageData = downloadImageAsBytes(imageUrl)
                        if (imageData != null) {
                            val decryptedData = DecryptUtils.xorDecode(imageData, decodeStr)
                            val baseDir = File(context.filesDir.parentFile, "app_flutter/download")
                            val regex = Regex("(/Image/.+)")
                            val matchResult = regex.find(imageUrl)
                            val extractedPath = matchResult?.value
                            val fullPath = extractedPath?.let { File(baseDir, it).absolutePath }

                            if (!fullPath.isNullOrEmpty()) {
                                val outputFile = File(fullPath)
                                // 检查文件是否已经存在
                                if (outputFile.exists()) {
                                    // 如果文件已存在，直接返回文件路径
                                    return extractedPath
                                } else {
                                    // 如果文件不存在，则创建目录并写入文件
                                    outputFile.parentFile?.mkdirs()
                                    outputFile.writeBytes(decryptedData)
                                    return extractedPath
                                }
                            }
                        }
                    }
                }
            }
            return null
        }
    }
}