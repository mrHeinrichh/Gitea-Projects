import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';
import 'package:permission_handler/permission_handler.dart';

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
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorBackground6,
                  width: 0.3,
                ),
              ),
            ),
            child: TabBar(
                controller: controller.tabController,
                tabs: controller.tabList,
                unselectedLabelColor: colorTextSecondary,
                labelColor: themeColor,
                indicatorColor: themeColor,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 80),
                labelStyle: jxTextStyle.normalText(
                  fontWeight: MFontWeight.bold5.value,
                )),
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

class ContactPermission extends StatelessWidget {
  const ContactPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: 3.15,
                    child: const Icon(
                      Icons.info,
                      size: 16,
                      color: colorRed,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 1.5),
                    child: Text(
                      localized(requestLocalContactTitle),
                      style: jxTextStyle.normalText(),
                    ),
                  ),
                ],
              ),
              OpacityEffect(
                child: GestureDetector(
                  onTap: () {
                    showCustomBottomAlertDialog(
                      context,
                      title: localized(accessRequestTitle),
                      subtitle: localized(requestLocalContactDialogTxt,
                          params: [Config().appName]),
                      confirmText: localized(openSettings),
                      confirmTextColor: themeColor,
                      onConfirmListener: () {
                        openAppSettings();
                      },
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/svgs/close_thick_outlined_icon.svg',
                    color: colorTextSecondarySolid,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            localized(requestLocalContactDescription,
                params: [Config().appName]),
            style: jxTextStyle.headerText(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CustomDivider(),
        ),
        OverlayEffect(
          child: GestureDetector(
            onTap: () {
              openAppSettings();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 11, left: 16),
              child: Row(
                // Use Row + Expanded to trigger onTap
                children: [
                  Expanded(
                    child: Text(
                      localized(allowAccessRequest),
                      style: jxTextStyle.headerText(
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CustomDivider(),
        ),
      ],
    );
  }
}

class ContactLoadingProgress extends StatelessWidget {
  const ContactLoadingProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
          width: 75,
          height: 75,
          child: CircularProgressIndicator(
            color: themeColor,
            strokeWidth: 3.0,
          )),
    );
  }
}

Widget buildContactTitleWidget(User user, {bool isFriend = false}) {
  return Row(
    children: [
      Flexible(
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: jxTextStyle.headerText(
              fontWeight: MFontWeight.bold5.value,
            ),
            children: [
              TextSpan(
                  text: isFriend
                      ? objectMgr.userMgr.getUserTitle(user)
                      : user.nickname),
              if (notBlank(user.localName))
                TextSpan(
                  text: ' (${user.localName})',
                  style: jxTextStyle.headerText(
                    color: colorTextSecondary,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
