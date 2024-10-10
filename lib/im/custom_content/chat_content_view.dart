import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/home/chat/pages/temp_chat_countdown_bar.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_item_cell.dart';
import 'package:jxim_client/im/custom_content/message_widget/time_item.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/scroll_event_dispatcher.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatContentView extends StatefulWidget {
  final String tag;

  const ChatContentView({super.key, required this.tag});

  @override
  State<ChatContentView> createState() => _ChatContentViewState();
}

class _ChatContentViewState extends State<ChatContentView> {
  final centerKey = GlobalKey();
  late final ChatContentController controller;

  RxMap<String, int> get highlightIndex =>
      controller.chatController.highlightIndex;

  int? unreadIndex;
  FocusNode mainListFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ChatContentController>(tag: widget.tag);
  }

  @override
  Widget build(BuildContext context) {
    return objectMgr.loginMgr.isDesktop
        ? SelectionArea(
            child: _buildListView(context),
          )
        : GestureDetector(
            onTapUp: (_) => controller.chatController.onCancelFocus(),
            child: _buildListView(context),
          );
  }

  Widget _buildListView(BuildContext context) {
    if (controller.chatController.chat.isDisband) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: ShapeDecoration(
            color: const Color(0x51FCFCFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/svgs/disband.svg'),
                  const SizedBox(height: 15),
                  Text(
                    localized(chatThisGroupIsNotAvailable),
                    style: jxTextStyle.textStyleBold16(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        NotificationListener(
          onNotification: (notification) {
            if (notification is ScrollNotification) {
              controller.onScroll(notification);
            }
            if (notification is ScrollEndNotification) {
              if (objectMgr.loginMgr.isDesktop) {
                mainListFocusNode.requestFocus();
              }
            }
            return false;
          },
          child: Focus(
            focusNode: controller.chatController.mainListFocusNode,
            child: CustomScrollView(
              center: centerKey,
              controller: controller.chatController.messageListController,
              reverse: true,
              physics: ScrollEventDispatcher(controller),
              slivers: <Widget>[
                const SliverPadding(
                  padding: EdgeInsets.only(top: 8.0),
                ),
                Obx(() {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        Message message =
                            controller.chatController.nextMessageList[index];
                        return VisibilityDetector(
                          key: ValueKey(message.message_id.toString()),
                          onVisibilityChanged: (info) {
                            double visiblePercentage =
                                info.visibleFraction * 100;
                            if (visiblePercentage > 10) {
                              controller.chatController.visibleFirstMessage =
                                  message;
                              controller.addVisibleMessage(message);
                            }
                            controller.onMessageVisible(message);
                          },
                          child: AutoScrollTag(
                            key: ValueKey(index),
                            index: index,
                            controller:
                                controller.chatController.messageListController,
                            child: Stack(
                              children: [
                                Obx(
                                  () => Positioned.fill(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 50),
                                      color: highlightIndex['list'] == 1 &&
                                              index == highlightIndex['index']
                                          ? colorTextPrimary.withOpacity(
                                              0.2,
                                            )
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                Container(
                                  key: controller.chatController
                                      .getMessageKey(message),
                                  child: MessageItemCell(
                                    index: index,
                                    message: message,
                                    isPrevious: false,
                                    tag: widget.tag,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount:
                          controller.chatController.nextMessageList.length,
                      addRepaintBoundaries: true,
                    ),
                  );
                }),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  key: centerKey,
                ),
                Obx(
                  () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        Message message = controller
                            .chatController.previousMessageList[index];
                        if (message.typ == messageTypeUnreadBar) {
                          unreadIndex = index;
                        }
                        return VisibilityDetector(
                          key: ValueKey(message.message_id.toString()),
                          onVisibilityChanged: (info) {
                            double visiblePercentage =
                                info.visibleFraction * 100;
                            if (visiblePercentage > 10) {
                              controller.chatController.visibleFirstMessage =
                                  message;
                              controller.addVisibleMessage(message);
                            }

                            controller.onMessageVisible(message);
                          },
                          child: AutoScrollTag(
                            key: ValueKey(index),
                            index: index,
                            controller:
                                controller.chatController.messageListController,
                            child: Stack(
                              children: [
                                Obx(
                                  () => Positioned.fill(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 50),
                                      color: highlightIndex['list'] == 0 &&
                                              index == highlightIndex['index']
                                          ? colorTextPrimary.withOpacity(0.2)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    top: controller
                                                    .chatController
                                                    .previousMessageList
                                                    .length -
                                                1 ==
                                            index
                                        ? controller.chatController
                                                .pinMessageList.isNotEmpty
                                            ? 80.0
                                            : 0.0
                                        : 0,
                                  ),
                                  key: controller.chatController
                                      .getMessageKey(message),
                                  child: MessageItemCell(
                                    index: index,
                                    message: message,
                                    isPrevious: true,
                                    tag: widget.tag,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount:
                          controller.chatController.previousMessageList.length,
                      addRepaintBoundaries: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 置顶消息
        Positioned(
          top: -1.0,
          left: 0.0,
          right: 0.0,
          child: Obx(
            () => ClipRect(
              child: Column(
                children: [
                  TempChatCountdownBar(
                    chatController: controller.chatController,
                  ),
                  const ChatPinContainer(
                    isFromHome: false,
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    heightFactor:
                        controller.chatController.pinMessageList.isNotEmpty
                            ? 1.0
                            : 0.0,
                    alignment: Alignment.topCenter,
                    child: IntrinsicHeight(
                      child: Container(
                        color: colorBackground,
                        height: 50,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: controller.onPinMessageTap,
                                child: OverlayEffect(
                                  child: Padding(
                                    padding: objectMgr.loginMgr.isDesktop
                                        ? const EdgeInsets.symmetric(
                                            vertical: 7,
                                            horizontal: 12,
                                          )
                                        : const EdgeInsets.only(
                                            top: 6,
                                            bottom: 6,
                                            right: 12,
                                            left: 12,
                                          ),
                                    child: Row(
                                      children: [
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: themeColor,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          width: 2,
                                          height: double.infinity,
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding:
                                                const EdgeInsets.only(left: 5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Text(
                                                  '${localized(
                                                    pinnedMessage,
                                                  )} ${controller.chatController.pinMessageList.length > 1 ? '#${controller.chatController.pinMessageList.length}' : ''}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        MFontSize.size15.value,
                                                    fontWeight:
                                                        MFontWeight.bold5.value,
                                                    color: themeColor,
                                                    height: 1,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                                if (controller.chatController
                                                    .pinMessageList.isNotEmpty)
                                                  Text(
                                                    _pinnedMsg(
                                                      controller.chatController
                                                          .pinMessageList.first,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: MFontSize
                                                          .size15.value,
                                                      fontWeight: MFontWeight
                                                          .bold4.value,
                                                      color: colorTextSecondary,
                                                      height: 1.1,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Obx(
                                          () {
                                            return Visibility(
                                              visible: controller
                                                          .chatController
                                                          .pinMessageList
                                                          .length >
                                                      1 ||
                                                  controller.chatController
                                                      .pinEnable.value,
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () async {
                                                  controller.chatController
                                                      .isPinnedOpened = true;
                                                  showModalBottomSheet(
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    barrierColor:
                                                        Colors.transparent,
                                                    context: context,
                                                    elevation: 0,
                                                    builder: (
                                                      BuildContext context,
                                                    ) =>
                                                        MultiplePinnedMessagesView(
                                                      tag: widget.tag,
                                                      pinEnable: controller
                                                          .chatController
                                                          .pinEnable
                                                          .value,
                                                    ),
                                                    constraints: BoxConstraints(
                                                      maxHeight:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height -
                                                              kToolbarHeight,
                                                    ),
                                                  ).then(
                                                    (value) {
                                                      controller.chatController
                                                          .playerService
                                                          .stopPlayer();
                                                      controller.chatController
                                                          .playerService
                                                          .resetPlayer();
                                                      controller.chatController
                                                              .isPinnedOpened =
                                                          false;
                                                    },
                                                  );
                                                },
                                                child: OpacityEffect(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      5.0,
                                                    ),
                                                    child: SvgPicture.asset(
                                                      'assets/svgs/chat_room_pin_icon.svg',
                                                      width: 20,
                                                      height: 20,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                        themeColor,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
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
                  // Show audio panel
                  if (!controller.chatController.chat.isDisband &&
                      !controller.chatController.chat.isKick &&
                      controller.chatController.chat.isGroup)
                    getChatControllerWidget(context),
                ],
              ),
            ),
          ),
        ),

        /// 顶部时间
        Obx(
          () => Positioned(
            left: 0.0,
            right: 0.0,
            top: controller.chatController.pinMessageList.isNotEmpty
                ? 60.0
                : 10.0,
            child: AnimatedOpacity(
              curve: Curves.easeInOut,
              opacity: controller.chatController.isShowDay.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TimeItem(
                createTime: controller.chatController.currMsgDayDisplay.value,
                showDay: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _pinnedMsg(Message msg) {
    if (msg.isEncrypted) {
      Chat? chat = objectMgr.chatMgr.getChatById(msg.chat_id);
      if (chat != null) {
        MessageMgr.decodeMsg(msg, chat, objectMgr.userMgr.mainUser.uid);
      }
      if (msg.isEncrypted) {
        return localized(messageEncrypted);
      }
    }

    switch (msg.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        var textData = msg.decodeContent(cl: MessageText.creator);

        Iterable<RegExpMatch> mentionMatches =
            Regular.extractSpecialMention(textData.text);

        if (mentionMatches.isNotEmpty) {
          List<MentionModel> mentionList = <MentionModel>[];

          if (msg.atUser.isNotEmpty) {
            mentionList.addAll(msg.atUser);
          } else if (msg.getValue('at_users', '').isNotEmpty &&
              msg.getValue('at_users') is String) {
            final atUser = jsonDecode(msg.getValue('at_users'));
            if (notBlank(atUser) && atUser is List) {
              mentionList.addAll(
                atUser
                    .map<MentionModel>((e) => MentionModel.fromJson(e))
                    .toList(),
              );
            }
          }

          String copiedText = textData.text;
          for (int i = mentionMatches.length - 1; i >= 0; i--) {
            final match = mentionMatches.toList()[i];
            String uidStr =
                Regular.extractDigit(match.group(0) ?? '')?.group(0) ?? '';

            if (uidStr.isEmpty) continue;

            int uid = int.parse(uidStr);

            String name = objectMgr.userMgr
                .getUserTitle(objectMgr.userMgr.getUserById(uid));

            final MentionModel? model = mentionList.firstWhereOrNull(
              (
                mention,
              ) =>
                  mention.userId == uid,
            );

            if (name.isEmpty) {
              if (model == null) {
                name = uidStr;
              } else {
                name = model.userName;
              }
            } else {
              if (model != null) {
                if (model.role.value == Role.all.value) {
                  name = localized(mentionAll);
                }
              }
            }

            copiedText =
                copiedText.replaceRange(match.start, match.end, '@$name');
          }
          return copiedText;
        }

        return textData.text;
      case messageTypeImage:
        return localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return localized(replyVideo);
      case messageTypeVoice:
        return localized(replyVoice);
      case messageTypeFile:
        return localized(chatTagFile);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);
      case messageTypeNewAlbum:
        return localized(chatTagAlbum);
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeNote:
        var textData = msg.decodeContent(cl: MessageFavourite.creator);
        return "[${localized(noteEditTitle)}] ${textData.title}";
      case messageTypeChatHistory:
        var textData = msg.decodeContent(cl: MessageFavourite.creator);
        return "[${localized(chatHistory)}] ${textData.title}";
      default:
        return '';
    }
  }
}

class MultiplePinnedMessagesView extends GetView<ChatContentController> {
  final bool pinEnable;
  @override
  final String tag;

  const MultiplePinnedMessagesView({
    super.key,
    required this.tag,
    this.pinEnable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? 12 : 0,
        ),
        decoration: const BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - kToolbarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: colorBorder,
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: OpacityEffect(
                        child: Text(
                          localized(buttonBack),
                          style: jxTextStyle.textStyle16(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        '${controller.chatController.pinMessageList.length} ${localized(pinnedMessage)}',
                        style: jxTextStyle.textStyleBold16(),
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: CustomScrollView(
                controller: controller.pinnedMessageScrollController,
                physics: const BouncingScrollPhysics(),
                reverse: true,
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.all(16).w,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          Message message =
                              controller.chatController.pinMessageList[index];
                          return AutoScrollTag(
                            key: ValueKey(index),
                            index: index,
                            controller:
                                controller.pinnedMessageScrollController,
                            child: MessageItemCell(
                              index: index,
                              message: message,
                              isPinOpen: true,
                              tag: tag,
                            ),
                          );
                        },
                        childCount:
                            controller.chatController.pinMessageList.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Bar
            if (controller.chatController.pinMessageList.isNotEmpty &&
                pinEnable)
              GestureDetector(
                onTap: () => controller.unPinAllMessages(context),
                child: OpacityEffect(
                  child: Container(
                    height: kToolbarHeight,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 1,
                          color: colorBorder,
                        ),
                      ),
                    ),
                    child: Text(
                      localized(unpinAllMessage),
                      style: jxTextStyle.textStyleBold16(color: themeColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
