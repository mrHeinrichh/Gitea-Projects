package com.jiangxia.flutter_captcha

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.os.AsyncTask
import android.preference.PreferenceManager
import android.text.TextUtils
import androidx.annotation.NonNull
import com.example.test_verify.NetRequestUtils
import com.geetest.sdk.GT3ConfigBean
import com.geetest.sdk.GT3ErrorBean
import com.geetest.sdk.GT3GeetestUtils
import com.geetest.sdk.GT3Listener
import com.geetest.sdk.utils.GT3ServiceNode

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

/** FlutterCaptchaPlugin */
class FlutterCaptchaPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var activity: Activity

  companion object {
    private lateinit var channel : MethodChannel
    private var gt3GeetestUtils: GT3GeetestUtils? = null
    private var gt3ConfigBean: GT3ConfigBean? = null
    private lateinit var appContext: Context
    var phoneNo : String = ""
    var countryCode : String = ""

    fun formatBody(data :String) : String {

      val jsonObject = JSONObject(data)
      jsonObject.put("contact", phoneNo)
      jsonObject.put("country_code", countryCode)

      return jsonObject.toString()
    }
  }

  internal class RequestAPI1 : AsyncTask<Void?, Void?, JSONObject?>() {
    override fun doInBackground(vararg params: Void?): JSONObject? {
      var jsonObject: JSONObject? = null
      try {
        val result: String? =
          NetRequestUtils.requestGet("http://im-user.jxtest.net/app/api/auth/geetest/register")
        jsonObject = JSONObject(result)
      } catch (e: Exception) {
        e.printStackTrace()
      }
      return jsonObject
    }

    override fun onPostExecute(params: JSONObject?) {
      // SDK可识别格式为
      // {"success":1,"challenge":"06fbb267def3c3c9530d62aa2d56d018","gt":"019924a82c70bb123aae90d483087f94","new_captcha":true}
      gt3ConfigBean?.setApi1Json(params)
      // 继续验证
      gt3GeetestUtils?.getGeetest()
    }
  }

  internal class RequestAPI2 : AsyncTask<String?, Void?, String>() {
    override fun doInBackground(vararg params: String?): String? {
      return NetRequestUtils.requestPostByBody(
        "http://im-user.jxtest.net/app/api/auth/geetest/validate",
        params[0]?.let { formatBody(it) }
      )
    }

    override fun onPostExecute(result: String) {
      try {
        val jsonObject = JSONObject(result)
        val data = jsonObject.optString("data")
        val dataObject = JSONObject(data)
        val status = dataObject.optString("result")


        if ("success" == status) {
          gt3GeetestUtils!!.showSuccessDialog()
          channel.invokeMethod("getResult", true)
        } else {
          gt3GeetestUtils!!.showFailedDialog()
          channel.invokeMethod("getResult", false)
        }
      } catch (e: Exception) {
        e.printStackTrace()
        gt3GeetestUtils!!.showFailedDialog()
      }
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_captcha")
    channel.setMethodCallHandler(this)
    appContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "verify" -> {
        try {
          phoneNo = call.argument<String>("phoneNo").toString()
          countryCode = call.argument<String>("countryCode").toString()
          gt3GeetestUtils?.startCustomFlow()
        }catch (e: java.lang.Exception){
          println(e)
        }

      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    try {
      captchaInit()
    }catch (e: java.lang.Exception){
      println(e)
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }

  private fun captchaInit() {
    
    gt3GeetestUtils = GT3GeetestUtils(activity)
    // 配置 GT3ConfigBean 文件, 也可在调用 startCustomFlow 方法前处理
    gt3ConfigBean = GT3ConfigBean()
    // 设置验证模式, 1: bind, 2: unbind
    gt3ConfigBean!!.pattern = 1
    // 设置回调监听
    gt3ConfigBean!!.listener = object : GT3Listener() {
      /**
       * 验证码加载完成
       * @param duration 加载时间和版本等信息，为json格式
       */
      override fun onDialogReady(duration: String) {
      }

      /**
       * 图形验证结果回调
       * @param code 1为正常 0为失败
       */
      override fun onReceiveCaptchaCode(code: Int) {
      }

      /**
       * 自定义api2回调
       * @param result，api2请求上传参数
       */
      override fun onDialogResult(result: String) {
        // 开启自定义api2逻辑
        RequestAPI2().execute(result)
      }

      /**
       * 统计信息，参考接入文档
       * @param result
       */
      override fun onStatistics(result: String) {
      }

      /**
       * 验证码被关闭
       * @param num 1 点击验证码的关闭按钮来关闭验证码, 2 点击屏幕关闭验证码, 3 点击返回键关闭验证码
       */
      override fun onClosed(num: Int) {
      }

      /**
       * 验证成功回调
       * @param result
       */
      override fun onSuccess(result: String) {
      }

      /**
       * 验证失败回调
       * @param errorBean 版本号，错误码，错误描述等信息
       */
      override fun onFailed(errorBean: GT3ErrorBean) {
      }

      /**
       * 自定义api1回调
       */
      override fun onButtonClick() {
        RequestAPI1().execute()
      }

      override fun actionBeforeDialogShow(dialog: Dialog) {
      }

      override fun actionAfterDialogShow(dialog: Dialog) {
      }
    }
    gt3GeetestUtils!!.init(gt3ConfigBean)
  }
}
