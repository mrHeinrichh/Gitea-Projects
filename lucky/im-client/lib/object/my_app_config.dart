import 'package:jxim_client/managers/utils.dart';

class MyAppConfig {
  final String kiwi_download_1;
  final String kiwi_download_2;
  final String kiwi_upload;
  final String kiwi_websocket;

  MyAppConfig({
    required this.kiwi_download_1,
    required this.kiwi_download_2,
    required this.kiwi_upload,
    required this.kiwi_websocket,
  });

  factory MyAppConfig.fromJson(Map<String, dynamic> json) {
    String kiwi_download_1 = '';
    String kiwi_download_2 = '';
    String kiwi_upload = '';
    String kiwi_websocket = '';
    Map<String, dynamic> kiwiJson = json['kiwi'] ?? json;
    if (kiwiJson.isNotEmpty && notBlank(kiwiJson)) {
      kiwi_download_1 = kiwiJson['kiwi_download_1'] ?? '';
      kiwi_download_2 = kiwiJson['kiwi_download_2'] ?? '';
      kiwi_upload = kiwiJson['kiwi_upload'] ?? '';
      kiwi_websocket = kiwiJson['kiwi_websocket'] ?? '';
    }
    return MyAppConfig(
      kiwi_download_1: kiwi_download_1,
      kiwi_download_2: kiwi_download_2,
      kiwi_upload: kiwi_upload,
      kiwi_websocket: kiwi_websocket,
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'kiwi_download_1': kiwi_download_1,
      'kiwi_download_2': kiwi_download_2,
      'kiwi_upload': kiwi_upload,
      'kiwi_websocket': kiwi_websocket,
    };
  }
}
