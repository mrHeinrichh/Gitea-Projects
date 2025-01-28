class DeviceListModel {
  List<DeviceModel>? deviceList;

  DeviceListModel({
    this.deviceList,
  });

  factory DeviceListModel.fromJson(Map<String, dynamic> json) =>
      DeviceListModel(
        deviceList: json['device_list']
            .map<DeviceModel>((item) => DeviceModel.fromJson(item))
            .toList(),
      );
}

class DeviceHistoryListModel {
  List<DeviceModel>? deviceHistoryList;

  DeviceHistoryListModel({
    this.deviceHistoryList,
  });

  factory DeviceHistoryListModel.fromJson(Map<String, dynamic> json) =>
      DeviceHistoryListModel(
        deviceHistoryList: json['device_history']
            .map<DeviceModel>((item) => DeviceModel.fromJson(item))
            .toList(),
      );
}

class DeviceModel {
  String? appVersion;
  String? deviceName;
  String? deviceOs;
  String? platform;
  String? ip;
  String? city;
  String? country;
  int? udid;
  int? lastActive;
  int enableVoip;

  DeviceModel({
    this.appVersion,
    this.deviceName,
    this.deviceOs,
    this.platform,
    this.ip,
    this.city,
    this.country,
    this.udid,
    this.lastActive,
    this.enableVoip = 1,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        appVersion: json["app_version"],
        deviceName: json["device_name"],
        deviceOs: json["device_os"],
        platform: json["platform"],
        ip: json["ip"],
        city: json["city"],
        country: json["country"],
        udid: json["udid"],
        lastActive: json["last_active"],
        enableVoip: json["enable_voip"],
      );
}
