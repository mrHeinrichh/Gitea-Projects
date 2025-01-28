import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_bottom_sheet_content.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/home/setting/view/feedback/ctr_feedback.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class GalleryPage extends StatelessWidget {
  CtrFeedback controller = Get.find<CtrFeedback>();

  GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      showCancelButton: true,
      useBottomSafeArea: false,
      useTopSafeArea: true,
      trailing: CustomTextButton(
        localized(buttonDone),
        fontSize: 17,
        color: themeColor,
        onClick: () {
          Get.back();
          controller.getAssetPath();
        },
      ),
      middleChild: AssetPicker<AssetEntity, AssetPathEntity>(
        key: UniqueKey(),
        builder: DefaultAssetPickerBuilderDelegate(
          provider: controller.assetPickerProvider!,
          initialPermission: controller.ps!,
          gridCount: controller.pickerConfig!.gridCount,
          pickerTheme: controller.pickerConfig!.pickerTheme,
          gridThumbnailSize: controller.pickerConfig!.gridThumbnailSize,
          previewThumbnailSize: controller.pickerConfig!.previewThumbnailSize,
          loadingIndicatorBuilder:
              controller.pickerConfig!.loadingIndicatorBuilder,
          selectPredicate: controller.pickerConfig!.selectPredicate,
          shouldRevertGrid: controller.pickerConfig!.shouldRevertGrid,
          limitedPermissionOverlayPredicate:
              controller.pickerConfig!.limitedPermissionOverlayPredicate,
          pathNameBuilder: controller.pickerConfig!.pathNameBuilder,
          textDelegate: controller.pickerConfig!.textDelegate,
          themeColor: themeColor,
          locale: Localizations.maybeLocaleOf(context),
        ),
      ),
    );
  }
}
