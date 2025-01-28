// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/request_data.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:synchronized/synchronized.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/code_define.dart';

import 'package:http/http.dart' as http;

HttpClient getHttpClient({int timeout = 10}) {
  const trustSelfSigned = true;
  HttpClient httpClient = HttpClient()
    ..connectionTimeout = Duration(seconds: timeout)
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => trustSelfSigned);
  return httpClient;
}

const _headers = {'Content-Type': 'application/x-www-form-urlencoded'};

class Request {
  static const String eventNotLogin = "eventNotLogin";
  static EventDispatcher event = EventDispatcher();

  static const String error = "error";

  static const String methodTypeGet = "get";
  static const String methodTypePost = "post";

  static const String methodTypePut = "put";
  static const int maxAttempts = 3;

  static String language = objectMgr.langMgr.currLocale.languageCode;
  static Lock lock = Lock();

  static String token = "";
  static int _flag = 0;
  static int _flag1 = 0;

  // 标识
  static int get flag {
    return _flag;
  }

  static set flag(int v) {
    _flag = v;
    _flag1 = 0;
  }

  static set flag1(int v) {
    _flag1 = v;
  }

  /// 发送请求
  /// attempts 尝试次数
  /// maxTry 最大尝试次数
  static Future<HttpResponseBean> send(
    String apiPath, {
    String method = Request.methodTypeGet,
    dynamic data = const {},
    Map<String, dynamic> headers = _headers,
    int attempts = 1,
    int maxTry = maxAttempts,
    bool cipher = false,
    bool printBody = true,
  }) async {
    String temptoken = token;
    //token不能空，不然怎么加密
    cipher = cipher && !temptoken.isEmpty;
    var __flag = _flag;
    var httpClient = getHttpClient();
    int startTime = DateTime.now().millisecondsSinceEpoch;
    Uri uri = Uri.parse(Config().host + apiPath);

    // if (!url.contains("${Request.env.mainDomain}")) {
    //   uri = Uri.parse(temptoken.isEmpty ? url : "$url?token=$temptoken");
    // } else {
    //   uri = Uri.parse(url);
    // }
    dynamic body;
    try {
      headers["lang"] = language;
      HttpClientRequest? request;

      if (method == Request.methodTypePost) {
        request = await httpClient.postUrl(uri);
      } else if (method == Request.methodTypePut) {
        request = await httpClient.putUrl(uri);
      } else if (method == Request.methodTypeGet) {
        request = await httpClient.getUrl(uri);
      }

      if (request == null) {
        return await HttpResponseBean({"code": -1}, apiPath, data);
      }
      if (cipher) request.headers.add('cipher', '');
      setHeader(request, data);
      if ((method == Request.methodTypePost ||
              method == Request.methodTypePut) &&
          data != null) {
        var parts = [];
        data.forEach((key, value) {
          parts.add('${Uri.encodeQueryComponent(key)}='
              '${Uri.encodeQueryComponent(value.toString())}');
        });
        parts.add('t=${startTime ~/ 1000}');
        var formData = parts.join('&');
        if (formData.isNotEmpty) {
          if (cipher)
            formData = aseEncode(formData, makeMD5(temptoken).substring(0, 16));
          request.write(formData);
        }
      }

      if (printBody) {
        pdebug('GET URL: ${uri.toString()}');
        pdebug('GET HEADER: ${request.headers}');
        pdebug('GET BODY: $data');
      }

      var rep = await request.close();
      int status = rep.statusCode;
      var utf8Stream = rep.transform(const Utf8Decoder());
      body = await utf8Stream.join();
      if (rep.headers.value("cipher") == "cipher") {
        body = aseDecode(body, makeMD5(temptoken).substring(0, 16));
      }

      if (printBody) {
        pdebug('GET URL: ${uri.toString()}');
        pdebug('GET RESPONSE: ${body}');
      }
      switch (status) {
        case 200:
          break;
        case 500:
          body = {'code': CodeDefine.codeServiceCrash, 'msg': body};
          break;
        case 403:
          pdebug("$apiPath 需要重新鉴权");
          body = {'code': CodeDefine.codeServiceCrash, 'msg': body};
          if (__flag == _flag && _flag1 == 0) {
            pdebug(
                '===========================Request.eventNotLogin=================');
            event.event(event, Request.eventNotLogin);
          }
          break;
        case 404:
          pdebug("$apiPath 路径不存在");
          body = {'code': CodeDefine.codeServiceCrash, 'msg': body};
          break;
        default:
          body = {"code": CodeDefine.codeHttpDefault, "msg": "$body"};
          break;
      }
    } catch (e) {
      // 异常转化成返回值
      return await _onHttpError(
          e, apiPath, method, data, headers, attempts, maxTry, cipher);
    } finally {
      int endTime = DateTime.now().millisecondsSinceEpoch;
      pdebug('requert url:${uri.toString()}');
      pdebug("body:$body  ${endTime - startTime}");
      httpClient.close();
    }
    if (apiPath.contains("${Config().host}")) {
      if (json.decode(body)["result_dummy"] != null) {
        if (json.decode(body)["result_dummy"].length != 0) {
          return await HttpResponseBean(
              json.encode(json.decode(body)["result_dummy"]), apiPath, data);
        }
        if (json.decode(body)["message"] == "user not exist") {
          return await HttpResponseBean(body, apiPath, data);
        }
      }
    }
    return await HttpResponseBean(body, apiPath, data);
  }

