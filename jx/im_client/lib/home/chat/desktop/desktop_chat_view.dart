import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_factory.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/chat/desktop/desktop_chat_empty_view.dart';
import 'package:jxim_client/home/chat/desktop/desktop_confirm_create_group.dart';
import 'package:jxim_client/home/chat/desktop/desktop_create_group.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_option/group_edit_permission_view.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_setting_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_view.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/search/search_chat_desktop_ui.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/contact/edit_contact_controller.dart';
import 'package:jxim_client/views/contact/edit_contact_view.dart';
import 'package:jxim_client/views/translation/translate_setting_controller.dart';
import 'package:jxim_client/views/translation/translate_setting_view.dart';
import 'package:jxim_client/views/translation/translate_to_controller.dart';
import 'package:jxim_client/views/translation/translate_to_view.dart';
import 'package:jxim_client/views/translation/translate_visual_controller.dart';
import 'package:jxim_client/views/translation/translate_visual_view.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

class DesktopChatView extends GetView<ChatListController> {
  const DesktopChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              /// 聊天室列表
              Visibility(
                visible:
                    // controller.selectedChat.value == null ||
                    constraints.maxWidth > 675,
                child: SizedBox(
                  width:
                      constraints.maxWidth > 675 ? 300 : constraints.maxWidth,
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        decoration: const BoxDecoration(
                          color: colorBackground,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: SizedBox(
                                width: 20,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Obx(() => Visibility(
                                    visible: objectMgr.appInitState.value ==
                                        AppInitState.fetching,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: themeColor,
                                        strokeWidth: 2,
                                      ),
                                    ))),
                                Obx(() => AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 100),
                                      transitionBuilder: (Widget child,
                                              Animation<double> animation) =>
                                          ScaleTransition(
                                              scale: animation, child: child),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          key: ValueKey(
                                              objectMgr.appInitState.value),
                                          objectMgr.appInitState.value.toName,
                                          textAlign: TextAlign.center,
                                          style: jxTextStyle.appTitleStyle(
                                              color: colorTextPrimary),
                                        ),
                                      ), // THIS CHANGES THE IMAGE FINE, BUT DOESNT ANIMATE
                                    ))
                              ],
                            ),
                            DesktopGeneralButton(
                              horizontalPadding: 10,
                              onPressed: () {
                                if (!Get.isRegistered<
                                    CreateGroupBottomSheetController>()) {
                                  Get.toNamed('createGroup', id: 1);
                                }
                              },
                              child: SvgPicture.asset(
                                'assets/svgs/edit_desktop.svg',
                                color: themeColor,
                                width: 24,
                                height: 24,
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
                              onTap: () {
                                // controller.searchLocal();
                                controller.isSearching(true);
                              },
                              onTapOutside: (event) {
                                if (controller.searchController.text
                                    .trim()
                                    .isEmpty) {
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
                                              shape: MaterialStateProperty.all(
                                                  const CircleBorder()),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              minimumSize:
                                                  MaterialStateProperty.all(
                                                      const Size(20, 20)),
                                            ),
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
                      Flexible(
                        child: Stack(
                          children: [
                            Obx(
                              () => controller.isSearching.value
                                  ? buildSearchContent()
                                  : buildChatContent(),
                            ),
                          ],
                        ),
                      ),
                      if (constraints.maxWidth > 675)
                        const SizedBox(height: 55),
                    ],
                  ),
                ),
              ),

              if (constraints.maxWidth > 675)
                const VerticalDivider(
                  color: colorTextPlaceholder,
                  width: 0.3,
                ),

              /// 聊天室页面
              Expanded(
                child: Navigator(
                  key: Get.nestedKey(1),
                  initialRoute: RouteName.desktopChatEmptyView,
                  onGenerateRoute: (settings) {
                    var destination = settings.name;
                    switch (destination) {
                      case RouteName.desktopChatEmptyView:
                        return GetPageRoute(
                          page: () => const DesktopChatEmptyView(),
                          transition: Transition.fadeIn,
                          transitionDuration: const Duration(milliseconds: 0),
                        );
                      case '/singleChat':
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => SingleChatView(
                            key: ValueKey(arguments['chat'].id.toString()),
                            tag: arguments['chat'].id.toString(),
                          ),
                          curve: Curves.easeInOutCubic,
                          routeName:
                              'chat/private_chat/${arguments['chat'].id.toString()}',
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 0),
                          binding: BindingsBuilder(() {
                            Get.put(
                                    SingleChatController.desktop(
                                        arguments['chat'],
                                        arguments['selectedMsgIds']),
                                    tag: arguments['chat'].id.toString())
                                .isSearching(false);
                            Get.put(
                                CustomInputController.desktop(
                                    arguments['chat']),
                                tag: arguments['chat'].id.toString());
                            Get.put(
                                ChatContentController.desktop(
                                    arguments['chat']),
                                tag: arguments['chat'].id.toString());
                          }),
                          popGesture: false,
                        );
                      case '/groupChat':
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => GroupChatView(
                            key: ValueKey(arguments['chat'].id.toString()),
                            tag: arguments['chat'].id.toString(),
                          ),
                          curve: Curves.easeInOutCubic,
                          routeName:
                              'chat/group_chat/${arguments['chat'].id.toString()}',
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 0),
                          binding: BindingsBuilder(() {
                            Get.put(
                                    GroupChatController.desktop(
                                        arguments['chat'],
                                        arguments['selectedMsgIds']),
                                    tag: arguments['chat'].id.toString())
                                .isSearching(false);
                            Get.put(
                                CustomInputController.desktop(
                                    arguments['chat']),
                                tag: arguments['chat'].id.toString());
                            Get.put(
                                ChatContentController.desktop(
                                    arguments['chat']),
                                tag: arguments['chat'].id.toString());
                          }),
                          popGesture: false,
                        );
                      case RouteName.chatInfo:
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => ChatInfoView(),
                          binding: BindingsBuilder(() {
                            Get.put(ChatInfoController.desktop(arguments['uid'],
                                chat: arguments['chat']));
                            Get.put(MoreSettingController.desktop(
                                uid: arguments['uid'],
                                chat: arguments['chat']));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.editContact:
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => const EditContactView(),
                          binding: BindingsBuilder(() {
                            Get.put(EditContactController.desktop(
                                uid: arguments['uid']));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.groupChatInfo:
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => GroupChatInfoView(),
                          binding: BindingsBuilder(() {
                            Get.put(GroupChatInfoController.desktop(
                                arguments['groupId']));
                            Get.put(MoreSettingController.desktop(
                                groupId: arguments['groupId'],
                                chat: arguments['chat']));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.groupChatEdit:
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => const GroupChatEditView(),
                          binding: BindingsBuilder(() {
                            Get.put(GroupChatEditController.desktop(
                                group: arguments['group'],
                                groupMemberListData:
                                    arguments['groupMemberListData'],
                                permission: arguments['permission']));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.groupChatEditPermission:
                        return GetPageRoute(
                          page: () => const GroupEditPermissionView(),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.groupAddMember:
                        Map arguments = settings.arguments as Map;
                        return GetPageRoute(
                          page: () => const GroupAddMemberView(),
                          binding: BindingsBuilder(() {
                            Get.put(GroupAddMemberController.desktop(
                                group: arguments['group'],
                                membersList: arguments['memberList']));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.translateSettingView:
                        return GetPageRoute(
                          page: () => const TranslateSettingView(),
                          binding: BindingsBuilder(() {
                            Get.put(TranslateSettingController.desktop(
                                settings.arguments));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.translateToView:
                        dynamic arguments = settings.arguments;
                        return GetPageRoute(
                          page: () => const TranslateToView(),
                          binding: BindingsBuilder(() {
                            Get.put(TranslateToController.desktop(
                              arguments[0],
                              arguments[1],
                            ));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.translateVisualView:
                        dynamic arguments = settings.arguments;
                        return GetPageRoute(
                          page: () => const TranslateVisualView(),
                          binding: BindingsBuilder(() {
                            Get.put(TranslateVisualController.desktop(
                              arguments[0],
                              arguments[1],
                            ));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case RouteName.redPacketLeaderboard:
                        return GetPageRoute(
                          page: () => const RedPacketLeaderboard(),
                          binding: BindingsBuilder(() {
                            Get.put(RedPacketLeaderboardController.desktop(
                                settings.arguments));
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case 'createGroup':
                        return GetPageRoute(
                          page: () => const DesktopCreateGroup(),
                          binding: BindingsBuilder(() {
                            Get.put(CreateGroupBottomSheetController());
                          }),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      case 'confirmCreateGroup':
                        return GetPageRoute(
                          page: () => const DesktopConfirmCreateGroup(),
                          transition: Transition.rightToLeft,
                          transitionDuration: const Duration(milliseconds: 200),
                          popGesture: false,
                        );
                      default:
                        return GetPageRoute(
                          page: () => Container(),
                          transition: Transition.leftToRight,
                          transitionDuration: const Duration(milliseconds: 200),
                        );
                    }
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildChatContent() {
    return Obx(
      () => controller.chatList.isEmpty
          ? buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: controller.chatList.length,
              itemBuilder: (context, index) {
                Chat chat = controller.chatList[index];
                final bool isLastPin = chat.sort > 0 &&
                    (index < controller.chatList.length - 1 &&
                        controller.chatList[index + 1].sort == 0);

                return Column(
                  children: [
                    ChatUIFactory.createComponent(
                      chat: chat,
                      tag: chat.id.toString(),
                      index: index,
                      controller: controller,
                    ),
                    if (index != controller.chatList.length - 1)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isLastPin ? 0 : jxDimension.chatCellPadding(),
                        ),
                        child: const CustomDivider(),
                      )
                  ],
                );
              },
            ),
    );
  }

  Widget buildSearchContent() {
    return SearchChatDesktopUI(
      controller: controller,
      isSearching: controller.isTyping.value,
      searchText: controller.searchParam
          .value, // 桌面端需要用searchParam.value，否则清除搜索框是，不能didUpdateWidget
    );
  }

  Widget buildEmptyState() {
    return Obx(
      () => controller.isSearching.value
          ? SearchEmptyState(
              searchText: controller.searchParam.value,
              emptyMessage: localized(
                oppsNoResultFoundTryNewSearch,
                params: [(controller.searchParam.value)],
              ),
            )
          : Center(
              child: Text(
                localized(noChatsAtThisMoment),
              ),
            ),
    );
  }
}
