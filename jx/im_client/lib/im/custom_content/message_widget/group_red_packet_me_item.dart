import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/data/db_red_packet.dart';
import 'package:jxim_client/im/custom_content/animation/red_packet_content_animation.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/red_packet_message_bubble.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/services/red_packet_animation.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class GroupRedPacketMeItem extends StatefulWidget {
  final Message message;
  final MessageRed messageRed;
  final Chat chat;
  final int index;
  final bool isPrevious;

  const GroupRedPacketMeItem({
    super.key,
    required this.message,
    required this.messageRed,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  @override
  State<GroupRedPacketMeItem> createState() => _GroupRedPacketMeItemState();
}

class _GroupRedPacketMeItemState
    extends MessageWidgetMixin<GroupRedPacketMeItem> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  Rx<ReceiveInfo> redPacketReceiveInfo = ReceiveInfo().obs;

  late Widget childBody;

  final RxBool redPacketIsExpired = false.obs;

  RedPacketStatus? rpStatus;
  final RxInt redPacketStatus = 0.obs;

  List<RedPacketStatus> get redPacketStatusList =>
      objectMgr.chatMgr.redPacketStatusMap[widget.chat.id] ?? [];

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    final status = redPacketStatusList
        .firstWhereOrNull((element) => element.id == widget.messageRed.id);
    if (status != null) {
      rpStatus = status;
      redPacketStatus.value = status.status ?? 0;
    }

    if (redPacketStatus.value == 0) {
      getRedPacketDetail();
    }
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventRedPacketStatus, _onRedPacketUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(controller.chatController, widget.index, widget.message);
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventRedPacketStatus, _onRedPacketUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  _onRedPacketUpdate(Object sender, Object type, Object? data) {
    if (data is RedPacketStatus) {
      if (data.id == widget.messageRed.id) {
        rpStatus = data;
        redPacketStatus.value = data.status ?? 0;
      }
    }

    if (data is Message) {
      MessageRed receivedMsg = data.decodeContent(cl: MessageRed.creator);
      if (!objectMgr.userMgr.isMe(receivedMsg.userId)) return;

      if (widget.messageRed.id == receivedMsg.id) {
        getRedPacketDetail();
      }
    }
  }

  Function? callToast;

  String getRedPacketClaimTxtByStatus(int redPacketStatus) {
    return switch (redPacketStatus) {
      // rpYetReceive => localized(redPacketUnClaim),
      rpReceived => localized(congratulationsYouHaveClaimedThisRedPacket),
      rpNotInExclusive => localized(NotInTheExclusiveRedPacket),
      rpFullyClaimed => localized(thisRedPacketHasBeenFullyClaimed),
      rpExpired => localized(redPacketExpired),
      _ => 'Unknown Status RedPacket',
    };
  }

  getRedPacketDetail() async {
    List<RedPacketStatus> rpsList =
        await objectMgr.chatMgr.getRedPacketInfoByRemote([
      [widget.message, widget.messageRed]
    ]);
    RedPacketStatus? rps;
    if (rpsList.isNotEmpty) {
      rps = rpsList.first;
    }

    if (rps == null) {
      return;
    }

    rps.id = widget.messageRed.id;

    if (redPacketStatusList.isNotEmpty) {
      final indexRp = redPacketStatusList.indexOf(rps);
      if (indexRp != -1) {
        redPacketStatusList[indexRp] = rps;
      } else {
        redPacketStatusList.add(rps);
      }
    } else {
      objectMgr.chatMgr.redPacketStatusMap
          .putIfAbsent(widget.chat.id, () => [rps!]);
    }

    objectMgr.sharedRemoteDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptReplace, DBRedPacket.tableName, [
        rps.toJson(),
      ]),
      notify: false,
    );

    rpStatus = rps;
    redPacketStatus.value = rps.status ?? 0;
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  Widget build(BuildContext context) {
    var rpConfig = widget.messageRed.rpType == RedPacketType.luckyRedPacket
        ? luckyRedPacketConfig
        : widget.messageRed.rpType == RedPacketType.normalRedPacket
            ? normalRedPacketConfig
            : exclusiveRedPacketConfig;

    childBody = messageBody(context, rpConfig);

    return Obx(() => isExpired.value || isDeleted.value
        ? const SizedBox()
        : Stack(
            children: [
              GestureDetector(
                key: targetWidgetKey,
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  tapPosition = details.globalPosition;
                  isPressed.value = true;
                },
                onTapUp: (details) {
                  if (controller.isCTRLPressed()) {
                    desktopGeneralDialog(
                      context,
                      color: Colors.transparent,
                      widgetChild: DesktopMessagePopMenu(
                        offset: details.globalPosition,
                        isSender: true,
                        emojiSelector: const SizedBox(),
                        popMenu: ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                        ),
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message, widget.chat,
                            extr: false),
                      ),
                    );
                  }
                  controller.chatController.onCancelFocus();
                  isPressed.value = false;
                },
                onTapCancel: () {
                  isPressed.value = false;
                },
                onLongPress: () {
                  if (!objectMgr.loginMgr.isDesktop) {
                    _showEnableFloatingWindow(context);
                    isPressed.value = false;
                  }
                },
                onSecondaryTapDown: (details) {
                  if (objectMgr.loginMgr.isDesktop) {
                    desktopGeneralDialog(
                      context,
                      color: Colors.transparent,
                      widgetChild: DesktopMessagePopMenu(
                        offset: details.globalPosition,
                        isSender: true,
                        emojiSelector: const SizedBox(),
                        popMenu: ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                        ),
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message, widget.chat,
                            extr: false),
                      ),
                    );
                  }
                  isPressed.value = true;
                },
                child: childBody,
              ),
              Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: 0.0,
                child: RepaintBoundary(
                  child: MoreChooseView(
                    chatController: controller.chatController,
                    message: widget.message,
                    chat: widget.chat,
                  ),
                ),
              ),
            ],
          ));
  }

  void _showEnableFloatingWindow(BuildContext context) {
    enableFloatingWindow(
      context,
      widget.chat.id,
      widget.message,
      childBody,
      targetWidgetKey,
      tapPosition,
      ChatPopMenuSheet(
        message: widget.message,
        chat: widget.chat,
        sendID: widget.message.send_id,
      ),
      bubbleType: BubbleType.sendBubble,
      menuHeight: ChatPopMenuUtil.getMenuHeight(widget.message, widget.chat),
    );
  }

  Widget messageBody(BuildContext context, Map<String, dynamic> rpConfig) {
    RedPacketTheme theme = RedPacketTheme(
      rpConfig['redPacketCover'],
      rpConfig['redPacketOpen'],
      rpConfig['topFoldBackground'],
      rpConfig['bottomFoldBackground'],
      rpConfig['bodyBackground'],
      rpConfig['paperBackground'],
    );

    BubblePosition position = isFirstMessage && isLastMessage
        ? BubblePosition.isFirstAndLastMessage
        : isLastMessage
            ? BubblePosition.isLastMessage
            : isFirstMessage
                ? BubblePosition.isFirstMessage
                : BubblePosition.isMiddleMessage;

    if (controller.chatController.isPinnedOpened) {
      position = BubblePosition.isLastMessage;
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: EdgeInsets.only(
          top: jxDimension.chatBubbleTopMargin(position),
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
          bottom:
              isPinnedOpen ? 4.w : jxDimension.chatBubbleBottomMargin(position),
        ),
        constraints: BoxConstraints(
          maxWidth: (ObjectMgr.screenMQ!.size.width * 0.8) +
              (widget.message.isSendOk ? 30 : 0),
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Obx(
                    () {
                      if (redPacketStatus.value == 0) {
                        return SizedBox(
                          width: ObjectMgr.screenMQ!.size.height * 0.26 * 0.77,
                          height: ObjectMgr.screenMQ!.size.height * 0.22,
                        );
                      }
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        child: Stack(
                          children: <Widget>[
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return Obx(
                                  () => GestureDetector(
                                    onTap: objectMgr.loginMgr.isDesktop
                                        ? null
                                        : controller.chatController.popupEnabled
                                            ? null
                                            : () {
                                                if (controller.chatController
                                                    .isSetPassword.value) {
                                                  openRedPacket(
                                                      constraints, theme);
                                                } else {
                                                  final snackBar = snackbar();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(snackBar);
                                                }
                                              },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: jxDimension
                                            .chatBubbleTopMargin(position),
                                        bottom: jxDimension
                                            .chatBubbleBottomMargin(position),
                                      ),
                                      child: RedPacketMessageBubble(
                                        bubbleType: BubbleType.sendBubble,
                                        rpType: widget.messageRed.rpType,
                                        redPacketStatus: redPacketStatus.value,
                                        redPacketRemark:
                                            widget.messageRed.remark,
                                        isPressed: isPressed.value,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              right: objectMgr.loginMgr.isDesktop ? 5 : 8.w,
                              bottom: objectMgr.loginMgr.isDesktop ? 5 : 8.w,
                              child: ChatReadNumView(
                                message: widget.message,
                                chat: widget.chat,
                                showPinned: controller
                                        .chatController.pinMessageList
                                        .firstWhereOrNull((pinnedMsg) =>
                                            pinnedMsg.id ==
                                            widget.message.id) !=
                                    null,
                                sender: false,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (!widget.message.isSendOk)
                    Padding(
                      padding: EdgeInsets.only(
                        left: objectMgr.loginMgr.isDesktop
                            ? 5
                            : !message.isSendFail
                                ? 0
                                : 5.w,
                        bottom: 1,
                      ),
                      child: _buildState(widget.message),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(
      key: Key(time.toString()),
      message: msg,
      failMsgClick: () {
        if (controller.chatController.popupEnabled) {
          return;
        }
        _showEnableFloatingWindow(context);
      },
    );
  }

  void openRedPacket(BoxConstraints constraints, RedPacketTheme theme) {
    controller.chatController.playerService.stopPlayer();
    controller.chatController.playerService.resetPlayer();
    bool isClicked = false;
    if (redPacketStatus.value != 0 && redPacketStatus.value != rpYetReceive) {
      navigateToLeaderboard();
    } else {
      if (controller.chatController.redPacketEntry != null) {
        controller.chatController.redPacketEntry?.remove();
        controller.chatController.redPacketEntry = null;
      }
      controller.chatController.redPacketEntry =
          OverlayEntry(builder: (BuildContext context) {
        return Container(
          color: colorOverlay40,
          width: ObjectMgr.screenMQ!.size.width,
          height: ObjectMgr.screenMQ!.size.height,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (notBlank(controller.chatController.redPacketEntry) &&
                    redPacketStatus.value != 0 &&
                    redPacketStatus.value != rpYetReceive) {
                  controller.chatController.redPacketEntry?.remove();
                  controller.chatController.redPacketEntry = null;
                  navigateToLeaderboard();
                }
              },
              child: RedPacket(
                redPacketMessage: RedPacketMessageWidget(
                  message: widget.message,
                  messageRed: widget.messageRed,
                  chat: widget.chat,
                ),
                onPressClose: () {
                  controller.chatController.redPacketEntry?.remove();
                  controller.chatController.redPacketEntry = null;
                },
                detailTap: () {
                  controller.chatController.redPacketEntry?.remove();
                  controller.chatController.redPacketEntry = null;
                  navigateToLeaderboard();
                },
                onFinish: () {
                  controller.chatController.redPacketEntry?.remove();
                  controller.chatController.redPacketEntry = null;
                },
                onOpen: () async {
                  Toast.show(allowClick: true);

                  if (!isClicked) {
                    isClicked = true;
                    try {
                      /// 调用领取 红包 api
                      final res = await WalletServices().receiveRedPacket(
                        rpID: widget.messageRed.id,
                        chatID: widget.message.chat_id,
                        rpType: widget.messageRed.rpType.value,
                      );

                      redPacketReceiveInfo.update((ReceiveInfo? info) {
                        info!.amount = res['amount'];
                        info.userId = objectMgr.userMgr.mainUser.id;
                        info.uuid = objectMgr.userMgr.mainUser.accountId;
                        info.receiveTime =
                            DateTime.now().millisecondsSinceEpoch;
                        info.receiveFlag =
                            res['status'] == rpReceived ? true : false;
                      });

                      if (res['error']) {
                        Toast.hide();
                        Toast.showToast(localized(redPacketFailedClaim));
                      } else {
                        final index = redPacketStatusList.indexWhere(
                            (element) => element.id == rpStatus!.id);
                        rpStatus!.status = res['status'];
                        redPacketStatus.value = res['status'];
                        redPacketStatusList[index] = rpStatus!;

                        objectMgr.sharedRemoteDB.applyUpdateBlock(
                          UpdateBlockBean.created(
                              blockOptUpdate, DBRedPacket.tableName, {
                            'id': widget.messageRed.id,
                            'status': rpStatus!.status,
                          }),
                          notify: false,
                        );

                        callToast = () => Toast.showToast(localized(
                            getRedPacketClaimTxtByStatus(
                                redPacketStatus.value)));
                      }
                    } on CodeException catch (e) {
                      Toast.hide();
                      Toast.showToast(e.getMessage());
                      return;
                    }
                  }
                  Toast.hide();

                  navigateToLeaderboard(function: callToast);
                  controller.chatController.redPacketEntry?.remove();
                  controller.chatController.redPacketEntry = null;
                },
              ),
            ),
          ),
        );
      });
      Overlay.of(context).insert(controller.chatController.redPacketEntry!);
    }
  }

  void navigateToLeaderboard({Function? function}) {
    Get.toNamed(RouteName.redPacketLeaderboard, arguments: {
      'redPacketStatus': redPacketStatus.value != 0 ? redPacketStatus.value : 6,
      'redPacketColor': widget.messageRed.rpType.bgColor,
      'redPacketBackground': widget.messageRed.rpType.leaderboardBg,
      'leaderBoardSelfGradient':
          widget.messageRed.rpType == RedPacketType.luckyRedPacket
              ? [
                  const Color(0xFFFBC676),
                  const Color(0xFFF7943C),
                ]
              : widget.messageRed.rpType == RedPacketType.normalRedPacket
                  ? [
                      const Color(0xFFEE4A4C),
                      const Color(0xFFEE4A4C),
                    ]
                  : [
                      const Color(0xFFFCD36B),
                      const Color(0xFFFCD36B),
                    ],
      'messageRed': widget.messageRed,
      'toast_function': function,
      'chat': widget.chat,
    });
  }

  SnackBar snackbar() {
    return SnackBar(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: 12,
        right: 0,
      ),
      content: Text(
        localized(unableToClaimPleaseSetupYourPasscode),
        style: jxTextStyle.textStyle14(color: Colors.white),
      ),
      action: SnackBarAction(
        label: localized(goSettings),
        onPressed: () {
          Get.toNamed(
            RouteName.privacySecurity,
            arguments: {
              'from_view': 'chat_view',
              'chat': controller.chatController.chat,
            },
          );
        },
      ),
    );
  }
}
