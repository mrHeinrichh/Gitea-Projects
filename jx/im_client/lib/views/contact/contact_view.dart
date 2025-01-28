import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/components/contact_list.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<StatefulWidget> createState() => ContactViewState();
}

class ContactViewState extends State<ContactView>
    with AutomaticKeepAliveClientMixin {
  ContactController get controller => Get.find<ContactController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => Scaffold(
        backgroundColor: colorBackground,
        resizeToAvoidBottomInset: false,
        appBar: PrimaryAppBar(
          isSearchingMode: controller.isSearching.value,
          isBackButton: false,
          titleSpacing: 0,
          titleWidget: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    localized(homeContact), // Update to local text
                    style: jxTextStyle.appTitleStyle(
                      color: colorTextPrimary,
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                child: OpacityEffect(
                    child: GestureDetector(
                  key: controller.notificationKey,
                  onTap: () async {
                    controller.showPopUpMenu(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    localized(sort),
                    style: jxTextStyle.headerText(
                      color: themeColor,
                    ),
                  ),
                )),
              ),
              Positioned(
                right: 0,
                child: OpacityEffect(
                  child: GestureDetector(
                    onTap: () async {
                      showAddFriendBottomSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      color: colorBackground,
                      child: SvgPicture.asset(
                        'assets/svgs/add.svg',
                        width: 20,
                        height: 20,
                        color: themeColor,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: const ContactList(),
        ),
      ),
    );
  }

  Future<void> showAddFriendBottomSheet(BuildContext context) async {
    Get.put(SearchContactController());
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const SearchingView(),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(
        const Duration(milliseconds: 200),
        () => Get.findAndDelete<SearchContactController>(),
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}
