import 'dart:convert';
import 'dart:io';

import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:intl/intl.dart';

const maxLine = 100;

class MyLog {
  static File? _logFile;
  static File? _debugFile;
  static int _curLogLines = 0;
  static String host = '';
  static String token = '';
  static bool _open = false;
  static io.File? _metricsFile;

  static void change(bool open) {
    if (!MyLog._open) {
      MyLog._open = open;
    }
  }

  static Future<void> init({String host = '', String token = ''}) async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/app_log.txt');
    _debugFile = File('${directory.path}/debug_log.txt');
    _curLogLines = 0;
    MyLog.host = host;
    MyLog.token = token;
    info("init myLog finished");

    _metricsFile = io.File('${directory.path}/metrics.txt');
    info("init metrics finished");
  }

  static void info(Object? object) {
    if (!_open) {
      return;
    }
    if (_logFile == null) {
      return;
    }
    DateTime now = DateTime.now();
    String line = "[${DateFormat('yyyy MMM dd HH:mm:ss.SSS').format(now)}] $object\r\n";
    pdebug('myLog: ${line}');
    _logFile!.writeAsStringSync(line, mode: io.FileMode.append);
  }

  static void addLog(String log){
    // if(_debugFile == null){
    //   return;
    // }
    //
    // if(_curLogLines >= maxLine){
    //   syncLogWithServer();
    //   return;
    // }
    //
    // _debugFile!.writeAsStringSync('$log\n', mode: FileMode.append);
    // _curLogLines++;
  }

  static syncLogWithServer() async {
    // if(_debugFile != null && _debugFile!.existsSync()){
    //   try{
    //     String logs = await _debugFile!.readAsString();
    //     final result = await uploadLogInfo(logs);
    //     if(result){
    //       clearLogFile();
    //     }
    //   }catch(e) {
    //     pdebug("syncLogWithServer failed: $e");
    //   }
    // }
  }

  static clearLogFile() async{
    if(_debugFile != null){
      _debugFile!.writeAsStringSync('', mode: FileMode.write);
      _curLogLines = 0;
    }
  }

  static Future<bool> uploadLogInfo(String logStr) async {
    if(!notBlank(host) || !notBlank(token) || !notBlank(logStr)){
      return false;
    }

    final appVer = await PlatformUtils.getAppVersion();
    Map<String, dynamic> dataBody = {"log": logStr, "app_version": appVer};
    try {
      HttpClient httpClient = getHttpClient();
      Uri uri = Uri.parse('${host}/app/api/account/report-user-device-log');
      HttpClientRequest request = await httpClient.postUrl(uri);
      String jsonData = json.encode(dataBody);
      request.headers.add("token", token);
      request.headers.add("content-type", 'application/json; charset=utf-8');
      request.write(jsonData);
      HttpClientResponse response = await request.close();
      var utf8Stream = response.transform(const Utf8Decoder());
      String body = await utf8Stream.join();
      Map<String, dynamic> jsonMap = jsonDecode(body);
      ResponseData responseData = ResponseData(code: jsonMap["code"], message: jsonMap["message"], data: jsonMap["data"]);
      pdebug('uploadLogInfo Success: ${responseData.message}');
      return responseData.success();
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
      pdebug('uploadLogInfo Failed: ${e.toString()}');
    }

    return false;
  }

  static void metrics(String type, int uid, int? startTime, int endTime, [List<Object>? others]) {
    if (!_open) {
      return;
    }
    if (_metricsFile == null) {
      return;
    }

    if (startTime == null) {
      startTime = 0;
    }
    if (startTime == -1) {
      startTime = DateTime.now().millisecondsSinceEpoch;
    }
    if (endTime == -1) {
      endTime = DateTime.now().millisecondsSinceEpoch;
    }

    DateTime now = DateTime.now();
    String line = "${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(now)}, ${type}, ${uid}, ${startTime}, ${endTime}, ${endTime - startTime}";
    if (others != null && others.length > 0) {
      others.forEach((o) {
        line += ", ${o}";
      });
    }
    line += "\r\n";
    _metricsFile!.writeAsStringSync(line, mode: io.FileMode.append);
  }
}
