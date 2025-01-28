package com.luckyd.im.utils

import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.util.Base64
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.luckyd.im.BuildConfig
import com.luckyd.im.R

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
                    Log.i("DecryptUtils ", "Error :: ${e.stackTrace}")
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
                e.printStackTrace()
                throw RuntimeException("AES decryption error: ${e.message}")
            }
        }
    }
}