import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/home/setting/view/feedback/ctr_feedback.dart';
import 'package:jxim_client/home/setting/view/feedback/gallery_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class FeedbackPage extends GetView<CtrFeedback> {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColor.systemBg,
      resizeToAvoidBottomInset: false,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(feedback),
        onPressedBackBtn: () =>
            objectMgr.loginMgr.isDesktop ? Get.back(id: 3) : Get.back(),
        trailing: [
          Obx(
            () => controller.isLoading.value
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 25,
                      width: 25,
                      child: BallCircleLoading(
                        radius: 10,
                        ballStyle: BallStyle(
                          size: 4,
                          color: themeColor,
                          ballType: BallType.solid,
                          borderWidth: 1,
                          borderColor: themeColor,
                        ),
                      ),
                    ),
                  )
                : OpacityEffect(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: controller.isEnable
                          ? () {
                              controller.submitFeedback();
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(
                              color: controller.isEnable
                                  ? themeColor
                                  : colorTextSecondary),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8, left: 16).w,
              child: Text(
                localized(category),
                style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: colorSurface,
                child: Column(
                  children: [
                    OverlayEffect(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            barrierColor: colorOverlay40,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return SelectionBottomSheet(
                                context: context,
                                selectionOptionModelList: controller.category,
                                onTapCancel: () {
                                  Navigator.pop(context);
                                },
                                callback: (index) {
                                  controller.selectedIndex.value = index;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 8,
                            top: 12,
                            bottom: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Obx(
                                  () => Text(
                                    controller.selectedIndex.value == -1
                                        ? localized(select)
                                        : controller
                                                .category[controller
                                                    .selectedIndex.value]
                                                .title ??
                                            "",
                                    style: jxTextStyle.headerText(
                                      color:
                                          controller.selectedIndex.value == -1
                                              ? colorTextSecondary
                                              : colorTextPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                'assets/svgs/arrow_right.svg',
                                color: colorTextSupporting,
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(bottom: 8, left: 16).w,
              child: Text(
                localized(description),
                style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
              ),
            ),
            Obx(
              () => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorSurface,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Center(
                      child: TextField(
                        contextMenuBuilder: im_common.textMenuBar,
                        textInputAction: TextInputAction.done,
                        controller: controller.descriptionController,
                        onChanged: (value) {
                          controller.getDescriptionWordCount();
                        },
                        style: jxTextStyle.headerText(),
                        minLines: 1,
                        maxLines: 10,
                        maxLength: 1000,
                        buildCounter: (
                          BuildContext context, {
                          required int currentLength,
                          required int? maxLength,
                          required bool isFocused,
                        }) {
                          return null;
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: localized(writeDescription),
                          hintStyle: jxTextStyle.headerText(
                            color: colorTextSupporting,
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(maxHeight: 48),
                          suffixIcon: Visibility(
                            visible: controller
                                .descriptionController.text.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  controller.descriptionController.clear();
                                  controller.descriptionWordCount.value = 1000;
                                },
                                child: OpacityEffect(
                                  child: SvgPicture.asset(
                                    'assets/svgs/clear_icon.svg',
                                    color: colorTextPlaceholder,
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${controller.descriptionWordCount.value}${localized(charactersLeft)}",
                          style: jxTextStyle.normalSmallText(
                            color: colorTextPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            if (!objectMgr.loginMgr.isDesktop) const SizedBox(height: 24),
            if (!objectMgr.loginMgr.isDesktop)
              Container(
                padding: const EdgeInsets.only(bottom: 8, left: 16).w,
                child: Text(
                  localized(attachSupportImage),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
                ),
              ),
            if (!objectMgr.loginMgr.isDesktop)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Obx(() => Visibility(
                          child: Row(
                            children: List.generate(
                              controller.resultPath.length,
                              (index) {
                                return _buildImage(
                                    controller.resultPath[index]);
                              },
                            ),
                          ),
                        )),
                    GestureDetector(
                      onTap: () {
                        if (controller.resultPath.length >= 5) {
                          imBottomToast(navigatorKey.currentContext!,
                              title: localized(maxImageCount, params: ["5"]),
                              icon: ImBottomNotifType.INFORMATION);
                        } else {
                          FocusScope.of(context).unfocus();
                          showModalBottomSheet(
                            context: context,
                            isDismissible: true,
                            isScrollControlled: true,
                            barrierColor: colorOverlay40,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return SelectionBottomSheet(
                                context: context,
                                selectionOptionModelList:
                                    controller.photoOption,
                                callback: (int index) async {
                                  if (index == 0) {
                                    if (objectMgr.callMgr.getCurrentState() !=
                                        CallState.Idle) {
                                      Toast.showToast(
                                          localized(toastEndCallFirst));
                                      return;
                                    }
                                    getCameraPhoto(context);
                                  } else if (index == 1) {
                                    await getGalleryPhoto(context);
                                  }
                                },
                              );
                            },
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 12,
                        ),
                        child: ForegroundOverlayEffect(
                          radius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                            bottom: Radius.circular(12),
                          ),
                          child: Container(
                            width: 98,
                            height: 98,
                            decoration: BoxDecoration(
                              color: colorSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/svgs/add.svg',
                                color: colorTextPrimary,
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!objectMgr.loginMgr.isDesktop)
              Container(
                padding: const EdgeInsets.only(top: 8, left: 16).w,
                child: Text(
                  localized(attachImageDescription, params: ["5", "5"]),
                  style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    return Stack(
      children: [
        Container(
          width: 98,
          height: 98,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.file(
            key: ValueKey(path),
            File(path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: GestureDetector(
            onTap: () {
              controller.resultPath.remove(path);
            },
            child: Center(
              child: SvgPicture.asset(
                'assets/svgs/greyClearIcon.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
        )
      ],
    );
  }

  getCameraPhoto(BuildContext context) async {
    var isGranted = await checkCameraOrPhotoPermission(type: 1);
    if (!isGranted) return;
    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
          isMirrorFrontCamera: isMirrorFrontCamera);
    } else {
      final Map<String, dynamic>? res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const CamerawesomePage()));
      if (res == null) {
        return;
      }
      entity = res["result"];
    }
    if (entity == null) {
      return;
    } else {
      File? assetFile = await entity.file;

      File? compressedFile = await getThumbImageWithPath(
        assetFile!,
        entity.width,
        entity.height,
        savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        sub: 'feedback',
      );
      controller.resultPath.add(compressedFile.path);
    }
  }

  getGalleryPhoto(BuildContext context) async {
    var isGranted = await controller.onPrepareMediaPicker();
    if (!isGranted) return;

    showModalBottomSheet(
      context: Get.context!,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return GalleryPage();
      },
    );
  }
}
