import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/navigator_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrCode extends StatefulWidget {
  const QrCode({Key? key}) : super(key: key);

  @override
  _QrCodeState createState() => _QrCodeState();
}

class IconObj {
  int index;
  String title;
  String url;

  IconObj({required this.index, required this.title, required this.url});
}

class _QrCodeState extends State<QrCode> {
  final GlobalKey _globalKey = GlobalKey();
  String downAppUrl = Config().scanAppUrl;

  _onScan(BuildContext context) async {
    if (rtcIsCalling()) {
      return;
    }
    var c = await Permissions.request([Permission.camera], context: context);
    if (!c) {
      return;
    }
    if (objectMgr.navigatorMgr.isExit(navigatorTypeScan)) {
      Get.back();
    }
  }

  _onSave() async {
    if (await Permission.storage.request().isGranted) {
      BuildContext? buildContext = _globalKey.currentContext;
      if (buildContext != null) {
        RenderRepaintBoundary boundary =
            buildContext.findRenderObject() as RenderRepaintBoundary;
        var image = await boundary.toImage();
        ByteData? byteData =
            await image.toByteData(format: ImageByteFormat.png);
        if (byteData != null) {
          var result = await ImageGallerySaver.saveImage(
              byteData.buffer.asUint8List(),
              quality: 100);
          Toast.showToast(result != null
              ? localized(toastSaveSuccess)
              : localized(toastSaveUnsuccessful));
        }
      }
    }
  }

  _onWechat() {
    Toast.showToast(localized(toastComingSoon));
  }

  _onQq() {
    Toast.showToast(localized(toastComingSoon));
  }

  _onPyq() {
    Toast.showToast(localized(toastComingSoon));
  }

  _onCheQu() {
    Toast.showToast(localized(toastComingSoon));
  }

  @override
  void initState() {
    super.initState();
    objectMgr.navigatorMgr.addRoutes(navigatorTypeQrcode);
  }

  @override
  void dispose() {
    objectMgr.navigatorMgr.removeRoutes(navigatorTypeQrcode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(newQRTitle),
        bgColor: colorF7F7F7,
        trailing: [
          GestureDetector(
            onTap: _onScan(context),
            child: Container(
              padding: EdgeInsets.only(left: 12.w, right: 16.w),
              color: Colors.transparent,
              child: Image.asset(
                'assets/images/message_new/scan1.png',
                width: 20.w,
                height: 20.w,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CustomAvatar(
                        uid: objectMgr.userMgr.mainUser.uid,
                        size: 48.w,
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                objectMgr.userMgr.mainUser.nickname,
                                style: TextStyle(
                                    color: const Color(0XFF333333),
                                    fontWeight: MFontWeight.bold6.value,
                                    fontSize: 14.sp,
                                    height: 1),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 20.w),
                  PrettyQr(
                    size: 263.w,
                    data:
                        downAppUrl + objectMgr.userMgr.mainUser.uid.toString(),
                    errorCorrectLevel: QrErrorCorrectLevel.M,
                    typeNumber: null,
                    roundEdges: false,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 110.w),
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).appBarTheme.backgroundColor == Colors.black
                      ? Colors.grey[800]
                      : colorFFFFFF,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            padding: EdgeInsets.fromLTRB(29.w, 24.w, 29.w, 36.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // iconItem('扫一扫', 'assets/images/mypage_new/scan.png', _onScan),
                // iconItem('保存', 'assets/images/message_new/preservation.png',
                //     _onSave),
                // iconItem(
                //     '微信', 'assets/images/message_new/wechat.png', _onWechat),
                // iconItem('QQ', 'assets/images/message_new/qq.png', _onQq),
                // iconItem('朋友圈', 'assets/images/message_new/byq.png', _onPyq),
                // iconItem(
                //     '聊天消息', 'assets/images/message_new/jxim.png', _onCheQu),
                iconItem(localized(newQRSave),
                    'assets/images/message_new/preservation.png', _onSave),
                iconItem(localized(newQRWeChat),
                    'assets/images/message_new/wechat.png', _onWechat),
                iconItem(localized(newQRQQ), 'assets/images/message_new/qq.png',
                    _onQq),
                iconItem(localized(newQRCommunity),
                    'assets/images/message_new/byq.png', _onPyq),
                iconItem(localized(newQRChat),
                    'assets/images/message_new/jxim.png', _onCheQu),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget iconItem(String iconText, String url, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            child: Image.asset(url),
          ),
          SizedBox(height: 8.w),
          Text(iconText,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.color /*color666666*/,
                  height: 1))
        ],
      ),
    );
  }
}
