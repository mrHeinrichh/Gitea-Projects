import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/im_toast/im_bottom_toast.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../views/component/new_appbar.dart';

class UploadReelView extends GetView<UploadReelController> {
  const UploadReelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        withBackTxt: false,
        title: localized(sendPost),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Obx(
                      () => Visibility(
                        child: Row(
                          children: List.generate(
                            controller.resultPath.length,
                            (index) {
                              return _buildImage(controller.resultPath[index]);
                            },
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.resultPath.length == 0,
                        child: GestureDetector(
                          onTap: () {
                            if (controller.resultPath.length >= 1) {
                              ImBottomToast(Routes.navigatorKey.currentContext!,
                                  title:
                                      localized(maxImageCount, params: ["1"]),
                                  icon: ImBottomNotifType.INFORMATION);
                            } else {
                              controller.showPickPhotoOption(context);
                            }
                          },
                          child: Container(
                            width: 98,
                            height: 98,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/svgs/add.svg',
                                colorFilter: const ColorFilter.mode(
                                    JXColors.primaryTextBlack, BlendMode.srcIn),
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
              const SizedBox(height: 8),
              _buildInput(
                  1, 30, localized(addTitle), controller.titleTextController),
              _buildInput(6, 100, "${localized(addDescription)}...",
                  controller.descriptionTextController),
              const CustomDivider(
                thickness: 1,
              ),
              Obx(
                () => Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: SvgPicture.asset(
                            'assets/svgs/tag_icon.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                                JXColors.primaryTextBlack, BlendMode.srcIn),
                          ),
                        ),
                        Text(
                          localized(tag),
                          style: jxTextStyle.textStyleBold16(
                              fontWeight: MFontWeight.bold6.value),
                        ),
                      ],
                    ),
                    tilePadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    trailing: SvgPicture.asset(
                      controller.isTagExpand.value
                          ? 'assets/svgs/arrow_right.svg'
                          : 'assets/svgs/arrow_down_icon.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                          JXColors.secondaryTextBlack, BlendMode.srcIn),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    initiallyExpanded: controller.isTagExpand.value,
                    children: <Widget>[
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 2.0
                        ),
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: controller.tagList.length,
                        itemBuilder: (context, index) {
                          return tagItem(index, controller.tagList[index]);
                        },
                      ),
                    ],
                    onExpansionChanged: (bool expanded) {
                      controller.onTagExpand(expanded);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Spacer(),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12.0)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/draft_icon.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  JXColors.primaryTextBlack, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localized(saveDraft),
                              style: jxTextStyle.textStyleBold16(),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.onSubmit(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: controller.isValidSubmit.value
                                ? accentColor
                                : JXColors.secondaryTextBlack,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12.0)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/svgs/post_icon.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localized(postText),
                                style: jxTextStyle.textStyleBold16(
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(AssetEntity assetEntity) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Image(
            image: AssetEntityImageProvider(
              assetEntity,
              isOriginal: false,
            ),
            width: 98,
            height: 98,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              controller.resultPath.remove(assetEntity);
              controller.validateSubmit();
            },
            child: Center(
              child: SvgPicture.asset(
                'assets/svgs/accent_clear_icon.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildInput(int maxLine, int maxLength, String hintText,
      TextEditingController textController) {
    return TextField(
      controller: textController,
      textInputAction: TextInputAction.done,
      style: jxTextStyle.textStyle16(),
      maxLines: maxLine,
      maxLength: maxLength,
      onChanged: (value) => controller.onChangeValue(value),
      buildCounter: (
        BuildContext context, {
        required int currentLength,
        required int? maxLength,
        required bool isFocused,
      }) {
        return null;
      },
      cursorColor: accentColor,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 8,
        ),
        hintText: hintText,
        hintStyle: jxTextStyle.textStyle16(color: JXColors.supportingTextBlack),
        border: InputBorder.none,
      ),
    );
  }

  Widget tagItem(int index, String tag) {
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
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 4),
          decoration: BoxDecoration(
            color: controller.selectedTagList.contains(tag)
                ? Colors.white
                : JXColors.primaryTextBlack.withOpacity(0.06),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(
                width: 1,
                color: controller.selectedTagList.contains(tag)
                    ? accentColor
                    : Colors.transparent),
          ),
          child: Text(
            tag,
            style: jxTextStyle.textStyle14(
              color: controller.selectedTagList.contains(tag)
                  ? JXColors.primaryTextBlack
                  : JXColors.secondaryTextBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