  static Future<ResponseData> doPost(
    String apiPath, {
    dynamic data,
    int attempts = 1,
    int refreshAttempts = 1,
    int maxTry = maxAttempts,
    bool cipher = false,
    bool printBody = false,
    bool needToken = true,
    bool offlineProcess = false,
    bool refreshToken = false,
    int timeoutInSeconds = 10,
  }) async {
    ///生成requestData的Object
    final RequestData requestData = RequestData(
      apiPath,
      data,
      attempts,
      refreshAttempts,
      maxTry,
      cipher,
      printBody,
      needToken,
      methodTypePost,
    );

    ///没有token
    if (token.isEmpty && cipher) {
      event.event(event, Request.eventNotLogin);
      throw AuthException('没有权限');
    } else {
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final httpClient = getHttpClient(timeout: timeoutInSeconds);
      final Uri uri = Uri.parse(Config().host + apiPath);
      dynamic body;
      String appRequestId = '';
      try {
        HttpClientRequest request = await httpClient.postUrl(uri);

        appRequestId =
            setHeader(request, data, cipher: cipher, needToken: needToken);

        String jsonData = "";
        if (data != null) {
          jsonData = json.encode(data);
          if (cipher) {
            String aesJsonData =
                aseEncode(jsonData, makeMD5(token).substring(0, 16));
            request.write(aesJsonData);
          } else {
            request.write(jsonData);
          }
        }

        if (printBody) {
          pdebug('POST URL: ${uri.toString()}');
          pdebug('POST HEADER: ${request.headers}');
          pdebug('POST BODY: ${jsonData}');
        }

        var rep = await request.close();
        var utf8Stream = rep.transform(const Utf8Decoder());
        body = await utf8Stream.join();
        if (rep.headers.value("cipher") == "cipher") {
          body = aseDecode(body, makeMD5(token).substring(0, 16));
        }

        if (printBody) {
          pdebug('POST URL: ${uri.toString()}');
          pdebug('POST RESPONSE: ${body}');
        }

        ///response处理
        return await statusCodeProcess(rep, body, requestData);
      } catch (e) {
        pdebug('Error from doPost: $e');
        if (e is ArgumentError && Config().host == '') {
          throw NetworkException(localized(waitingForNetworkConnection));
        }
        if (attempts >= maxTry) {
          statusJWTProcess(e);
        }
        if (e is AppException) {
          // 到达服务器时候的错误
          rethrow;
        } else {
          // http请求错误
          if (attempts >= maxTry) {
            throw NetworkException(
                localized(connectionFailedPleaseCheckTheNetwork));
          }
          attempts++;
          return doPost(
            apiPath,
            data: data,
            attempts: attempts,
            refreshAttempts: refreshAttempts,
            maxTry: maxTry,
            cipher: cipher,
            printBody: printBody,
            needToken: needToken,
            offlineProcess: offlineProcess,
          );
        }
      } finally {
        int endTime = DateTime.now().millisecondsSinceEpoch;
        pdebug(
            'request url:${uri.toString()} in ${endTime - startTime} millis (APP-REQUEST-ID: "$appRequestId")');
        httpClient.close();
      }
    }
  }

