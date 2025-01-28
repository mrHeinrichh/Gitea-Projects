class ResponseData<T> {
  int code;
  String message;
  T? data;

  ResponseData({this.code = -1, this.message = '', this.data});

  bool success() => code == 0;

  factory ResponseData.fromJson(Map<String, dynamic> json) => ResponseData<T>(
        code: json["code"],
        message: json["message"],
        data: json["result"] ?? json["data"] as T,
      );

  @override
  String toString() => message;
}

extension ResponseDataExtension<T> on ResponseData<T> {
  //方便多个支付流程里获取是否需要手机或邮箱的二次验证
  bool get needTwoFactorAuthPhone {
    if (success() && data != null) {
      if (data is Map) {
        Map m = data as Map;
        return m["phoneVcodeSend"] ?? false;
      }
    }
    return false;
  }
  bool get needTwoFactorAuthEmail {
    if (success() && data != null) {
      if (data is Map) {
        Map m = data as Map;
        return m["emailVcodeSend"] ?? false;
      }
    }
    return false;
  }
  String get txID {
    if (success() && data != null) {
      if (data is Map) {
        Map m = data as Map;
        return m["txID"] ?? "";
      }
    }
    return "";
  }
}
