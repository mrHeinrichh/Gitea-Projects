import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class UploadReelView extends GetView<UploadReelController> {
  const UploadReelView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: localized(sendPost),
          onPressedBackBtn: controller.getBackPage,
        ),
        body: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => controller.resultPath.isNotEmpty
                        ? _buildImage(controller.resultPath.first)
                        : GestureDetector(
                            onTap: () async {
                              if (controller.resultPath.isNotEmpty) {
                                imBottomToast(
                                  navigatorKey.currentContext!,
                                  title:
                                      localized(maxImageCount, params: ["1"]),
                                  icon: ImBottomNotifType.INFORMATION,
                                );
                              } else {
                                controller.showPickPhotoOption(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ForegroundOverlayEffect(
                                radius: BorderRadius.circular(8),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colorWhite,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      width: 1,
                                      color: colorTextPrimary.withOpacity(0.20),
                                    ),
                                  ),
                                  child: CustomImage(
                                    'assets/svgs/add.svg',
                                    color: colorTextPrimary.withOpacity(0.20),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // _buildInput(
                          //   maxLines: 1,
                          //   maxLength: 30,
                          //   hintText: localized(addTitle),
                          //   textController: controller.titleTextController,
                          // ),
                          _buildInput(
                            maxLength: 1000,
                            hintText: "${localized(addDescription)}...",
                            textController:
                                controller.descriptionTextController,
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            String selectedTagText = '';
                            for (var tag in controller.selectedTagList) {
                              selectedTagText += '#${tag.tag} ';
                            }

                            return Text(
                              selectedTagText,
                              style: jxTextStyle.textStyle17(color: themeColor),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const CustomDivider(),
                  _buildTagContent(context),
                  const SizedBox(height: 45),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagContent(BuildContext context) {
    double itemHeight = 34;
    double itemSpacing = 4;
    int itemCount = 4;
    int maxRow = 5;
    double itemWidth = (MediaQuery.of(context).size.width - 36) / itemCount;

    return Column(
      children: [
        Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              controller.onTagExpand(!controller.isTagExpand.value);
            },
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  const CustomImage(
                    'assets/svgs/tag_icon.svg',
                    width: 24,
                    height: 24,
                    color: colorTextPrimary,
                    padding: EdgeInsets.only(right: 4),
                  ),
                  Text(
                    localized(tag),
                    style: jxTextStyle.textStyleBold17(),
                  ),
                  const Spacer(),
                  OpacityEffect(
                    child: CustomImage(
                      'assets/svgs/arrow_${controller.isTagExpand.value ? 'up' : 'down'}_icon.svg',
                      size: 24,
                      color: colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: (itemHeight * maxRow) + (itemSpacing * maxRow),
          child: Obx(() {
            int tagLength = controller.tagList.length;

            if (!controller.isTagExpand.value && tagLength > 8) {
              tagLength = 8;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: itemCount,
                crossAxisSpacing: itemSpacing,
                mainAxisSpacing: itemSpacing,
                childAspectRatio: itemWidth / itemHeight,
              ),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: tagLength,
              itemBuilder: (context, index) {
                return _buildTagItem(index, controller.tagList[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: CustomButton(
              callBack: () {
                Toast.showToast(localized(homeToBeContinue));
              },
              color: Colors.transparent,
              withBorder: true,
              contentWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomImage(
                    'assets/svgs/draft_icon.svg',
                    size: 20,
                    color: colorTextPrimary,
                    padding: EdgeInsets.only(right: 8),
                  ),
                  Text(
                    localized(saveDraft),
                    style: jxTextStyle.textStyleBold14(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              callBack: () => controller.onSubmit(),
              color: controller.isValidSubmit.value
                  ? themeColor
                  : colorTextSecondary,
              contentWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomImage(
                    'assets/svgs/post_icon.svg',
                    size: 20,
                    color: colorWhite,
                    padding: EdgeInsets.only(right: 8),
                  ),
                  Text(
                    localized(postText),
                    style: jxTextStyle.textStyleBold14(color: colorWhite),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(AssetEntity assetEntity) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, right: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: AssetEntityImageProvider(
                assetEntity,
                isOriginal: false,
              ),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: CustomImage(
            'assets/svgs/reel_delete_icon.svg',
            size: 20,
            padding: const EdgeInsets.all(20),
            onClick: () {
              controller.resultPath.remove(assetEntity);
              controller.validateSubmit();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    int? maxLines,
    required int maxLength,
    required String hintText,
    required TextEditingController textController,
  }) {
    return Expanded(
      child: ListView(
        children: [
          TextField(
            contextMenuBuilder: common.textMenuBar,
            controller: textController,
            // textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: MFontSize.size17.value,
              color: colorTextPrimary,
              decorationThickness: 0,
            ),
            maxLines: maxLines,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            onChanged: (value) => controller.onChangeValue(value),
            cursorColor: themeColor,
            cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hintText,
              hintStyle: jxTextStyle.textStyle17(color: colorTextSupporting),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(int index, ReelUploadTag tag) {
    final borderRadius = BorderRadius.circular(4);

    return Obx(
      () => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (index == 0) {
            controller.redirectToAddTag();
          } else {
            controller.selectTag(tag);
          }
        },
        child: ForegroundOverlayEffect(
          radius: borderRadius,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: controller.selectedTagList.contains(tag)
                  ? colorWhite
                  : colorTextPrimary.withOpacity(0.06),
              borderRadius: borderRadius,
              border: Border.all(
                width: 1,
                color: controller.selectedTagList.contains(tag)
                    ? themeColor
                    : Colors.transparent,
              ),
            ),
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  if (index == 0)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: CustomImage(
                        'assets/svgs/add.svg',
                        size: 10,
                        padding: EdgeInsets.only(right: 4),
                      ),
                    ),
                  TextSpan(
                    text: tag.tag,
                    style: jxTextStyle.textStyle14(
                      color: controller.selectedTagList.contains(tag)
                          ? colorTextPrimary
                          : colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
