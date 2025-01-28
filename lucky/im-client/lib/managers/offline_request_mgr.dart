import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

import 'utils.dart';

class OfflineRequestMgr extends EventDispatcher implements MgrInterface {
  String offlineRequestName = "";
  List<OfflineRequest> requestList = [];

  Future<void> execute() async {
    if (requestList.isEmpty) return;

    /// 相同API call会放到一起
    Map<String, List<OfflineRequest>> apiReqMap = {};
    for (final req in requestList.reversed) {
      if (apiReqMap.containsKey(req.apiPath)) {
        apiReqMap[req.apiPath]?.add(req);
      } else {
        apiReqMap.putIfAbsent(req.apiPath, () => [req]);
      }
    }

    List<Future<void>> futures = apiReqMap.entries.map((entry) async {
      /// 相同的API call会根据时间进行排序，然后同步进行
      entry.value.sort((a, b) => a.createTime.compareTo(b.createTime));
      return await Future.forEach(entry.value, (req) => doRequest(req));
    }).toList();

    await Future.wait(futures);
  }

  Future<void> doRequest(OfflineRequest request) async {
    try {
      ResponseData rep;
      if (request.method == "POST") {
        rep = await Request.doPost(request.apiPath,
            data: request.data,
            needToken: request.needToken,
            cipher: request.cipher);
      } else {
        rep = await Request.doGet(request.apiPath,
            data: request.data,
            needToken: request.needToken,
            cipher: request.cipher);
      }

      if (notBlank(request.eventKey)) {
        event(this, request.eventKey, data: rep.data);
      }

      remove(request);
    } on CodeException catch (e) {
      remove(request);
      mypdebug('OfflineRequest --> ${e.toString()}');
    } catch (e) {
      if (request.attempts < request.maxTry) {
        request.attempts++;
        await Future.delayed(const Duration(microseconds: 100) * request.attempts);
      } else {
        /// 超过最大重试从列表里面移除
        remove(request);
      }
    }
  }

  void add(OfflineRequest request) {
    requestList.add(request);
    save();
  }

  void remove(OfflineRequest request) {
    requestList.remove(request);
    save();
  }

  void save() {
    if (requestList.isNotEmpty) {
      String jsonStr = jsonEncode(requestList);
      objectMgr.localStorageMgr
          .writeSecurely(offlineRequestName, jsonStr);
    } else {
      objectMgr.localStorageMgr.remove(offlineRequestName);
    }
  }

  void load() {
    final String? jsonStr =
        objectMgr.localStorageMgr.readSecurely(offlineRequestName);
    if (notBlank(jsonStr)) {
      final List data = json.decode(jsonStr!);
      requestList = fromJson(data);
    }
  }

  List<OfflineRequest> fromJson(List json) {
    List<OfflineRequest> list = [];
    for (var i = 0; i < json.length; i++) {
      Map<String, dynamic> data = json[i];
      OfflineRequest model = OfflineRequest.fromJson(data);
      list.add(model);
    }
    return list;
  }

  @override
  Future<void> init() async {
    offlineRequestName = LocalStorageMgr.OFFLINE_REQUEST + "${objectMgr.userMgr.mainUser.uid}";
    load();
  }

  @override
  Future<void> logout() async {
    save();
  }

  @override
  Future<void> register() async {}

  @override
  Future<void> reloadData() async {
    execute();
  }
}

class OfflineRequest {
  final String apiPath;
  final Map<String, dynamic> data;
  final String method;
  final bool cipher;
  final bool needToken;
  final int inSeconds;
  final int everySeconds;
  final String eventKey;
  final int createTime;
  final int maxTry;
  int attempts;

  OfflineRequest(this.apiPath, this.data,
      {this.method = "POST",
      this.cipher = false,
      this.needToken = true,
      this.inSeconds = 0,
      this.everySeconds = 0,
      this.eventKey = '',
      int? createTime,
      this.maxTry = 5,
      this.attempts = 0})
      : this.createTime = createTime ?? DateTime.now().millisecondsSinceEpoch;

  factory OfflineRequest.fromJson(Map<String, dynamic> json) {
    return OfflineRequest(
      json['apiPath'] ?? '',
      json['data'] ?? {},
      method: json['method'] ?? 'POST',
      cipher: json["cipher"] ?? false,
      needToken: json["needToken"] ?? false,
      inSeconds: json["inSeconds"] ?? 0,
      everySeconds: json["everySeconds"] ?? 0,
      eventKey: json["eventKey"] ?? '',
      createTime: json["createTime"] ?? 0,
      maxTry: json["maxTry"] ?? 0,
      attempts: json["attempts"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiPath': apiPath,
      'data': data,
      'method': method,
      'cipher': cipher,
      'needToken': needToken,
      'inSeconds': inSeconds,
      'everySeconds': everySeconds,
      'eventKey': eventKey,
      'createTime': createTime,
      'maxTry': maxTry,
      'attempts': attempts,
    };
  }
}
