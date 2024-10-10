// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/managers/retry_mgr.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/offline_retry/retry_parameter.dart';
import 'package:jxim_client/utils/net/request_data.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:synchronized/synchronized.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/code_define.dart';

import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';

HttpClient getHttpClient() {
  const trustSelfSigned = true;
  HttpClient httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => trustSelfSigned);
  return httpClient;
}

class CustomRequest {
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
    String method = CustomRequest.methodTypeGet,
    dynamic data = const {},
    Map<String, dynamic>? headers,
    int attempts = 1,
    int maxTry = maxAttempts,
    bool printBody = true,
  }) async {
    if (Config().host == '') {
      throw NetworkException(localized(waitingForNetworkConnection));
    }
    //token不能空，不然怎么加密
    var flag = _flag;
    var httpClient = getHttpClient();
    int startTime = DateTime.now().millisecondsSinceEpoch;
    Uri uri = Uri.parse(Config().host + apiPath);

    dynamic body;
    try {
      headers ??= {};
      headers.addAll({'lang': language});
      HttpClientRequest? request;

      if (method == CustomRequest.methodTypePost) {
        request = await httpClient.postUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request send timeout'));
      } else if (method == CustomRequest.methodTypePut) {
        request = await httpClient.putUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request send timeout'));
      } else if (method == CustomRequest.methodTypeGet) {
        request = await httpClient.getUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request send timeout'));
      }

      if (request == null) {
        return HttpResponseBean({"code": -1}, apiPath, data);
      }
      setHeader(request, data);
      if ((method == CustomRequest.methodTypePost ||
              method == CustomRequest.methodTypePut) &&
          data != null) {
        var parts = [];
        data.forEach((key, value) {
          parts.add('${Uri.encodeQueryComponent(key)}='
              '${Uri.encodeQueryComponent(value.toString())}');
        });
        parts.add('t=${startTime ~/ 1000}');
        var formData = parts.join('&');
        if (formData.isNotEmpty) {
          request.write(formData);
        }
      }

      if (printBody) {
        pdebug('GET URL: ${uri.toString()}');
        pdebug('GET HEADER: ${request.headers}');
        pdebug('GET BODY: $data');
      }

      var rep = await request.close().timeout(const Duration(seconds: 10),
          onTimeout: () =>
              throw TimeoutException('Request send close timeout'));
      int status = rep.statusCode;
      var utf8Stream = rep.transform(const Utf8Decoder());
      body = await utf8Stream.join();

      if (printBody) {
        pdebug('GET URL: ${uri.toString()}');
        pdebug('GET RESPONSE: $body');
      }
      switch (status) {
        case HttpStatus.ok:
          break;
        case HttpStatus.internalServerError:
          body = {
            'code': CodeDefine.codeServiceCrash,
            'msg': body,
            "status": status,
          };
          break;
        case HttpStatus.forbidden:
          pdebug("$apiPath 需要重新鉴权");
          body = {
            'code': CodeDefine.codeServiceCrash,
            'msg': body,
            "status": status,
          };
          if (flag == _flag && _flag1 == 0) {
            pdebug(
              '===========================Request.eventNotLogin=================',
            );
            event.event(event, CustomRequest.eventNotLogin);
          }
          break;
        case HttpStatus.notFound:
          pdebug("$apiPath 接口路由不存在");
          body = {
            'code': CodeDefine.codeServiceCrash,
            'msg': body,
            "status": status,
          };
          break;
        default:
          pdebug("$apiPath 其他异常，不一样是网络异常 status:$status");
          body = {
            "code": CodeDefine.codeHttpDefault,
            "msg": "$body",
            "status": status,
          };
          debugInfo.printErrorStack(
            "异常地址:$apiPath,异常状态:$status",
            'null',
            toast: false,
          );
          break;
      }
    } catch (e) {
      pdebug('send error===============================e:${e.runtimeType}');
      if (e is TimeoutException) {
        rethrow;
      }
      if (e is UnsupportedError) {
        rethrow;
      }
      if (e is HttpException) {
        rethrow;
      }
      if (e is SocketException) {
        rethrow;
      }
      // 异常转化成返回值
      return await _onHttpError(
        e,
        apiPath,
        method,
        data,
        headers,
        attempts,
        maxTry,
      );
    } finally {
      int endTime = DateTime.now().millisecondsSinceEpoch;
      pdebug('requert url:${uri.toString()}');
      pdebug("body:$body  ${endTime - startTime}");
      httpClient.close();
    }
    if (apiPath.contains(Config().host)) {
      if (json.decode(body)["result_dummy"] != null) {
        if (json.decode(body)["result_dummy"].length != 0) {
          return HttpResponseBean(
            json.encode(json.decode(body)["result_dummy"]),
            apiPath,
            data,
          );
        }
        if (json.decode(body)["message"] == "user not exist") {
          return HttpResponseBean(body, apiPath, data);
        }
      }
    }
    return HttpResponseBean(body, apiPath, data);
  }

  static Future<ResponseData> doPost(
    String apiPath, {
    dynamic data,
    int attempts = 1,
    int refreshAttempts = 1,
    int maxTry = maxAttempts,
    bool printBody = false,
    bool needToken = true,
    bool offlineProcess = false,
    bool refreshToken = false,
    RetryParameter? retryParameter,
  }) async {
    if (Config().host == '') {
      throw NetworkException(localized(waitingForNetworkConnection));
    }

    ///生成requestData的Object
    final RequestData requestData = RequestData(
      apiPath,
      data: data,
      attempts: attempts,
      refreshAttempts: refreshAttempts,
      maxTry: maxTry,
      printBody: printBody,
      needToken: needToken,
      methodType: methodTypePost,
    );

    if (retryParameter != null) {
      if (!objectMgr.requestFunctionMap!
          .containsCallback(retryParameter.callbackFunctionName)) {
        throw ArgumentError(
            'Callback function ${retryParameter.callbackFunctionName} is not registered in RequestFunctionMap');
      }
      int uuid = RetryMgr.generateNumericUUID();
      requestQueue.addRetry(
          requestData.apiPath,
          methodTypePost,
          retryParameter.callbackFunctionName,
          retryParameter.expireTime,
          retryParameter.isReplaced,
          requestData,
          uuid);
      return ResponseData()
        ..message = RetryMgr.RETRY_PROCESS
        ..code = 0
        ..data = {"uuid": uuid};
    } else {
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final httpClient = getHttpClient();
      final Uri uri = Uri.parse(Config().host + apiPath);
      dynamic body;
      String appRequestId = '';
      try {
        HttpClientRequest request = await httpClient.postUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request doPost timeout'));

        appRequestId = setHeader(request, data, needToken: needToken);

        String jsonData = "";
        if (data != null) {
          jsonData = json.encode(data);
          request.write(jsonData);
        }

        if (printBody) {
          pdebug('POST URL: ${uri.toString()}');
          pdebug('POST HEADER: ${request.headers}');
          pdebug('POST BODY: $jsonData');
        }

        var rep = await request.close().timeout(const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Request doPost close timeout'));
        var utf8Stream = rep.transform(const Utf8Decoder());
        body = await utf8Stream.join();

        if (printBody) {
          pdebug('POST URL: ${uri.toString()}');
          pdebug('POST RESPONSE: $body');
        }

        ///response处理
        return await statusCodeProcess(rep, body, requestData);
      } catch (e) {
        pdebug('doPost error===============================e:${e.runtimeType}');
        if (e is TimeoutException) {
          rethrow;
        }
        if (e is UnsupportedError) {
          rethrow;
        }
        if (e is HttpException) {
          rethrow;
        }
        if (e is SocketException) {
          rethrow;
        }
        if (e is ArgumentError && Config().host == '') {
          throw NetworkException(localized(waitingForNetworkConnection));
        }
        if (attempts >= maxTry) {
          statusJWTProcess(e);
        }
        if (e is AppException) {
          if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST ||
              e.getPrefix() == ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST ||
              e.getPrefix() == ErrorCodeConstant.STATUS_NOT_IN_CHAT) {
            return ResponseData(
              code: e.getPrefix(),
              message: "failed",
              data: {
                'success': false,
              },
            );
          }
          // 到达服务器时候的错误
          rethrow;
        } else {
          // http请求错误
          if (attempts >= maxTry) {
            throw NetworkException(
              localized(connectionFailedPleaseCheckTheNetwork),
            );
          }
          await Future.delayed(Duration(milliseconds: 100 * attempts));
          attempts++;
          return doPost(
            apiPath,
            data: data,
            attempts: attempts,
            refreshAttempts: refreshAttempts,
            maxTry: maxTry,
            printBody: printBody,
            needToken: needToken,
            offlineProcess: offlineProcess,
          );
        }
      } finally {
        int endTime = DateTime.now().millisecondsSinceEpoch;
        pdebug(
          'request url:${uri.toString()} in ${endTime - startTime} millis (APP-REQUEST-ID: "$appRequestId")',
        );
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
    bool printBody = true,
    bool needToken = true,
    bool offlineProcess = false,
    RetryParameter? retryParameter,
  }) async {
    if (Config().host == '') {
      throw NetworkException(localized(waitingForNetworkConnection));
    }

    ///生成requestData的Object
    final RequestData requestData = RequestData(
      apiPath,
      data: data,
      attempts: attempts,
      refreshAttempts: refreshAttempts,
      maxTry: maxTry,
      printBody: printBody,
      needToken: needToken,
      methodType: methodTypeGet,
    );

    if (retryParameter != null) {
      if (!objectMgr.requestFunctionMap!
          .containsCallback(retryParameter.callbackFunctionName)) {
        throw ArgumentError(
            'Callback function ${retryParameter.callbackFunctionName} is not registered in RequestFunctionMap');
      }
      int uuid = RetryMgr.generateNumericUUID();
      requestQueue.addRetry(
          requestData.apiPath,
          methodTypeGet,
          retryParameter.callbackFunctionName,
          retryParameter.expireTime,
          retryParameter.isReplaced,
          requestData,
          uuid);
      return ResponseData()
        ..message = RetryMgr.RETRY_PROCESS
        ..code = 0
        ..data = {"uuid": uuid};
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
        HttpClientRequest request = await httpClient.getUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request get timeout'));

        ///设置 Header
        appRequestId = setHeader(request, data, needToken: needToken);

        var rep = await request.close().timeout(const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Request get close timeout'));

        var utf8Stream = rep.transform(const Utf8Decoder());
        body = await utf8Stream.join();

        if (printBody) {
          pdebug('url:${uri.toString()} data = $data');
          pdebug('body: $body');
        }

        ///response处理
        return await statusCodeProcess(rep, body, requestData);
      } catch (e) {
        pdebug('doGet error===============================e:${e.runtimeType}');
        if (e is TimeoutException) {
          rethrow;
        }
        if (e is UnsupportedError) {
          rethrow;
        }
        if (e is HttpException) {
          rethrow;
        }
        if (e is SocketException) {
          rethrow;
        }
        if (e is ArgumentError && Config().host == '') {
          throw NetworkException(
            localized(connectionFailedPleaseCheckTheNetwork),
          );
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
              localized(connectionFailedPleaseCheckTheNetwork),
            );
          }
          await Future.delayed(Duration(milliseconds: 100 * attempts));
          attempts++;
          return doGet(
            apiPath,
            data: data,
            attempts: attempts,
            refreshAttempts: refreshAttempts,
            maxTry: maxTry,
            printBody: printBody,
            needToken: needToken,
          );
        }
      } finally {
        int endTime = DateTime.now().millisecondsSinceEpoch;
        pdebug(
          'request url:${uri.toString()} in ${endTime - startTime} millis (APP-REQUEST-ID: "$appRequestId")',
        );
        httpClient.close();
      }
    }
  }

  static AppException _onRequestError(int status) {
    switch (status) {
      case 500:
        return RequestException('服务器崩溃');
      case 401:
        event.event(event, CustomRequest.eventNotLogin);
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
  static dynamic _onHttpError(
    e,
    String url,
    String method,
    dynamic data,
    dynamic headers,
    int attempts,
    int maxTry,
  ) async {
    if (attempts >= maxTry) {
      pdebug('requert error:$url  data: $data');
      return HttpResponseBean(
        {"code": -1, 'msg': localized(connectionFailedPleaseCheckTheNetwork)},
        url,
        data,
      );
    }
    attempts++;
    return await send(
      url,
      method: method,
      data: data,
      headers: headers,
      attempts: attempts,
      maxTry: maxTry,
    );
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
    bool needToken = true,
  }) {
    Map<String, dynamic> headers = {};
    if (needToken) headers['token'] = objectMgr.loginMgr.account?.token;
    headers["lang"] = language;
    headers["Content-Type"] = "application/json; charset=utf-8";
    headers["Keep-Alive"] = "timeout=60";
    headers["Channel"] = Config().orgChannel;
    headers["Platform"] = appVersionUtils.getDownloadPlatform() ?? '';
    headers["Client-Version"] = appVersionUtils.currentAppVersion;

    // 请求幂等性
    const requestIdKey = 'APP-Request-ID';
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
    var rep,
    var body,
    RequestData requestData,
  ) async {
    int status = rep.statusCode;
    if (status == 200) {
      ResponseData responseData = ResponseData.fromJson(json.decode(body));
      if (responseData.success()) {
        return responseData;
      } else {
        if (requestData.refreshAttempts >= maxAttempts) {
          throw CodeException(
            ErrorCodeConstant.STATUS_GENERATE_JWT_FAILED,
            "Failed to refresh token",
            null,
          );
        }

        if (responseData.code ==
                ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST ||
            responseData.code ==
                ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST ||
            responseData.code == ErrorCodeConstant.STATUS_NOT_IN_CHAT) {
          throw CodeException(responseData.code, "", null);
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
