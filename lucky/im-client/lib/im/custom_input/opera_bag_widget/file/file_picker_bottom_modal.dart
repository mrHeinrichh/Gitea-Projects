import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/recent_file_grid.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/login/components/purple_button.dart';
import 'package:path/path.dart' as p;

import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/aws_s3/file_uploader.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/im/custom_input/sheet_title_bar.dart';

class FilePickerBottomModal extends GetView<FilePickerController> {
  final CustomInputController inputController;
  final String picTag;

  FilePickerBottomModal(
      {Key? key, required this.inputController, required this.picTag})
      : super(key: key) {
    Get.put(FilePickerController());
  }

  _loadingView() {
    return Center(
        child: SizedBox(
      width: 44,
      height: 44,
      child: CircularProgressIndicator(
        color: accentColor,
      ),
    ));
  }

  Future<void> sendFile(FilePickerResult result) async {
    List<PlatformFile> toRemove = [];
    List<PlatformFile> duplicateFile = [];
    List<String> pathList = [];

    ///check now uploading file
    if (FileUploader.shared.uploadFileMap.length > 0) {
      FileUploader.shared.uploadFileMap.forEach((key, value) {
        pathList.add(value.originalPath!);
      });
    }

    for (var file in result.files) {
      ///check if exits in the uploading file
      if (pathList.isNotEmpty && pathList.contains(file.path)) {
        duplicateFile.add(file);
      }

      /// check the file is larger than 1GB
      if (file.size >= pow(2, 30)) {
        toRemove.add(file);
      } else if (p.basename(file.path!).split('.').length == 1) {
        /// check is no extension file
        Toast.showToast(localized(errorFileNoExtensionSupport),
            duration: const Duration(seconds: 2));
      }
    }

    /// remove the file
    result.files.removeWhere((element) =>
        toRemove.contains(element) || element.name.split('.').length == 1);

    if (toRemove.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: Text(localized(information)),
          content: Text(
              '${localized(selectedFile)} ${toRemove.map((element) => element.name).toList().toString().substring(1, toRemove.map((element) => element.name).toList().toString().length - 1)} ${localized(isTooLarge)}'),
          actions: [
            PurpleButton(
              title: localized(buttonOk),
              onPressed: () {
                Get.back();
                toRemove.clear();
              },
            )
          ],
        ),
      );
    }

    if (duplicateFile.isNotEmpty) {
      Toast.showToast(
          '${duplicateFile.map((e) => p.basename(e.path!)).toList()} ${localized(errorSelectedFileSend)}',
          duration: const Duration(seconds: 2));
      result.files.removeWhere((element) => duplicateFile.contains(element));
    }

    /// convert the PlatformFIle to file
    List<File> files = [];
    files = result.paths.map((path) => File(path!)).toList();

    inputController.fileList.value = files;
    inputController.chatController.onCancelFocus();

    inputController.onSend(null);
    controller.selectedList.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SheetTitleBar(
                title: localized(files),
                divider: false,
              ),
        Expanded(
          
          child: Container(
            color: sheetTitleBarColor,
            
            child: Column(
              children: <Widget>[
                
                const SizedBox(
                  height: 24,
                ),
                _buildMenu(context),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.only(left: 16, top: 24, bottom: 4),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localized(recentFile),
                    style: TextStyle(
                      fontSize: 12,
                      color: JXColors.secondaryTextBlack,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      right: 16,
                      left: 16,
                      bottom: 16,
                    ),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    child: Obx(
                      () =>
                          (controller.isLoading.value || !controller.isInit.value) &&
                                  Platform.isAndroid
                              ? _loadingView()
                              : controller.recentFilesList.length > 0
                                  ? RecentFilesGrid(
                                      recentFilesList: controller.recentFilesList,
                                      inputController: inputController,
                                    )
                                  : Container(
                                      decoration: const BoxDecoration(
                                        color: JXColors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            localized(noRecentFile),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: MFontWeight.bold5.value,
                                            ),
                                          ),
                                          Text(
                                            localized(findMoreOfYourDocument),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: MFontWeight.bold4.value,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> onFileMenuClick(BuildContext context) async {
    bool allowMultiple = notBlank(
            objectMgr.chatMgr.replyMessageMap[inputController.chatId]) ||
        notBlank(objectMgr.chatMgr.selectedMessageMap[inputController.chatId]);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: !allowMultiple,
    );

    ///check the result is null or not
    if (result != null) {
      /// if select more than 10 files
      if (result.files.length > 10) {
        result.files.removeRange(10, result.files.length);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: localized(errorMax10Files),
              content: Text(localized(theFirst10SelectedFileWillSendOnly)),
              confirmText: localized(send),
              confirmColor: accentColor,
              cancelText: localized(cancel),
              confirmCallback: () {
                controller.recentFilesList.clear();
                Get.back();
                sendFile(result);
              },
            );
          },
        );
      } else {
        controller.recentFilesList.clear();
        Get.back();
        sendFile(result);
      }
    }
  }

  _buildMenu(context) {
    return Container(
      height: 88,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(8.0),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Get.toNamed(RouteName.albumView,
                  preventDuplicates: false,
                  arguments: {
                    'tag': picTag,
                    'sendAsFile': true,
                  });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 43.5,
                  width: 60,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svgs/pic_icon.svg',
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                        accentColor,
                        BlendMode.srcIn),
                  ),
                ),
                Text(
                  localized(chooseFromGalley),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: MFontWeight.bold4.value,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: EdgeInsets.only(left: 60.w),
            color: JXColors.outlineColor,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              await onFileMenuClick(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 43.5,
                  width: 60,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svgs/cloud_icon.svg',
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                        accentColor,
                        BlendMode.srcIn),
                  ),
                ),
                Text(
                  localized(chooseFromFiles),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: MFontWeight.bold4.value,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
