import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';

class GifsComponentGridView extends StatefulWidget {
  final String title;
  final List<Gifs> data;
  final String chatId;

  const GifsComponentGridView({
    super.key,
    required this.title,
    required this.data,
    required this.chatId,
  });

  @override
  State<GifsComponentGridView> createState() => _GifsComponentGridViewState();
}

class _GifsComponentGridViewState extends State<GifsComponentGridView> {
  CustomInputController? controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomInputController>(tag: widget.chatId);
  }

  int crossAxisCount = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          widget.title,
          style: jxTextStyle
              .textStyleBold12(
                color: colorTextSecondary,
              )
              .copyWith(
                fontFamily: 'pingfang',
                height: ImLineHeight.getLineHeight(
                  fontSize: objectMgr.loginMgr.isDesktop ? 11 : 12,
                  lineHeight: objectMgr.loginMgr.isDesktop ? 13 : 14.4,
                ),
              ),
          textAlign: TextAlign.center,
        ),
        ImGap.vGap8,
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: objectMgr.loginMgr.isDesktop ? 2 : 0.5,
            crossAxisSpacing: objectMgr.loginMgr.isDesktop ? 2 : 0.5,
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.1
          ),
          itemCount: widget.data.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                controller?.onSend(
                  null,
                  isSendGif: true,
                  gifs: widget.data[index],
                );
                objectMgr.stickerMgr.updateRecentGif(widget.data[index]);
              },
              child: RemoteImage(
                width: ScreenUtil().screenWidth / crossAxisCount,
                height: ScreenUtil().screenWidth / crossAxisCount,
                fit: BoxFit.cover,
                key: ValueKey(widget.data[index].id),
                src: widget.data[index].path,
                shouldAnimate: true,
              ),
            );
          },
        ),
      ],
    );
  }
}
