import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/utils/net/response_data.dart';

/// `Retry` 資料結構
class Retry extends RowObject with EventDispatcher {

  Retry() : super();

  static Retry creator() {
    return Retry();
  }

  ///     CREATE TABLE IF NOT EXISTS  retry (
  ///     id INTEGER PRIMARY KEY AUTOINCREMENT,
  ///     uid INTEGER,
  ///     api_type TEXT DEFAULT "",
  ///     end_point TEXT DEFAULT "",
  ///     request_data TEXT DEFAULT "",
  ///     synced INTEGER,
  ///     callback_fun TEXT DEFAULT "",
  ///     expired INTEGER,
  ///     replace INTEGER,
  ///     expire_time INTEGER,
  ///     create_time INTEGER,
  ///     __add_index INTEGER
  /// );
  factory Retry.fromJson(Map<String, dynamic> json) {
    Retry retry = creator();
    retry.uid = json['uid'] ?? 0;
    retry.apiType = json['api_type'] ?? '';
    retry.endPoint = json['end_point'] ?? '';
    retry.requestData = json['request_data'] ?? '';
    retry.synced = json['synced'] ?? '';
    retry.callbackFun = json['callback_fun'] ?? '';
    retry.expired = json['expired'] ?? 0;
    retry.replace = json['replace'] ?? 0;

    try {
      retry.expireTime = json["expire_time"] ?? 0;
      retry.createTime = json["create_time"] ?? 0;
    } catch (e) {
      retry.expireTime = 0;
      retry.createTime = 0;
    }

    return retry;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'uid': uid,
      'api_type': apiType,
      'end_point': endPoint,
      'request_data': requestData,
      'synced': synced,
      'callback_fun': callbackFun,
      'expired': expired,
      'replace': replace,
      'expire_time': expireTime,
      'create_time': createTime,
    };
  }

  void copyFrom(Retry other) {
    uid = other.uid;
    apiType = other.apiType;
    endPoint = other.endPoint;
    requestData = other.requestData;
    synced = other.synced;
    callbackFun = other.callbackFun;
    expired = other.expired;
    replace = other.replace;
    expireTime = other.expireTime;
    createTime = other.createTime;
  }

  Retry.generate(uid, apiType, endPoint, requestData, synced, callbackFun, expired, replace, expireTime, createTime){
    this.uid = uid;
    this.apiType = apiType;
    this.endPoint = endPoint;
    this.requestData = requestData;
    this.synced = synced;
    this.callbackFun = callbackFun;
    this.expired = expired;
    this.replace = replace;
    this.expireTime = expireTime;
    this.createTime = createTime;
  }

  //Will be deleted
  @override
  bool operator == (other) {
    return (other is Retry) &&
        other.uid == uid &&
        other.apiType == apiType &&
        other.endPoint == endPoint &&
        other.requestData == requestData &&
        other.synced == synced &&
        other.callbackFun == callbackFun &&
        other.expired == expired &&
        other.replace == replace &&
        other.expireTime == expireTime &&
        other.createTime == createTime;
  }

  ResponseData? responseData;

  int get uid => getValue('uid', 0);

  set uid(int value) {
    setValue('uid', value);
  }

  String get apiType => getValue('api_type', '');

  set apiType(String value) {
    setValue('api_type', value);
  }

  String get endPoint => getValue('end_point', '');

  set endPoint(String value) {
    setValue('end_point', value);
  }

  String get requestData => getValue('request_data', '');

  set requestData(String value) {
    setValue('request_data', value);
  }

  int get synced => getValue('synced', 0);

  set synced(int value) {
    setValue('synced', value);
  }

  String get callbackFun => getValue('callback_fun', '');

  set callbackFun(String value) {
    setValue('callback_fun', value);
  }

  int get expired => getValue('expired', 0);

  set expired(int value) {
    setValue('expired', value);
  }

  int get replace => getValue('replace', 0);

  set replace(int value) {
    setValue('replace', value);
  }

  int get expireTime => getValue('expire_time', 0);
  set expireTime(int? value) {
    setValue('expire_time', value);
  }

  int get createTime => getValue('create_time', 0);
  set createTime(int? value) {
    setValue('create_time', value);
  }

  @override
  int get hashCode {
    return uid.hashCode ^
    apiType.hashCode ^
    endPoint.hashCode ^
    requestData.hashCode ^
    synced.hashCode ^
    callbackFun.hashCode ^
    expired.hashCode ^
    replace.hashCode ^
    expireTime.hashCode ^
    createTime.hashCode;
  }

}