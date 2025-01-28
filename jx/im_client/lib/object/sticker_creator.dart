class StickerCreator {
  final int id;
  final String uuid;
  final String username;
  final String nickname;
  final String contact;
  final String countryCode;

  StickerCreator({
    required this.id,
    required this.uuid,
    required this.username,
    required this.nickname,
    required this.contact,
    required this.countryCode,
  });

  factory StickerCreator.fromJson(Map<String, dynamic> json) => StickerCreator(
    id: json["id"] ?? 0,
    uuid: json["uuid"] ?? "",
    username: json["username"] ?? "",
    nickname: json["nickname"] ?? "",
    contact: json["contact"] ?? "",
    countryCode: json["country_code"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uuid": uuid,
    "username": username,
    "nickname": nickname,
    "contact": contact,
    "country_code": countryCode,
  };
}
