import 'dart:typed_data';

class ShareImage {
  int chatId = 0;
  String caption = '';
  List<ShareItem> dataList = [];

  ShareImage.fromJson(Map<String, dynamic> json) {
    if (json['asset'] != null) {
      dataList = (json['asset'] as List)
          .map((e) => ShareItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    chatId = (json['chatId'] != null) ? json['chatId'] : 0;
    caption = (json['caption'] != null) ? json['caption'] : '';
  }
}

class ShareItem {
  double width = 0.0;
  double height = 0.0;
  Uint8List? imageData;
  String videoPath = '';
  double videoDuration = 0.0;
  double videoWidth = 0.0;
  double videoHeight = 0.0;
  int videoSize = 0;
  String imagePath = '';
  String webLink = '';

  //文件
  String filePath = '';
  String file_name = '';
  String suffix = '';
  int length = 0;
  Uint8List? file_data;

  // 文案
  String text = '';

  ShareItem.fromJson(Map<String, dynamic> json) {
    width =
    (json['width'] != null) ? double.parse(json['width'].toString()) : 0;
    height =
    (json['height'] != null) ? double.parse(json['height'].toString()) : 0;
    imageData = (json['image'] != null) ? json['image'] : null;
    videoPath = (json['video_to_path'] != null) ? json['video_to_path'] : '';
    videoDuration = (json['video_duration'] != null) ? double.parse(json['video_duration'].toString()) : 0;
    videoWidth = (json['video_width'] != null) ? double.parse(json['video_width'].toString()) : 0;
    videoHeight = (json['video_height'] != null) ? double.parse(json['video_height'].toString()) : 0;
    videoSize = (json['video_size'] != null) ? int.parse(json['video_size'].toString()) : 0;
    imagePath = (json['image_to_path'] != null) ? json['image_to_path'] : '';
    webLink = (json['web_link'] != null) ? json['web_link'] : '';
    filePath = (json['file_to_path'] != null) ? json['file_to_path'] : '';
    file_name = (json['file_name'] != null) ? json['file_name'] : '';
    suffix = (json['suffix'] != null) ? json['suffix'] : '';
    length = (json['length'] != null) ? json['length'] : 0;
    file_data = (json['file_data'] != null) ? json['file_data'] : null;
    text = (json['text'] != null) ? json['text'] : '';
  }
}
