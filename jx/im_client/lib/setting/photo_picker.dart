import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoPicker extends StatelessWidget {
  final DefaultAssetPickerProvider provider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final bool isUseCommonAlbum; //是否使用共用的相冊元件

  const PhotoPicker({
    super.key,
    required this.provider,
    required this.pickerConfig,
    required this.ps,
    this.isUseCommonAlbum = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      title: localized(album),
      leading: CustomImage(
        'assets/svgs/close_icon.svg',
        size: 24,
        color: themeColor,
        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        onClick: () => Get.back(),
      ),
      useBottomSafeArea: false,
      middleChild: SizedBox(
        height: double.infinity,
        child: AssetPicker<AssetEntity, AssetPathEntity>(
          key: Singleton.pickerKey,
          builder: DefaultAssetPickerBuilderDelegate(
            provider: provider,
            initialPermission: ps,
            gridCount: pickerConfig.gridCount,
            pickerTheme: pickerConfig.pickerTheme,
            gridThumbnailSize: pickerConfig.gridThumbnailSize,
            previewThumbnailSize: pickerConfig.previewThumbnailSize,
            specialPickerType: pickerConfig.specialPickerType,
            specialItemPosition: pickerConfig.specialItemPosition,
            specialItemBuilder: pickerConfig.specialItemBuilder,
            loadingIndicatorBuilder: pickerConfig.loadingIndicatorBuilder,
            selectPredicate: pickerConfig.selectPredicate,
            shouldRevertGrid: pickerConfig.shouldRevertGrid,
            limitedPermissionOverlayPredicate:
                pickerConfig.limitedPermissionOverlayPredicate,
            pathNameBuilder: pickerConfig.pathNameBuilder,
            textDelegate: pickerConfig.textDelegate,
            themeColor: pickerConfig.themeColor,
            locale: Localizations.maybeLocaleOf(context),
          ),
        ),
      ),
    );
  }
}
