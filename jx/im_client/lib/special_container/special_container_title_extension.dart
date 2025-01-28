import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/mini/components/local_mini_app_widget.dart';
import 'package:jxim_client/special_container/spexial_container_title.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

extension MiniAppExtension on SpecialContainerTitle {
  Widget getNoToolBarMiniAppWidget(BuildContext context) {
    Color color = hexToColor(objectMgr.miniAppMgr.h5Color.value);
    return Obx(
          () => Stack(
            alignment: Alignment.center, // 确保 _buildContentTitle() 的内容居中
            children: [
              // 中间内容
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 使 Row 内容大小仅包裹子组件
                  children: _buildContentTitle(),
                ),
              ),
              // 右侧控件
              Positioned(
                right: 16,
                child: Text(
                  objectMgr.miniAppMgr.h5Text.value,
                  style: jxTextStyle.textStyle14(color: color),
                ),
              ),
            ],
          ),
    );
  }

  Widget getFullScreenMiniAppWidget(BuildContext context, {String? route}) {
    return LocalMiniAppWidget(
      key: ValueKey("${objectMgr.miniAppMgr.currentApp?.id}"),
      app: objectMgr.miniAppMgr.currentApp ?? Apps(),
      startUrl: objectMgr.miniAppMgr.startUrl,
      openUid: objectMgr.miniAppMgr.currentOpenUid,
      isHorizontalScreen: objectMgr.miniAppMgr.isSpecialHorizontalScreen,
    );
  }

  List<Widget> _buildContentTitle() {
    String basePath = objectMgr.miniAppMgr.basePath;
    String path =
        "$basePath/mini_app/${objectMgr.miniAppMgr.currentApp?.id}";
    List<Widget> list = [];
    for (int i = 0; i < objectMgr.miniAppMgr.h5List.length; i++) {
      list.add(_buildContentCell(objectMgr.miniAppMgr.h5List[i], path));
      if (i < objectMgr.miniAppMgr.h5List.length - 1) {
        list.add(const SizedBox(width: 4));
      }
    }
    return list;
  }

  Widget _buildContentCell(String name, String path) {
    String url = "$path$name";
    return SvgPicture.file(
      File(url),
      width: 30,
      height: 30,
    );
  }
}
