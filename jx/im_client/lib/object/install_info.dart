class InstallInfo {
  String url;
  int expiry;
  int duration;
  String inviteCode;
  int inviteCodeExpiry;

  InstallInfo({
    this.url = '',
    this.expiry = -1,
    this.duration = -1,
    this.inviteCode = '',
    this.inviteCodeExpiry = -1,
  });

  factory InstallInfo.fromJson(Map<String, dynamic> json) =>
      InstallInfo(
        url: json["url"] ?? '',
        expiry: json["expiry"] ?? -1,
        duration: json['duration'] ?? -1,
        inviteCode: json['invite_code'] ?? '',
        inviteCodeExpiry: json['invite_code_expiry'] ?? '',
      );
}
