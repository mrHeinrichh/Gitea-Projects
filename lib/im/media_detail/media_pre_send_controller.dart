import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/clip_board_util.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MediaPreSendViewController extends GetxController {
  RxBool showToolOption = true.obs;
  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocus = FocusNode();
  final bottomBarHeight = 48.0;


  Rx<List<List<String>>> imageDataList = Rx<List<List<String>>>([]);
  late PhotoViewPageController photoPageController;
  Rx<List<bool>> selectedState = Rx<List<bool>>([]);
  Rx<List<int>> countNumber = Rx<List<int>>([]);
  RxInt currentPage = 0.obs;
  int chatId = 0;

  @override
  void onInit() {
    super.onInit();
    photoPageController = PhotoViewPageController(
      initialPage: 0,//data.length - 1,
      shouldIgnorePointerWhenScrolling: true,
    );
    final arguments = Get.arguments as Map<String, dynamic>;
    String contentText = arguments['contentText'];
    chatId = arguments['chatId'];


    ClipboardUtil.getClipboardImages().then((List<List<String>> data){
      imageDataList.value = data;
      selectedState.value = List.generate(data.length, (_) => true);
      countNumber.value = List.generate(data.length, (index) => index + 1);
      update();
    });
    captionController.text = contentText;
  }

  @override
  void onClose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    captionController.dispose();
    captionFocus.dispose();
    super.onClose();
  }

  void onPageChange(int index) {
    currentPage.value = index;
    update();
  }

  void onSwitchToolOption() {
    showToolOption.value = !showToolOption.value;
    captionFocus.unfocus();
  }

  void editAsset() async {
    // try {
    //   coverFilePath.value = filePath.value!;
    //   final newFile = await copyImageFile(File(filePath.value!));
    //   var done = await FlutterPhotoEditor().editImage(
    //     newFile.path,
    //     languageCode: objectMgr.langMgr.currLocale.languageCode,
    //   );
    //   if (done) {
    //     filePath.value = newFile.path;
    //     update(['editedChanged']);
    //   }
    // } catch (e) {
    //   debugPrint('[onPhotoEdit]: edit photo in error $e');
    // }
  }


  Future<void> sendImage() async {
    // 显示加载对话框
    showDialog(
      context: Get.context!,
      barrierDismissible: false, // 阻止用户关闭对话框
      builder: (context) => Dialog(
        backgroundColor: const Color(0x00FFFFFF),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: const Center(
            child: SizedBox(
              width: 30,  // 你可以调整这个值来改变 CircularProgressIndicator 的宽度
              height: 30, // 你可以调整这个值来改变 CircularProgressIndicator 的高度
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    List<List<String>> imageDataList = this.imageDataList.value;
    if (imageDataList.isEmpty) {
      // 关闭加载对话框
      Navigator.of(Get.context!).pop();
      return;
    }
    if (!selectedState.value.any((element) => element == true)) {
      // 关闭加载对话框
      Navigator.of(Get.context!).pop();
      return;
    }

    // 筛选出选中的图片
    List<List<String>> selectedImages = [];
    for (int i = 0; i < imageDataList.length; i++) {
      if (selectedState.value[i]) {
        selectedImages.add(imageDataList[i]);
      }
    }

    if (selectedImages.length == 1) {
      // 只有一张图片
      List<String> imageInfo = selectedImages[0];
      objectMgr.chatMgr.sendImage(
        chatID: chatId,
        width: int.parse(imageInfo[1]),
        height: int.parse(imageInfo[2]),
        data: File(imageInfo[0]),
        resolution: MediaResolution.image_high,
          caption: captionController.text
      );
    } else {
      // 多张图片
      List<AssetPreviewDetail> details = [];
      for (int i = 0; i < selectedImages.length; i++) {
        List<String> imageInfo = selectedImages[i];
        final String filePath = imageInfo[0];
        String fileName = filePath.split("/").last;
        final AssetEntity? result = await PhotoManager.editor.saveImageWithPath(
          filePath,
          title: fileName,
        );
        if (result != null) {
          details.add(
            AssetPreviewDetail(
              id: result.id,
              index: i,
              entity: result,
              caption: captionController.text,
            ),
          );
        }
      }
      objectMgr.chatMgr.sendNewAlbum(
        chatID: chatId,
        assets: details,
        caption: captionController.text,
      );
    }

    // 关闭加载对话框
    Navigator.of(Get.context!).pop();

    // 返回
    Get.back();
  }


  Future<void> sendImage1() async {
    List<List<String>> imageDataList = await ClipboardUtil.getClipboardImages();
    if(imageDataList.isEmpty) {
      // 没有图片就什么都不用干
      return;
    }
    if (!selectedState.value.any((element) => element == true)) {
      // 没有任何一张图片被选中，就什么都不用发送
      return;
    }

    // 筛选出选中的图片
    // List<List<String>> imageDataList = [];
    // for(int i = 0; i < imageDataListOriginal.length; i ++) {
    //   if(selectedState.value[i]) {
    //     imageDataList.add(imageDataListOriginal[i]);
    //   }
    // }

    if(imageDataList.length == 1) {
      // 就一张图片
      List<String> imageInfo = imageDataList[0];
      objectMgr.chatMgr.sendImage(
        chatID: chatId,
        width: int.parse(imageInfo[1]),
        height: int.parse(imageInfo[2]),
        data: File(imageInfo[0]),
        resolution: MediaResolution.image_high,
      );
    } else {
      // 代表有多张图片
      List<AssetPreviewDetail> details = [];
      for(int i = 0; i < imageDataList.length; i++) {
        List<String> imageInfo = imageDataList[i];
        final String filePath = imageInfo[0];
        final String fileName = filePath.split("/").toList().last;
        AssetEntity? result = await PhotoManager.editor.saveImageWithPath(
          filePath,
          title: fileName,
        );
        if(result != null) {
          details.add(AssetPreviewDetail(id: result.id, index: i, entity: result, caption: captionController.text));
        }
      }
      objectMgr.chatMgr.sendNewAlbum(chatID: chatId, assets: details,caption: captionController.text);
    }
    Get.back();
  }

  // 处理图片点击事件
  void toggleSelection() {
    int index = currentPage.value;
    if (index < 0 || index >= selectedState.value.length) return;

    bool wasSelected = selectedState.value[index];
    selectedState.value[index] = !wasSelected;

    if (wasSelected) {
      List<int> updatedNumbers = List.from(countNumber.value);
      List<bool> updatedSelection = List.from(selectedState.value);

      for (int i = index; i < updatedNumbers.length; i++) {
        updatedNumbers[i] -= 1;
      }
      updatedSelection[index] = false;

      countNumber.value = updatedNumbers;
      selectedState.value = updatedSelection;
    } else {
      List<int> updatedNumbers = List.from(countNumber.value);
      List<bool> updatedSelection = List.from(selectedState.value);

      for (int i = index; i < updatedNumbers.length; i++) {
        updatedNumbers[i] += 1;
      }
      updatedSelection[index] = true;

      countNumber.value = updatedNumbers;
      selectedState.value = updatedSelection;
    }
  }

}
