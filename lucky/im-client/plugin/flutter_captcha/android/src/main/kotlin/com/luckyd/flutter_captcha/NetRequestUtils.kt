package com.example.test_verify

import okhttp3.*
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException

class NetRequestUtils {
    private val TAG = "NetRequestUtils"

    companion object {
        private var okHttpClient: OkHttpClient? = null
        fun requestGet(urlString: String): String? {
            okHttpClient = OkHttpClient()

            val urlBuilder: HttpUrl.Builder = HttpUrl.parse(urlString)!!.newBuilder()
            urlBuilder.addQueryParameter("t", System.currentTimeMillis().toString())

            val request: Request = Request.Builder()
                .url(urlBuilder.build())
                .build()

            try {
                val response: Response = okHttpClient!!.newCall(request).execute()
                return response.body()?.string()
            } catch (e: IOException) {
                e.printStackTrace()
            }
            return null
        }

        fun requestPostByForm(url: String?, param: String?): String? {
            val urlBuilder = HttpUrl.parse(url!!)!!.newBuilder()
            urlBuilder.addQueryParameter("t", System.currentTimeMillis().toString() + "")
            val mediaType = MediaType.parse("application/x-www-form-urlencoded")
            val requestBody: RequestBody =
                RequestBody.create(mediaType, NetRequestUtils.jsonToForm(param!!))
            val request = Request.Builder()
                .post(requestBody)
                .url(urlBuilder.build())
                .build()
            try {
                val response = okHttpClient!!.newCall(request).execute()
                return response.body()!!.string()
            } catch (e: IOException) {
                e.printStackTrace()
            }
            return null
        }

        fun requestPostByBody(url: String?, param: String?): String? {
            val urlBuilder = HttpUrl.parse(url!!)!!.newBuilder()
//            urlBuilder.addQueryParameter("t", System.currentTimeMillis().toString() + "")

            val mediaType = MediaType.parse("application/json")
            val requestBody: RequestBody = RequestBody.create(mediaType, param!!)

            val request = Request.Builder()
                .post(requestBody)
                .url(urlBuilder.build())
                .build()

            try {
                val response = okHttpClient!!.newCall(request).execute()
                return response.body()!!.string()
            } catch (e: IOException) {
                e.printStackTrace()
            }
            return null
        }

        private val GEETEST_VALIDATE = "geetest_validate"
        private val GEETEST_SECCODE = "geetest_seccode"
        private val GEETEST_CHALLENGE = "geetest_challenge"

        private fun jsonToForm(param: String): String? {
            try {
                val jsonObject = JSONObject(param)
                val seccode = jsonObject.getString(GEETEST_SECCODE)
                val validate = jsonObject.getString(GEETEST_VALIDATE)
                val challenge = jsonObject.getString(GEETEST_CHALLENGE)
                return "$GEETEST_VALIDATE=$validate&$GEETEST_SECCODE=$seccode&$GEETEST_CHALLENGE=$challenge"
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            return null
        }
    }




}