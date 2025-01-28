import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/setting/chat_category_folder/components/chat_category_create_item.dart';
import 'package:jxim_client/setting/chat_category_folder/create/chat_category_selection.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ChatCategoryCreate extends StatefulWidget {
  final ChatCategory? category;

  const ChatCategoryCreate({
    super.key,
    this.category,
  });

  @override
  State<ChatCategoryCreate> createState() => _ChatCategoryCreateState();
}

class _ChatCategoryCreateState extends State<ChatCategoryCreate> {
  late final TextEditingController nameController;

  final RxBool isNameEmpty = true.obs;

  List<Chat> allChat = <Chat>[];

  final RxList<Chat> includedChatList = <Chat>[].obs;

  final RxList<Chat> excludedChatList = <Chat>[].obs;

  bool get isEditMode => widget.category != null;
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.category?.name ?? '');

    isNameEmpty.value = nameController.text.isEmpty;

    includedChatList.add(
      Chat()
        ..name = localized(chatCategoryAddChatRoom)
        ..chat_id = -1,
    );
    excludedChatList.add(
      Chat()
        ..name = localized(chatCategoryAddChatRoom)
        ..chat_id = -1,
    );

    _initChatList();

    nameController.addListener(_inputListener);
    _controller.addListener(() {
      if (_controller.size <= 0.3) {
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_inputListener);

    super.dispose();
  }

  void _inputListener() {
    isNameEmpty.value = nameController.text.isEmpty;
  }

  void _initChatList() async {
    allChat = await getChatList();

    if (widget.category == null) return;

    assert(widget.category != null,
        'Category must not be null when initialize include and exclude chat list');

    if (widget.category!.includedChatIds.isNotEmpty) {
      includedChatList.addAll(allChat.where(
        (c) => widget.category!.includedChatIds.contains(c.chat_id),
      ));
    }

    if (widget.category!.excludedChatIds.isNotEmpty) {
      excludedChatList.addAll(allChat.where(
        (c) => widget.category!.excludedChatIds.contains(c.chat_id),
      ));
    }
  }

  Future<List<Chat>> getChatList() async {
    List<Chat> tempList = objectMgr.chatMgr.getAllChats();
    objectMgr.chatMgr.sortChatList(tempList);
    return tempList;
  }

  void onAddChatRoomTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (ctx) => ChatCategorySelection(
        isInclude: true,
        includedChatList:
            includedChatList.length == 1 ? null : includedChatList,
        allChat: allChat,
      ),
    ).then((result) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (result == null || result is! List<Chat>) return;

      includedChatList.assignAll(result);
      includedChatList.insert(
        0,
        Chat()
          ..name = localized(chatCategoryAddChatRoom)
          ..chat_id = -1,
      );
    });
  }

  void onCreateChatCategory(BuildContext context) async {
    if (nameController.text.trim().isEmpty) {
      imBottomToast(
        context,
        title: localized(chatCategoryCreateNoName),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    // if (includedChatList.isEmpty && excludedChatList.isEmpty) {
    //   im_common.ImBottomToast(
    //     context,
    //     title: '聊天室不能为空',
    //     icon: im_common.ImBottomNotifType.warning,
    //   );
    //   return;
    // }

    // Get all chat category list
    final List<ChatCategory> categoryList = objectMgr.chatMgr.chatCategoryList;

    if (categoryList.length >= 21 && widget.category == null) {
      im_common.ImBottomToast(
        context,
        title: localized(chatCategoryCreateExceedLimit, params: ["20"]),
        icon: im_common.ImBottomNotifType.warning,
      );
      return;
    }

    final List<int> unreadCategoryChatList = <int>[];

    // Create current chat category
    ChatCategory category = ChatCategory();
    if (widget.category != null) {
      final tempCategory =
          categoryList.firstWhereOrNull((c) => c.id == widget.category!.id);
      if (tempCategory != null) {
        category = tempCategory.copyWith();
      } else {
        final maxId = categoryList
            .map((c) => c.id)
            .reduce((value, next) => value > next ? value : next);
        category.id = maxId + 1;
        category.seq = maxId + 1;
      }
      category.name = nameController.text.trim();
      category.includedChatIds = includedChatList
          .where((c) => c.chat_id != -1)
          .map<int>((c) => c.chat_id)
          .toList();
      category.excludedChatIds = excludedChatList
          .where((c) => c.chat_id != -1)
          .map<int>((c) => c.chat_id)
          .toList();
    } else {
      int maxId = 0;
      if (categoryList.isNotEmpty) {
        maxId = categoryList
            .map((c) => c.id)
            .reduce((value, next) => value > next ? value : next);
      }

      category.id = maxId + 1;
      category.seq = maxId + 1;
      category.name = nameController.text.trim();
      category.includedChatIds = includedChatList
          .where((c) => c.chat_id != -1)
          .map<int>((c) => c.chat_id)
          .toList();
      category.excludedChatIds = excludedChatList
          .where((c) => c.chat_id != -1)
          .map<int>((c) => c.chat_id)
          .toList();
      category.createTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    unreadCategoryChatList.assignAll(includedChatList
        .where((c) => c.unread_count > 0)
        .map((c) => c.chat_id)
        .toList());

    objectMgr.chatMgr.updateChatCategory(
      category,
      isCategoryFound: widget.category != null,
      unreadChatListIds: unreadCategoryChatList,
      updateRemote: true,
    );
    // 2. get.back
    Get.back();
  }

  void onDeleteTap(BuildContext context, Chat chat) {
    showCustomBottomAlertDialog(
      context,
      confirmText: localized(buttonDelete),
      cancelText: localized(buttonCancel),
      cancelTextColor: themeColor,
      withHeader: false,
      onConfirmListener: () => includedChatList.remove(chat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.94,
      child: Stack(
        children: <Widget>[
          Container(
            color: colorBackground,
            margin: const EdgeInsets.only(top: 59.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/chat_category_create_icon.png',
                        width: 84.0,
                        height: 84.0,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        localized(chatCategoryFolderName),
                        style: jxTextStyle.normalSmallText(
                            color: colorTextSecondary),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCategoryNameInput(context)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 24.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        localized(chatCategoryIncludedChatRoom),
                        style: jxTextStyle.normalSmallText(
                            color: colorTextSecondary),
                      ),
                    ),
                  ),
                  SlidableAutoCloseBehavior(
                    child: Obx(
                      () => DecoratedSliver(
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final chat = includedChatList[index];
                              if (index == 0 && chat.chat_id == -1) {
                                return _buildAddChatRoom(
                                  context,
                                  chat,
                                );
                              }
                              return ChatCategoryCreateItem(
                                chat: chat,
                                isLast: index + 1 == includedChatList.length,
                                onDeleteTap: (Chat c) =>
                                    onDeleteTap(context, c),
                              );
                            },
                            childCount: includedChatList.length,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 8.0,
                        bottom: 24.0,
                      ),
                      child: Text(
                        localized(chatCategoryIncludedChatSubTitle),
                        style: jxTextStyle.normalSmallText(
                            color: colorTextSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: colorBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned(
                    left: 0.0,
                    right: 0.0,
                    child: Text(
                      isEditMode
                          ? localized(chatCategoryEditFolder)
                          : localized(chatCategoryCreateFolder),
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
                            localized(cancel),
                            style: jxTextStyle.textStyle17(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0.0,
                    child: GestureDetector(
                      onTap: () => onCreateChatCategory(context),
                      child: OpacityEffect(
                        child: Container(
                          padding: const EdgeInsets.only(right: 16.0),
                          alignment: Alignment.centerRight,
                          child: Text(
                            localized(isEditMode ? buttonDone : buttonCreate),
                            style: jxTextStyle.textStyle17(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNameInput(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.multiline,
        controller: nameController,
        inputFormatters: [
          ChineseCharacterInputFormatter(max: 10),
        ],
        style: jxTextStyle.textStyle17(),
        maxLines: 1,
        maxLength: 10,
        buildCounter: (
          BuildContext context, {
          required int currentLength,
          required int? maxLength,
          required bool isFocused,
        }) {
          return null;
        },
        cursorColor: themeColor,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          hintText: localized(chatCategoryHintInput),
          hintStyle: const TextStyle(
            color: colorTextSupporting,
          ),
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: Obx(
            () => isNameEmpty.value
                ? const SizedBox()
                : GestureDetector(
                    onTap: nameController.clear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      child: SvgPicture.asset(
                        'assets/svgs/clear_icon.svg',
                        color: colorTextSecondary,
                        width: 20,
                        height: 20,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddChatRoom(BuildContext context, Chat chat) {
    return GestureDetector(
      onTap: () => onAddChatRoomTap(context),
      child: OverlayEffect(
        radius: BorderRadius.circular(8.0),
        child: Container(
          height: 44.0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 40.0,
                width: 40.0,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/svgs/add.svg',
                  height: 24.0,
                  width: 24.0,
                  colorFilter: ColorFilter.mode(
                    themeColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          chat.name,
                          style: jxTextStyle.textStyle17(
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                    if (includedChatList.length > 1) const CustomDivider(),
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
