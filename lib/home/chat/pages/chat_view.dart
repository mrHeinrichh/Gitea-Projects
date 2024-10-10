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
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<StatefulWidget> createState() => ChatViewState();
}

class SlowScrollPhysics extends BouncingScrollPhysics{
  const SlowScrollPhysics({super.parent});

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(position, velocity * 0.9); // 减缓滚动速度
  }
}

class ChatViewState extends State<ChatView> with AutomaticKeepAliveClientMixin {
  ChatListController get controller => Get.find<ChatListController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () {
        final searchBar = Container(
          margin: EdgeInsets.symmetric(
            vertical: kSearchHeight.value / 4.5,
          ),
          child: Row(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.centerRight,
                curve: Curves.decelerate,
                widthFactor: controller.isSearching.value ? 1 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: controller.isSearching.value ? 1 : 0,
                  child: Visibility(
                   visible: controller.isSearching.value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: (){
                        controller.searchFocus.unfocus();
                        controller.clearSearching();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SvgPicture.asset(
                          'assets/svgs/Back.svg',
                          width: 24,
                          height: 24,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: controller.isSearching.value ? 12.0 : 16.0),
                  child: SearchingAppBar(
                    onTap: () {
                      controller.isSearching(true);
                      controller.searchFocus.unfocus();
                      Future.delayed(const Duration(milliseconds: 50), () {
                        controller.searchFocus.requestFocus();
                      });
                    },
                    onChanged: controller.onSearchChanged,
                    onCancelTap: () {
                      controller.searchFocus.unfocus();
                      controller.clearSearching();
                    },
                    searchBarHeight: kSearchHeight.value,
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
                          color: colorTextSupporting,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    isShowCancelText: false,
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.centerLeft,
                curve: Curves.decelerate,
                widthFactor: controller.isSearching.value ? 1 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: controller.isSearching.value ? 1 : 0,
                  child: Visibility(
                    visible: controller.isSearching.value,
                    child: GestureDetector(
                      onTap: () => controller.enterSecretaryChat(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: OpacityEffect(
                          child: ClipOval(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Image.asset(
                                'assets/images/message_new/secretary.png',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: colorBackground,
          resizeToAvoidBottomInset: false,
          appBar: ChatViewAppBar(
            height: getTopBarHeight(),
            titleWidget: connectView(),
            leading: CustomTextButton(
              controller.isEditing.value
                  ? localized(buttonDone)
                  : localized(buttonEdit),
              onClick: controller.onChatEditTap,
            ),
            trailing: Visibility(
              visible: !controller.isEditing.value,
              child: Row(
                children: [
                  CustomImage(
                    'assets/svgs/home_scan.svg',
                    size: 24,
                    color: themeColor,
                    fit: BoxFit.fitWidth,
                    onClick: () async => controller.scanQRCode(),
                  ),
                  const SizedBox(width: 12),
                  CustomImage(
                    'assets/svgs/home_new_chat.svg',
                    size: 24,
                    color: themeColor,
                    fit: BoxFit.fitWidth,
                    onClick: () => controller.showCreateChatPopup(context),
                  ),
                ],
              ),
            ),
            isSearchingMode: controller.isSearching.value,
            searchWidget: searchBar,
            bottomWidget: const ChatPinContainer(isFromHome: true),
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
                      physics: const AlwaysScrollableScrollPhysics(
                          parent:  SlowScrollPhysics()),
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
                                      if (controller.isClosed) return;

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
                                        // if (index !=
                                        //     controller.chatList.length - 1)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: jxDimension.chatCellPadding(),
                                          ),
                                          child: const CustomDivider(),
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
                                              (controller.searchParam.value)
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Obx(
          () => Visibility(
            visible: objectMgr.appInitState.value == AppInitState.fetching,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                color: themeColor,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (Widget child, Animation<double> animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              key: ValueKey(objectMgr.appInitState.value),
              objectMgr.appInitState.value.toName,
              textAlign: TextAlign.center,
              style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
            ), // THIS CHANGES THE IMAGE FINE, BUT DOESNT ANIMATE
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
