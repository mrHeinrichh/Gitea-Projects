package com.jiangxia.im.utils

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.util.Base64
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.jiangxia.im.BuildConfig
import com.jiangxia.im.R
import io.sentry.Sentry

class DecryptUtils {

    companion object {
        @RequiresApi(Build.VERSION_CODES.O)
        fun decryptData(secretKey: String, encryptedData: String?): Map<String, Any>? {

            var dataMap: Map<String, Any>? = null

            if (encryptedData != null) {
                try {
                    val decodedData = Base64.getDecoder().decode(encryptedData)

                    val decryptedData = aesDecryption(secretKey, decodedData)
                    val decryptedString = String(decryptedData)

                    val gson = Gson()
                    val mapType = object : TypeToken<Map<String, Any>>() {}.type

                    dataMap = gson.fromJson(decryptedString, mapType)
                } catch (e: Exception) {
                    Sentry.captureException(e)
                    Log.i("DecryptUtils ", "Error :: ${e.stackTrace}")
                }
            }

            return dataMap
        }

        @RequiresApi(Build.VERSION_CODES.O)
        fun decryptDataCTR(secretKey: String, encryptedData: String?): Map<String, Any>? {

            var dataMap: Map<String, Any>? = null

            if (encryptedData != null) {
                try {
                    val decodedData = Base64.getDecoder().decode(encryptedData)

                    val decryptedData = aesDecryptionCTR(secretKey, decodedData)
                    val decryptedString = String(decryptedData)
                    Log.i("DecryptUtils ", "success :: ${decryptedString}")
                    val gson = Gson()
                    val mapType = object : TypeToken<Map<String, Any>>() {}.type

                    dataMap = gson.fromJson(decryptedString, mapType)
                } catch (e: Exception) {
                    Log.i("DecryptUtils ", "Error :: ${e.toString()}")
                }
            }

            return dataMap
        }

        private fun aesDecryption(secretKey: String, encryptedData: ByteArray): ByteArray {

//            val secretKey = BuildConfig.SECRET

            try {
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                val keySpec = SecretKeySpec(secretKey.toByteArray(), "AES")

                val nonceSize = 12 // GCM nonce size is fixed at 12 bytes
                if (encryptedData.size < nonceSize) {
                    throw IllegalArgumentException("Size not matched")
                }

                val nonce = encryptedData.sliceArray(0 until nonceSize)
                val cipherText = encryptedData.sliceArray(nonceSize until encryptedData.size)

                val parameterSpec = GCMParameterSpec(128, nonce)

                cipher.init(Cipher.DECRYPT_MODE, keySpec, parameterSpec)

                return cipher.doFinal(cipherText)
            } catch (e: Exception) {
                Sentry.captureException(e)
                e.printStackTrace()
                throw RuntimeException("AES decryption error: ${e.message}")
            }
        }

        private fun aesDecryptionCTR(secretKey: String, encryptedData: ByteArray): ByteArray {
            try {
                val cipher = Cipher.getInstance("AES/CTR/PKCS7PADDING")
                val keySpec = SecretKeySpec(secretKey.toByteArray(), "AES")
                // Initialize the IV with a 16-byte zero array (as per your original code)
                val iv =
                    ByteArray(16)  // Zeroed IV array, same as [UInt8](repeating: 0, count: 16) in Swift
                val ivSpec = IvParameterSpec(iv)  // Initialization Vector for AES


                cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec)

                return cipher.doFinal(encryptedData)
            } catch (e: Exception) {
                e.printStackTrace()
                throw RuntimeException("AES decryption error: ${e.message}")
            }
        }

        fun getDecodeKey(url: String, context: Context): String {
            if (url.isEmpty() || !url.contains("secret/")) {
                return ""
            }
            val asserList: String = context.getString(R.string.assert_list)
            val assertList = asserList.split(",")
            var decodeStr = ""
            val regex = Regex("secret/[^/]+/(\\d+)/")
            val matchResult = regex.find(url)

            if (matchResult != null) {
                // Extracted number
                val result = matchResult.groupValues[1]

                val codeIndex = result.toIntOrNull()
                if (codeIndex != null && codeIndex >= 0) {
                    if (assertList.size > codeIndex) {
                        decodeStr = assertList[codeIndex]
//                      ("decodeStr 下载地址 $url 解密密钥位置：$codeIndex decodeStr:$decodeStr")
                    }
                }
            }

            return decodeStr
        }

        fun xorDecode(inputBytes: ByteArray, key: String): ByteArray {
            val keyLen = key.length
            val decodedBytes = ByteArray(inputBytes.size)

            for (i in inputBytes.indices) {
                decodedBytes[i] = (inputBytes[i].toInt() xor key[i % keyLen].code).toByte()
            }

            return decodedBytes
        }
    }
}