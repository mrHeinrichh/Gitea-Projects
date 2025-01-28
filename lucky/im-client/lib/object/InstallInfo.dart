class InstallInfo {
  String url;
  int expiry;
  int duration;

  InstallInfo({
    this.url = '',
    this.expiry = -1,
    this.duration = -1,
  });

  factory InstallInfo.fromJson(Map<String, dynamic> json) =>
      InstallInfo(
        url: json["url"] ?? '',
        expiry: json["expiry"] ?? -1,
        duration: json['duration'] ?? -1,
      );
}
