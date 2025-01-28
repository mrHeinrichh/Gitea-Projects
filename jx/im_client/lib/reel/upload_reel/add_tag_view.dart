import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class AddTagView extends StatefulWidget {
  const AddTagView({super.key});

  @override
  State<AddTagView> createState() => _AddTagViewState();
}

class _AddTagViewState extends State<AddTagView> {
  UploadReelController? get controller =>
      Get.isRegistered<UploadReelController>()
          ? Get.find<UploadReelController>()
          : null;

  @override
  void dispose() {
    controller?.tagWordCount.value = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(reelCustomLabel),
        onPressedBackBtn: () {
          controller?.tagTextController.clear();
          Get.back();
        },
        trailing: [
          Obx(
            () => Visibility(
              visible: controller!.isValidCreateTag.value,
              child: Center(
                child: CustomTextButton(
                  localized(saveButton),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onClick: () {
                    controller?.createTag();
                    controller?.tagTextController.clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              contextMenuBuilder: textMenuBar,
              controller: controller?.tagTextController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontSize: MFontSize.size17.value,
                color: colorTextPrimary,
                decorationThickness: 0,
              ),
              maxLines: 1,
              onChanged: (value) => controller?.onChangeTagValue(value),
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              cursorColor: themeColor,
              cursorRadius: const Radius.circular(2),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                hintText: localized(reelCustomizeWorkLabel),
                hintStyle: jxTextStyle.textStyle17(color: colorTextSupporting),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${controller?.tagWordCount.value}",
                    style: jxTextStyle.textStyle17(
                      color: controller?.tagWordCount.value == 0
                          ? colorTextSupporting
                          : colorTextPrimary,
                    ),
                  ),
                  Text(
                    "/10",
                    style: jxTextStyle.textStyle17(color: colorTextSupporting),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            List searchTagList = controller!.searchTagList;

            return Visibility(
              visible: searchTagList.isNotEmpty,
              child: _buildSearchTagList(searchTagList),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchTagList(List searchTagList) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      color: colorTextPrimary.withOpacity(0.04),
      child: Row(
        children: [
          Text(
            "${localized(reelSimilarTo)}:",
            style: jxTextStyle.textStyle17(color: colorTextSecondary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: searchTagList.length,
                padding: EdgeInsets.zero,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: _buildTagItem(
                      index,
                      searchTagList[index],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(int index, String tag) {
    final borderRadius = BorderRadius.circular(4);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => controller?.onClickSearchTag(tag),
      child: ForegroundOverlayEffect(
        radius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorTextPrimary.withOpacity(0.06),
            borderRadius: borderRadius,
          ),
          child: Text(
            tag,
            style: jxTextStyle.textStyle14(color: colorTextSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
