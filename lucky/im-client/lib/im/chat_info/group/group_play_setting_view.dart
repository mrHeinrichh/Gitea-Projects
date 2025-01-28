import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../home/setting/setting_item.dart';
import '../../../main.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views/component/new_appbar.dart';

class GroupPlaySettingView extends StatelessWidget {
  const GroupPlaySettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : const PrimaryAppBar(title: '群组玩法'),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    color: JXColors.outlineColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        // Get.back(id: 3);
                        // Get.find<SettingController>()
                        //     .desktopSettingCurrentRoute = '';
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/Back.svg',
                              width: 10,
                              height: 20,
                              color: JXColors.blue,
                            ),
                            Text(
                              localized(buttonBack),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JXColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ListView(
                children: [
                  SizedBox(
                    height: 24.w,
                  ),
                  Container(
                    margin: objectMgr.loginMgr.isDesktop
                        ? const EdgeInsets.only(bottom: 24)
                        : const EdgeInsets.only(bottom: 24).w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle('完整教程'),
                            Container(
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    objectMgr.loginMgr.isDesktop ? 8 : 8.w),
                              ),
                              child: Column(
                                children: [
                                  SettingItem(
                                    onTap: () {},
                                    title: '用户教程',
                                    rightTitle: "未学习",
                                    withBorder: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 24.w,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle('模块教程'),
                            Container(
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    objectMgr.loginMgr.isDesktop ? 8 : 8.w),
                              ),
                              child: Column(
                                children: [
                                  SettingItem(
                                    onTap: () {},
                                    title: '主题设置',
                                  ),
                                  SettingItem(
                                    onTap: () {},
                                    title: '返佣设置',
                                    rightTitle: "未学习",
                                  ),
                                  SettingItem(
                                    onTap: () {},
                                    title: '投资坐庄',
                                  ),
                                  SettingItem(
                                    onTap: () {},
                                    title: '收益提现',
                                    rightTitle: "未学习",
                                    withBorder: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildTitle(String title) {
    return Container(
      margin: objectMgr.loginMgr.isDesktop
          ? const EdgeInsets.only(left: 16, bottom: 4)
          : const EdgeInsets.only(left: 16, bottom: 4).w,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }
}
