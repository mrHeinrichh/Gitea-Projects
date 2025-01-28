import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/share_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import '../../../../utils/color.dart';
import '../../../../utils/utility.dart';

class RecentFilesGrid extends StatelessWidget {
  const RecentFilesGrid({
    Key? key,
    required this.recentFilesList,
    required this.inputController,
  }) : super(key: key);
  final List<RecentFile> recentFilesList;
  final CustomInputController inputController;

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
        itemCount: recentFilesList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final recentFile = recentFilesList[index];

          return GestureDetector(
            onTap: () {
              final controller = Get.find<FilePickerController>();

              if (controller.selectedList.contains(recentFile)) {
                controller.selectedList.remove(recentFile);
              } else if (controller.selectedList.isNotEmpty &&
                  (notBlank(objectMgr
                          .chatMgr.replyMessageMap[inputController.chatId]) ||
                      notBlank(objectMgr.chatMgr
                          .selectedMessageMap[inputController.chatId]))) {
                Toast.showToast(localized(errorReplyForwardMax1));
                return;
              } else if (controller.selectedList.length < 10) {
                controller.selectedList.add(recentFile);
              } else {
                Toast.showToast(localized(errorMax10Files));
              }

              if (controller.selectedList.length >= 1) {
                inputController.sendState.value = true;
              } else {
                inputController.sendState.value = false;
              }

              if (controller.selectedList.length > 1) {
                inputController.inputController.clear();
              }

              inputController.fileList.value = controller.selectedList
                  .where((e) => e.path != null)
                  .map<File>((e) => File(e.path!))
                  .toList();
            },
            child: Row(
              children: <Widget>[
                _buildFileIcon(recentFile),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.3,
                          color: ImColor.borderColor,
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
                            color: JXColors.primaryTextBlack,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        /// 文件大小
                        Text(
                          '${bytesToMB(recentFile.size ?? 0).toStringAsFixed(2)} MB',
                          style: const TextStyle(
                            color: JXColors.secondaryTextBlack,
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
                            ? accentColor
                            : JXColors.offWhite,
                        shape: BoxShape.circle,
                        border: Border.all(color: JXColors.white),
                      ),
                      child:
                          controller?.selectedList.contains(recentFile) ?? false
                              ? Center(
                                  child: Text(
                                    '${controller!.selectedList.indexOf(recentFile) + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: JXColors.white,
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
          color: accentColor,
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
