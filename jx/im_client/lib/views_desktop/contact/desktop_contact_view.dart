import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
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
import 'package:jxim_client/views/component/search_empty_state.dart';
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
                    ? 300
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
                        () => Container(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 10, top: 0),
                          decoration: const BoxDecoration(
                            color: colorBackground,
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                                color: colorBackground6,
                              ),
                            ),
                          ),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: colorBackground6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              focusNode: controller.searchFocus,
                              autofocus: false,
                              cursorColor: themeColor,
                              cursorHeight: 16,
                              onChanged: controller.onSearchChanged,
                              onTap: () => controller.isSearching(true),
                              onTapOutside: (event) {
                                if(controller.searchController.text.trim().isEmpty) {
                                  controller.isSearching(false);
                                }
                                controller.searchFocus.unfocus();
                              },
                              controller: controller.searchController,
                              enableInteractiveSelection:
                              controller.isSearching.value,
                              maxLines: 1,
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
                                fontSize: 16,
                                decorationThickness: 0,
                                decoration: TextDecoration.none,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isCollapsed: true,
                                prefixIcon: controller.isSearching.value
                                    ? UnconstrainedBox(
                                  child: TextButtonTheme(
                                    data: TextButtonThemeData(
                                      style: ButtonStyle(
                                          padding:
                                          MaterialStateProperty.all(
                                              EdgeInsets.zero),
                                          backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.transparent),
                                          overlayColor:
                                          MaterialStateProperty.all(
                                              colorBackground6),
                                          shape:
                                          MaterialStateProperty.all(
                                              const CircleBorder()),
                                          visualDensity:
                                          VisualDensity.compact,
                                          minimumSize:
                                          MaterialStateProperty.all(
                                              const Size(20, 20))),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        controller.searchFocus.unfocus();
                                        controller.clearSearching();
                                      },
                                      child: Image.asset(
                                        'assets/icons/Search_thin.png',
                                        height: 16,
                                        width: 16,
                                        color: colorTextPrimary,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    UnconstrainedBox(
                                      child: Image.asset(
                                        'assets/icons/Search_thin.png',
                                        color: colorTextPrimary,
                                        height: 16,
                                        width: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      localized(hintSearch),
                                      style: jxTextStyle.textStyle13(
                                        color: colorTextSupporting,
                                      ),
                                    )
                                  ],
                                ),
                                hintText: localized(hintSearch),
                                hintStyle: jxTextStyle.textStyle13(
                                  color: colorTextSupporting,
                                ),
                                suffixIcon: Visibility(
                                  visible:
                                  controller.searchParam.value.isNotEmpty,
                                  child: TextButtonTheme(
                                    data: TextButtonThemeData(
                                      style: ButtonStyle(
                                          padding: MaterialStateProperty.all(
                                              EdgeInsets.zero),
                                          backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.transparent),
                                          overlayColor:
                                          MaterialStateProperty.all(
                                              colorBackground6),
                                          shape: MaterialStateProperty.all(
                                              const CircleBorder()),
                                          visualDensity: VisualDensity.compact,
                                          minimumSize:
                                          MaterialStateProperty.all(
                                              const Size(30, 20))),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        controller.searchController.clear();
                                        controller.searchParam.value = '';
                                        controller.searchLocal();
                                      },
                                      child: SvgPicture.asset(
                                          'assets/svgs/close_round_icon.svg',
                                          width: 16,
                                          height: 16,
                                          color: colorTextSecondarySolid),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ),

                    Obx(
                      () => Visibility(
                        visible: controller.friendList.isNotEmpty,
                        child: Expanded(
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
                            separatorBuilder: (context, index) => separateDivider(indent: 60.0),
                            itemCount: controller.friendList.length,
                          ),
                        ),
                      ),
                    ),

                    Obx(
                        () => Visibility(
                          visible:
                          controller.friendList.isEmpty,
                          child: Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: objectMgr.loginMgr.isDesktop ? 0 : 50),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: controller.isSearching.value
                                    ? SearchEmptyState(
                                  searchText: controller
                                      .searchParam.value,
                                  emptyMessage: localized(
                                    oppsNoResultFoundTryNewSearch,
                                    params: [
                                      (controller
                                          .searchParam.value)
                                    ],
                                  ),
                                )
                                    : Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svgs/no_contact.svg',
                                        width: 148,
                                        height: 148,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        localized(connectWithFriend),
                                        style: jxTextStyle.headerText(
                                            fontWeight:
                                            MFontWeight.bold5.value),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ),



                    const SizedBox(height: 50),
                  ],
                ),
              ),
              const VerticalDivider(
                color: colorTextPlaceholder,
                width: 0.3,
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
