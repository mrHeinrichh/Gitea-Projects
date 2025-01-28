import 'dart:convert';

/// addrName : ""
/// addrID : ""
/// address : ""
/// netType : ""

WalletAddressArguments walletAddressArgumentsFromJson(
  String str,
) =>
    WalletAddressArguments.fromJson(json.decode(str));

String walletAddressArgumentsToJson(
  WalletAddressArguments data,
) =>
    json.encode(data.toJson());

class WalletAddressArguments {
  WalletAddressArguments({
    required String addrName,
    required String addrID,
    required String address,
    required String netType,
  }) {
    _addrName = addrName;
    _addrID = addrID;
    _address = address;
    _netType = netType;
  }

  WalletAddressArguments.fromJson(dynamic json) {
    _addrName = json['addrName'] ?? '';
    _addrID = json['addrID'] ?? '';
    _address = json['address'] ?? '';
    _netType = json['netType'] ?? '';
  }

  String _addrName = '';
  String _addrID = '';
  String _address = '';
  String _netType = '';

  WalletAddressArguments copyWith({
    String? addrName,
    String? addrID,
    String? address,
    String? netType,
  }) =>
      WalletAddressArguments(
        addrName: addrName ?? _addrName,
        addrID: addrID ?? _addrID,
        address: address ?? _address,
        netType: netType ?? _netType,
      );

  String get addrName => _addrName;

  String get addrID => _addrID;

  String get address => _address;

  String get netType => _netType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['addrName'] = _addrName;
    map['addrID'] = _addrID;
    map['address'] = _address;
    map['netType'] = _netType;
    return map;
  }
}
