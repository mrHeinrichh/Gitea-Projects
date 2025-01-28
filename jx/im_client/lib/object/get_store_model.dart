import 'dart:convert';

class CustomData {
  final String channel;
  final Map<String, dynamic> message;

  CustomData({
    required this.channel,
    required this.message,
  });

  factory CustomData.fromJson(Map<String, dynamic> json) {
    return CustomData(
      channel: json['channel'],
      message: jsonDecode(json['message']),
    );
  }
}

class GetStoreData {
  final String key;
  final String value;
  final int updateTime;

  GetStoreData({
    required this.key,
    required this.value,
    required this.updateTime,
  });

  factory GetStoreData.fromJson(Map<String, dynamic> json) {
    return GetStoreData(
      key: json['key'],
      value: json['value'],
      updateTime: json['update_time'] ?? 0,
    );
  }
}

class GetStoresData {
  List<GetStoreData> stores;

  GetStoresData({required this.stores});

  factory GetStoresData.fromJson(Map<String, dynamic> json) {
    if (json['stores'] != null && json['stores'] is List) {
      return GetStoresData(
        stores: json['stores']
            .map<GetStoreData>((e) => GetStoreData.fromJson(e))
            .toList(),
      );
    }

    return GetStoresData(stores: []);
  }
}
