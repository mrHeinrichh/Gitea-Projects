import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

Client getHttpClient1() {
  var ioClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  Client _client = IOClient(ioClient);
  return _client;
}

HttpClient getHttpClient2() {
  const trustSelfSigned = true;
  HttpClient httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => trustSelfSigned);
  return httpClient;
}

const _headers = {'Content-Type': 'application/x-www-form-urlencoded'};

class Request {
  static const String error = "error";

  static const String methodTypeGet = "get";
  static const String methodTypePost = "post";
  static const String methodTypePut = "put";
  static const int maxAttempts = 3;

  static String token = "";

  /// 发送请求
  /// attempts 尝试次数
  /// maxTry 最大尝试次数
  static Future<HttpResponseBean> send(String url,
      [String method = Request.methodTypeGet,
      dynamic data,
      dynamic headers = _headers,
      int attempts = 1,
      int maxTry = maxAttempts]) async {
    var httpClient = getHttpClient2();
    dynamic body;
    int startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      Uri uri = Uri.parse(token.isEmpty ? url : "$url?token=$token");
      //pdebug("Request.send: $uri");
      HttpClientRequest? request;

      if (method == Request.methodTypePost) {
        request = await httpClient.postUrl(uri);
      } else if (method == Request.methodTypePut) {
        request = await httpClient.putUrl(uri);
      } else if (method == Request.methodTypeGet) {
        request = await httpClient.getUrl(uri);
      }
      if (request == null) {
        return HttpResponseBean({"code": -1}, url, data);
      }
      request.headers.add('Content-type', 'application/x-www-form-urlencoded');
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
          request.write(formData);
        }
      }

      var rep = await request.close();
      int status = rep.statusCode;
      var utf8Stream = rep.transform(const Utf8Decoder());
      var responseBody = await utf8Stream.join();
      // print('url:$url body: $responseBody');
      switch (status) {
        case 200:
          body = jsonDecode(responseBody);
          break;
        default:
          body = {"statusCode": status, "msg": responseBody};
          break;
      }
      body["code"] = 0;
    } catch (e) {
      // 异常转化成返回值
      return await _onHttpError(
          e, url, method, data, headers, attempts, maxTry);
    } finally {
      // int endTime = DateTime.now().millisecondsSinceEpoch;
      // print("requert end: $url  ${endTime - startTime}");
      httpClient.close();
    }
    return HttpResponseBean(body, url, data);
  }

  /// 请求发生错误
  static dynamic _onHttpError(e, String url, String method, dynamic data,
      dynamic headers, int attempts, int maxTry) async {
    if (attempts >= maxTry) {
      return HttpResponseBean({"code": -1}, url, data);
    }
    attempts++;
    return await send(url, method, data, headers, attempts, maxTry);
  }
}

/// 获取数据
/// key 如:data.name
T _getByPath<T>(dynamic object, String key) {
  var keys = key.split('.');
  dynamic obj = object;
  while (obj != null && keys.isNotEmpty) {
    String key0 = keys.removeAt(0);
    obj = obj[key0];
  }
  return obj as T;
}

/// http返回对象
class HttpResponseBean {
  //这个包的原始信息
  String? _uri;
  String? get uri => _uri;
  dynamic _params;
  dynamic get params => _params;
  //源数据
  final Map<dynamic, dynamic>? _json;
  //返回的代码
  int get code => _json?['code'];
  bool get success => code == 0;
  //data是map
  dynamic get data => _json;

  HttpResponseBean(this._json, [String? uri, dynamic params]) {
    _uri = uri;
    _params = params;
  }

  /// 获取数据
  /// key 如:data.name
  T get<T>(String key) {
    return _getByPath(_json, key);
  }

  /// 子节点遍历功能
  forEach(String key, void Function(dynamic, dynamic) action) {
    var keys = key.split('.');
    var obj = _json;
    while (obj != null && keys.isNotEmpty) {
      obj = obj[keys.removeAt(0)];
    }
    if (obj != null) {
      obj.forEach(action);
    }
  }

  @override
  String toString() {
    return '[$runtimeType] res:$_json, uri:$_uri, params:$_params';
  }
}
