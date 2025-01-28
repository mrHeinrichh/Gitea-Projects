import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:jxim_client/object/user.dart';

class Account {
  String accId;
  String token;
  String refreshToken;
  User? user;
  String deviceId;
  String deviceToken;

  Account({
    this.accId = '',
    this.token = '',
    this.refreshToken = '',
    this.deviceId = '',
    this.deviceToken = '',
    this.user,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        accId: json["account_id"] ?? "",
        token: json["access_token"] ?? "",
        refreshToken: json["refresh_token"] ?? "",
        deviceId: json["device_id"] ?? "",
        deviceToken: json["device_token"] ?? '',
        user: json['profile'] != null ? User.fromJson(json['profile']) : null,
      );

  bool isExpired() {
    if (token.isEmpty) return true;
    bool isTokenExpired = JwtDecoder.isExpired(token);
    return isTokenExpired;
  }

  void getToken(Map<String, dynamic> dataBody) {
    dataBody["access_token"] = token;
    dataBody["refresh_token"] = refreshToken;
  }

  void saveToken(String accessToken, String newRefreshToken) {
    token = accessToken;
    refreshToken = newRefreshToken;
  }

  Map<String, dynamic> toJson() => {
        "account_id": accId,
        "access_token": token,
        "refresh_token": refreshToken,
        "device_id": deviceId,
        "device_token": deviceToken,
        "profile": {
          'id': user?.id,
          'uid': user?.id,
          'uuid': user?.accountId,
          'username': user?.username,
          'nickname': user?.nickname,
          'contact': user?.contact,
          'country_code': user?.countryCode,
          'profile_pic': user?.profilePicture,
        },
      };
}
