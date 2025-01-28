import 'package:jxim_client/managers/utils.dart';

class AppVersion {
  List<PlatformDetail> androidList;
  List<PlatformDetail> iosList;
  List<PlatformDetail> windowsList;
  List<PlatformDetail> macList;

  AppVersion({
    required this.androidList,
    required this.iosList,
    required this.windowsList,
    required this.macList,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => AppVersion(
        androidList: json['android']
            .map<PlatformDetail>((item) => PlatformDetail.fromJson(item))
            .toList(),
        iosList: json['ios']
            .map<PlatformDetail>((item) => PlatformDetail.fromJson(item))
            .toList(),
        windowsList: json['windows']
            .map<PlatformDetail>((item) => PlatformDetail.fromJson(item))
            .toList(),
        macList: json['mac']
            .map<PlatformDetail>((item) => PlatformDetail.fromJson(item))
            .toList(),
      );
}

///平台详情
class PlatformDetail {
  int id;
  int os;
  String platform;
  int channel;
  String version;
  String minVersion;
  String uninstallVersion;
  String url;
  int createdAt;
  int updatedAt;
  String description;

  PlatformDetail({
    this.id = 0,
    this.os = 0,
    this.platform = '',
    this.channel = 1,
    this.version = '',
    this.minVersion = '',
    this.uninstallVersion = '',
    this.url = '',
    this.createdAt = 0,
    this.updatedAt = 0,
    this.description = '',
  });

  factory PlatformDetail.fromJson(Map<String, dynamic> json) => PlatformDetail(
        id: json["id"],
        os: json["os"],
        platform: json["platform"],
        channel: notBlank(json["channel"]) ? json["channel"] : 1,
        version: (json["version"] != "") ? json["version"] : '0.0.0',
        minVersion: (json["min_version"] != "") ? json["min_version"] : '0.0.0',
        uninstallVersion: (json["uninstall_version"] != "") ? json["uninstall_version"] : "0.0.0",
        url: json["url"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        description: json["description"],
      );
}

///心跳版本详情
class HeartBeatAppVersion {
  String version;
  String minVersion;
  String uninstallVersion;
  String description;

  HeartBeatAppVersion({
    this.version = '',
    this.minVersion = '',
    this.uninstallVersion = '',
    this.description = '',
  });

  factory HeartBeatAppVersion.fromJson(Map<String, dynamic> json) =>
      HeartBeatAppVersion(
        version: (json["version"] != "") ? json["version"] : '0.0.0',
        minVersion: (json["min_version"] != "") ? json["min_version"] : '0.0.0',
        uninstallVersion: (json["uninstall_version"] != "")
            ? json["uninstall_version"]
            : "0.0.0",
        description: json["description"],
      );
}

class EventAppVersion {
  int? updateType;
  bool? isShowUninstall;
  bool isShow;

  EventAppVersion({
    this.updateType,
    this.isShowUninstall = false,
    this.isShow = true,
  });
}
