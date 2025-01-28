import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

class ChatCategorySelection extends StatefulWidget {
  final bool isInclude;
  final List<Chat>? includedChatList;
  final List<Chat> allChat;

  const ChatCategorySelection({
    super.key,
    required this.isInclude,
    this.includedChatList,
    required this.allChat,
  });

  @override
  State<ChatCategorySelection> createState() => _ChatCategorySelectionState();
}

class _ChatCategorySelectionState extends State<ChatCategorySelection> {
  final TextEditingController searchController = TextEditingController();

  final RxList<Chat> localAllChats = <Chat>[].obs;
  final RxList<Chat> selectedChatList = <Chat>[].obs;

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final RxBool isSearching = false.obs;
  final RxString searchParam = "".obs;

  @override
  void initState() {
    super.initState();

    localAllChats.assignAll(widget.allChat);

    if (widget.includedChatList?.isNotEmpty ?? false) {
      selectedChatList.assignAll(
        widget.includedChatList!.where((c) => c.chat_id != -1).toList(),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onSearchTap() => isSearching.value = !isSearching.value;

  void _onSearchChanged(String value) {
    searchParam.value = value.toLowerCase();
    _debouncer.call(() => _onSearchLocal());
  }

  void _onSearchLocal() {
    final searchedList = widget.allChat.where((chat) {
      if (chat.isSingle) {
        final alias = objectMgr.userMgr.getUserTitle(
          objectMgr.userMgr.getUserById(chat.friend_id),
        );
        return alias.toLowerCase().contains(searchParam.value);
      } else if (chat.isSystem) {
        return localized(chatSystem).toLowerCase().contains(searchParam.value);
      } else if (chat.isSecretary) {
        return localized(chatSecretary)
            .toLowerCase()
            .contains(searchParam.value);
      } else if (chat.isSaveMsg) {
        return localized(homeSavedMessage)
            .toLowerCase()
            .contains(searchParam.value);
      }
      return chat.name.toLowerCase().contains(searchParam.value);
    }).toList();

    localAllChats.assignAll(searchedList);
  }

  void _onChatSelect(Chat chat) {
    if (selectedChatList.contains(chat)) {
      selectedChatList.remove(chat);
    } else {
      selectedChatList.add(chat);
    }
  }

  void _onDoneTap() {
    Get.back(result: selectedChatList);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      height: MediaQuery.of(context).size.height * 0.94,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  child: Text(
                    widget.isInclude
                        ? localized(chatCategoryIncludedChatRoom)
                        : localized(chatCategoryExcludedChatRoom),
                    key: UniqueKey(),
                    textAlign: TextAlign.center,
                    style: jxTextStyle.appTitleStyle(
                      color: colorTextPrimary,
                    ),
                  ),
                ),
                Positioned(
                  left: 0.0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 24,
                        ),
                        child: Text(
                          localized(buttonBack),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0.0,
                  child: GestureDetector(
                    onTap: _onDoneTap,
                    child: OpacityEffect(
                      child: Container(
                        padding: const EdgeInsets.only(right: 16.0),
                        alignment: Alignment.centerRight,
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              color: colorBackground,
              padding: const EdgeInsets.symmetric(
                vertical: 9.0,
                horizontal: 16.0,
              ),
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Obx(
                  () => Wrap(
                    children: <Widget>[
                      ...List.generate(
                        selectedChatList.length,
                        (index) {
                          final chat = selectedChatList[index];
                          return _buildSelectedChatItem(context, chat);
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          onTap: _onSearchTap,
                          controller: searchController,
                          onChanged: _onSearchChanged,
                          cursorColor: themeColor,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: localized(chatCategorySearchChatRoom),
                            hintStyle: jxTextStyle.textStyle14(
                              color: colorTextSupporting,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const CustomDivider(),
          Expanded(
            child: ColoredBox(
              color: colorWhite,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Container(
                        color: colorTextPrimary.withOpacity(0.03),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localized(chatCategoryChatRoom),
                          style: jxTextStyle.textStyle13(
                            color: colorTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final chat = localAllChats[index];
                            return _buildChatDisplayItem(context, chat);
                          },
                          childCount: localAllChats.length,
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
  }

  Widget _buildSelectedChatItem(BuildContext context, Chat chat) {
    Widget avatar = const SizedBox(width: 22.0, height: 22.0);
    Widget name = const SizedBox();
    if (chat.isSystem) {
      avatar = const SystemMessageIcon(size: 22);
      name = Text(
        localized(chatSystem),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: MFontSize.size14.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (chat.isSaveMsg) {
      avatar = const SavedMessageIcon(size: 22);
      name = Text(
        localized(homeSavedMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: MFontSize.size14.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (chat.isSecretary) {
      avatar = const SecretaryMessageIcon(size: 22);
      name = Text(
        localized(chatSecretary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: MFontSize.size14.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else {
      avatar = CustomAvatar.chat(
        chat,
        size: 22,
        headMin: Config().headMin,
      );
      name = NicknameText(
        uid: chat.isSingle ? chat.friend_id : chat.id,
        displayName: chat.name,
        fontSize: MFontSize.size14.value,
        color: colorTextPrimary,
        isTappable: false,
        isGroup: chat.isGroup,
        overflow: TextOverflow.ellipsis,
        fontSpace: 0,
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        right: 8.0,
        bottom: 8.0,
      ),
      padding: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: colorTextPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20.0),
      ),
      constraints: const BoxConstraints(maxWidth: 150.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: avatar,
          ),
          const SizedBox(width: 4.0),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: name,
          ),
        ],
      ),
    );
  }

  Widget _buildChatDisplayItem(BuildContext context, Chat chat) {
    Widget avatar = const SizedBox(width: 40.0, height: 40.0);
    Widget name = const SizedBox();
    if (chat.isSystem) {
      avatar = const SystemMessageIcon(size: 40);
      name = Text(
        localized(chatSystem),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (chat.isSaveMsg) {
      avatar = const SavedMessageIcon(size: 40);
      name = Text(
        localized(homeSavedMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (chat.isSecretary) {
      avatar = const SecretaryMessageIcon(size: 40);
      name = Text(
        localized(chatSecretary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    }else if(chat.isChatTypeMiniApp){
      avatar = CustomAvatar.chat(
        chat,
        size: 40,
        headMin: Config().headMin,
      );
      name = Text(
        chat.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else {
      avatar = CustomAvatar.chat(
        chat,
        size: 40,
        headMin: Config().headMin,
      );
      name = NicknameText(
        uid: chat.isSingle ? chat.friend_id : chat.id,
        displayName: chat.name,
        fontSize: MFontSize.size17.value,
        fontWeight: MFontWeight.bold5.value,
        color: colorTextPrimary,
        isTappable: false,
        isGroup: chat.isGroup,
        overflow: TextOverflow.ellipsis,
        fontSpace: 0,
      );
    }

    return GestureDetector(
      onTap: () => _onChatSelect(chat),
      child: OverlayEffect(
        child: SizedBox(
          height: 48.0,
          child: Row(
            children: <Widget>[
              Obx(
                () => Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: CheckTickItem(
                    circleSize: 24.0,
                    isCheck: selectedChatList.contains(chat),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    avatar,
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorTextPrimary.withOpacity(0.2),
                              width: 0.33,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            name,

                            // todo: 相同聊天室文件夹展示
                          ],
                        ),
                      ),
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
}
