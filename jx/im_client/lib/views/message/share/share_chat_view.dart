import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/message/share/share_chat_controller.dart';

class ShareChatView extends GetView<ShareChatController> {
  const ShareChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: PrimaryAppBar(
            title: localized(share),
            isSearchingMode: controller.isSearching.value,
          ),
          body: NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollNotification) {
                controller.onScroll(notification);
              }
              return false;
            },
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: controller.isPin.value,
                        expandedHeight: 0,
                        elevation: 0.2,
                        toolbarHeight: 52,
                        shape: Border(
                          bottom: BorderSide(
                            color: colorTextPrimary.withOpacity(0.2),
                            width: 0.33,
                          ),
                        ),
                        backgroundColor: colorBackground,
                        leading: const SizedBox(),
                        flexibleSpace: Container(
                          color: colorBackground,
                          margin: const EdgeInsets.only(
                            top: 8.0,
                            left: 16.0,
                            right: 16.0,
                          ),
                          child: Obx(() {
                            return SearchingAppBar(
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
                                visible:
                                    controller.searchParam.value.isNotEmpty,
                                child: IconButton(
                                  onPressed: () {
                                    controller.clearSearching(isUnfocus: true);
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/svgs/close_round_icon.svg',
                                    color: colorTextSupporting,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                            childCount: controller.filterChatList.length,
                            addRepaintBoundaries: false, (context, index) {
                          final Chat chat = controller.filterChatList[index];
                          return _buildItem(chat, index);
                        }),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  return Visibility(
                    visible: controller.selectedChatList.isNotEmpty,
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.bottomCenter,
                      curve: Curves.easeInOutCubic,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: colorTextPrimary.withOpacity(0.08),
                              blurRadius: 32,
                              offset: const Offset(0, -4),
                            ),
                          ],
                          color: colorWhite,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  _getSelectedAvatar(),
                                  _getSelectedName(),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildCaptionTextField(),
                                const SizedBox(width: 12),
                                _buildSendButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildItem(Chat chat, int index) {
    return GestureDetector(
      onTapDown: (_) {
        controller.captionFocus.unfocus();
      },
      onTap: () {
        controller.chatOnTap(index);
      },
      child: OverlayEffect(
        child: Column(
          children: [
            Obx(() {
              return Container(
                color: controller.selectedChatList.contains(chat)
                    ? themeColor.withOpacity(0.08)
                    : null,
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 10.0,
                ),
                child: Row(
                  children: [
                    _buildHead(chat),
                    const SizedBox(width: 10),
                    _buildName(chat),
                  ],
                ),
              );
            }),
            index == controller.filterChatList.length - 1
                ? const SizedBox()
                : const Padding(
                    padding: EdgeInsets.only(left: 80.0),
                    child: CustomDivider(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHead(Chat chat) {
    return Stack(
      children: [
        chat.typ == chatTypeSaved
            ? ForegroundOverlayEffect(
                overlayColor: colorTextPrimary.withOpacity(0.3),
                radius: const BorderRadius.vertical(
                  top: Radius.circular(100),
                  bottom: Radius.circular(100),
                ),
                child: const SavedMessageIcon(
                  size: 60,
                ),
              )
            : ForegroundOverlayEffect(
                overlayColor: colorTextPrimary.withOpacity(0.3),
                radius: const BorderRadius.vertical(
                  top: Radius.circular(100),
                  bottom: Radius.circular(100),
                ),
                child: CustomAvatar.chat(
                  key: ValueKey(chat.isGroup ? chat.id : chat.friend_id),
                  chat,
                  size: 60,
                  headMin: Config().headMin,
                ),
              ),
        Positioned(
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: CheckTickItem(
              key: ValueKey("share_chat_${chat.id}"),
              isCheck: controller.selectedChatList.contains(chat),
              showUnCheckbox: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildName(Chat chat) {
    return Expanded(
      child: chat.typ == chatTypeSaved
          ? Text(
              chat.name,
              style: jxTextStyle.textStyleBold16(
                fontWeight: MFontWeight.bold6.value,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            )
          : NicknameText(
              uid: chat.isGroup ? chat.id : chat.friend_id,
              isGroup: chat.isGroup,
              isTappable: false,
              overflow: TextOverflow.ellipsis,
              fontSize: MFontSize.size16.value,
              fontWeight: MFontWeight.bold6.value,
              maxLine: 2,
            ),
    );
  }

  Widget _getSelectedAvatar() {
    List<Chat> selectedChats = controller.selectedChatList;
    if (selectedChats.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      width: (24 *
              (selectedChats.length < 3
                  ? selectedChats.length == 1
                      ? 1.5
                      : selectedChats.length
                  : 3))
          .toDouble(),
      height: 24.0,
      child: Stack(
        children: List.generate(selectedChats.length, (index) {
          if (index > 2) {
            return const SizedBox();
          }

          if (index == 2) {
            return Positioned(
              left: index == 0 ? 0 : (16 * index).toDouble(),
              top: 0.0,
              child: ClipOval(
                child: Stack(
                  children: [
                    Container(
                      color: Colors.white,
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Text(
                        "+${selectedChats.length - 2}",
                        style: jxTextStyle.textStyle10(color: themeColor),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: themeColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Positioned(
            left: index == 0 ? 0 : (16 * index).toDouble(),
            top: 0.0,
            child: selectedChats[index].isSaveMsg
                ? const SavedMessageIcon(
                    size: 24,
                  )
                : CustomAvatar.chat(
                    key: ValueKey(
                      selectedChats[index].isGroup
                          ? selectedChats[index].id
                          : selectedChats[index].friend_id,
                    ),
                    selectedChats[index],
                    size: 24,
                    headMin: Config().headMin,
                  ),
          );
        }),
      ),
    );
  }

  Widget _getSelectedName() {
    return Expanded(
      child: Text(
        controller.getSelectedName(),
        style: jxTextStyle.textStyle12(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String setFilterUsername(String text) {
    String username = text;
    if (text.length > 7) {
      username = "${text.substring(0, 7)}...";
    }
    return username;
  }

  Widget _buildCaptionTextField() {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 120,
          minHeight: 40,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorBackground6,
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller.captionController,
          focusNode: controller.captionFocus,
          scrollPhysics: const ClampingScrollPhysics(),
          maxLines: 20,
          minLines: 1,
          maxLength: 4096,
          style: TextStyle(
            fontSize: MFontSize.size17.value,
            decoration: TextDecoration.none,
            color: colorTextPrimary,
            height: 1.3,
            textBaseline: TextBaseline.alphabetic,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: localized(enterMessage),
            hintStyle: const TextStyle(
              color: colorTextSupporting,
            ),
            suffixIconConstraints: const BoxConstraints(maxHeight: 48),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: InputBorder.none,
          ),
          buildCounter: (
            BuildContext context, {
            required int currentLength,
            required int? maxLength,
            required bool isFocused,
          }) {
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () {
        // controller.onSend();
      },
      behavior: HitTestBehavior.translucent,
      child: ForegroundOverlayEffect(
        radius: const BorderRadius.vertical(
          top: Radius.circular(100),
          bottom: Radius.circular(100),
        ),
        overlayColor: colorTextPrimary.withOpacity(0.3),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: SvgPicture.asset(
            'assets/svgs/send.svg',
            width: 16,
            height: 16,
          ),
        ),
      ),
    );
  }
}
