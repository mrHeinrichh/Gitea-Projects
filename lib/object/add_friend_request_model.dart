class GetFriendRequestModel {
  String? url;
  int? expiry;
  int? duration;

  GetFriendRequestModel({
    this.url,
    this.expiry,
    this.duration,
  });

  factory GetFriendRequestModel.fromJson(Map<String, dynamic> json) => GetFriendRequestModel(
    url: json["url"],
    expiry: json["expiry"],
    duration: json["duration"],
  );
}

class QRSocketModel {
  int? duration;
  int? expiry;
  String? secret;
  int? userId;


  QRSocketModel({
    this.duration,
    this.expiry,
    this.secret,
    this.userId,
  });

  factory QRSocketModel.fromJson(Map<String, dynamic> json) => QRSocketModel(
    duration: json["duration"],
    expiry: json["expiry"],
    secret: json["secret"],
    userId: json["user_id"],
  );
}
