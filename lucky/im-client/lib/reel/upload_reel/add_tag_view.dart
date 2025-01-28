import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../views/component/click_effect_button.dart';
import '../../views/component/new_appbar.dart';

class AddTagView extends StatefulWidget {
  const AddTagView({Key? key}) : super(key: key);

  @override
  State<AddTagView> createState() => _AddTagViewState();
}

class _AddTagViewState extends State<AddTagView> {
  UploadReelController? get controller =>
      Get.isRegistered<UploadReelController>()
          ? Get.find<UploadReelController>()
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: "自定义标签",
        onPressedBackBtn: () => controller?.getBackPage(),
        trailing: [
          Obx(
            () => Visibility(
              visible: controller!.isValidCreateTag.value,
              child: GestureDetector(
                onTap: () => controller?.createTag(),
                child: OpacityEffect(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      localized(buttonDone),
                      style: jxTextStyle.textStyle17(color: accentColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: controller?.tagTextController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: jxTextStyle.textStyle16(),
                  maxLines: 1,
                  maxLength: 10,
                  onChanged: (value) => controller?.onChangeTagValue(value),
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
                    hintText: "请自定义您的作品标签",
                    hintStyle: jxTextStyle.textStyle16(
                        color: JXColors.supportingTextBlack),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12.0),
              alignment: Alignment.centerRight,
              child: Obx(
                () => Text(
                  "${controller?.tagWordCount.value}/10",
                  style: jxTextStyle.textStyle17(
                      color: JXColors.supportingTextBlack),
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller!.searchTagList.length > 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: JXColors.primaryTextBlack.withOpacity(0.04),
                  child: Row(
                    children: [
                      Text(
                        "类似:",
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              controller!.searchTagList.length,
                              (index) {
                                return tagItem(
                                    index, controller!.searchTagList[index]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tagItem(int index, String tag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => controller?.onClickSearchTag(tag),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        width: 88,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: JXColors.primaryTextBlack.withOpacity(0.06),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          tag,
          style: jxTextStyle.textStyle14(
            color: JXColors.secondaryTextBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
