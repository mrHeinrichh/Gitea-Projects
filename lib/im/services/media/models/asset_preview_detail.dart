import 'dart:io';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewDetail {
  String id;
  int index;
  AssetEntity entity;

  File? editedFile;
  int? editedWidth;
  int? editedHeight;

  String caption;

  File? editedThumbFile;

  MediaResolution imageResolution = MediaResolution.image_standard;
  MediaResolution videoResolution = MediaResolution.video_standard;

  bool isCompressed = false;

  AssetPreviewDetail({
    required this.id,
    required this.index,
    required this.entity,
    required this.caption,
  });
}

enum MediaResolution {
  image_standard(900),
  image_high(1600),
  video_standard(480),
  video_high(720);

  const MediaResolution(this.minSize);

  final int minSize;
}