  static Future<ResponseData> doGet(
    String apiPath, {
    dynamic data,
    int attempts = 1,
    int refreshAttempts = 1,
    int maxTry = maxAttempts,
    bool cipher = false,
    bool printBody = true,
    bool needToken = true,
    bool offlineProcess = false,
  }) async {
    ///生成requestData的Object
    final RequestData requestData = RequestData(
      apiPath,
      data,
      attempts,
      refreshAttempts,
      maxTry,
      cipher,
      printBody,
      needToken,
      methodTypeGet,
    );

    ///没有token
    if (token.isEmpty && cipher) {
      event.event(event, Request.eventNotLogin);
      throw AuthException('没有权限');
    } else {
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final httpClient = getHttpClient();
      Uri uri = Uri.parse(Config().host + apiPath);
      dynamic body;
      String appRequestId = '';
      try {
        if (data != null) {
          uri = Uri.parse('${uri.toString()}${getParam(data)}');
        }
        HttpClientRequest request = await httpClient.getUrl(uri);

        ///设置 Header
        appRequestId =
            setHeader(request, data, cipher: cipher, needToken: needToken);

        var rep = await request.close();

        var utf8Stream = rep.transform(const Utf8Decoder());
        body = await utf8Stream.join();
        if (rep.headers.value("cipher") == "cipher") {
          body = aseDecode(body, makeMD5(token).substring(0, 16));
        }

        if (printBody) {
          pdebug('url:${uri.toString()} data = $data');
          pdebug('body: $body');
        }

        ///response处理
        return await statusCodeProcess(rep, body, requestData);
      } catch (e) {
        pdebug('Error from doGet: $e');
        if (e is ArgumentError && Config().host == '') {
          throw NetworkException(
              localized(connectionFailedPleaseCheckTheNetwork));
        }
        if (attempts >= maxTry) {
          statusJWTProcess(e);
        }
        if (e is AppException) {
          // 到达服务器时候的错误
          rethrow;
        } else {
          // http请求错误
          if (attempts >= maxTry) {
            throw NetworkException(
                localized(connectionFailedPleaseCheckTheNetwork));
          }
          attempts++;
          return doGet(
            apiPath,
            data: data,
            attempts: attempts,
            refreshAttempts: refreshAttempts,
            maxTry: maxTry,
            cipher: cipher,
            printBody: printBody,
            needToken: needToken,
          );
        }
      } finally {
        int endTime = DateTime.now().millisecondsSinceEpoch;
        pdebug(
            'request url:${uri.toString()} in ${endTime - startTime} millis (APP-REQUEST-ID: "$appRequestId")');
        httpClient.close();
      }
    }
  }

  static AppException _onRequestError(int status) {
    switch (status) {
      case 500:
        return RequestException('服务器崩溃');
      case 401:
        event.event(event, Request.eventNotLogin);
        return AuthException('没有权限');
      case 403:
        return RequestException('禁止访问网络');
      case 404:
        return RequestException('请求地址不存在');
      default:
        return RequestException('未知请求错误($status)');
    }
  }

  /// doGet获取param
  static String getParam(Map<String, dynamic> param) {
    /// get request的param
    String urlParam = '';
    if (param.isEmpty) {
      return '';
    }
    param.forEach((key, value) {
      if (key == param.keys.first) {
        urlParam += '?${key.toString()}=${value.toString()}';
      } else {
        urlParam += '&${key.toString()}=${value.toString()}';
      }
    });
    return urlParam;
  }

  /// 请求发生错误
  static dynamic _onHttpError(e, String url, String method, dynamic data,
      dynamic headers, int attempts, int maxTry, bool cipher) async {
    if (attempts >= maxTry) {
      pdebug('requert error:$url  data: $data');
      return await HttpResponseBean(
          {"code": -1, 'msg': localized(connectionFailedPleaseCheckTheNetwork)},
          url,
          data);
    }
    attempts++;
    return await send(url,
        method: method,
        data: data,
        headers: headers,
        attempts: attempts,
        maxTry: maxTry,
        cipher: cipher);
  }

  static Future<bool> _onMessageError(
    int code,
    String message,
    dynamic data,
  ) async {
    switch (code) {
      case ErrorCodeConstant.STATUS_JWT_EXPIRED:
        return lock.synchronized(() async {
          if (objectMgr.loginMgr.account != null &&
              !objectMgr.loginMgr.account!.isExpired()) return true;
          try {
            final bool tokenRefreshed = await tokenRefresh();
            if (tokenRefreshed) {
              return true;
            } else {
              //获取不到新的token
              objectMgr.userMgr.popLogoutDialog(displayMessage: message);
              throw CodeException(code, message, data);
            }
          } catch (e) {
            throw CodeException(code, message, data);
          }
        });
      case ErrorCodeConstant.STATUS_JWT_INVALID:
      case ErrorCodeConstant.STATUS_SESSION_INVALID:
      case ErrorCodeConstant.STATUS_ERR_PARSING_KEY:
      case ErrorCodeConstant.STATUS_ERR_SIGNING_METHOD:
      case ErrorCodeConstant.STATUS_REFRESH_TOKEN_FAILED:
        final String errorMessage = localized(unexpectedError);
        objectMgr.userMgr.popLogoutDialog(displayMessage: errorMessage);
        throw CodeException(code, message, data);
      case ErrorCodeConstant.STATUS_USER_LOGGED_IN_ANOTHER_DEVICE:
        objectMgr.userMgr.popLogoutDialog();
        throw CodeException(code, message, data);
      default:
        throw CodeException(code, message, data);
    }
  }

