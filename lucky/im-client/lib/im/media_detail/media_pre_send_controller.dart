import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/utility.dart';

class MediaPreSendViewController extends GetxController {
  RxBool showToolOption = true.obs;
  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocus = FocusNode();
  final bottomBarHeight = 48.0;
  final filePath = Rxn<String>();
  late Message message;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>;
    filePath.value = arguments['filePath'];
    message = arguments['message'];
  }

  @override
  void onClose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    captionController.dispose();
    captionFocus.dispose();
    super.onClose();
  }

  void onSwitchToolOption() {
    showToolOption.value = !showToolOption.value;
    captionFocus.unfocus();
  }

  void editAsset() async {
    try {
      final newFile = await copyImageFile(File(filePath.value!));
      var done = await FlutterPhotoEditor().editImage(newFile.path);
      if (done) {
        filePath.value = newFile.path;
        update(['editedChanged']);
      }
    } catch (e) {
      debugPrint('[onPhotoEdit]: edit photo in error $e');
    }
  }

  Future<void> sendAsset() async {
    final newFile = await copyImageFile(File(filePath.value!));
    final result = <String, dynamic>{
      'filePath': newFile.path,
      'caption': captionController.text,
    };
    Get.back(result: result);
  }
}
