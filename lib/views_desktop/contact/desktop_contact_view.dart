import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/home/chat/desktop/desktop_chat_empty_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_view.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_setting_controller.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

import 'package:jxim_client/views/contact/edit_contact_controller.dart';
import 'package:jxim_client/views/contact/edit_contact_view.dart';

class DesktopContactView extends GetView<ContactController> {
  const DesktopContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: <Widget>[
              SizedBox(
                width: constraints.maxWidth > 675
                    ? 320
                    : constraints.maxWidth - 1.5,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        color: colorBackground,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            localized(homeContact),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: MFontWeight.bold5.value,
                              color: colorTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Flexible(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            final User user = controller.friendList[index];
                            return ContactCard(
                              key: ValueKey(user.uid),
                              user: user,
                              gotoChat: false,
                              subTitle: UserUtils.onlineStatus(user.lastOnline),
                            );
                          },
                          separatorBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(left: 60),
                            child: CustomDivider(),
                          ),
                          itemCount: controller.friendList.length,
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                  ],
                ),
              ),
              VerticalDivider(
                color: Colors.grey.shade500,
                width: 1.5,
              ),
              if (constraints.maxWidth > 675)
                Expanded(
                  child: Navigator(
                    key: Get.nestedKey(2),
                    initialRoute: RouteName.desktopChatEmptyView,
                    onGenerateRoute: (settings) {
                      var destination = settings.name;

                      switch (destination) {
                        case RouteName.desktopChatEmptyView:
                          return GetPageRoute(
                            page: () => const DesktopChatEmptyView(),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.chatInfo:
                          Map arguments = settings.arguments as Map;
                          return GetPageRoute(
                            page: () => ChatInfoView(),
                            binding: BindingsBuilder(() {
                              Get.put(
                                ChatInfoController.desktop(arguments['uid']),
                              );
                              Get.put(
                                MoreSettingController.desktop(
                                  uid: arguments['uid'],
                                  chat: arguments['chat'],
                                ),
                              );
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        case RouteName.editContact:
                          Map arguments = settings.arguments as Map;
                          return GetPageRoute(
                            page: () => const EditContactView(),
                            binding: BindingsBuilder(() {
                              Get.put(
                                EditContactController.desktop(
                                  uid: arguments['uid'],
                                ),
                              );
                            }),
                            transition: Transition.rightToLeft,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                        default:
                          return GetPageRoute(
                            page: () => Container(
                              color: colorBackground,
                            ),
                            transition: Transition.leftToRight,
                            transitionDuration: const Duration(milliseconds: 0),
                          );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
