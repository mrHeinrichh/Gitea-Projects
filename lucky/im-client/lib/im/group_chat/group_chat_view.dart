import 'dart:io';

import 'package:agora/agora_plugin.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_view.dart';
import 'package:jxim_client/im/custom_input/component/mention_view.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/message/component/custom_angle.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/desktop/detail_chat_view.dart';
import 'package:jxim_client/redefine_functions.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/im/custom_content/chat_scroll_to_bottom.dart';
import 'package:jxim_client/im/custom_content/chat_wall_paper.dart';
import 'package:im/widget/toast_widget.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jxim_client/im/custom_input/text_input_field_factory.dart';
import 'package:jxim_client/im/group_chat/game_group_chat_view.dart';

class GroupChatView extends GameGroupChatView {
  final String tag;
  late final GroupChatController controller;
  late final CustomInputController inputTextController;

  GroupChatView({Key? key, required this.tag}) : super(key: key) {
    controller = Get.find<GroupChatController>(tag: tag);
    inputTextController = Get.find<CustomInputController>(tag: tag);
    //定義開始語音通話時螢幕恆亮
    audioManager.startChatRoom = () {
      WakelockPlus.enable();
      controller.onAudioRoomIsJoined();
    };
    //定義結束語音通話時螢幕不用恆亮
    audioManager.stopChatRoom = () {
      WakelockPlus.disable();
      controller.onAudioRoomIsJoined();
    };
    RedefineFunctions.initGroupChatView(controller,tag);
  }

