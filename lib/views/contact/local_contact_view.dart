import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';

class LocalContactView extends GetView<LocalContactController> {
  const LocalContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(localContactLocalContactSync),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorBorder,
                  width: 0.5.h,
                ),
              ),
            ),
            child: TabBar(
              controller: controller.tabController,
              tabs: controller.tabList,
              unselectedLabelColor: colorTextSecondary,
              labelColor: themeColor,
              indicatorColor: themeColor,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 50.w),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: controller.tabViewList,
      ),
    );
  }
}

class FriendEmptyState extends StatelessWidget {
  const FriendEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 108.h),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/svgs/empty_request.svg',
            width: 148,
            height: 148,
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Text(
              localized(noResults),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              localized(noMatchingContactsWereFound),
            ),
          ),
        ],
      ),
    );
  }
}
