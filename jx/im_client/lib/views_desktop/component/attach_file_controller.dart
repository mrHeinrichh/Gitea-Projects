import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:video_compress/video_compress.dart';
import 'package:jxim_client/utils/file_type_util.dart' as file_type_util;
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
    required file_type_util.FileType fileType,
    required int chatId,
  }) async {
    Get.back();
    final String? replyData =
        notBlank(objectMgr.chatMgr.replyMessageMap[chatId])
            ? jsonEncode(objectMgr.chatMgr.replyMessageMap[chatId]!.toJson())
            : null;

    if (fileType == file_type_util.FileType.allMedia ||
        fileType == file_type_util.FileType.image ||
        fileType == file_type_util.FileType.video) {
      for (var file in files) {
        final file_type_util.FileType selectedFile =
            file_type_util.getFileType(file.path);
        if (selectedFile == file_type_util.FileType.image) {
          ChatHelp.desktopSendImage(
            file,
            chatId,
            captionController.text,
            replyData,
          );
        } else if (selectedFile == file_type_util.FileType.video) {
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
      }
    } else if (fileType == file_type_util.FileType.document) {
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

  Future<void> addMoreItems(file_type_util.FileType fileType) async {
    if (isGettingFile) return;

    isGettingFile = true;

    FileType? type;
    List<String>? typeList;

    if (fileType == file_type_util.FileType.image) {
      typeList = file_type_util.imageExtension;
    } else if (fileType == file_type_util.FileType.video) {
      typeList = file_type_util.videoExtension;
    } else if (fileType == file_type_util.FileType.allMedia) {
      type = FileType.media;
    } else {
      type = FileType.any;
    }

    FilePickerResult? r = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type ?? FileType.custom,
      allowedExtensions: typeList,
    );
    FilePickerResult? result = await renameFiles(r) ?? r;
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
    try {
      final info = await VideoCompress.getMediaInfo(
        path,
      ).timeout(const Duration(seconds: 5)).catchError((onError) {
        if (onError is TimeoutException) {
          pdebug('接口超时');
        }
        return onError;
      });
      return info;
    } catch (e) {
      pdebug(e);
    }

    return null;
  }
}
