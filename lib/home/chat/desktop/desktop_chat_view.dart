import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/item_views/chat_cell_view.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

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
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/contact/edit_contact_controller.dart';
import 'package:jxim_client/views/contact/edit_contact_view.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/home/component/home_searching_header.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/chat/desktop/desktop_chat_empty_view.dart';
import 'package:jxim_client/home/chat/desktop/desktop_confirm_create_group.dart';
import 'package:jxim_client/home/chat/desktop/desktop_create_group.dart';

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
                      constraints.maxWidth > 675 ? 320 : constraints.maxWidth,
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
                                color: colorBorder,
                              ),
                            ),
                          ),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: colorBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              focusNode: controller.searchFocus,
                              autofocus: false,
                              cursorColor: themeColor,
                              onChanged: controller.onSearchChanged,
                              onTap: () => controller.isSearching(true),
                              controller: controller.searchController,
                              enableInteractiveSelection:
                                  controller.isSearching.value,
                              maxLines: 1,
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
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
                                                        colorBorder),
                                                shape:
                                                    MaterialStateProperty.all(
                                                        const CircleBorder()),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                minimumSize:
                                                    MaterialStateProperty.all(
                                                        const Size(60, 20))),
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              controller.searchFocus.unfocus();
                                              controller.clearSearching();
                                            },
                                            child: SvgPicture.asset(
                                              'assets/svgs/desktop_arrow_right.svg',
                                              height: 20,
                                              width: 20,
                                              color: themeColor,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          UnconstrainedBox(
                                            child: SvgPicture.asset(
                                              'assets/svgs/Search.svg',
                                              height: 16,
                                              width: 16,
                                              color: colorTextSupporting,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            localized(hintSearch),
                                            style: jxTextStyle.textStyle16(
                                              color: colorTextSupporting,
                                            ),
                                          )
                                        ],
                                      ),
                                hintText: localized(hintSearch),
                                hintStyle: jxTextStyle.textStyle16(
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
                                                  colorBorder),
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
                                      ),
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
                            CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                ///搜索聊天室列表header
                                HomeSearchingHeader<Chat>(
                                  controller: controller,
                                  title: localized(chatInfoChats),
                                  list: controller.chatList,
                                ),

                                ///支援動畫的sliver list
                                SlidableAutoCloseBehavior(
                                  child: Obx(
                                    () => SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final Chat chat =
                                              controller.chatList[index];
                                          if (chat.typ == chatTypePostNotify) {
                                            return const SizedBox();
                                          }
                                          return ChatCellView<
                                                ChatListController>(
                                              key: ValueKey(chat.id.toString()),
                                              tag: chat.id.toString(),
                                              chat: chat,
                                              index: index,
                                          );
                                        },
                                        childCount: controller.chatList.length,
                                        addRepaintBoundaries: false,
                                      ),
                                    ),
                                  ),
                                ),

                                ///搜索消息列表header
                                HomeSearchingHeader<Message>(
                                  controller: controller,
                                  title: localized(homeTitle),
                                  list: controller.messageList,
                                ),

                                Obx(
                                  () => SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final Message message =
                                            controller.messageList[index];
                                        final Chat? chat = objectMgr.chatMgr
                                            .getChatById(message.chat_id);

                                        if (chat != null &&
                                            chat.typ == chatTypePostNotify) {
                                          return const SizedBox();
                                        }

                                        return MessageCellView(
                                          key: ValueKey(
                                              '${message.id}${message.chat_id}'),
                                          message: message,
                                          chatId: message.chat_id,
                                          searchText:
                                              controller.searchParam.value,
                                        );
                                      },
                                      childCount: controller
                                                  .isSearching.value &&
                                              controller.messageList.isNotEmpty
                                          ? controller.messageList.length
                                          : 0,
                                      addRepaintBoundaries: false,
                                    ),
                                  ),
                                ),
                                Obx(
                                  () => SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Container(
                                      ///這個是為了聊天列表底部數量不足一頁時,用白色填滿空間,請不要再拿掉了～
                                      color: Colors.white,
                                      child: Visibility(
                                        visible:
                                            controller.messageList.isEmpty &&
                                                controller.chatList.isEmpty,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 50),
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
                                                : Text(
                                                    localized(
                                                        noChatsAtThisMoment),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Obx(
                            //   () => Visibility(
                            //     visible: controller.isShowSoftUpdate.value,
                            //     child: Positioned(
                            //       left: 0,
                            //       right: 0,
                            //       bottom: 0,
                            //       child: Container(
                            //         margin: const EdgeInsets.symmetric(
                            //             vertical: 12.0, horizontal: 12.0),
                            //         padding: const EdgeInsets.symmetric(
                            //             vertical: 12.0, horizontal: 12.0),
                            //         decoration: BoxDecoration(
                            //           color: const Color(0xD1121212)
                            //               .withOpacity(0.8),
                            //           borderRadius: BorderRadius.circular(
                            //               8), // Set border radius here
                            //         ),
                            //         child: Row(
                            //           children: [
                            //             Padding(
                            //               padding: const EdgeInsets.only(
                            //                   right: 12.0),
                            //               child: SvgPicture.asset(
                            //                 'assets/svgs/install-icon.svg',
                            //                 width: 24,
                            //                 height: 24,
                            //                 color: Colors.white,
                            //               ),
                            //             ),
                            //             Expanded(
                            //               child: Container(
                            //                 child: Column(
                            //                   crossAxisAlignment:
                            //                       CrossAxisAlignment.start,
                            //                   children: [
                            //                     Text(
                            //                       localized(
                            //                           newVersionIsAvailableNow),
                            //                       style: TextStyle(
                            //                           color: ImColor.white),
                            //                     ),
                            //                     Visibility(
                            //                       visible: controller
                            //                           .isRecommendUninstall
                            //                           .value,
                            //                       child: Text(
                            //                         localized(
                            //                             highlyRecommendToUninstall),
                            //                         style: const TextStyle(
                            //                             color: JXColors
                            //                                 .secondaryTextWhite),
                            //                         maxLines: 2,
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ),
                            //             GestureDetector(
                            //               onTap: () {
                            //                 controller.showUpdateAlert(context);
                            //               },
                            //               child: Text(
                            //                 localized(updates),
                            //                 style: const TextStyle(
                            //                   fontSize: 13,
                            //                   color: Color(0xFF82D2FF),
                            //                 ),
                            //               ),
                            //             ),
                            //             GestureDetector(
                            //               onTap: () {
                            //                 controller
                            //                     .disableSoftUpdateNotification();
                            //               },
                            //               child: const Padding(
                            //                 padding: const EdgeInsets.only(
                            //                     left: 12.0),
                            //                 child: const Icon(
                            //                   Icons.close,
                            //                   size: 24.0,
                            //                   color: Colors.white,
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
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
                VerticalDivider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                  width: 1,
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
                            Get.put(
                                ChatInfoController.desktop(arguments['uid']));
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
}
