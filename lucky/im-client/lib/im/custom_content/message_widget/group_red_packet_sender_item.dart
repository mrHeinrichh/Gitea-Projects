import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/data/db_red_packet.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/red_packet_animation.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../../utils/localization/app_localizations.dart';
import '../../../utils/saved_message_icon.dart';
import '../../../views_desktop/component/desktop_general_dialog.dart';
import '../../services/desktop_message_pop_menu.dart';

class GroupRedPacketSenderItem extends StatefulWidget {
  final Message message;
  final MessageRed messageRed;
  final Chat chat;
  final int index;
  final isPrevious;

  const GroupRedPacketSenderItem({
    Key? key,
    required this.message,
    required this.messageRed,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);

  @override
  State<GroupRedPacketSenderItem> createState() =>
      _GroupRedPacketSenderItemState();
}

class _GroupRedPacketSenderItemState extends State<GroupRedPacketSenderItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  Rx<ReceiveInfo> redPacketReceiveInfo = ReceiveInfo().obs;
  final RxString enterDetailText = 'Click To View Details >>>'.obs;
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

    initMessage(controller.chatController, widget.index, widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventRedPacketStatus, _onRedPacketUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
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

  bool get showAvatar =>
      !controller.chat!.isSystem &&
          !controller.chat!.isSecretary &&
          !controller.chat!.isSingle &&
          (isLastMessage || controller.chatController.isPinnedOpened);

  @override
  Widget build(BuildContext context) {
    var rpConfig = widget.messageRed.rpType == RedPacketType.luckyRedPacket
        ? luckyRedPacketConfig
        : widget.messageRed.rpType == RedPacketType.normalRedPacket
        ? normalRedPacketConfig
        : exclusiveRedPacketConfig;

    Widget child = messageBody(rpConfig);

    return Obx(
          () => isExpired.value || isDeleted.value
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
                DesktopGeneralDialog(
                  context,
                  color: Colors.transparent,
                  widgetChild: DesktopMessagePopMenu(
                    offset: details.globalPosition,
                    emojiSelector: const SizedBox(),
                    popMenu: ChatPopMenuSheet(
                      message: widget.message,
                      chat: widget.chat,
                      sendID: widget.message.send_id,
                    ),
                    menuHeight: ChatPopMenuSheet.getMenuHeight(
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
                enableFloatingWindow(
                  context,
                  widget.chat.id,
                  widget.message,
                  child,
                  targetWidgetKey,
                  tapPosition,
                  ChatPopMenuSheet(
                    message: widget.message,
                    chat: widget.chat,
                    sendID: widget.message.send_id,
                  ),
                  bubbleType: BubbleType.receiverBubble,
                  menuHeight: ChatPopMenuSheet.getMenuHeight(
                      widget.message, widget.chat),
                );
                isPressed.value = false;
              }
            },
            onSecondaryTapDown: (details) {
              if (objectMgr.loginMgr.isDesktop) {
                DesktopGeneralDialog(
                  context,
                  color: Colors.transparent,
                  widgetChild: DesktopMessagePopMenu(
                    offset: details.globalPosition,
                    emojiSelector: const SizedBox(),
                    popMenu: ChatPopMenuSheet(
                      message: widget.message,
                      chat: widget.chat,
                      sendID: widget.message.send_id,
                    ),
                    menuHeight: ChatPopMenuSheet.getMenuHeight(
                        widget.message, widget.chat,
                        extr: false),
                  ),
                );
              }
              isPressed.value = true;
            },
            child: child,
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
      ),
    );
  }

  Widget messageBody(Map<String, dynamic> rpConfig) {
    RedPacketTheme theme = RedPacketTheme(
      rpConfig['redPacketCover'],
      rpConfig['redPacketOpen'],
      rpConfig['topFoldBackground'],
      rpConfig['bottomFoldBackground'],
      rpConfig['bodyBackground'],
      rpConfig['paperBackground'],
    );

    return Obx(() {
      /// 消息主体
      if (redPacketStatus.value == 0) {
        return SizedBox(
          width: ObjectMgr.screenMQ!.size.height * 0.26 * 0.77,
          height: ObjectMgr.screenMQ!.size.height * 0.22,
        );
      }

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

      Widget body = AnimatedContainer(
        margin: EdgeInsets.only(left: jxDimension.chatBubbleLeftMargin),
        duration: const Duration(milliseconds: 100),
        constraints: BoxConstraints(
          maxWidth: ObjectMgr.screenMQ!.size.height * 0.26 * 0.77,
          maxHeight: ObjectMgr.screenMQ!.size.height * 0.22,
        ),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Obx(
                      () => GestureDetector(
                    onTap: controller.chatController.popupEnabled
                        ? null
                        : () {
                      if (controller.chatController.isSetPassword.value) {
                        openRedPacket(constraints, theme);
                      } else {
                        final snackBar = snackbar();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(snackBar);
                      }
                    },
                    child: getRedPacketImage(
                      redPacketStatus.value,
                      constraints,
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
                showPinned: controller.chatController.pinMessageList
                    .firstWhereOrNull(
                        (pinnedMsg) => pinnedMsg.id == widget.message.id) !=
                    null,
                backgroundColor: JXColors.black48,
                sender: true,
              ),
            ),
          ],
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          top: jxDimension.chatBubbleTopMargin(position),
          right: jxDimension.chatRoomSideMarginMaxGap,
          left: controller.chatController.chooseMore.value
              ? 40.w
              : (widget.chat.typ == chatTypeSingle
              ? jxDimension.chatRoomSideMarginSingle
              : jxDimension.chatRoomSideMargin),
          bottom:
          isPinnedOpen ? 4.w : jxDimension.chatBubbleBottomMargin(position),
        ),
        constraints: BoxConstraints(
          maxWidth: (ObjectMgr.screenMQ!.size.width * 0.8) +
              (widget.message.isSendOk ? 30 : 0),
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              body,
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (controller.chat!.isSaveMsg) {
      return Container(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color(0xFFFFD08E),
              Color(0xFFFFECD2),
            ],
          ),
        ),
        child: const SavedMessageIcon(),
      );
    }

    if (controller.chat!.isSecretary) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        uid: widget.message.send_id,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: widget.message.send_id == 0
            ? null
            : () {
          Get.toNamed(RouteName.chatInfo,
              arguments: {
                "uid": widget.message.send_id,
              },
              id: objectMgr.loginMgr.isDesktop ? 1 : null);
        },
        onLongPress: widget.message.send_id == 0
            ? null
            : () async {
          User? user = await objectMgr.userMgr
              .loadUserById2(widget.message.send_id);
          if (user != null) {
            controller.inputController.addMentionUser(user);
          }
        },
      );
    }