  ///设置Header
  static String setHeader(
    HttpClientRequest req,
    dynamic data, {
    bool cipher = false,
    bool needToken = true,
  }) {
    Map<String, dynamic> headers = {};
    if (cipher) headers['cipher'] = '';
    if (needToken) headers['token'] = objectMgr.loginMgr.account?.token;
    headers["lang"] = language;
    headers["Content-Type"] = "application/json; charset=utf-8";
    headers["Keep-Alive"] = "timeout=60";
    headers["Channel"] = Config().orgChannel;
    headers["Platform"] = appVersionUtils.getDownloadPlatform() ?? '';
    headers["Client-Version"] = appVersionUtils.currentAppVersion;

    // 请求幂等性
    final requestIdKey = 'APP-Request-ID';
    int now = DateTime.now().microsecondsSinceEpoch;
    if (req.headers.value(requestIdKey) == null) {
      req.headers.add(requestIdKey, '$now${data.hashCode}');
    }

    headers.forEach((key, value) {
      req.headers.add(key, value);
    });
    return '$now${data.hashCode}';
  }

  ///处理status code
  static Future<ResponseData> statusCodeProcess(
      var rep, var body, RequestData requestData) async {
    int status = rep.statusCode;
    if (status == 200) {
      ResponseData responseData = ResponseData.fromJson(json.decode(body));
      if (responseData.success()) {
        return responseData;
      } else {
        if (requestData.refreshAttempts >= maxAttempts) {
          throw CodeException(ErrorCodeConstant.STATUS_GENERATE_JWT_FAILED,
              "Failed to refresh token", null);
        }

        ///Token过期叫方法
        final tokenExpired = await _onMessageError(
          responseData.code,
          responseData.message,
          responseData.data,
        );
        if (tokenExpired) {
          requestData.refreshAttempts++;

          ///判断请求的方法
          if (requestData.methodType == methodTypePost) {
            return doPost(
              requestData.apiPath,
              data: requestData.data,
              attempts: requestData.attempts,
              refreshAttempts: requestData.refreshAttempts,
              maxTry: requestData.maxTry,
              cipher: requestData.cipher,
              printBody: requestData.printBody,
              needToken: requestData.needToken,
            );
          } else if (requestData.methodType == methodTypeGet) {
            return doGet(
              requestData.apiPath,
              data: requestData.data,
              attempts: requestData.attempts,
              refreshAttempts: requestData.refreshAttempts,
              maxTry: requestData.maxTry,
              cipher: requestData.cipher,
              printBody: requestData.printBody,
              needToken: requestData.needToken,
            );
          } else {
            throw RequestException('请求不合法');
          }
        } else {
          throw AuthException(responseData.code.toString());
        }
      }
    } else {
      // 到达服务器时候的错误
      throw _onRequestError(status);
    }
  }

  /// 异常,抛jwt处理
  static void statusJWTProcess(var e) async {
    /// {"code":30125,"message":"刷新JWT失败","data":{}}
    bool jwtErr1 = e.toString().contains('30125');
    // bool jwtErr11 = e.toString().contains('刷新JWT失败');

    /// {"code":30002,"message":"JWT已过期","data":{}}
    bool jwtErr2 = e.toString().contains('30002');
    // bool jwtErr22 = e.toString().contains('JWT已过期');

    if (jwtErr1 || jwtErr2) {
      objectMgr.userMgr
          .popLogoutDialog(displayMessage: "您的该账号正在其他设备登录,为确保安全请重新登录!");
    }
  }
}

Future<String> getTextFileFromUrl(String fileUrl) async {
  try {
    final response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode == 200)
      return response.body;
    else
      throw Exception('Failed to load text file from $fileUrl');
  } catch (e) {
    throw Exception('Failed to load text file from $fileUrl');
  }
}
