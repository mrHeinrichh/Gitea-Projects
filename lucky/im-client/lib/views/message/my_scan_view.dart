import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/navigator_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/api/account.dart' as account_api;

import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';

class MyScanView extends StatefulWidget {
  const MyScanView({
    Key? key,
  }) : super(key: key);

  @override
  _MyScanViewState createState() => _MyScanViewState();
}

class _MyScanViewState extends State<MyScanView> {
  // QrReaderViewController? _controller;

  _onBack() {
    Get.back();
  }

  _onAlbum() async {
    if (Platform.isAndroid) {
      var b = await Permissions.request([Permission.storage]);
      if (!b) {
        return;
      }
      var c = await Permissions.request([Permission.accessMediaLocation]);
      if (!c) {
        return;
      }
    } else {
      var b = await Permissions.request([Permission.photos]);
      if (!b) {
        return;
      }
    }

    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
        limitedPermissionOverlayPredicate: (permissionState) {
          return false;
        },
      ),
    );
    if (assets != null) {
      assets.first.file.then((value) async {
        // final rest = await FlutterQrReader.imgScan(value!.path);
        // _onScan(rest);
      });
    }
  }

  bool _showResultView = false;
  String _result = '';

  _onScan(String data) async {
    if (_result == data) {
      return;
    }
    _result = data;
    try {
      final user = await account_api.getUser(userId: data);
    } catch (e) {
      Get.back();
      Toast.showToast(localized(toastQrFailed));
    }
  }

  _onMyQrcode() {
    if (objectMgr.navigatorMgr.isExit(navigatorTypeQrcode)) {
      Get.back();
    } else {
      Get.toNamed(RouteName.qrCodeView,
          arguments: {'user': objectMgr.userMgr.mainUser});
    }
  }

  Future startScan() async {
    // _controller?.startCamera((String result, _) async {
    //   _onScan(result);
    //   if (Platform.isAndroid) {
    //     await stopScan();
    //   } else {
    //     if (mounted) {
    //       setState(() {
    //         _showResultView = true;
    //       });
    //     }
    //   }
    // });
  }

  Future stopScan() async {
    // await _controller?.stopCamera();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
              // child: QrReaderView(
              //   width: MediaQuery.of(context).size.width,
              //   height: MediaQuery.of(context).size.height,
              //   callback: (controller) {
              //     _controller = controller;
              //     startScan();
              //   },
              // ),
              ),
          Container(
            child: _buildAppBar(),
          ),
          Container(
            child: _buildMyQrcode(),
          ),
          if (_showResultView)
            Container(
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          padding: EdgeInsets.only(left: 5, right: 15),
          child: Row(
            children: [
              GestureDetector(
                onTap: _onBack,
                child: Image.asset(
                  'assets/images/message/left_return.png',
                  width: 30,
                  height: 56,
                  fit: BoxFit.fitWidth,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  // '扫一扫',
                  localized(scanTitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onAlbum,
                child: Image.asset(
                  'assets/images/message/album.png',
                  width: 20,
                  height: 56,
                  fit: BoxFit.fitWidth,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyQrcode() {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: 400.w),
        child: GestureDetector(
          onTap: _onMyQrcode,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Image.asset(
                  'assets/images/message/news_qr_code_white.png',
                  width: 30.w,
                  height: 30.w,
                ),
              ),
              Text(
                // '我的二维码',
                localized(scanContext),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.w,
                  fontWeight: MFontWeight.bold5.value,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
