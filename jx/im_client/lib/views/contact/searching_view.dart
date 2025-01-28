import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/custom_tab_bar.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';

class SearchingView extends GetView<SearchContactController> {
  const SearchingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colorBackground,
        resizeToAvoidBottomInset: false,
        appBar: PrimaryAppBar(
          height: 66,
          isBackButton: false,
          titleWidget: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              _backButton(),
              _tabBar(),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller.tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: controller.tabList,
        ));
  }

  Align _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OpacityEffect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.back(),
          child: Obx(() {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: controller.isSecondPage.value,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: SvgPicture.asset(
                      'assets/svgs/Back.svg',
                      width: 24,
                      height: 24,
                      color: themeColor,
                    ),
                  ),
                ),
                Text(
                  controller.isSecondPage.value
                      ? localized(buttonBack)
                      : localized(buttonCancel),
                  style: jxTextStyle.headerText(
                    color: themeColor,
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Container _tabBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorBackground6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTabBar(
        tabController: controller.tabController,
        tabList: controller.tabTitle,
      ),
    );
  }
}

class SearchOptionList extends StatelessWidget {
  const SearchOptionList({super.key, required this.controller});
  final SearchContactController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorSurface,
      ),
      margin: const EdgeInsets.only(top: 32),
      child: _addOptionList(context),
    );
  }

  Column _addOptionList(context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildListTile(
          onTap: () {
            showQRCodeDialog(context);
          },
          icon: 'qrCode',
          title: localized(newQRTitle),
          subtitle: localized(searchMeQRSubTitle),
        ),
        _buildListTile(
          onTap: () => controller.scanQR(),
          icon: 'scan_rounded',
          title: localized(scanMe),
          subtitle: localized(searchScanMeSubTitle),
        ),
        _buildListTile(
          onTap: () {
            if (objectMgr.loginMgr.isDesktop) {
              Get.toNamed(RouteName.shareView);
            } else {
              _showShareViewDialog(context);
            }
          },
          icon: 'menu_forward',
          title: localized(
            shareHeyTalk,
            params: [Config().appName],
          ),
          subtitle: localized(
            shareHeyTalkDetails,
            params: [Config().appName],
          ),
          withBorder: true,
        ),
        _buildListTile(
          onTap: () => controller.findContact(context),
          icon: 'contact_icon',
          title: localized(findContacts),
          subtitle: localized(connectFriendDesc),
          withBorder: false,
        ),
      ],
    );
  }

  Widget _buildListTile({
    GestureTapCallback? onTap,
    required String icon,
    required String title,
    required String subtitle,
    bool withBorder = true,
  }) {
    return SettingItem(
      onTap: onTap,
      iconName: icon,
      iconColor: themeColor,
      title: title,
      subtitle: subtitle,
      subtitleStyle: jxTextStyle.normalSmallText(color: colorTextSecondary),
      withBorder: withBorder,
    );
  }

  Future _showShareViewDialog(BuildContext context) {
    return showModalBottomSheet(
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        Get.lazyPut(() => ShareController());
        return const ShareView();
      },
    ).whenComplete(() => Get.findAndDelete<ShareController>());
  }
}
