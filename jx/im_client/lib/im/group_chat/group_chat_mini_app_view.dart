import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as cm;
import 'package:jxim_client/home/chat/desktop/detail_chat_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_content/chat_content_view.dart';
import 'package:jxim_client/im/custom_content/chat_scroll_to_bottom.dart';
import 'package:jxim_client/im/custom_content/chat_wall_paper.dart';
import 'package:jxim_client/im/custom_input/text_input_field_factory.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/group_chat/list_mode_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:jxim_client/views/message/component/custom_angle.dart';

class GroupChatMiniAppView extends StatelessWidget {
  final String tag;
  late final SingleChatController controller;

  GroupChatMiniAppView({super.key, required this.tag}) {
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
                                      color: controller
                                              .chooseMessage.values.isNotEmpty
                                          ? themeColor
                                          : colorTextPlaceholder,
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
                                        int otherChatTotal = objectMgr.chatMgr
                                                .totalUnreadCount.value -
                                            (controller.chat.isMute
                                                ? 0
                                                : controller.chat.unread_count);
                                        if (otherChatTotal == 0) {
                                          return Text(
                                            localized(buttonBack),
                                            style: jxTextStyle.textStyle17(
                                              color: themeColor,
                                            ),
                                          );
                                        } else {
                                          return CustomAngle(
                                            bgColor: themeColor,
                                            height: 20.w,
                                            value: otherChatTotal,
                                            fontSize: MFontSize.size15.value,
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
                                    visible:
                                        controller.searchParam.value.isNotEmpty,
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.searchController.clear();
                                        controller.searchParam.value = '';
                                        controller.getIndexList();
                                        controller.isListModeSearch.value =
                                            false;
                                        controller.isTextTypeSearch.value =
                                            true;
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
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
                              );
                            }

                            if (controller.chooseMore.value) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localized(
                                      'selectedWithParam',
                                      params: [
                                        '${controller.chooseMessage.values.toList().length}',
                                      ],
                                    ),
                                    style: jxTextStyle.textStyleBold17(),
                                  ),
                                ],
                              );
                            }

                            return Center(
                              child: _buildAvatarInfo(controller.chat),
                            );
                          }),
                        ),
                      ],
                    ),
                    trailing: [
                      Obx(
                        () => Visibility(
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
                        ),
                      ),
                      Obx(
                        () => Visibility(
                          visible: !controller.isSearching.value &&
                              !controller.chooseMore.value,
                          child: GestureDetector(
                            onTap: () {
                              controller.onEnterChatInfo(true, controller.chat,
                                  controller.chat.friend_id,
                                  isSpecialChat: controller.chat.isSaveMsg ||
                                      controller.chat.isSecretary ||
                                      controller.chat.isSystem);
                            },
                            child: SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  const Spacer(),
                                  Container(
                                    margin:
                                        const EdgeInsets.fromLTRB(12, 0, 8, 3),
                                    child: controller.chat.typ == chatTypeSaved
                                            ? Container(
                                                width: jxDimension
                                                    .chatRoomAvatarSize(),
                                                height: jxDimension
                                                    .chatRoomAvatarSize(),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomRight,
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
                                            : controller.chat.typ ==
                                                    chatTypeSystem
                                                ? SystemMessageIcon(
                                                    size: jxDimension
                                                        .chatRoomAvatarSize(),
                                                  )
                                                : OpacityEffect(
                                                    child: CustomAvatar.chat(
                                                      controller.chat,
                                                      size: jxDimension
                                                          .chatRoomAvatarSize(),
                                                      headMin: Config().headMin,
                                                      fontSize: MFontSize
                                                          .size17.value,
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
                          children: <Widget>[
                            Expanded(
                              child: AnimatedSize(
                                curve: Curves.easeInOutCubic,
                                duration: const Duration(milliseconds: 200),
                                child: Stack(
                                  children: [
                                    Obx(
                                      () => SizedBox(
                                        child:
                                            controller.isListModeSearch.value ||
                                                    !controller
                                                        .isTextTypeSearch.value
                                                ? ListModeView(
                                                    tag: tag,
                                                    isGroupChat: false,
                                                  )
                                                : ChatContentView(tag: tag),
                                      ),
                                    ),
                                    if (controller.chat.typ !=
                                        chatTypeSmallSecretary)
                                      ChatScrollToBottom(
                                          controller: controller),
                                  ],
                                ),
                              ),
                            ),

                            ///进入后台
                            _buildBottom(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    Get.back();
                  }
                }
              },
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: null,
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
                          children: <Widget>[
                            Expanded(
                              child: AnimatedSize(
                                curve: Curves.easeInOutCubic,
                                duration: const Duration(milliseconds: 200),
                                child: Stack(
                                  children: [
                                    ChatContentView(tag: tag),
                                    ChatScrollToBottom(controller: controller),
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

  Widget _buildDesktopHeader() {
    return Obx(() {
      if (!controller.isSearching.value) {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 24.0, right: 8.0),
              child: _buildAvatar(controller.chat),
            ),
            Expanded(child: _buildAvatarInfo(controller.chat)),
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
          },
          isSearchingMode: controller.isSearching.value,
          isAutoFocus: true,
          focusNode: controller.searchFocusNode,
          controller: controller.searchController,
          suffixIcon: Visibility(
            visible: controller.searchParam.value.isNotEmpty,
            child: CustomImage(
              'assets/svgs/close_round_icon.svg',
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: colorTextSecondarySolid,
              onClick: () {
                controller.searchController.clear();
                controller.searchParam.value = '';
                controller.getIndexList();
                controller.isListModeSearch.value = false;
                controller.isTextTypeSearch.value = true;
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAvatar(Chat chat) {
    double avatarSize = jxDimension.chatRoomAvatarSize();
    Widget avatar = const SizedBox.shrink();

    if (chat.isSecretary) {
      avatar = SecretaryMessageIcon(size: avatarSize);
    } else if (chat.isSaveMsg) {
      avatar = SavedMessageIcon(size: avatarSize);
    } else if (chat.isSystem) {
      avatar = SystemMessageIcon(size: avatarSize);
    } else {
      avatar = CustomAvatar.chat(
        chat,
        size: avatarSize,
        headMin: Config().headMin,
        fontSize: MFontSize.size17.value,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          controller.onEnterChatInfo(
            true,
            chat,
            chat.friend_id,
            isSpecialChat: chat.isSaveMsg || chat.isSecretary || chat.isSystem,
          );
        },
        child: OpacityEffect(child: avatar),
      ),
    );
  }

  Widget _buildAvatarInfo(Chat chat) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          controller.onEnterChatInfo(
            true,
            chat,
            chat.friend_id,
            isSpecialChat: chat.isSaveMsg || chat.isSecretary || chat.isSystem,
          );
        },
        child: OpacityEffect(child: _listUserInfo(chat)),
      ),
    );
  }

  Widget _buildTitleView(String title) {
    return Row(
      mainAxisAlignment: objectMgr.loginMgr.isDesktop
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: MFontWeight.bold5.value,
            fontSize: MFontSize.size17.value,
            height: 1.2,
            color: colorTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _listUserInfo(Chat chat) {
    if (chat.isSecretary) {
      return _buildTitleView(localized(chatSecretary));
    }

    if (chat.isSaveMsg) {
      return _buildTitleView(localized(homeSavedMessage));
    }

    if (chat.isSystem) {
      return _buildTitleView(localized(chatSystem));
    }

    if (chat.isSpecialChat) {
      return Row(
        mainAxisAlignment: objectMgr.loginMgr.isDesktop
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Text(
            chat.name,
            style: TextStyle(
              fontWeight: MFontWeight.bold5.value,
              fontSize: MFontSize.size17.value,
              height: 1.2,
              color: colorTextPrimary,
            ),
          ),
          CustomImage(
            'assets/svgs/secretary_check_icon.svg',
            padding: const EdgeInsets.only(left: 4),
            color: themeColor,
            fit: BoxFit.fitWidth,
          ),
        ],
      );
    }

    if (chat.isSingle) {
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
              Obx(
                () => Visibility(
                  visible: controller.isEncrypted.value,
                  child: const CustomImage(
                    'assets/svgs/chatroom_icon_encrypted.svg',
                    padding: EdgeInsets.only(right: 4.0),
                  ),
                ),
              ),
              Flexible(
                child: NicknameText(
                  uid: chat.friend_id,
                  fontSize: MFontSize.size17.value,
                  overflow: TextOverflow.ellipsis,
                  fontSpace: objectMgr.loginMgr.isDesktop ? 0.25 : 0.15,
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
          const SizedBox(height: 2),
          Obx(
            () {
              if (controller.chatIsDeleted.value) {
                return const SizedBox();
              }

              if (ChatTypingTask.whoIsTyping[chat.id] != null &&
                  ChatTypingTask.whoIsTyping[chat.id]!.isNotEmpty) {
                return whoIsTypingWidget(
                  ChatTypingTask.whoIsTyping[chat.id]!,
                  jxTextStyle.normalSmallText(
                    color: objectMgr.loginMgr.isDesktop
                        ? themeColor
                        : colorTextSecondary,
                  ),
                  isSingleChat: true,
                  mainAlignment: objectMgr.loginMgr.isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                );
              }

              if (objectMgr.appInitState.value == AppInitState.no_network ||
                  objectMgr.appInitState.value == AppInitState.no_connect ||
                  objectMgr.appInitState.value == AppInitState.connecting) {
                return Text(
                  objectMgr.appInitState.value.toName,
                  style: jxTextStyle.normalSmallText(color: colorTextSecondary),
                );
              }

              if (controller.lastOnline.value.isNotEmpty) {
                return Visibility(
                  visible: !controller.chatIsDeleted.value,
                  child: Text(
                    controller.lastOnline.value,
                    style:
                        jxTextStyle.normalSmallText(color: colorTextSecondary),
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      );
    }

    return Text(
      chat.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: MFontSize.size17.value,
        letterSpacing: objectMgr.loginMgr.isDesktop ? 0.25 : 0.15,
        fontWeight: MFontWeight.bold5.value,
        color: colorTextPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Container(
      height: 80.w,
      width: 1.sw,
      color: Colors.white,
      alignment: Alignment.topCenter,
      child: Container(
        alignment: Alignment.center,
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: cm.PrimaryButton(
          onPressed: () {
            objectMgr.miniAppMgr.useFriendIdLoginMiniApp(context,friendId: controller.chat.friend_id);
          },
          height: 36,
          borderRadius: 20,
          txtColor: Colors.white,
          title: localized(butlerEnterBackstage),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
