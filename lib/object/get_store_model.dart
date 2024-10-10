import 'dart:convert';

class CustomData {
  final String channel;
  final Map<String,dynamic> message;

  CustomData({
    required this.channel,
    required this.message,
  });

  factory CustomData.fromJson(Map<String,dynamic> json){
    return CustomData(
      channel: json['channel'],
      message: jsonDecode(json['message']),
    );
  }
}

class GetStoreData {
  final String key;
  final String value;

  GetStoreData({
    required this.key,
    required this.value,
  });

  factory GetStoreData.fromJson(Map<String,dynamic> json){
    return GetStoreData(
      key: json['key'],
      value: json['value'],
    );
  }
}
