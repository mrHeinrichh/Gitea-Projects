import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:jxim_client/object/user.dart';

class Account {
  String accId;
  String token;
  String refreshToken;
  User? user;

  Account(
      {this.accId = '', this.token = '', this.refreshToken = '', this.user});

  factory Account.fromJson(Map<String, dynamic> json) => Account(
      accId: json["account_id"] ?? "",
      token: json["access_token"] ?? "",
      refreshToken: json["refresh_token"] ?? "",
      user: json['profile'] != null ? User.fromJson(json['profile']) : null);

  bool isExpired() {
    bool isTokenExpired = JwtDecoder.isExpired(token);
    return isTokenExpired;
  }

  void getToken(Map<String, dynamic> dataBody) {
    dataBody["access_token"] = token;
    dataBody["refresh_token"] = refreshToken;
  }

  void saveToken(String accessToken, String refreshToken) {
    this.token = accessToken;
    this.refreshToken = refreshToken;
  }

  Map<String, dynamic> toJson() => {
        "account_id": accId,
        "access_token": token,
        "refresh_token": refreshToken,
        "profile": {
          'id': user?.id,
          'uid': user?.id,
          'uuid': user?.accountId,
          'username': user?.username,
          'nickname': user?.nickname,
          'contact': user?.contact,
          'country_code': user?.countryCode,
          'profile_pic': user?.profilePicture,
        }
      };
}
