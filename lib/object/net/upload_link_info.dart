class UploadLinkInfo {
  String key = '';
  String path = '';
  String fileName = '';
  String url = '';
  String error = '';
  int code = 0;

  UploadLinkInfo();

  UploadLinkInfo.fromJson(Map<String, dynamic> json) {
    key = json['key'] ?? '';
    path = json['path'] ?? '';
    fileName = json['fileName'] ?? '';
    url = json['url'] ?? '';
    error = json['error'] ?? '';
    code = json['code'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['path'] = path;
    data['fileName'] = fileName;
    data['url'] = url;
    data['error'] = error;
    data['code'] = code;
    return data;
  }
}
