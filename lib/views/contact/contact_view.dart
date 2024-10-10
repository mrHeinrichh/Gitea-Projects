import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/menu_item.dart';
import 'package:jxim_client/views/contact/components/contact_list.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';
import 'package:jxim_client/extension/extension_expand.dart';

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
                left: 0,
                child: OpacityEffect(
                  child: PopupMenuButton(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width * 0.4,
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                    ),
                    tooltip: "",
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localized(sort),
                        style: jxTextStyle.textStyle17(
                          color: themeColor,
                        ),
                      ),
                    ),
                    offset: const Offset(0, 30),
                    onSelected: (value) {
                      if (value == 0) {
                        controller.isCheckedOrder.value = 0;
                        controller.contactSortClick(0);
                      } else if (value == 1) {
                        controller.isCheckedOrder.value = 1;
                        controller.contactSortClick(1);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        menuItem(
                          value: 0,
                          text: localized(lastOnline),
                          isShowTick: controller.isCheckedOrder.value == 0,
                        ),
                        menuItem(
                          value: 1,
                          text: localized(name),
                          isShowTick: controller.isCheckedOrder.value == 1,
                        ),
                      ];
                    },
                    splashRadius: 1.0,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: OpacityEffect(
                  child: GestureDetector(
                    onTap: () async {
                      //Get.toNamed(RouteName.searchUserView);
                      showAddFriendBottomSheet(context);
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        Get.find<SearchContactController>().isModalBottomSheet = true;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const SearchingView(),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => Get.findAndDelete<SearchContactController>(),
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}
