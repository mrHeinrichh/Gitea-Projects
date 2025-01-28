import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/controllers/chat_item_controller.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/item_views/chat_cell_view.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/component/home_searching_header.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> with AutomaticKeepAliveClientMixin {
  ChatListController get controller => Get.find<ChatListController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () {
        final searchBar = Container(
          color: backgroundColor,
          margin: const EdgeInsets.only(
            top: 8.0,
            left: 16.0,
            right: 16.0,
          ),
          child: SearchingAppBar(
            onTap: () => controller.isSearching(true),
            onChanged: controller.onSearchChanged,
            onCancelTap: () {
              controller.searchFocus.unfocus();
              controller.clearSearching();
            },
            isSearchingMode: controller.isSearching.value,
            isAutoFocus: false,
            focusNode: controller.searchFocus,
            controller: controller.searchController,
            suffixIcon: Visibility(
              visible: controller.searchParam.value.isNotEmpty,
              child: IconButton(
                onPressed: () {
                  controller.searchController.clear();
                  controller.searchParam.value = '';
                  controller.searchLocal();
                },
                icon: SvgPicture.asset(
                  'assets/svgs/close_round_icon.svg',
                  color: JXColors.iconSecondaryColor,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        );
        return Scaffold(
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: false,
          appBar: ChatViewAppBar(
            isSearchingMode: controller.isSearching.value,
            titleWidget: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    width: 0.3,
                    color: JXColors.borderPrimaryColor,
                  ),
                ),
              ),
              height: getTopBarHeight(),
              child: !controller.isSearching.value
                  ? Stack(
                      children: [
                        connectView(),
                        Positioned(
                          top: topBarTitleTopGap,
                          left: 16,
                          child: OpacityEffect(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: controller.onChatEditTap,
                              child: Text(
                                controller.isEditing.value
                                    ? localized(buttonDone)
                                    : localized(buttonEdit),
                                style: jxTextStyle.textStyle17(
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: topBarTitleTopGap,
                          right: 16,
                          child: Visibility(
                            visible: !controller.isEditing.value,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => controller.scanQRCode(),
                                      child: OpacityEffect(
                                        child: SvgPicture.asset(
                                          'assets/svgs/home_scan.svg',
                                          width: 24,
                                          height: 24,
                                          color: accentColor,
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    ),
                                    ImGap.hGap12,
                                    GestureDetector(
                                      onTap: () => controller
                                          .showCreateChatPopup(context),
                                      child: OpacityEffect(
                                        child: SvgPicture.asset(
                                          'assets/svgs/home_new_chat.svg',
                                          width: 24,
                                          height: 24,
                                          color: accentColor,
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: kTitleHeight + 9 + topBarTitleTopGap,
                          left: 0,
                          right: 0,
                          child: Container(
                            child: Column(
                              children: [
                                searchBar,
                                const Padding(
                                  padding: EdgeInsets.only(top: topBarTitleTopGap -3),
                                  child: ChatPinContainer(
                                    isFromHome: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : searchBar,
            ),
          ),
          body: Stack(
            children: <Widget>[
              ///不要再拿掉,底部上滑bouncing要看到白色背景色
              Positioned(
                bottom: 0,
                left: 0, // 设置左侧边界,不可拿掉
                right: 0, // 设置右侧边界,不可拿掉
                child: Container(
                  height: 310.w,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              RefreshIndicator(
                edgeOffset: -100.0,
                displacement: 0.0,
                onRefresh: () => controller.onRefresh(),
                child: Listener(
                  onPointerUp: (event) {
                    controller.touchUpDown = true;
                  },
                  onPointerDown: (event) {
                    controller.touchUpDown = false;
                  },
                  child: NotificationListener(
                    onNotification: (notification) {
                      if (notification is ScrollNotification) {
                        controller.onScroll(notification);
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      controller: controller.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        ///搜索消息列表header
                        HomeSearchingHeader<Chat>(
                            controller: controller,
                            title: localized(homeChat),
                            list: controller.chatList,
                            isShowLabel: controller.isShowLabel.value),

                        SlidableAutoCloseBehavior(
                          child: Obx(
                            () => SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final Chat chat = controller.chatList[index];
                                  if (chat.typ == chatTypePostNotify) {
                                    return const SizedBox();
                                  }

                                  return VisibilityDetector(
                                    key: ValueKey('${chat.id}'),
                                    onVisibilityChanged:
                                        (VisibilityInfo visibilityInfo) {
                                      controller.onChatVisible(chat);
                                      if (index ==
                                              controller.chatList.length - 1 &&
                                          visibilityInfo.visibleFraction == 0) {
                                        controller.isShowLabel.value = false;
                                      } else {
                                        controller.isShowLabel.value = true;
                                      }
                                    },
                                    child: Column(
                                      children: <Widget>[
                                        GetBuilder<ChatItemController>(
                                          tag:
                                              'chat_item_${chat.id.toString()}',
                                          builder: (controller) {
                                            return ChatCellView<
                                                ChatItemController>(
                                              tag:
                                                  'chat_item_${chat.id.toString()}',
                                              chat: chat,
                                              index: index,
                                            );
                                          },
                                          init:
                                              Get.findOrPut<ChatItemController>(
                                            ChatItemController(
                                                chat: chat,
                                                isEditing:
                                                    controller.isEditing),
                                            tag:
                                                'chat_item_${chat.id.toString()}',
                                            permanent: true,
                                          ),
                                        ),
                                        if (index !=
                                            controller.chatList.length - 1)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left:
                                                  jxDimension.chatCellPadding(),
                                            ),
                                            child: const CustomDivider(
                                              thickness: 0.33,
                                              color:
                                                  JXColors.borderPrimaryColor,
                                            ),
                                          )
                                      ],
                                    ),
                                  );
                                },
                                childCount: controller.chatList.length,
                                addRepaintBoundaries: false,
                              ),
                            ),
                          ),
                        ),

                        // ///支援動畫的sliver list
                        // SlidableAutoCloseBehavior(
                        //   child: Obx(
                        //     () => SliverAnimatedList(
                        //       key: controller.chatListKey,
                        //       initialItemCount: controller.chatList.length,
                        //       itemBuilder: (BuildContext context, int index,
                        //           Animation<double> animation) {
                        //         pdebug(
                        //             "Index: $index | Animation: ${animation.value}");
                        //         final Chat chat = controller.chatList[index];
                        //         if (chat.typ == chatTypePostNotify ||
                        //             chat.typ == chatTypeSystem) {
                        //           return const SizedBox();
                        //         }
                        //
                        //         return ChatCellView(
                        //           key: ValueKey('${chat.id}'),
                        //           chat: chat,
                        //           animation: animation,
                        //           index: index,
                        //         );
                        //       },
                        //     ),
                        //   ),
                        // ),

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
                                  searchText: controller.searchParam.value,
                                );
                              },
                              childCount: controller.isSearching.value &&
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
                                visible: controller.messageList.isEmpty &&
                                    controller.chatList.isEmpty,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: controller.isSearching.value
                                      ? SearchEmptyState(
                                          searchText:
                                              controller.searchParam.value,
                                          emptyMessage: localized(
                                            oppsNoResultFoundTryNewSearch,
                                            params: [
                                              '${controller.searchParam.value}'
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding:
                                              const EdgeInsets.only(top: 50),
                                          child: Text(
                                            localized(noChatsAtThisMoment),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget connectView() {
    return Padding(
      padding: const EdgeInsets.only(top: topBarTitleTopGap),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Obx(() => Visibility(
              visible: objectMgr.appInitState.value == AppInitState.fetching,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 2.w,
                ),
              ))),
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (Widget child, Animation<double> animation) =>
                    ScaleTransition(child: child, scale: animation),
                child: Text(
                  key: ValueKey(objectMgr.appInitState.value),
                  objectMgr.appInitState.value.toName,
                  textAlign: TextAlign.center,
                  style:
                      jxTextStyle.appTitleStyle(color: JXColors.primaryTextBlack),
                ), // THIS CHANGES THE IMAGE FINE, BUT DOESNT ANIMATE
              ))
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// class SearchBarHeader extends SliverPersistentHeaderDelegate {
//   final Widget searchBarWidget;
//
//   const SearchBarHeader({required this.searchBarWidget});
//
//   @override
//   Widget build(
//       BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return searchBarWidget;
//   }
//
//   @override
//   double get maxExtent => 50;
//
//   @override
//   double get minExtent => 0;
//
//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
//       true;
// }
