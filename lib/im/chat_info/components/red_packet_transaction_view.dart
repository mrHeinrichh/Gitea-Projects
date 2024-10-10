import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_info.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class RedPacketTransactionView extends StatefulWidget {
  final Chat chat;

  const RedPacketTransactionView({super.key, required this.chat});

  @override
  State<RedPacketTransactionView> createState() =>
      _RedPacketTransactionViewState();
}

class _RedPacketTransactionViewState extends State<RedPacketTransactionView>
    with AutomaticKeepAliveClientMixin, MessageWidgetMixin {
  /// 加载状态
  final isLoading = false.obs;

  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  final List<TargetWidgetKeyModel> _keyList = [];

  final options = [
    MessagePopupOption.findInChat,
    MessagePopupOption.delete,
    MessagePopupOption.select,
  ];

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    groupInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;

    if (widget.chat.flag_my >= ChatStatus.MyChatFlagKicked.value) {
      chatIsDeleted = true;
    } else {
      chatIsDeleted = false;
    }

    loadTransactionList();

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onRedPacketMessageUpdate);
    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    }
  }

  _onRedPacketMessageUpdate(sender, type, data) {
    if (data['id'] != widget.chat.id || data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int messageId = 0;
      if (item is Message) {
        id = item.id;
      } else {
        messageId = item;
      }
      for (final asset in messageList) {
        Message? msg = asset;
        if (id == 0) {
          if (msg.message_id == messageId) {
            delAsset.add(asset);
          }
        } else {
          if (msg.id == id) {
            delAsset.add(asset);
          }
        }
      }
    }

    if (delAsset.isNotEmpty) {
      for (final item in delAsset) {
        int index = messageList.indexOf(item);
        _keyList.removeAt(index);
        messageList.remove(item);
      }
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat.id) {
      if (data.typ != messageTypeSendRed) return;

      if (messageList.isEmpty) {
        final timeMsg = Message();
        timeMsg.send_id = -1;
        timeMsg.typ = messageTypeSysmsg;
        timeMsg.chat_idx = 0;
        timeMsg.create_time = data.create_time;
        messageList.add(timeMsg);
        messageList.add(data);
        return;
      }

      final Message timeMsg = messageList.first;
      if (FormatTime.iSameDay(timeMsg.create_time, data.create_time)) {
        messageList.insert(1, data);
        return;
      } else {
        final timeMsg = Message();
        timeMsg.send_id = -1;
        timeMsg.typ = messageTypeSysmsg;
        timeMsg.chat_idx = 0;
        timeMsg.create_time = data.create_time;
        messageList.insert(0, timeMsg);
        messageList.insert(1, data);
        return;
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onRedPacketMessageUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);

    super.dispose();
  }

  loadTransactionList() async {
    if (messageList.isEmpty) isLoading.value = true;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ?',
      [
        widget.chat.id,
        messageList.isEmpty
            ? widget.chat.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeSendRed,
      ],
      null,
      null,
    );
    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    if (mList.isNotEmpty) {
      for (final msg in mList) {
        if (msg.isDeleted || msg.isExpired) continue;
        if (messageList.isEmpty) {
          final timeMsg = Message();
          timeMsg.send_id = -1;
          timeMsg.typ = messageTypeSysmsg;
          timeMsg.chat_idx = 0;
          timeMsg.create_time = msg.create_time;
          messageList.add(timeMsg);
          messageList.add(msg);
          continue;
        }

        final lastMsgTime = DateTime.fromMillisecondsSinceEpoch(
          messageList.last.create_time * 1000,
        );
        final msgTime =
            DateTime.fromMillisecondsSinceEpoch(msg.create_time * 1000);

        if (lastMsgTime.day != msgTime.day) {
          final timeMsg = Message();
          timeMsg.send_id = -1;
          timeMsg.typ = messageTypeSysmsg;
          timeMsg.chat_idx = 0;
          timeMsg.create_time = msgTime.millisecondsSinceEpoch ~/ 1000;
          messageList.add(timeMsg);
        }
        messageList.add(msg);
      }
    }

    isLoading.value = false;
  }

  onItemLongPress(Message message) async {
    groupInfoController!.onMoreSelect.value = true;
    groupInfoController!.selectedMessageList.add(message);
  }

  onItemTap(Message message) {
    if (groupInfoController!.selectedMessageList.contains(message)) {
      groupInfoController!.selectedMessageList.remove(message);
      if (groupInfoController!.selectedMessageList.isEmpty) {
        groupInfoController!.onMoreSelect.value = false;
      }
    } else {
      groupInfoController!.selectedMessageList.add(message);
    }
  }

  onJumpToOriginalMessage(Message message) {
    Get.back();

    if (Get.isRegistered<GroupChatController>(tag: widget.chat.id.toString())) {
      final groupController =
          Get.find<GroupChatController>(tag: widget.chat.id.toString());
      groupController.clearSearching();
      groupController.locateToSpecificPosition([message.chat_idx]);
    } else {
      Routes.toChat(chat: widget.chat, selectedMsgIds: [message]);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: Platform.isAndroid
          ? () async {
              resetPopupWindow();
              return true;
            }
          : null,
      child: Obx(() {
        if (isLoading.value) {
          return BallCircleLoading(
            radius: 20,
            ballStyle: BallStyle(
              size: 4,
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
            ),
          );
        }

        if (messageList.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
                child: SvgPicture.asset(
                  'assets/svgs/empty_state.svg',
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localized(noHistoryYet),
                style: jxTextStyle.textStyleBold16(),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style: jxTextStyle.textStyle14(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          groupInfoController?.setUpItemKey(messageList, _keyList);
          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    Message msg = messageList[index];
                    if (msg.typ == messageTypeSysmsg) {
                      return const SizedBox(); //由前端處理日期分類會有bug產生, 因此先註解掉
                      // return Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 20.0,
                      //     vertical: 7.5,
                      //   ),
                      //   color: colorBorder,
                      //   child: Text(
                      //     '${isToday ? "${FormatTime.chartTime(msg.create_time, true)} " : ""}${FormatTime.getDateFormat(msg.create_time)}',
                      //     style: const TextStyle(color: colorTextSecondary),
                      //   ),
                      // );
                    }

                    MessageRed msgRed =
                        msg.decodeContent(cl: MessageRed.creator);

                    Widget child = buildTransaction(msg, msgRed);
                    TargetWidgetKeyModel model = _keyList[index];

                    return GestureDetector(
                      key: model.targetWidgetKey,
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (details) {
                        tapPosition = details.globalPosition;
                      },
                      onTap: () {
                        if (groupInfoController!.onMoreSelect.value &&
                            groupInfoController!.selectedMessageList.isEmpty) {
                          onItemTap(msg);
                        } else if (groupInfoController!.selectedMessageList
                            .contains(msg)) {
                          onItemTap(msg);
                        }
                      },
                      onLongPress: () {
                        vibrate();
                        if (objectMgr.loginMgr.isDesktop) {
                          if (!groupInfoController!.onMoreSelect.value) {
                            onItemLongPress(msg);
                          }
                        } else {
                          final msg = messageList[index];
                          enableFloatingWindowInfo(
                            context,
                            widget.chat.id,
                            msg,
                            child,
                            model.targetWidgetKey,
                            tapPosition,
                            ChatPopMenuSheetInfo(
                              message: msg,
                              chat: widget.chat,
                              sendID: msg.send_id,
                              options: options,
                              menuClick: (String title) {
                                resetPopupWindow();
                              },
                            ),
                            chatPopAnimationType: ChatPopAnimationType.right,
                            menuHeight: ChatPopMenuSheetInfo.getMenuHeight(
                              msg,
                              widget.chat,
                              options: options,
                            ),
                          );
                        }
                      },
                      child: child,
                    );
                  },
                  childCount: messageList.length,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget buildTransaction(
    Message msg,
    MessageRed msgRed,
  ) {
    return OverlayEffect(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 14.0,
        ),
        decoration: BoxDecoration(
          color: groupInfoController!.selectedMessageList.contains(msg)
              ? colorBorder
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(
              color: colorBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: NicknameText(
                    uid: msg.send_id,
                    isTappable: false,
                    fontWeight: MFontWeight.bold6.value,
                    fontSize: MFontSize.size16.value,
                    overflow: TextOverflow.ellipsis,
                    groupId: widget.chat.isGroup ? widget.chat.chat_id : null,
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(
                  '${msgRed.totalAmount} ${msgRed.currency}',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 16,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${FormatTime.getDateFormat(msg.create_time)} ${FormatTime.get12hourTime(msg.create_time)}',
                    style: const TextStyle(
                      color: colorTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(
                  localized(msgRed.rpType.name),
                  style: const TextStyle(
                    color: colorTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
