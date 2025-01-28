import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final DefaultAssetPickerProvider provider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final bool isUseCommonAlbum; //是否使用共用的相冊元件

  const ProfilePhotoPicker({
    super.key,
    required this.provider,
    required this.pickerConfig,
    required this.ps,
    this.isUseCommonAlbum = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      title: localized(chooseProfilePhoto),
      showCancelButton: true,
      height: MediaQuery.of(context).size.height,
      trailing: CustomTextButton(
        localized(album),
        onClick: () async {
          if (!isUseCommonAlbum) {
            XFile? data =
                await ImagePicker().pickImage(source: ImageSource.gallery);
            final AssetEntity? imageEntity =
                await PhotoManager.editor.saveImageWithPath(
              data!.path,
              title: data.name,
            );

            provider.selectAsset(imageEntity!);
          } else {
            Get.toNamed(
              RouteName.commonAlbumView,
              preventDuplicates: false,
              arguments: {
                'tag': commonAlbumTag,
              },
            )?.then((value) {
              if (value != null) Get.back();
            });
          }
        },
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
