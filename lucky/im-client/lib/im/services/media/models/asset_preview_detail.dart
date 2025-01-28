import 'dart:io';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPreviewDetail {
  String id;
  int index;
  AssetEntity entity;
  File? editedFile;
  int? editedWidth;
  int? editedHeight;

  String caption = '';

  File? editedThumbFile;

  AssetPreviewDetail({
    required this.id,
    required this.index,
    required this.entity,
  });
}