    return SizedBox(
      key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
      width: controller.chatController.chat.isSingle ||
          controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
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
            return GestureDetector(
              onTap: () {
                controller.chatController.redPacketEntry?.remove();
                controller.chatController.redPacketEntry = null;
              },
              child: Container(
                color: Colors.grey.withOpacity(0.3),
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
                    child: Container(
                      width: 400 * 0.7,
                      height: 350,
                      child: Obx(
                            () => RedPacketAnimImpl(
                          isMessage: false,
                          rpStatus: redPacketStatus.value,
                          message: widget.message,
                          messageRed: widget.messageRed,
                          theme: theme,
                          isOpen: redPacketStatus.value != 0 &&
                              redPacketStatus.value != rpYetReceive,
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
                                  Toast.showToast('领取失败! 已领取过此红包');
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
                                      'status': res['status'],
                                    }),
                                    notify: false,
                                  );
                                }
                              } on CodeException catch (e) {
                                Toast.hide();
                                Toast.showToast(e.getMessage());
                                return;
                              }
                            }

                            Toast.hide();
                          },
                          redPacketReceiveInfo: redPacketReceiveInfo.value,
                          cardSize: const Size(
                            400 * 0.6,
                            400 - 84.0 - 10.0,
                          ),
                          onDetailTapCallback: () {
                            navigateToLeaderboard();
                            controller.chatController.redPacketEntry?.remove();
                            controller.chatController.redPacketEntry = null;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
      Overlay.of(context).insert(controller.chatController.redPacketEntry!);
    }
  }

  void navigateToLeaderboard() {
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
    });
  }

  Widget getRedPacketImage(int redPacketStatus, BoxConstraints constraints) {
    String claimImage = 'rp_claimed.png';
    String fullyClaimedImage = 'rp_fully_claimed.png';
    String expiredImage = 'rp_expired.png';
    String notInExclusiveImage = 'rp_not_in_exclusive.png';

    if (AppLocalizations.of(context)?.isMandarin()) {
      claimImage = 'rp_claimed_cn_simplified.png';
      fullyClaimedImage = 'rp_fully_claimed_cn_simplified.png';
      expiredImage = 'rp_expired_cn_simplified.png';
      notInExclusiveImage = 'rp_not_in_exclusive_cn_simplified.png';
    }

    switch (redPacketStatus) {
      case rpYetReceive:
        return Image.asset(
          widget.messageRed.rpType == RedPacketType.normalRedPacket
              ? 'assets/images/red_packet/message/rp_normal_close_cover.png'
              : widget.messageRed.rpType == RedPacketType.luckyRedPacket
              ? 'assets/images/red_packet/message/rp_lucky_close_cover.png'
              : 'assets/images/red_packet/message/rp_specific_close_cover.png',
          width: constraints.maxWidth * 0.9,
          height: constraints.maxHeight,
          fit: BoxFit.contain,
        );
      case rpReceived:
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image.asset(
              widget.messageRed.rpType == RedPacketType.normalRedPacket
                  ? 'assets/images/red_packet/message/rp_normal_open_cover.png'
                  : widget.messageRed.rpType == RedPacketType.luckyRedPacket
                  ? 'assets/images/red_packet/message/rp_lucky_open_cover.png'
                  : 'assets/images/red_packet/message/rp_specific_open_cover.png',
              width: constraints.maxWidth * 0.9,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.7,
              child: Image.asset(
                'assets/images/red_packet/message/${claimImage}',
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      case rpNotInExclusive:
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image.asset(
              widget.messageRed.rpType == RedPacketType.normalRedPacket
                  ? 'assets/images/red_packet/message/rp_normal_open_cover.png'
                  : widget.messageRed.rpType == RedPacketType.luckyRedPacket
                  ? 'assets/images/red_packet/message/rp_lucky_open_cover.png'
                  : 'assets/images/red_packet/message/rp_specific_open_cover.png',
              width: constraints.maxWidth * 0.9,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.7,
              child: Image.asset(
                'assets/images/red_packet/message/${notInExclusiveImage}',
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      case rpFullyClaimed:
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image.asset(
              widget.messageRed.rpType == RedPacketType.normalRedPacket
                  ? 'assets/images/red_packet/message/rp_normal_open_cover.png'
                  : widget.messageRed.rpType == RedPacketType.luckyRedPacket
                  ? 'assets/images/red_packet/message/rp_lucky_open_cover.png'
                  : 'assets/images/red_packet/message/rp_specific_open_cover.png',
              width: constraints.maxWidth * 0.9,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.7,
              child: Image.asset(
                'assets/images/red_packet/message/${fullyClaimedImage}',
                fit: BoxFit.contain,
              ),
            ),
          ],
        );

      case rpExpired:
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image.asset(
              widget.messageRed.rpType == RedPacketType.normalRedPacket
                  ? 'assets/images/red_packet/message/rp_normal_open_cover.png'
                  : widget.messageRed.rpType == RedPacketType.luckyRedPacket
                  ? 'assets/images/red_packet/message/rp_lucky_open_cover.png'
                  : 'assets/images/red_packet/message/rp_specific_open_cover.png',
              width: constraints.maxWidth * 0.9,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.7,
              child: Image.asset(
                'assets/images/red_packet/message/${expiredImage}',
                fit: BoxFit.contain,
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
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
