import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/menu_item.dart';
import 'package:jxim_client/views/contact/components/contact_list.dart';
import '../../utils/color.dart';
import '../../utils/theme/text_styles.dart';
import '../component/new_appbar.dart';
import 'contact_controller.dart';

class ContactView extends StatefulWidget {
  const ContactView({Key? key}) : super(key: key);

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
        backgroundColor: backgroundColor,
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
                        color: JXColors.primaryTextBlack),
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
                            color: accentColor,
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
                              isShowTick: controller.isCheckedOrder == 0),
                          menuItem(
                              value: 1,
                              text: localized(name),
                              isShowTick: controller.isCheckedOrder == 1),
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
                    onTap: () {
                      Get.toNamed(RouteName.searchUserView);
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: SvgPicture.asset(
                        'assets/svgs/add.svg',
                        width: 20,
                        height: 20,
                        color: accentColor,
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

  @override
  bool get wantKeepAlive => true;
}
