import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:video_compress/video_compress.dart';
import 'package:jxim_client/utils/file_type_util.dart' as fileUtils;
import 'package:jxim_client/utils/input/desktop_new_line_input.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

class AttachFileController extends GetxController {
  final FocusNode focusNode = FocusNode();
  final TextEditingController captionController = TextEditingController();
  RxList<XFile> files = RxList<XFile>();
  RxBool isMediaOnHover = false.obs;
  int onHoverIndex = -1;
  bool isGettingFile = false;

  void deleteFileFromList(int index) {
    files.removeAt(index);
    files.refresh();
    focusNode.requestFocus();
  }

  Future<void> onSend({
    required fileUtils.FileType fileType,
    required int chatId,
  }) async {
    Get.back();
    final String? replyData =
        notBlank(objectMgr.chatMgr.replyMessageMap[chatId])
            ? jsonEncode(objectMgr.chatMgr.replyMessageMap[chatId]!.toJson())
            : null;

    if (fileType == fileUtils.FileType.allMedia ||
        fileType == fileUtils.FileType.image ||
        fileType == fileUtils.FileType.video) {
      files.forEach((file) async {
        final fileUtils.FileType selectedFile =
            fileUtils.getFileType(file.path);
        if (selectedFile == fileUtils.FileType.image) {
          ChatHelp.desktopSendImage(
            file,
            chatId,
            captionController.text,
            replyData,
          );
        } else if (selectedFile == fileUtils.FileType.video) {
          final MediaInfo? info = await getVideoInfo(file.path);
          final int duration = (info?.duration ?? 1) ~/ 1000;
          final int width = info?.width ?? 1280;
          final int height = info?.height ?? 1280;
          ChatHelp.desktopSendVideo(
            file,
            chatId,
            captionController.text,
            width,
            height,
            duration,
            replyData,
          );
        }
      });
    } else if (fileType == fileUtils.FileType.document) {
      ChatHelp.desktopSendFile(
        files,
        chatId,
        captionController.text,
        replyData,
      );
    }
    objectMgr.chatMgr.replyMessageMap.remove(chatId);
    captionController.clear();
    Get.find<CustomInputController>(tag: chatId.toString()).update();
  }

  Future<void> addMoreItems(fileUtils.FileType fileType) async {
    if (isGettingFile) return;

    isGettingFile = true;
    FilePickerResult? result;
    FileType? type;
    List<String>? typeList;

    if (fileType == fileUtils.FileType.image) {
      typeList = fileUtils.imageExtension;
    } else if (fileType == fileUtils.FileType.video) {
      typeList = fileUtils.videoExtension;
    } else if (fileType == fileUtils.FileType.allMedia) {
      type = FileType.media;
    } else {
      type = FileType.any;
    }

    result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type ?? FileType.custom,
      allowedExtensions: typeList,
    );
    isGettingFile = false;
    if (result == null) return;

    List<XFile> fileList =
        result.files.map((file) => XFile(file.path!)).toList();
    files.addAll(fileList);
    files.refresh();
    focusNode.requestFocus();
  }

  void checkDesktopKeyStroke(
    RawKeyEvent event,
    void Function() function,
  ) {
    if (event is RawKeyUpEvent) return;
    if (isEnterPressed()) {
      function.call();
    }
  }

  Future<MediaInfo?> getVideoInfo(String path) async {
    final info = await VideoCompress.getMediaInfo(
      path,
    );

    return info;
  }
}
