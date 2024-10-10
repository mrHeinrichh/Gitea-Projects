import 'package:jxim_client/managers/utils.dart';

class MyAppConfig {
  final String kiwiDownload1;
  final String kiwiDownload2;
  final String kiwiUpload;
  final String kiwiWebsocket;

  MyAppConfig({
    required this.kiwiDownload1,
    required this.kiwiDownload2,
    required this.kiwiUpload,
    required this.kiwiWebsocket,
  });

  factory MyAppConfig.fromJson(Map<String, dynamic> json) {
    String kiwiDownload1 = '';
    String kiwiDownload2 = '';
    String kiwiUpload = '';
    String kiwiWebsocket = '';
    Map<String, dynamic> kiwiJson = json['kiwi'] ?? json;
    if (kiwiJson.isNotEmpty && notBlank(kiwiJson)) {
      kiwiDownload1 = kiwiJson['kiwi_download_1'] ?? '';
      kiwiDownload2 = kiwiJson['kiwi_download_2'] ?? '';
      kiwiUpload = kiwiJson['kiwi_upload'] ?? '';
      kiwiWebsocket = kiwiJson['kiwi_websocket'] ?? '';
    }
    return MyAppConfig(
      kiwiDownload1: kiwiDownload1,
      kiwiDownload2: kiwiDownload2,
      kiwiUpload: kiwiUpload,
      kiwiWebsocket: kiwiWebsocket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kiwi_download_1': kiwiDownload1,
      'kiwi_download_2': kiwiDownload2,
      'kiwi_upload': kiwiUpload,
      'kiwi_websocket': kiwiWebsocket,
    };
  }
}
