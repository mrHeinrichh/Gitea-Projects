import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../utils/theme/text_styles.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final DefaultAssetPickerProvider provider;
  final AssetPickerConfig pickerConfig;
  final PermissionState ps;
  final bool isUseCommonAlbum;    //是否使用共用的相冊元件

  ProfilePhotoPicker({
    Key? key,
    required this.provider,
    required this.pickerConfig,
    required this.ps,
    this.isUseCommonAlbum = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          /// 本体
          Positioned.fill(
            top: 60.0.w,
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

          // appBar
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            child: Container(
              padding: EdgeInsets.all(20.0.w),
              decoration: BoxDecoration(
                color: offWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0.w),
                  topRight: Radius.circular(18.0.w),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: dividerColor,
                    blurRadius: 0.0.w,
                    offset: const Offset(0.0, -1.0),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: OpacityEffect(
                      child: Text(
                        localized(buttonCancel),
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      localized(chooseProfilePhoto),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (!isUseCommonAlbum) {
                        XFile? data = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        final AssetEntity? imageEntity =
                        await PhotoManager.editor.saveImageWithPath(
                          data!.path,
                          title: data.name,
                        );

                        provider.selectAsset(imageEntity!);
                      } else {
                        Get.toNamed(RouteName.commonAlbumView,
                            preventDuplicates: false,
                            arguments: {
                              'tag': commonAlbumTag,
                            });
                      }
                    },
                    child: OpacityEffect(
                      child: Text(
                        localized(album),
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
