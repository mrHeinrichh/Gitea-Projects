import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../component/new_appbar.dart';

class AccountAndSafe extends StatefulWidget {
  const AccountAndSafe({Key? key}) : super(key: key);

  @override
  _AccountAndSafeState createState() => _AccountAndSafeState();
}

class SafeAnds {
  int index;
  String title;
  String url;
  String text;

  SafeAnds(
      {required this.index,
      required this.title,
      required this.url,
      required this.text});
}

class _AccountAndSafeState extends State<AccountAndSafe> {
  List<SafeAnds> setList = [
    // SafeAnds(index: 0, title: '手机绑定', url: '', text: ''),
    // SafeAnds(index: 1, title: '设置密码', url: '', text: ''),
    SafeAnds(
        index: 0, title: localized(mySettingAcc_SecPhone), url: '', text: ''),
    SafeAnds(
        index: 1,
        title: localized(mySettingAcc_SecPassword),
        url: '',
        text: ''),
    SafeAnds(
        index: 2,
        // title: '微信绑定',
        title: localized(mySettingAcc_SecWechat),
        url: 'assets/images/mypage_new/wechat.png',
        // text: '未绑定'),
        // SafeAnds(index: 3, title: '注销账号（慎用）', url: '', text: ''),
        text: localized(mySettingAcc_SecWechatHint)),
    SafeAnds(
        index: 3, title: localized(mySettingAcc_SecDelete), url: '', text: ''),
  ];

  bool isWxLogin = false;
  String? _wxOpenid;

  _setJumpToPage(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        if (index == 2 && isWxLogin) {
          return;
        }
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _getMyPhone();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _getMyPhone() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(title: '账户与安全'),
      body: ListView(
          physics:
              BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            Column(
                children: setList.map((e) {
              return _item(e);
            }).toList()),
          ]),
    );
  }

  Widget _item(SafeAnds e) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.transparent,
            border:
                Border(bottom: BorderSide(width: 0.5.w, color: colorF2F2F2))),
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: e.index == 2 ? 7.w : 16.w),
        child: Row(
          children: [
            Row(
              children: [
                Visibility(
                    visible: e.url != '',
                    child: Container(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Image.asset(
                        e.url,
                        width: 32.w,
                      ),
                    )),
                Text(
                  e.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall /*TextStyle(
                      height: 1.1, color: color1A1A1A, fontSize: 14.sp)*/
                  ,
                ),
              ],
            ),
            Expanded(child: const SizedBox()),
            Visibility(
                visible: e.text != '',
                child: Text(e.text,
                    style: TextStyle(fontSize: 14.sp, color: color999999))),
            SizedBox(
              width: e.index == 0 && e.text != '' ? 4.w : 20.w,
              height: 20.w,
              child: Visibility(
                  visible: !(e.index == 0 && e.text != ''),
                  child:
                      Image.asset('assets/images/mypage_new/next_setting.png')),
            )
          ],
        ),
      ),
      onTap: () {
        _setJumpToPage(e.index);
      },
    );
  }
}
