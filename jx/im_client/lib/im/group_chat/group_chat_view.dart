import 'dart:io';

import 'package:agora/agora_plugin.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/desktop/detail_chat_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/im/custom_content/chat_content_view.dart';
import 'package:jxim_client/im/custom_content/chat_scroll_to_bottom.dart';
import 'package:jxim_client/im/custom_content/chat_wall_paper.dart';
import 'package:jxim_client/im/custom_input/component/mention_view.dart';
import 'package:jxim_client/im/custom_input/component/shortcut_image_widget.dart';
import 'package:jxim_client/im/custom_input/v2/custom_input_view2.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/group_chat/list_mode_view.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/wake_lock_utils.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';

class GroupChatView extends StatelessWidget {
  final String tag;
  late final GroupChatController controller;

  GroupChatView({super.key, required this.tag}) {
    controller = Get.find<GroupChatController>(tag: tag);
    //定義開始語音通話時螢幕恆亮
    audioManager.startChatRoom = () {
      WakeLockUtils.enable();
      controller.onAudioRoomIsJoined();
    };
    //定義結束語音通話時螢幕不用恆亮
    audioManager.stopChatRoom = () {
      WakeLockUtils.disable();
      controller.onAudioRoomIsJoined();
    };
  }

  //檢查當前有無開啟語音群聊
  void _checkJoinAudioRoom(BuildContext context) {
    if (agoraHelper.isJoinAudioRoom) {
      agoraHelper.gameManagerGetCheckCloseDialog(
        context,
        action: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          Get.back();
        },
      );
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    if (!isDesktop) {
      return Obx(
        () => WillPopScope(
          onWillPop: controller.isJoinAudioRoom.value
              ? () async {
                  agoraHelper.gameManagerGetCheckCloseDialog(
                    context,
                    action: () async {
                      await Future.delayed(const Duration(milliseconds: 100));
                      Get.back();
                    },
                  );
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
          child: GetBuilder<GroupChatController>(
            init: controller,
            tag: tag,
            builder: (_) {
              return Obx(
                () => Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: AnimatedPadding(
                    padding: EdgeInsets.only(top: controller.downOffset.value),
                    duration: const Duration(milliseconds: 100),
                    child: Column(
                      children: [
                        PrimaryAppBar(
                          titleSpacing: 0,
                          isBackButton: false,
                          height: controller.isSearching.value ? 52 : 44,
                          titleWidget: Row(
                            children: [
                              /// 選取多項模式的頂部條-全部刪除
                              Obx(() {
                                bool hasSelect =
                                    controller.chooseMessage.values.isNotEmpty;
                                return Visibility(
                                  visible: controller.chooseMore.value,
                                  child: OpacityEffect(
                                    child: Container(
                                      width: 100.w,
                                      padding: EdgeInsets.only(left: 10.w),
                                      child: GestureDetector(
                                        onTap: controller.onClearChooseMessage,
                                        child: Text(
                                          localized(deselect),
                                          style: jxTextStyle.textStyle17(
                                            color: hasSelect
                                                ? themeColor
                                                : const Color(0x7a121212),
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
                                                  (controller.chat.isMute
                                                      ? 0
                                                      : controller
                                                          .chat.unread_count);
                                              if (otherChatTotal == 0) {
                                                return Text(
                                                  localized(buttonBack),
                                                  style: jxTextStyle.headerText(
                                                    color: themeColor,
                                                  ),
                                                );
                                              } else {
                                                return Container(
                                                  height: 20,
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  alignment: Alignment.center,
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 20),
                                                  decoration: BoxDecoration(
                                                    color: themeColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Center(
                                                    child: otherChatTotal > 999
                                                        ? Text(
                                                            '999+',
                                                            style: jxTextStyle
                                                                .headerSmallText(
                                                              color: colorWhite,
                                                            ),
                                                          )
                                                        : AnimatedFlipCounter(
                                                            value:
                                                                otherChatTotal,
                                                            textStyle: jxTextStyle
                                                                .headerSmallText(
                                                              color: colorWhite,
                                                            ),
                                                          ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          buttonOnPressed: () {
                                            //檢查當前有無開啟語音群聊
                                            _checkJoinAudioRoom(context);
                                            controller.removeShortcutImage();
                                          },
                                        ),
                                      )
                                    : const SizedBox(),
                              ),

                              Expanded(
                                child: Obx(
                                  () => controller.isSearching.value
                                      ? Container(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                            bottom: 8,
                                          ),
                                          child: SearchingAppBar(
                                            onTap: () =>
                                                controller.isSearching(true),
                                            onChanged: (value) {
                                              controller.searchParam.value =
                                                  value;
                                              controller.getIndexList();
                                              if (!value.startsWith(
                                                '${localized(chatFrom)}:',
                                              )) {
                                                controller.clearSearchState();
                                              } else {
                                                controller
                                                    .onSearchChanged(value);
                                              }
                                            },
                                            onCancelTap: () {
                                              controller.searchFocusNode
                                                  .unfocus();
                                              controller.clearSearching();
                                              controller.clearSearchState();
                                            },
                                            isSearchingMode:
                                                controller.isSearching.value,
                                            isAutoFocus: true,
                                            focusNode:
                                                controller.searchFocusNode,
                                            controller:
                                                controller.searchController,
                                            suffixIcon: Visibility(
                                              visible: controller
                                                  .searchParam.value.isNotEmpty,
                                              child: GestureDetector(
                                                onTap: () {
                                                  controller.searchController
                                                      .clear();
                                                  controller.searchParam.value =
                                                      '';
                                                  controller.getIndexList();
                                                  controller.isListModeSearch
                                                      .value = false;
                                                  controller.isTextTypeSearch
                                                      .value = true;
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 8.0,
                                                  ),
                                                  child: SvgPicture.asset(
                                                    'assets/svgs/close_round_icon.svg',
                                                    width: 20,
                                                    height: 20,
                                                    color: colorTextSupporting,
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
                                                  localized(
                                                    'selectedWithParam',
                                                    params: [
                                                      '${controller.chooseMessage.values.toList().length}',
                                                    ],
                                                  ),
                                                  style: jxTextStyle
                                                      .textStyleBold17(),
                                                ),
                                              ],
                                            )
                                          : GestureDetector(
                                              behavior:
                                                  HitTestBehavior.translucent,
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
                                                              if (controller
                                                                  .chat
                                                                  .isEncrypted)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              4.0),
                                                                  child:
                                                                      SvgPicture
                                                                          .asset(
                                                                    'assets/svgs/chatroom_icon_encrypted.svg',
                                                                    width: 16,
                                                                    height: 16,
                                                                  ),
                                                                ),
                                                              Flexible(
                                                                child:
                                                                    NicknameText(
                                                                  uid: controller
                                                                      .chat
                                                                      .chat_id,
                                                                  isGroup:
                                                                      controller
                                                                          .chat
                                                                          .isGroup,
                                                                  displayName:
                                                                      notBlank(
                                                                    controller
                                                                        .chat
                                                                        .name,
                                                                  )
                                                                          ? controller
                                                                              .chat
                                                                              .name
                                                                          : '',
                                                                  fontSize:
                                                                      MFontSize
                                                                          .size17
                                                                          .value,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  fontWeight: Platform
                                                                          .isAndroid
                                                                      ? FontWeight
                                                                          .w500
                                                                      : FontWeight
                                                                          .w600,
                                                                  isTappable:
                                                                      false,
                                                                ),
                                                              ),
                                                              if (controller
                                                                  .chat
                                                                  .isTmpGroup)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                    left: 2.0,
                                                                  ),
                                                                  child:
                                                                      SvgPicture
                                                                          .asset(
                                                                    'assets/svgs/temporary_indicator.svg',
                                                                    width: 16,
                                                                    height: 16,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                    color: controller
                                                                            .isGroupExpireSoon
                                                                            .value
                                                                        ? colorRed
                                                                        : themeColor,
                                                                  ),
                                                                ),
                                                              if (controller
                                                                  .isMute.value)
                                                                SvgPicture
                                                                    .asset(
                                                                  'assets/svgs/mute_icon3.svg',
                                                                  width:
                                                                      20.23.w,
                                                                  height: 20.w,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
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
                                                                    .groupMembers,
                                                              );
                                                              if (ChatTypingTask
                                                                              .whoIsTyping[
                                                                          controller
                                                                              .chat
                                                                              .id] !=
                                                                      null &&
                                                                  ChatTypingTask
                                                                      .whoIsTyping[controller
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
                                                                      .normalSmallText(
                                                                    color:
                                                                        colorTextSecondary,
                                                                  ),
                                                                );
                                                              }
                                                              return Text(
                                                                controller
                                                                    .getHeaderText(),
                                                                style: jxTextStyle
                                                                    .normalSmallText(
                                                                  color:
                                                                      colorTextLevelTwo,
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : const SizedBox(),
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
                            Obx(
                              () => Visibility(
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
                              ),
                            ),
                            Obx(
                              () => Visibility(
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
                                            12,
                                            3,
                                            8,
                                            3,
                                          ),
                                          child: OpacityEffect(
                                            child: CustomAvatar.chat(
                                              controller.chat,
                                              size: jxDimension
                                                  .chatRoomAvatarSize(),
                                              headMin: Config().headMin,
                                              fontSize: MFontSize.size17.value,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const CustomDivider(),
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
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Stack(
                                        children: [
                                          Obx(
                                            () => SizedBox(
                                              child: controller.isListModeSearch
                                                          .value ||
                                                      !controller
                                                          .isTextTypeSearch
                                                          .value
                                                  ? ListModeView(
                                                      tag: tag,
                                                      isGroupChat: true,
                                                    )
                                                  : ChatContentView(tag: tag),
                                            ),
                                          ),

                                          ChatScrollToBottom(
                                            controller: controller,
                                          ),
                                          // Obx(
                                          //   () => Visibility(
                                          //     visible:
                                          //         controller.isVideoRecording.value,
                                          //     child: CameraRecordScreen(tag: tag),
                                          //   ),
                                          // ),
                                          Obx(
                                            () => controller
                                                    .showMentionList.value
                                                ? Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: MentionView(
                                                      groupMembers: controller
                                                          .groupMembers,
                                                      chat: controller.chat,
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ),
                                          ShortcutImage(controller: controller),
                                        ],
                                      ),
                                    ),
                                  ),
                                  CustomInputViewV2(
                                    tag,
                                    key: ValueKey(tag.toString()),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
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
            Obx(
              () => WillPopScope(
                onWillPop: controller.isJoinAudioRoom.value
                    ? () async {
                        agoraHelper.gameManagerGetCheckCloseDialog(
                          context,
                          action: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            Get.back();
                          },
                        );
                        return false;
                      }
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
                            Get.back();
                          }
                        }
                      },
                      child: Scaffold(
                        resizeToAvoidBottomInset: false,
                        body: Column(
                          children: [
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorBackground,
                                border: customBorder,
                              ),
                              child: _buildDesktopHeader(),
                            ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: colorDesktopChatBg,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      "assets/images/chat_bg.png",
                                    ),
                                    fit: BoxFit.none,
                                    opacity: 0.8,
                                    repeat: ImageRepeat.repeat,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // getChatControllerWidget(context),

                                    /// 消息列表
                                    Expanded(
                                      child: AnimatedSize(
                                        curve: Curves.easeInOutCubic,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Stack(
                                          children: [
                                            ChatContentView(tag: tag),
                                            ChatScrollToBottom(
                                              controller: controller,
                                            ),
                                            // Obx(
                                            //   () => Visibility(
                                            //     visible:
                                            //         controller.isVideoRecording.value,
                                            //     child: CameraRecordScreen(tag: tag),
                                            //   ),
                                            // ),
                                            Obx(
                                              () => controller
                                                      .showMentionList.value
                                                  ? Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: MentionView(
                                                        groupMembers: controller
                                                            .groupMembers,
                                                        chat: controller.chat,
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    CustomInputViewV2(
                                      tag,
                                      key: ValueKey(tag.toString()),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
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

  Widget _buildDesktopHeader() {
    return Obx(() {
      if (!controller.showSearchBar.value) {
        return Row(
          children: [
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.onEnterChatInfo(
                      false,
                      controller.chat,
                      controller.chat.chat_id,
                    );
                  },
                  child: OpacityEffect(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                            left: 24.0,
                            right: 8.0,
                          ),
                          child: CustomAvatar.chat(
                            controller.chat,
                            size: 36.0,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (controller.chat.isEncrypted)
                                    const CustomImage(
                                      'assets/svgs/chatroom_icon_encrypted.svg',
                                      padding: EdgeInsets.only(right: 4.0),
                                    ),
                                  Flexible(
                                    child: NicknameText(
                                      uid: controller.chat.chat_id,
                                      isGroup: controller.chat.isGroup,
                                      displayName:
                                          notBlank(controller.chat.name)
                                              ? controller.chat.name
                                              : '',
                                      overflow: TextOverflow.ellipsis,
                                      fontSpace: 0.25,
                                      fontWeight: MFontWeight.bold5.value,
                                      isTappable: false,
                                    ),
                                  ),
                                  if (controller.isMute.value)
                                    const CustomImage(
                                      'assets/svgs/mute_icon3.svg',
                                      padding: EdgeInsets.only(left: 4.0),
                                    ),
                                ],
                              ),
                              controller.chat.isValid
                                  ? Obx(
                                      () {
                                        //設置語音的成員名單
                                        audioManager.setMemberList(
                                          controller.groupMembers,
                                        );
                                        if (ChatTypingTask.whoIsTyping[
                                                    controller.chat.id] !=
                                                null &&
                                            ChatTypingTask
                                                .whoIsTyping[
                                                    controller.chat.id]!
                                                .isNotEmpty) {
                                          return Transform.translate(
                                            offset: const Offset(-7.0, 0.0),
                                            child: whoIsTypingWidget(
                                              ChatTypingTask.whoIsTyping[
                                                  controller.chat.id]!,
                                              jxTextStyle.textStyle14(
                                                color: themeColor,
                                              ),
                                              mainAlignment:
                                                  MainAxisAlignment.start,
                                            ),
                                          );
                                        }

                                        return Text(
                                          UserUtils.groupMembersLengthInfo(
                                              controller.groupMembers.length),
                                          style: jxTextStyle.textStyle12(
                                              color: colorTextSecondary),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomImage(
              'assets/svgs/desktop_search.svg',
              size: 24,
              color: themeColor,
              padding: const EdgeInsets.only(right: 24.0),
              onClick: controller.onTapSearchDesktop,
            ),
            if (controller.chooseMore.value)
              CustomTextButton(
                localized(cancel),
                padding: const EdgeInsets.only(right: 24.0),
                onClick: controller.onChooseMoreCancel,
              ),
          ],
        );
      }

      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: SearchingAppBar(
          tag: tag.toString(),
          onTap: () => controller.isSearching(true),
          onChanged: (value) {
            controller.searchParam.value = value;
            controller.getIndexList();
          },
          onCancelTap: () {
            controller.searchFocusNode.unfocus();
            controller.clearSearching();
            controller.showSearchBar(false);
          },
          searchBarHeight: 30,
          isSearchingMode: controller.isSearching.value,
          isAutoFocus: false,
          focusNode: controller.searchFocusNode,
          controller: controller.searchController,
          suffixIcon: Visibility(
            visible: controller.searchParam.value.isNotEmpty ||
                controller.isSearching.value,
            child: GestureDetector(
              onTap: () {
                if (controller.searchParam.value.isNotEmpty) {
                  controller.searchController.clear();
                  controller.searchParam.value = '';
                  controller.getIndexList();
                  controller.isListModeSearch.value = false;
                  controller.isTextTypeSearch.value = true;
                } else {
                  controller.isSearching(false);
                }
              },
              child: OpacityEffect(
                child: SvgPicture.asset('assets/svgs/close_round_icon.svg',
                    width: 16, height: 16, color: colorTextSecondarySolid),
              ),
            ),
        ),
      ));
    });
  }
}

Widget whoIsTypingWidget(
  List<ChatInput> whoIsTyping,
  TextStyle style, {
  bool isSingleChat = false,
  MainAxisAlignment mainAlignment = MainAxisAlignment.center,
}) {
  if (whoIsTyping.isEmpty) return const SizedBox();
  var names = whoIsTyping.first.username;

  if (whoIsTyping.length == 1 && isSingleChat) {
    names = '';
  }

  if (whoIsTyping.first.state.isSendingMedia) {
    names = '$names ${localized(chatTypingTitle, params: [
          whoIsTyping.first.state.toString(),
        ])}';
  } else {
    if (whoIsTyping.length > 2) {
      names += ' ${localized(shareAnd)} ${localized(
        chatTypingOther,
        params: [(whoIsTyping.length - 1).toString()],
      )}';
    } else if (whoIsTyping.length == 2) {
      names =
          "${whoIsTyping[0].username} ${localized(shareAnd)} ${whoIsTyping[1].username}${localized(chatTyping)}";
    } else {
      names += ' ${localized(chatTyping)}';
    }
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
      ),
    ],
  );
}
