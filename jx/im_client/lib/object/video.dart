class VideoData {
  List<VideoHLS>? hls;
  String? sourceFile;

  VideoData({
    this.hls,
    this.sourceFile,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) => VideoData(
        hls: json['hls']?.map<VideoHLS>((x) => VideoHLS.fromJson(x)).toList(),
        sourceFile: json['source_file'],
      );
}

class VideoHLS {
  String? path;
  bool? isExist;
  bool? isEnd;
  bool? isDefault;
  bool? isOriginal;
  int? resolution;
  String? vCodec;
  String? aCodec;
  int? lastFailedAt;

  VideoHLS({
    this.path,
    this.isExist,
    this.isEnd,
    this.isDefault,
    this.isOriginal,
    this.resolution,
    this.vCodec,
    this.aCodec,
    this.lastFailedAt,
  });

  factory VideoHLS.fromJson(Map<String, dynamic> json) => VideoHLS(
        path: json['path'],
        isExist: json['is_exist'],
        isEnd: json['is_end'],
        isDefault: json['is_default'],
        isOriginal: json['is_original'],
        resolution: json['resolution'],
        vCodec: json['vcodec'],
        aCodec: json['acodec'],
        lastFailedAt: json['last_failed_at'],
      );
}
