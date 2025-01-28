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
  String fileName = '';
  String suffix = '';
  int length = 0;
  Uint8List? fileData;

  // 文案
  String text = '';

  //分享链接
  String miniAppLink = '';
  /// 小程序 头像
  String miniAppAvatar = "";
  /// 小程序 描述图片
  String miniAppPicture = "";
  /// 小程序高斯图像
  String miniAppPictureGaussian = "";
  /// 小程序 应用名
  String miniAppName = "";

  /// 小程序 标题
  String miniAppTitle = "";


  ShareItem.fromJson(Map<String, dynamic> json) {
    width =
    (json['width'] != null) ? double.parse(json['width'].toString()) : 0;
    height =
    (json['height'] != null) ? double.parse(json['height'].toString()) : 0;
    imageData = (json['image'] != null) ? json['image'] : null;
    videoPath = (json['video_to_path'] != null) ? json['video_to_path'] : '';
    videoDuration = (json['video_duration'] != null)
        ? double.parse(json['video_duration'].toString())
        : 0;
    videoWidth = (json['video_width'] != null)
        ? double.parse(json['video_width'].toString())
        : 0;
    videoHeight = (json['video_height'] != null)
        ? double.parse(json['video_height'].toString())
        : 0;
    videoSize = (json['video_size'] != null)
        ? int.parse(json['video_size'].toString())
        : 0;
    imagePath = (json['image_to_path'] != null) ? json['image_to_path'] : '';
    webLink = (json['web_link'] != null) ? json['web_link'] : '';
    filePath = (json['file_to_path'] != null) ? json['file_to_path'] : '';
    fileName = (json['file_name'] != null) ? json['file_name'] : '';
    suffix = (json['suffix'] != null) ? json['suffix'] : '';
    length = (json['length'] != null) ? json['length'] : 0;
    fileData = (json['file_data'] != null) ? json['file_data'] : null;
    text = (json['text'] != null) ? json['text'] : '';
    miniAppLink = (json['mini_app_link'] != null) ? json['mini_app_link'] : '';
    miniAppPicture = (json['mini_app_picture'] != null) ? json['mini_app_picture'] : '';
    miniAppAvatar = (json['mini_app_avatar'] != null) ? json['mini_app_avatar'] : '';
    miniAppPictureGaussian = (json['mini_app_picture_gaussian'] != null) ? json['mini_app_picture_gaussian'] : '';
    miniAppName = (json['mini_app_name'] != null) ? json['mini_app_name'] : '';
    miniAppTitle = (json['mini_app_title'] != null) ? json['mini_app_title'] : '';
  }
}
