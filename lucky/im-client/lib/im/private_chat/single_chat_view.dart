import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_view.dart';
import 'package:jxim_client/im/custom_content/chat_scroll_to_bottom.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/message/component/custom_angle.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/desktop/detail_chat_view.dart';

import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/im/custom_content/chat_wall_paper.dart';
import 'package:jxim_client/im/custom_input/text_input_field_factory.dart';

class SingleChatView extends StatelessWidget {
  final String tag;
  late final SingleChatController controller;

  SingleChatView({Key? key, required this.tag}) : super(key: key) {
    controller = Get.find<SingleChatController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    if (!isDesktop) {
      return Obx(
        () => WillPopScope(
          onWillPop: (controller.chooseMessage.values.isNotEmpty)
              ? () async {
                  if (controller.chooseMessage.values.isNotEmpty) {
                    controller.onChooseMoreCancel();
                    return false;
                  } else {
                    return true;
                  }
                }
              : null,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: PrimaryAppBar(
              titleSpacing: 0,
              isBackButton: false,
              height: controller.isSearching.value ? 52 : 44,
              titleWidget: Row(
                children: [
                  /// 選取多項模式的頂部條-全部刪除
                  Obx(() {
                    return Visibility(
                      visible: controller.chooseMore.value,
                      child: Container(
                        width: 100.w,
                        padding: EdgeInsets.only(left: 10.w),
                        child: OpacityEffect(
                          child: GestureDetector(
                            onTap: controller.onClearChooseMessage,
                            child: Text(
                              localized(deselect),
                              style: jxTextStyle.textStyle17(
                                color:
                                    controller.chooseMessage.values.isNotEmpty
                                        ? accentColor
                                        : const Color(0x7a121212),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Obx(
                    () => !controller.isSearching.value &&
                            !controller.chooseMore.value
                        ? SizedBox(
                            width: 80,
                            child: CustomLeadingIcon(
                              badgeView: Obx(
                                () {
                                  int otherChatTotal =
                                      objectMgr.chatMgr.totalUnreadCount.value -
                                          (controller.chat.isMute
                                              ? 0
                                              : controller.chat.unread_count);
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
                                Get.back();
                              },
                            ),
                          )
                        : const SizedBox(),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.isSearching.value) {
                        return Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 8,
                          ),
                          child: SearchingAppBar(
                            onTap: () => controller.isSearching(true),
                            onChanged: (value) {
                              controller.searchParam.value = value;
                              controller.getIndexList();
                            },
                            onCancelTap: () {
                              controller.searchFocusNode.unfocus();
                              controller.clearSearching();
                            },
                            isSearchingMode: controller.isSearching.value,
                            isAutoFocus: true,
                            focusNode: controller.searchFocusNode,
                            controller: controller.searchController,
                            suffixIcon: Visibility(
                              visible: controller.searchParam.value.isNotEmpty,
                              child: GestureDetector(
                                onTap: () {
                                  controller.searchController.clear();
                                  controller.searchParam.value = '';
                                  controller.getIndexList();
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: SvgPicture.asset(
                                    'assets/svgs/close_round_icon.svg',
                                    width: 20,
                                    height: 20,
                                    color: JXColors.iconSecondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      if (controller.chooseMore.value) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localized('selectedWithParam', params: [
                                '${controller.chooseMessage.values.toList().length}'
                              ]),
                              style: jxTextStyle.textStyleBold17(),
                            )
                          ],
                        );
                      }

                      if (controller.chat.typ == chatTypeSmallSecretary) {
                        return Text(
                          localized(chatSecretary),
                          textAlign: TextAlign.center,
                        );
                      }

                      if (controller.chat.isSaveMsg) {
                        return Text(
                          controller.chat.name,
                          textAlign: TextAlign.center,
                        );
                      }

                      if (controller.chat.isSystem) {
                        return _systemTitleView();
                      }

                      return _buildAvatar();
                    }),
                  ),
                ],
              ),
              trailing: [
                Obx(() => Visibility(
                      visible: controller.chooseMore.value,
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.only(right: 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: controller.onChooseMoreCancel,
                            child: Text(
                              localized(buttonCancel),
                              style: jxTextStyle.textStyle17(
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
                Obx(
                  () => Visibility(
                    visible: !controller.isSearching.value &&
                        !controller.chooseMore.value,
                    child: GestureDetector(
                      onTap: () => {
                        if (controller.chat.typ != chatTypeSaved &&
                            controller.chat.typ != chatTypeSmallSecretary &&
                            !controller.chat.isSystem)
                          {
                            controller.onEnterChatInfo(
                              true,
                              controller.chat,
                              controller.chat.friend_id,
                            ),
                          }
                      },
                      child: SizedBox(
                        width: 80,
                        child: Row(
                          children: [
                            const Spacer(),
                            Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 8, 3),
                              child: controller.chat.typ ==
                                      chatTypeSmallSecretary
                                  ? Image.asset(
                                      'assets/images/message_new/secretary.png',
                                      width: jxDimension.chatRoomAvatarSize(),
                                      height: jxDimension.chatRoomAvatarSize(),
                                    )
                                  : controller.chat.typ == chatTypeSaved
                                      ? Container(
                                          width:
                                              jxDimension.chatRoomAvatarSize(),
                                          height:
                                              jxDimension.chatRoomAvatarSize(),
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
                                          child: const Center(
                                            child: SavedMessageIcon(),
                                          ),
                                        )
                                      : controller.chat.typ == chatTypeSystem
                                          ? Image.asset(
                                              'assets/images/message_new/sys_notification.png',
                                              width: jxDimension
                                                  .chatRoomAvatarSize(),
                                              height: jxDimension
                                                  .chatRoomAvatarSize(),
                                            )
                                          : OpacityEffect(
                                              child: CustomAvatar(
                                                uid: controller.chat.friend_id,
                                                size: jxDimension
                                                    .chatRoomAvatarSize(),
                                                headMin: Config().headMin,
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
                        children: <Widget>[
                          Expanded(
                            child: AnimatedSize(
                              curve: Curves.easeInOutCubic,
                              duration: const Duration(milliseconds: 200),
                              child: Stack(
                                children: [
                                  ChatContentView(tag: tag),
                                  if (controller.chat.typ !=
                                      chatTypeSmallSecretary)
                                    ChatScrollToBottom(controller: controller),
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
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  if (controller.isSearching.value) {
                    controller.isSearching.value = false;
                    controller.searchController.clear();
                  } else {
                    Get.back(id: 1);
                    Get.find<ChatListController>().desktopSelectedChatID.value =
                        01010;
                  }
                }
              },
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: null,
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
                            Obx(
                              () => Visibility(
                                visible: !controller.isSearching.value &&
                                    !controller.chooseMore.value,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => {
                                      if (controller.chat.typ !=
                                              chatTypeSaved &&
                                          controller.chat.typ !=
                                              chatTypeSmallSecretary)
                                        {
                                          controller.onEnterChatInfo(
                                            true,
                                            controller.chat,
                                            controller.chat.friend_id,
                                          ),
                                        }
                                    },
                                    child: SizedBox(
                                      width: 70,
                                      child: Row(
                                        children: [
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.only(
                                                left: 16, right: 12),
                                            child: controller.chat.typ ==
                                                    chatTypeSmallSecretary
                                                ? Image.asset(
                                                    'assets/images/message_new/secretary.png',
                                                    width: jxDimension
                                                        .chatRoomAvatarSize(),
                                                    height: jxDimension
                                                        .chatRoomAvatarSize(),
                                                  )
                                                : controller.chat.typ ==
                                                        chatTypeSaved
                                                    ? Container(
                                                        width: jxDimension
                                                            .chatRoomAvatarSize(),
                                                        height: jxDimension
                                                            .chatRoomAvatarSize(),
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .bottomRight,
                                                            end: Alignment
                                                                .topLeft,
                                                            colors: [
                                                              Color(0xFFFFD08E),
                                                              Color(0xFFFFECD2),
                                                            ],
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child:
                                                              const SavedMessageIcon(),
                                                        ),
                                                      )
                                                    : controller.chat.typ ==
                                                            chatTypeSystem
                                                        ? Image.asset(
                                                            'assets/images/message_new/sys_notification.png',
                                                            width: jxDimension
                                                                .chatRoomAvatarSize(),
                                                            height: jxDimension
                                                                .chatRoomAvatarSize(),
                                                          )
                                                        : OpacityEffect(
                                                            child: CustomAvatar(
                                                              uid: controller
                                                                  .chat
                                                                  .friend_id,
                                                              size: jxDimension
                                                                  .chatRoomAvatarSize(),
                                                            ),
                                                          ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Obx(() {
                                if (controller.isSearching.value) {
                                  return Container(
                                    padding: const EdgeInsets.only(left: 10),
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
                                      },
                                      isSearchingMode:
                                          controller.isSearching.value,
                                      isAutoFocus: true,
                                      focusNode: controller.searchFocusNode,
                                      controller: controller.searchController,
                                      suffixIcon: Visibility(
                                        visible: controller
                                            .searchParam.value.isNotEmpty,
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              controller.searchController
                                                  .clear();
                                              controller.searchParam.value = '';
                                              controller.getIndexList();
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: SvgPicture.asset(
                                                'assets/svgs/close_round_icon.svg',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (controller.chooseMore.value) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        localized('selectedWithParam', params: [
                                          '${controller.chooseMessage.values.toList().length}'
                                        ]),
                                        style: jxTextStyle.textStyleBold17(),
                                      )
                                    ],
                                  );
                                }

                                if (controller.chat.typ ==
                                    chatTypeSmallSecretary) {
                                  return Text(
                                    localized(chatSecretary),
                                    textAlign: TextAlign.left,
                                    style: jxTextStyle
                                        .textStyleSecretaryChatTitle(),
                                  );
                                }

                                if (controller.chat.isSaveMsg ||
                                    controller.chat.isSystem) {
                                  return Text(
                                    controller.chat.name,
                                    textAlign: TextAlign.left,
                                  );
                                }

                                return _buildAvatar();
                              }),
                            ),
                            Visibility(
                              visible: controller.chat.typ !=
                                      chatTypeSmallSecretary &&
                                  !controller.isSearching.value,
                              child: OpacityEffect(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: controller.onTapSearchDesktop,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
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
                                    color: JXColors.desktopChatBgColor,
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
                              children: <Widget>[
                                Expanded(
                                  child: AnimatedSize(
                                    curve: Curves.easeInOutCubic,
                                    duration: const Duration(milliseconds: 200),
                                    child: Stack(
                                      children: [
                                        ChatContentView(tag: tag),
                                        ChatScrollToBottom(
                                            controller: controller),
                                        // Obx(
                                        //   () => Visibility(
                                        //     visible: controller.isVideoRecording.value,
                                        //     child: CameraRecordScreen(tag: tag),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                                TextInputFieldFactory
                                    .createCustomInputViewComponent(
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

  Widget _buildAvatar() {
    return Obx(
      () => OpacityEffect(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.onEnterChatInfo(
                true, controller.chat, controller.chat.friend_id),
            child: Container(
              // padding: EdgeInsets.symmetric(
              //     vertical: objectMgr.loginMgr.isDesktop ? 0 : 30),
              alignment: Alignment.centerLeft,
              child: _listUserInfo(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _systemTitleView() {
    return Text(
      localized(chatSystem),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: MFontWeight.bold6.value,
        fontSize: 17,
        inherit: true,
        height: 1.25,
        color: Colors.black,
      ),
    );
  }

  Widget _listUserInfo() {
    if (controller.chat.typ == chatTypeSingle) {
      return Column(
        mainAxisAlignment: objectMgr.loginMgr.isDesktop
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        crossAxisAlignment: objectMgr.loginMgr.isDesktop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: objectMgr.loginMgr.isDesktop
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Flexible(
                child: NicknameText(
                  uid: controller.chat.friend_id,
                  fontSize: objectMgr.loginMgr.isDesktop
                      ? MFontSize.size14.value
                      : MFontSize.size17.value,
                  overflow: TextOverflow.ellipsis,
                  fontSpace: objectMgr.loginMgr.isDesktop ? 0.25 : 0.15,
                  fontWeight: MFontWeight.bold5.value,
                  fontLineHeight: 1.1,
                  isTappable: false,
                ),
              ),
              SizedBox(
                width: objectMgr.loginMgr.isDesktop ? 2 : 2.w,
              ),
              if (controller.isMute.value)
                SvgPicture.asset(
                  'assets/svgs/mute_icon3.svg',
                  width: objectMgr.loginMgr.isDesktop ? 20 : 20.23.w,
                  height: objectMgr.loginMgr.isDesktop ? 20 : 20.w,
                  fit: BoxFit.fill,
                ),
            ],
          ),
          Obx(
            () => Visibility(
              visible: ChatTypingTask.whoIsTyping[controller.chat.id] != null &&
                  ChatTypingTask.whoIsTyping[controller.chat.id]!.isNotEmpty,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: const DotLoadingView(
                      size: 8,
                      dotColor: JXColors.secondaryTextBlack,
                    ),
                  ),
                  Text(localized(chatTyping),
                      style: TextStyle(
                          fontSize: MFontSize.size12.value,
                          fontWeight: MFontWeight.bold5.value,
                          fontFamily: appFontfamily,
                          color: JXColors.secondaryTextBlack,
                          height: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Obx(
            () => Visibility(
              visible:
                  !(ChatTypingTask.whoIsTyping[controller.chat.id] != null &&
                          ChatTypingTask
                              .whoIsTyping[controller.chat.id]!.isNotEmpty) &&
                      controller.lastOnline.value != "",
              child: Text(
                '${controller.lastOnline.value}',
                style: TextStyle(
                  fontSize: MFontSize.size13.value,
                  fontWeight: MFontWeight.bold4.value,
                  fontFamily: appFontfamily,
                  color: JXColors.secondaryTextBlack,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Text(
        controller.chat.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: objectMgr.loginMgr.isDesktop ? 16 : 16.sp,
            color: color1A1A1A,
            fontWeight: FontWeight.bold,
            height: 1.1,
            letterSpacing: 1.1,
            decoration: TextDecoration.none),
      );
    }
  }
}
