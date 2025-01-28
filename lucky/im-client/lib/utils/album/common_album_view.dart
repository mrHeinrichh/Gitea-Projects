import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../theme/text_styles.dart';

class CommonAlbumView extends StatefulWidget {
  const CommonAlbumView({
    Key? key,
  }) : super(key: key);

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
    controller = Get.find<CommonAlbumController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).iconTheme.color),
        ),
        title: Text(localized(album)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: ListView.builder(
          itemCount: controller.assetPickerProvider?.pathsList.keys.length,
          itemBuilder: (BuildContext context, int index) {
            final AssetPathEntity pathEntity =
            controller.assetPickerProvider!.pathsList.keys.elementAt(index);
            final Uint8List? data = controller
                .assetPickerProvider?.pathsList.values
                .elementAt(index);

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                Get.toNamed(RouteName.commonSelectedAlbumView, arguments: {
                  'pathEntity': pathEntity,
                  'tag': tag,
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
                            controller.getPathName(context, pathEntity),
                            style: jxTextStyle.textStyleBold16(fontWeight: MFontWeight.bold6.value,),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            pathEntity.assetCount.toString(),
                            style: TextStyle(
                              color: systemColor,
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
      ),
    );
  }
}