  //檢查當前有無開啟語音群聊
  checkJoinAudioRoom(BuildContext context) {
    if (agoraHelper.isJoinAudioRoom) {
      agoraHelper.gameManagerGetCheckCloseDialog(context, action: () async {
        await Future.delayed(const Duration(milliseconds: 100));
        Get.back();
      });
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    if (!isDesktop) {
      return Obx(() => WillPopScope(
        onWillPop: controller.isJoinAudioRoom.value
            ? () async {
          agoraHelper.gameManagerGetCheckCloseDialog(context,
              action: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                Get.back();
              });
          return false;
        }
        : (controller.chooseMessage.values.isNotEmpty)
            ? () async {
          if (controller.chooseMessage.values.isNotEmpty) {
            controller.onChooseMoreCancel();
            return false;
          } else {
            return true;
          }
        }
            : Platform.isAndroid
            ? () => Future.value(true)
            : null,
        child: ProviderScope(
          child: GetBuilder<GroupChatController>(
            init: controller,
            tag: tag,
            builder: (_) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: isDesktop
                    ? null
                    : PreferredSize(
                  preferredSize: Size.fromHeight(44.w),
                  child: PrimaryAppBar(
                    titleSpacing: 0,
                    isBackButton: false,
                    titleWidget: Row(
                      children: [
                        /// 選取多項模式的頂部條-全部刪除
                        Obx(() {
                          bool hasSelect = controller
                              .chooseMessage.values.isNotEmpty;
                          return Visibility(
                            visible:
                            controller.chooseMore.value,
                            child: OpacityEffect(
                              child: Container(
                                width: 100.w,
                                padding:
                                EdgeInsets.only(left: 10.w),
                                child: GestureDetector(
                                  onTap: controller
                                      .onClearChooseMessage,
                                  child: Text(
                                    localized(deselect),
                                    style:
                                    jxTextStyle.textStyle17(
                                      color: hasSelect
                                          ? accentColor
                                          : const Color(
                                          0x7a121212),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                          /// 返回
                          Obx(
                            () => !controller.isSearching.value &&
                                    !controller.chooseMore.value
                                ? SizedBox(
                                    width: 80,
                                    child: CustomLeadingIcon(
                                      badgeView: Obx(
                                        () {
                                          int otherChatTotal = objectMgr.chatMgr
                                                  .totalUnreadCount.value -
                                              (controller.chat.isMute
                                                  ? 0
                                                  : controller
                                                      .chat.unread_count);
                                          if (otherChatTotal == 0) {
                                            return Text(
                                              localized(buttonBack),
                                              style: jxTextStyle.textStyle17(
                                                  color: accentColor),
                                            );
                                          } else {
                                            return CustomAngle(
                                              bgColor: accentColor,
                                              height: 20.w,
                                              value: otherChatTotal,
                                            );
                                          }
                                        },
                                      ),
                                      buttonOnPressed: () {
                                        //檢查當前有無開啟語音群聊
                                        checkJoinAudioRoom(context);
                                      },
                                    ),
                                  )
                                : const SizedBox(),
                          ),

                        Expanded(
                          child: Obx(
                                () => controller.isSearching.value
                                ? Container(
                              padding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                bottom: 8.w,
                              ),
                              child: SearchingAppBar(
                                onTap: () => controller
                                    .isSearching(true),
                                onChanged: (value) {
                                  controller.searchParam
                                      .value = value;
                                  controller
                                      .getIndexList();
                                },
                                onCancelTap: () {
                                  controller
                                      .searchFocusNode
                                      .unfocus();
                                  controller
                                      .clearSearching();
                                },
                                isSearchingMode:
                                controller.isSearching
                                    .value,
                                isAutoFocus: true,
                                focusNode: controller
                                    .searchFocusNode,
                                controller: controller
                                    .searchController,
                                suffixIcon: Visibility(
                                  visible: controller
                                      .searchParam
                                      .value
                                      .isNotEmpty,
                                  child: GestureDetector(
                                    onTap: () {
                                      controller
                                          .searchController
                                          .clear();
                                      controller
                                          .searchParam
                                          .value = '';
                                      controller
                                          .getIndexList();
                                    },
                                    child: Padding(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                          vertical:
                                          8.0),
                                      child: SvgPicture
                                          .asset(
                                        'assets/svgs/close_round_icon.svg',
                                        color: JXColors.black48,
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )

                                  /// 選取多項模式的頂部條-選擇了幾了
                                  : controller.chooseMore.value
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              localized('selectedWithParam',
                                                  params: [
                                                    '${controller.chooseMessage.values.toList().length}'
                                                  ]),
                                              style:
                                                  jxTextStyle.textStyleBold17(),
                                            )
                                          ],
                                        )
                                      : GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () =>
                                              controller.onEnterChatInfo(
                                            false,
                                            controller.chat,
                                            controller.chat.chat_id,
                                          ),
                                          child: OpacityEffect(
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Flexible(
                                                          child: NicknameText(
                                                            uid: controller
                                                                .chat.chat_id,
                                                            isGroup: controller
                                                                .chat.isGroup,
                                                            displayName: notBlank(
                                                                    controller
                                                                        .chat
                                                                        .name)
                                                                ? controller
                                                                    .chat.name
                                                                : '',
                                                            fontSize: MFontSize
                                                                .size17.value,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontWeight: Platform
                                                                    .isAndroid
                                                                ? FontWeight
                                                                    .w500
                                                                : FontWeight
                                                                    .w600,
                                                            isTappable: false,
                                                          ),
                                                        ),
                                                        if (controller
                                                            .isMute.value)
                                                          SvgPicture.asset(
                                                            'assets/svgs/mute_icon3.svg',
                                                            width: 20.23.w,
                                                            height: 20.w,
                                                            fit: BoxFit.fill,
                                                          ),
                                                      ],
                                                    )),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                controller.chat.isValid
                                                    ? Obx(
                                                        () {
                                                          //設置語音的成員名單
                                                          audioManager
                                                              .setMemberList(
                                                                  controller
                                                                      .groupMembers);
                                                          if (ChatTypingTask
                                                                          .whoIsTyping[
                                                                      controller
                                                                          .chat
                                                                          .id] !=
                                                                  null &&
                                                              ChatTypingTask
                                                                  .whoIsTyping[
                                                                      controller
                                                                          .chat
                                                                          .id]!
                                                                  .isNotEmpty) {
                                                            return whoIsTypingWidget(
                                                              ChatTypingTask
                                                                      .whoIsTyping[
                                                                  controller
                                                                      .chat
                                                                      .id]!,
                                                              jxTextStyle
                                                                  .textStyle12(
                                                                      color: JXColors
                                                                          .secondaryTextBlack)
                                                                  .copyWith(
                                                                      height:
                                                                          1),
                                                            );
                                                          }
                                                          return Text(
                                                            UserUtils.groupMembersLengthInfo(
                                                                controller
                                                                    .groupMembers
                                                                    .length),
                                                            style: jxTextStyle
                                                                .textStyleGroupMemberCount(
                                                                    color: JXColors
                                                                        .secondaryTextBlack),
                                                          );
                                                        },
                                                      )
                                                    : const SizedBox()
                                              ],
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                        ],
                      ),
                      trailing: [
                        /// 選取多項模式的頂部條-取消
                        Obx(() => Visibility(
                              visible: controller.chooseMore.value,
                              child: Container(
                                width: 100.w,
                                padding: EdgeInsets.only(right: 10.w),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: controller.onChooseMoreCancel,
                                    child: Text(
                                      localized(buttonCancel),
                                      style: jxTextStyle.textStyle17(
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )),
                        Obx(() => Visibility(
                              visible: !controller.isSearching.value &&
                                  !controller.chooseMore.value,
                              child: GestureDetector(
                                onTap: () => controller.onEnterChatInfo(
                                  false,
                                  controller.chat,
                                  controller.chat.chat_id,
                                ),
                                child: SizedBox(
                                  width: 80,
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            12, 3, 8, 3),
                                        child: OpacityEffect(
                                          child: CustomAvatar(
                                            uid: controller.chat.chat_id,
                                            size: jxDimension
                                                .chatRoomAvatarSize(),
                                            isGroup: true,
                                            headMin: Config().headMin,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    )),
                    body: Column(
                      children: [
                        Container(
                          color: JXColors.borderPrimaryColor,
                          height: 0.33,
                        ),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              RepaintBoundary(child: chatWallPaper),
                              Column(
                                children: [
                                  // getChatControllerWidget(context),

                              /// 消息列表
                              Expanded(
                                child: AnimatedSize(
                                  curve: Curves.easeInOutCubic,
                                  duration: const Duration(milliseconds: 200),
                                  child: Stack(
                                    children: [
                                      ChatContentView(tag: tag),

                                      ChatScrollToBottom(
                                        controller: controller,
                                        gameIcon: getGameIcon(context),
                                      ),
                                      // Obx(
                                      //   () => Visibility(
                                      //     visible:
                                      //         controller.isVideoRecording.value,
                                      //     child: CameraRecordScreen(tag: tag),
                                      //   ),
                                      // ),
                                      Obx(
                                            () => controller.showMentionList.value
                                            ? Align(
                                          alignment:
                                          Alignment.bottomCenter,
                                          child: MentionView(
                                            groupMembers:
                                            controller.groupMembers,
                                            chat: controller.chat,
                                          ),
                                        )
                                            : const SizedBox(),
                                      ),
                                      const Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: ToastWidget(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextInputFieldFactory.createCustomInputViewComponent(
                                key: ValueKey(tag.toString()),
                                tag: tag,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ));
    }

    return Obx(
      () => DropTarget(
        onDragDone: (value) async {
          await controller.dropDesktopFile(value, context);
        },
        onDragEntered: (value) {
          controller.onHover.value = true;
          controller.checkFileType(value.files);
        },
        onDragExited: (_) => controller.onHover(false),
        child: Stack(
          children: [
            Obx(() => WillPopScope(
                  onWillPop: controller.isJoinAudioRoom.value
                      ? () async {
                          agoraHelper.gameManagerGetCheckCloseDialog(context,
                              action: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            Get.back();
                          });
                          return false;
                        }
                      : Platform.isAndroid
                          ? () => Future.value(true)
                          : null,
                  child: GetBuilder<GroupChatController>(
                    init: controller,
                    tag: tag,
                    builder: (_) {
                      return KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event.logicalKey == LogicalKeyboardKey.escape) {
                            if (controller.isSearching.value) {
                              controller.isSearching.value = false;
                              controller.searchController.clear();
                            } else {
                              Get.back(id: 1);
                              Get.find<ChatListController>()
                                  .desktopSelectedChatID
                                  .value = 01010;
                            }
                          }
                        },
                        child: Scaffold(
                          resizeToAvoidBottomInset: false,
                          appBar: isDesktop
                              ? null
                              : PreferredSize(
                                  preferredSize: Size.fromHeight(52.w),
                                  child: PrimaryAppBar(
                                    titleSpacing: 0,
                                    isBackButton: false,
                                    titleWidget: Row(
                                      children: [
                                        /// 選取多項模式的頂部條-全部刪除
                                        Obx(() {
                                          bool hasSelect = controller
                                              .chooseMessage.values.isNotEmpty;
                                          return Visibility(
                                            visible:
                                                controller.chooseMore.value,
                                            child: OpacityEffect(
                                              child: Container(
                                                width: 100.w,
                                                padding:
                                                    EdgeInsets.only(left: 10.w),
                                                child: GestureDetector(
                                                  onTap: controller
                                                      .onClearChooseMessage,
                                                  child: Text(
                                                    localized(deleteAll),
                                                    style:
                                                        jxTextStyle.textStyle17(
                                                      color: hasSelect
                                                          ? accentColor
                                                          : const Color(
                                                              0x7a121212),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),

                              /// 返回
                              Obx(
                                    () => !controller.isSearching.value &&
                                    !controller.chooseMore.value
                                    ? SizedBox(
                                  width: 80,
                                  child: CustomLeadingIcon(
                                    badgeView: Obx(
                                          () {
                                        int otherChatTotal = objectMgr
                                            .chatMgr
                                            .totalUnreadCount
                                            .value -
                                            (controller
                                                .chat.isMute
                                                ? 0
                                                : controller
                                                .chat
                                                .unread_count);
                                        if (otherChatTotal ==
                                            0) {
                                          return Text(
                                            localized(
                                                buttonBack),
                                            style: TextStyle(
                                              fontSize:
                                              MFontSize
                                                  .size17
                                                  .value,
                                              fontWeight:
                                              FontWeight
                                                  .w400,
                                              color:
                                              accentColor,
                                              height: 1.2,
                                            ),
                                          );
                                        } else {
                                          return CustomAngle(
                                            bgColor:
                                            accentColor,
                                            height: 20.w,
                                            value:
                                            otherChatTotal,
                                          );
                                        }
                                      },
                                    ),
                                    buttonOnPressed: () {
                                      //檢查當前有無開啟語音群聊
                                      checkJoinAudioRoom(
                                          context);
                                    },
                                  ),
                                )
                                    : const SizedBox(),
                              ),

                              Expanded(
                                child: Obx(
                                      () => controller.isSearching.value
                                      ? Container(
                                    padding: EdgeInsets.only(
                                      left: 16.w,
                                      right: 16.w,
                                      bottom: 8.w,
                                    ),
                                    child: SearchingAppBar(
                                      onTap: () => controller
                                          .isSearching(true),
                                      onChanged: (value) {
                                        controller.searchParam
                                            .value = value;
                                        controller
                                            .getIndexList();
                                      },
                                      onCancelTap: () {
                                        controller
                                            .searchFocusNode
                                            .unfocus();
                                        controller
                                            .clearSearching();
                                      },
                                      isSearchingMode:
                                      controller.isSearching
                                          .value,
                                      isAutoFocus: true,
                                      focusNode: controller
                                          .searchFocusNode,
                                      controller: controller
                                          .searchController,
                                      suffixIcon: Visibility(
                                        visible: controller
                                            .searchParam
                                            .value
                                            .isNotEmpty,
                                        child: GestureDetector(
                                          onTap: () {
                                            controller
                                                .searchController
                                                .clear();
                                            controller
                                                .searchParam
                                                .value = '';
                                            controller
                                                .getIndexList();
                                          },
                                          child: Padding(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                vertical:
                                                8.0),
                                            child: SvgPicture
                                                .asset(
                                              'assets/svgs/close_round_icon.svg',
                                              width: 20,
                                              height: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )

                                                /// 選取多項模式的頂部條-選擇了幾了
                                                : controller.chooseMore.value
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            localized(
                                                                'selectedWithParam',
                                                                params: [
                                                                  '${controller.chooseMessage.values.toList().length}'
                                                                ]),
                                                            style: jxTextStyle
                                                                .textStyleBold17(),
                                                          )
                                                        ],
                                                      )
                                                    : GestureDetector(
                                                        onTap: () => controller
                                                            .onEnterChatInfo(
                                                          false,
                                                          controller.chat,
                                                          controller
                                                              .chat.chat_id,
                                                        ),
                                                        child: Column(
                                                          children: <Widget>[
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                    child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Flexible(
                                                                      child:
                                                                          NicknameText(
                                                                        uid: controller
                                                                            .chat
                                                                            .chat_id,
                                                                        isGroup: controller
                                                                            .chat
                                                                            .isGroup,
                                                                        displayName: notBlank(controller.chat.name)
                                                                            ? controller.chat.name
                                                                            : '',
                                                                        fontSize: MFontSize
                                                                            .size17
                                                                            .value,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        fontWeight: MFontWeight
                                                                            .bold6
                                                                            .value,
                                                                        isTappable:
                                                                            false,
                                                                        fontLineHeight:
                                                                            1.1,
                                                                      ),
                                                                    ),
                                                                    if (controller
                                                                        .isMute
                                                                        .value)
                                                                      SvgPicture
                                                                          .asset(
                                                                        'assets/svgs/mute_icon3.svg',
                                                                        width:
                                                                            20.23.w,
                                                                        height:
                                                                            20.w,
                                                                        fit: BoxFit
                                                                            .fill,
                                                                      ),
                                                                  ],
                                                                )),
                                                              ],
                                                            ),
                                                            controller.chat
                                                                    .isValid
                                                                ? Obx(
                                                                    () {
                                                                      //設置語音的成員名單
                                                                      audioManager
                                                                          .setMemberList(
                                                                              controller.groupMembers);
                                                                      if (ChatTypingTask.whoIsTyping[controller.chat.id] !=
                                                                              null &&
                                                                          ChatTypingTask
                                                                              .whoIsTyping[controller.chat.id]!
                                                                              .isNotEmpty) {
                                                                        return whoIsTypingWidget(
                                                                          ChatTypingTask.whoIsTyping[controller
                                                                              .chat
                                                                              .id]!,
                                                                          jxTextStyle.textStyle14(
                                                                              color: JXColors.secondaryTextBlack),
                                                                        );
                                                                      }
                                                                      return Text(
                                                                        UserUtils.groupMembersLengthInfo(controller
                                                                            .groupMembers
                                                                            .length),
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize: MFontSize
                                                                              .size14
                                                                              .value,
                                                                          fontWeight: MFontWeight
                                                                              .bold5
                                                                              .value,
                                                                          fontFamily:
                                                                              appFontfamily,
                                                                          color:
                                                                              JXColors.secondaryTextBlack,
                                                                          height:
                                                                              1.2,
                                                                        ),
                                                                      );
                                                                    },
                                                                  )
                                                                : const SizedBox()
                                                          ],
                                                        ),
                                                      ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: [
                                      /// 選取多項模式的頂部條-取消
                                      Obx(() => Visibility(
                                            visible:
                                                controller.chooseMore.value,
                                            child: Container(
                                              width: 100.w,
                                              padding:
                                                  EdgeInsets.only(right: 10.w),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: GestureDetector(
                                                  onTap: controller
                                                      .onChooseMoreCancel,
                                                  child: Text(
                                                    localized(buttonCancel),
                                                    style:
                                                        jxTextStyle.textStyle17(
                                                      color: Theme.of(context)
                                                          .iconTheme
                                                          .color,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )),
                                      Obx(() => Visibility(
                                            visible: !controller
                                                    .isSearching.value &&
                                                !controller.chooseMore.value,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  controller.onEnterChatInfo(
                                                false,
                                                controller.chat,
                                                controller.chat.chat_id,
                                              ),
                                              child: SizedBox(
                                                width: 80,
                                                child: Row(
                                                  children: [
                                                    const Spacer(),
                                                    Container(
                                                      margin: const EdgeInsets
                                                              .fromLTRB(
                                                              12, 7, 8, 3)
                                                          .w,
                                                      child: CustomAvatar(
                                                        uid: controller
                                                            .chat.chat_id,
                                                        size: 38,
                                                        isGroup: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                          body: Column(
                            children: [
                              Container(
                                color: JXColors.borderPrimaryColor,
                                height: 0.33,
                              ),
                              if (isDesktop)
                                Container(
                                  height: 52,
                                  color: backgroundColor,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Obx(() => Visibility(
                                            visible: !controller
                                                    .isSearching.value &&
                                                !controller.chooseMore.value,
                                            child: OpacityEffect(
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () => controller
                                                      .onEnterChatInfo(
                                                    false,
                                                    controller.chat,
                                                    controller.chat.chat_id,
                                                  ),
                                                  child: SizedBox(
                                                    width: 70,
                                                    child: Row(
                                                      children: [
                                                        const Spacer(),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 16,
                                                                  right: 12),
                                                          child: CustomAvatar(
                                                            uid: controller
                                                                .chat.chat_id,
                                                            size: 38,
                                                            isGroup: true,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )),
                                      Expanded(
                                        child: Obx(
                                          () => controller.isSearching.value
                                              ? Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: SearchingAppBar(
                                                    tag: tag.toString(),
                                                    onTap: () => controller
                                                        .isSearching(true),
                                                    onChanged: (value) {
                                                      controller.searchParam
                                                          .value = value;
                                                      controller.getIndexList();
                                                    },
                                                    onCancelTap: () {
                                                      controller.searchFocusNode
                                                          .unfocus();
                                                      controller
                                                          .clearSearching();
                                                    },
                                                    isSearchingMode: controller
                                                        .isSearching.value,
                                                    isAutoFocus: true,
                                                    focusNode: controller
                                                        .searchFocusNode,
                                                    controller: controller
                                                        .searchController,
                                                    suffixIcon: Visibility(
                                                      visible: controller
                                                          .searchParam
                                                          .value
                                                          .isNotEmpty,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          controller
                                                              .searchController
                                                              .clear();
                                                          controller.searchParam
                                                              .value = '';
                                                          controller
                                                              .getIndexList();
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      8.0),
                                                          child:
                                                              SvgPicture.asset(
                                                            'assets/svgs/close_round_icon.svg',
                                                            width: 20,
                                                            height: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )

                                              /// 選取多項模式的頂部條-選擇了幾了
                                              : controller.chooseMore.value
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          localized(
                                                              'selectedWithParam',
                                                              params: [
                                                                '${controller.chooseMessage.values.toList().length}'
                                                              ]),
                                                          style: jxTextStyle
                                                              .textStyleBold17(),
                                                        )
                                                      ],
                                                    )
                                                  : OpacityEffect(
                                                      child: MouseRegion(
                                                        cursor:
                                                            SystemMouseCursors
                                                                .click,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            controller
                                                                .onEnterChatInfo(
                                                              false,
                                                              controller.chat,
                                                              controller
                                                                  .chat.chat_id,
                                                            );
                                                          },
                                                          behavior:
                                                              HitTestBehavior
                                                                  .translucent,
                                                          child: Column(
                                                            mainAxisAlignment: objectMgr
                                                                    .loginMgr
                                                                    .isDesktop
                                                                ? MainAxisAlignment
                                                                    .center
                                                                : MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment: objectMgr
                                                                    .loginMgr
                                                                    .isDesktop
                                                                ? CrossAxisAlignment
                                                                    .start
                                                                : CrossAxisAlignment
                                                                    .center,
                                                            children: <Widget>[
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                      child:
                                                                          Row(
                                                                    mainAxisAlignment: objectMgr
                                                                            .loginMgr
                                                                            .isDesktop
                                                                        ? MainAxisAlignment
                                                                            .start
                                                                        : MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Flexible(
                                                                        child:
                                                                            NicknameText(
                                                                          uid: controller
                                                                              .chat
                                                                              .chat_id,
                                                                          isGroup: controller
                                                                              .chat
                                                                              .isGroup,
                                                                          displayName: notBlank(controller.chat.name)
                                                                              ? controller.chat.name
                                                                              : '',
                                                                          fontSize: objectMgr.loginMgr.isDesktop
                                                                              ? MFontSize.size14.value
                                                                              : MFontSize.size17.value,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          fontSpace: objectMgr.loginMgr.isDesktop
                                                                              ? 0.25
                                                                              : 0.15,
                                                                          fontWeight: MFontWeight
                                                                              .bold6
                                                                              .value,
                                                                          isTappable:
                                                                              false,
                                                                        ),
                                                                      ),
                                                                      if (controller
                                                                          .isMute
                                                                          .value)
                                                                        SvgPicture
                                                                            .asset(
                                                                          'assets/svgs/mute_icon3.svg',
                                                                          width: objectMgr.loginMgr.isDesktop
                                                                              ? 20
                                                                              : 20.23.w,
                                                                          height: objectMgr.loginMgr.isDesktop
                                                                              ? 20
                                                                              : 20.w,
                                                                          fit: BoxFit
                                                                              .fill,
                                                                        ),
                                                                    ],
                                                                  )),
                                                                ],
                                                              ),
                                                              controller.chat
                                                                      .isValid
                                                                  ? Obx(
                                                                      () {
                                                                        //設置語音的成員名單
                                                                        audioManager
                                                                            .setMemberList(controller.groupMembers);
                                                                        if (ChatTypingTask.whoIsTyping[controller.chat.id] !=
                                                                                null &&
                                                                            ChatTypingTask.whoIsTyping[controller.chat.id]!.isNotEmpty) {
                                                                          return whoIsTypingWidget(
                                                                            ChatTypingTask.whoIsTyping[controller.chat.id]!,
                                                                            jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
                                                                            mainAlignment:
                                                                                MainAxisAlignment.start,
                                                                          );
                                                                        }
                                                                        return Text(
                                                                          UserUtils.groupMembersLengthInfo(controller
                                                                              .groupMembers
                                                                              .length),
                                                                          style:
                                                                              jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
                                                                        );
                                                                      },
                                                                    )
                                                                  : const SizedBox()
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                        ),
                                      ),
                                      Obx(
                                        () => Visibility(
                                          visible:
                                              !controller.isSearching.value,
                                          child: OpacityEffect(
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: controller
                                                    .onTapSearchDesktop,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    child: SvgPicture.asset(
                                                      'assets/svgs/desktop_search.svg',
                                                      width: 24,
                                                      height: 24,
                                                      fit: BoxFit.fill,
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
                                ),
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    if (!objectMgr.loginMgr.isDesktop)
                                      RepaintBoundary(child: chatWallPaper),
                                    Container(
                                      decoration: objectMgr.loginMgr.isDesktop
                                          ? const BoxDecoration(
                                              color:
                                                  JXColors.desktopChatBgColor,
                                              image: DecorationImage(
                                                image: AssetImage(
                                                  "assets/images/chat_bg.png",
                                                ),
                                                fit: BoxFit.none,
                                                opacity: 0.8,
                                                repeat: ImageRepeat.repeat,
                                              ),
                                            )
                                          : null,
                                      child: Column(
                                        children: [
                                          // getChatControllerWidget(context),

                                      /// 消息列表
                                      Expanded(
                                        child: AnimatedSize(
                                          curve: Curves.easeInOutCubic,
                                          duration: const Duration(
                                              milliseconds: 200),
                                          child: Stack(
                                            children: [
                                              ChatContentView(tag: tag),
                                              ChatScrollToBottom(
                                                  controller: controller),
                                              // Obx(
                                              //   () => Visibility(
                                              //     visible:
                                              //         controller.isVideoRecording.value,
                                              //     child: CameraRecordScreen(tag: tag),
                                              //   ),
                                              // ),
                                              Obx(
                                                    () => controller
                                                    .showMentionList
                                                    .value
                                                    ? Align(
                                                  alignment: Alignment
                                                      .bottomCenter,
                                                  child: MentionView(
                                                    groupMembers:
                                                    controller
                                                        .groupMembers,
                                                    chat: controller
                                                        .chat,
                                                  ),
                                                )
                                                    : const SizedBox(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TextInputFieldFactory.createCustomInputViewComponent(
                                        key: ValueKey(tag.toString()),
                                        tag: tag,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )),
            Visibility(
              visible: controller.onHover.value,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 75,
                  bottom: 65,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    controller.allImage || controller.allVideo
                        ? DropZoneContainer(
                      fileType: FileType.document,
                      globalKey: controller.upperDropAreaKey,
                    )
                        : const Spacer(),
                    Visibility(
                      visible: controller.allVideo || controller.allImage,
                      child: const SizedBox(
                        height: 10,
                      ),
                    ),
                    DropZoneContainer(
                      fileType: controller.allVideo
                          ? FileType.video
                          : controller.allImage
                          ? FileType.image
                          : FileType.document,
                      globalKey: controller.lowerDropAreaKey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget whoIsTypingWidget(List<ChatInput> whoIsTyping, TextStyle style,
    {MainAxisAlignment mainAlignment = MainAxisAlignment.center}) {
  if (whoIsTyping.isEmpty) return const SizedBox();
  var names = whoIsTyping.first.username + "${localized(chatTyping)}";
  if (whoIsTyping.length > 2) {
    names += ' ${localized(shareAnd)} 其他${whoIsTyping.length - 1}位';
  } else if (whoIsTyping.length == 2) {
    names = whoIsTyping[0].username +
        " ${localized(shareAnd)} " +
        whoIsTyping[1].username +
        "${localized(chatTyping)}";
  }
  return Row(
    mainAxisAlignment: mainAlignment,
    children: [
      SizedBox(
        width: 30,
        child: DotLoadingView(
          size: 8,
          dotColor: style.color ?? Colors.white,
        ),
      ),
      Flexible(
        child: Text(
          names,
          style: style,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      )
    ],
  );
}
