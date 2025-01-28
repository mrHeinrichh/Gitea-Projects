import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class CommonAlbumView extends StatefulWidget {
  const CommonAlbumView({
    super.key,
  });

  @override
  State<CommonAlbumView> createState() => _CommonAlbumViewState();
}

class _CommonAlbumViewState extends State<CommonAlbumView> {
  late String tag;
  late final CommonAlbumController controller;

  @override
  void initState() {
    super.initState();
    tag = Get.arguments['tag'];
    controller =
        Get.findOrPut<CommonAlbumController>(CommonAlbumController(), tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        title: Text(localized(album)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: controller.assetPickerProvider!.isAssetsEmpty
          ? Center(
              child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                SvgPicture.asset(
                  'assets/svgs/noPermission_state_photo.svg',
                  width: 148,
                  height: 148,
                ),
                const SizedBox(height: 16),
                Text(
                  localized(chatEmptyList),
                  style: jxTextStyle.textStyleBold16(),
                ),
              ],
            ))
          : ListView.builder(
              itemCount: controller.assetPickerProvider?.paths.length,
              itemBuilder: (BuildContext context, int index) {
                final PathWrapper<AssetPathEntity> pathEntity =
                    controller.assetPickerProvider!.paths.elementAt(index);
                final Uint8List? data = controller.assetPickerProvider?.paths
                    .elementAt(index)
                    .thumbnailData;

                if (pathEntity.assetCount == 0) return const SizedBox.shrink();

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Get.toNamed(
                      RouteName.commonSelectedAlbumView,
                      arguments: {
                        'pathEntity': pathEntity,
                        'tag': tag,
                      },
                    )?.then((value) {
                      if (value != null) {
                        Get.back(result: value);
                        return;
                      }
                      Future.delayed(
                          const Duration(milliseconds: 300),
                          () => controller.assetPickerProvider!.switchPath(
                              controller.assetPickerProvider!.paths.first));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        if (data != null)
                          Image.memory(
                            data,
                            width: 60.0,
                            height: 60.0,
                            fit: BoxFit.cover,
                          ),
                        if (data != null) const SizedBox(width: 5.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.getPathName(
                                    context, pathEntity.path),
                                style: jxTextStyle.textStyleBold16(
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                pathEntity.assetCount.toString(),
                                style: const TextStyle(
                                  color: colorTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
