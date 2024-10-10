import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/sheet_title_bar.dart';
import 'package:jxim_client/managers/share_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/component/no_content_view.dart';
import 'package:jxim_client/views/login/components/purple_button.dart';
import 'package:path/path.dart' as p;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class GeneralFilePicker extends GetView<FilePickerController> {
  final DefaultAssetPickerProvider assetPickerProvider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final String picTag;
  final bool isAllowMultiple;
  final Function(List<File>) onFilesSelected;

  GeneralFilePicker({
    super.key,
    required this.picTag,
    required this.assetPickerProvider,
    required this.pickerConfig,
    required this.ps,
    required this.isAllowMultiple,
    required this.onFilesSelected,
  }) {
    Get.put(FilePickerController());
  }

  _loadingView() {
    return Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
          color: themeColor,
        ),
      ),
    );
  }

  Future<void> sendFile(FilePickerResult result) async {
    List<PlatformFile> toRemove = [];
    List<PlatformFile> duplicateFile = [];
    List<String> pathList = [];

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
            ),
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
    List<File> files = [];
    files = result.paths.map((path) => File(path!)).toList();
    onFilesSelected(files);
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
            color: colorBackground,
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
                      color: colorTextSecondary,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    child: Obx(
                      () => (controller.isLoading.value ||
                                  !controller.isInit.value) &&
                              Platform.isAndroid
                          ? _loadingView()
                          : controller.recentFilesList.isNotEmpty
                              ? GeneralRecentFile(
                                  recentFilesList: controller.recentFilesList,
                                  isAllowMultiple: isAllowMultiple,
                                  onFilesSelected: (List<File> selectedFiles) {
                                    onFilesSelected(selectedFiles);
                                  },
                                )
                              : Container(
                                  height: 310,
                                  decoration: const BoxDecoration(
                                    color: colorWhite,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                  ),
                                  child: NoContentView(
                                    icon: 'empty_folder_icon',
                                    title: localized(noRecentFile),
                                    subtitle: localized(findMoreOfYourDocument),
                                    subtitleFontSize: MFontSize.size17.value,
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
                    'provider': assetPickerProvider,
                    'pConfig': pickerConfig,
                    'ps': ps,
                    'tag': picTag,
                    'sendAsFile': true,
                    'showCaption': false,
                    'showResolution': false,
                    'enableMediaPreview': false,
                  })?.then((value) async {
                if (!value.containsKey('shouldSend') || !value['shouldSend']) {
                  return;
                }
                controller.selectedList.clear();
                Get.back();
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
                    colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
                  ),
                ),
                Text(
                  localized(chooseFromGalley),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: MFontWeight.bold4.value,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 60),
            color: colorBorder,
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
                    colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
                  ),
                ),
                Text(
                  localized(chooseFromFiles),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: MFontWeight.bold4.value,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onFileMenuClick(BuildContext context) async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    FilePickerResult? result = await renameFiles(r) ?? r;

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
              confirmColor: themeColor,
              cancelText: localized(cancel),
              confirmCallback: () {
                controller.recentFilesList.clear();
                sendFile(result);
              },
            );
          },
        );
      } else {
        controller.recentFilesList.clear();
        sendFile(result);
      }
    }
  }
}

class GeneralRecentFile extends StatelessWidget {
  const GeneralRecentFile({
    super.key,
    required this.recentFilesList,
    required this.isAllowMultiple,
    required this.onFilesSelected,
  });
  final List<RecentFile> recentFilesList;
  final bool isAllowMultiple;
  final Function(List<File>) onFilesSelected;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.metrics is PageMetrics) {
          return false;
        }

        if (notification.metrics is FixedScrollMetrics) {
          if (notification.metrics.axisDirection == AxisDirection.left ||
              notification.metrics.axisDirection == AxisDirection.right) {
            return false;
          }
        }

        return false;
      },
      child: ListView.builder(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        shrinkWrap: true,
        itemCount: recentFilesList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final recentFile = recentFilesList[index];

          return GestureDetector(
            onTap: () {
              final controller = Get.find<FilePickerController>();
              if (controller.selectedList.contains(recentFile)) {
                controller.selectedList.remove(recentFile);
              }

              if (controller.selectedList.length < 10) {
                controller.selectedList.add(recentFile);
              } else {
                Toast.showToast(localized(errorMax10Files));
              }

              if (!isAllowMultiple) {
                if (controller.selectedList.isNotEmpty) {
                  List<File> fileList = controller.selectedList
                      .where((e) => e.path != null)
                      .map<File>((e) => File(e.path!))
                      .toList();
                  onFilesSelected(fileList);
                }
              }
            },
            child: Row(
              children: <Widget>[
                _buildFileIcon(recentFile),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.3,
                          color: colorBorder,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        /// 文件名
                        Text(
                          recentFile.displayName ?? '',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: colorTextPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        /// 文件大小
                        Text(
                          '${bytesToMB(recentFile.size ?? 0).toStringAsFixed(2)} MB',
                          style: const TextStyle(
                            color: colorTextSecondary,
                            fontSize: 14,
                            height: 1,
                            overflow: TextOverflow.ellipsis,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  FilePickerController? controller;
                  if (Get.isRegistered<FilePickerController>()) {
                    controller = Get.find<FilePickerController>();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: controller?.selectedList.contains(recentFile) ??
                                false
                            ? themeColor
                            : colorWhite,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorWhite),
                      ),
                      child:
                          controller?.selectedList.contains(recentFile) ?? false
                              ? Center(
                                  child: Text(
                                    '${controller!.selectedList.indexOf(recentFile) + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: colorWhite,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  _buildFileIcon(RecentFile recentFile) {
    if (recentFile.type == "image/jpeg") {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: FileImage(File(recentFile.path!)),
            fit: BoxFit.fill,
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: themeColor,
        ),
        child: SvgPicture.asset(
          'assets/svgs/file_icon.svg',
          width: 18,
          height: 18,
        ),
      );
    }
  }
}
