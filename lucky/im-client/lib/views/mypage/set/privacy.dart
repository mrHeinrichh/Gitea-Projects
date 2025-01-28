import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../component/new_appbar.dart';

class Privacy extends StatefulWidget {
  const Privacy({Key? key}) : super(key: key);

  @override
  _PrivacyState createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  List<Permission> _permissionList = [];

  @override
  void initState() {
    super.initState();
    objectMgr.on(ObjectMgr.eventAppLifeState, updateOpenData);
    _checkSysOpen();
  }

  //app唤醒
  updateOpenData(sender, type, data) {
    if (data == AppLifecycleState.resumed) {
      _checkSysOpen();
    }
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.off(ObjectMgr.eventAppLifeState, updateOpenData);
  }

  //打开系统通知界面
  _appSet() async {
    await openAppSettings();
  }

  //判断系统消息总开关
  _checkSysOpen() async {
    await Permissions.request(
        [Permission.photos, Permission.microphone],
        isShowToast: false, permissCallBack: (data) {
      _permissionList = data;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(title: '隐私设置'),
      body: ListView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          // _title('权限隐私'),
          _title(localized(myPrivacyPermission)),
          // _item('允许获取设备信息',false),
          // _item('允许访问位置信息', _permissionList.contains(Permission.location)),
          // _item('允许使用相机', _permissionList.contains(Permission.photos)),
          // _item('允许范围麦克风权限', _permissionList.contains(Permission.microphone)),
          // _item(localized(myLocation), _permissionList.contains(Permission.location)),
          _item(
              localized(myCamera), _permissionList.contains(Permission.photos)),
          _item(localized(myMicrophone),
              _permissionList.contains(Permission.microphone)),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: MFontWeight.bold5.value),
        /*TextStyle(
              fontSize: 14.sp, color: color1A1A1A, fontWeight: fontWeight500)*/
      ),
    );
  }

  Widget _item(String text, bool value) {
    return Column(
      children: [
        Container(
          // color: colorFFFFFF,
          padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 14.sp)
                  /* TextStyle(
                      fontSize: 14.sp,
                      color: color1A1A1A,
                      fontWeight: FontWeight.normal)*/
                  ),
              Container(
                height: 22.w,
                width: 32.w,
                child: Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: !value,
                    trackColor: colorCCCCCC,
                    activeColor: colorE5454D,
                    onChanged: (value) {
                      _appSet();
                    },
                  ),
                ),
              )
            ],
          ),
        ),
        _line(0.5.w),
      ],
    );
  }

  Widget _line(double height,
      {bool value = true, bool needPadding = true, Color? color}) {
    return Visibility(
        visible: value,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: needPadding ? 16.w : 0),
          height: height,
          color: color ?? colorF2F2F2,
        ));
  }
}
