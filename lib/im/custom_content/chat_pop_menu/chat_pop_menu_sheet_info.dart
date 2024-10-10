import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_menu_effect.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/utils/lang_util.dart';

class ChatPopMenuSheetInfo extends StatefulWidget {
  final Message message;
  final Chat chat;
  final int sendID;
  final List<MessagePopupOption> options;
  final ChatPopMenuSheetSubType chatPopMenuSheetSubType;
  final ValueChanged<String>? menuClick;

  const ChatPopMenuSheetInfo({
    super.key,
    required this.message,
    required this.chat,
    required this.sendID,
    this.options = const [],
    this.chatPopMenuSheetSubType = ChatPopMenuSheetSubType.none,
    this.menuClick,
  });

  static List<ToolOptionModel> getFilteredOptionList(
    Message message,
    Chat chat, {
    ChatPopMenuSheetSubType chatPopMenuSheetSubType =
        ChatPopMenuSheetSubType.none,
  }) {
    List<ToolOptionModel> originalOptionList = [
      ToolOptionModel(
        title: localized(findInChat),
        optionType: MessagePopupOption.findInChat.optionType,
        imageUrl: 'assets/svgs/menu_findInChat.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(forward),
        optionType: MessagePopupOption.forward.optionType,
        imageUrl: 'assets/svgs/menu_forward.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(delete),
        optionType: MessagePopupOption.delete.optionType,
        imageUrl: 'assets/svgs/menu_bin.svg',
        color: colorRed,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
        subOptions: [
          ToolOptionModel(
            title: localized(deleteForEveryone),
            optionType: DeletePopupOption.deleteForEveryone.optionType,
            largeDivider: false,
            color: colorRed,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(deleteForMe),
            optionType: DeletePopupOption.deleteForMe.optionType,
            color: colorRed,
            largeDivider: false,
            isShow: true,
            tabBelonging: 1,
          ),
        ],
      ),
    ];

    return originalOptionList.map<ToolOptionModel>((e) {
      return e;
    }).toList();
  }

  /// 长按计算坐标使用
  static double getMenuHeight(
    Message message,
    Chat chat, {
    bool extr = true,
    List<MessagePopupOption> options = const [],
    ChatPopMenuSheetSubType chatPopMenuSheetSubType =
        ChatPopMenuSheetSubType.none,
  }) {
    List<ToolOptionModel> optionList =
        ChatPopMenuSheetInfo.getFilteredOptionList(
      message,
      chat,
      chatPopMenuSheetSubType: chatPopMenuSheetSubType,
    );
    if (options.isNotEmpty) {
      optionList = optionList
          .where(
            (element) =>
                options.any((opt) => opt.optionType == element.optionType),
          )
          .toList();
    }

    double menuHeight = 0;
    for (int i = 0; i < optionList.length; i++) {
      ToolOptionModel toolOptionModel = optionList[i];
      if (toolOptionModel.isShow) {
        menuHeight = 44 + menuHeight;
      }
    }

    if (extr) {
      menuHeight = 51 + menuHeight + 51;
    }

    return menuHeight;
  }

  @override
  State<ChatPopMenuSheetInfo> createState() => _ChatPopMenuSheetState();
}

class _ChatPopMenuSheetState extends State<ChatPopMenuSheetInfo> {
  final isMobile = objectMgr.loginMgr.isMobile;

  /// ============================== 消息长按 配置 ===============================
  List<ToolOptionModel> optionList = [];
  bool isSubList = false, _hasSelect = true;
  bool _isSend = false;
  int touchIndex = -1;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    optionList = ChatPopMenuSheetInfo.getFilteredOptionList(
      widget.message,
      widget.chat,
      chatPopMenuSheetSubType: widget.chatPopMenuSheetSubType,
    );
    if (widget.options.isNotEmpty) {
      optionList = optionList
          .where(
            (element) => widget.options
                .any((opt) => opt.optionType == element.optionType),
          )
          .toList();
      _hasSelect = widget.options.any(
        (opt) => opt.optionType == MessagePopupOption.select.optionType,
      ); // when list involved select
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onTapSecondMenu(ToolOptionModel option, Message message) {
    switch (option.optionType) {
      case 'deleteForEveryone':
      case 'deleteForMe':
        if (_isSend) {
          return;
        }
        _isSend = true;
        widget.menuClick?.call(option.optionType);
        if (widget.chat.isGroup) {
          groupInfoController?.onDeleteOptionTap(
            context,
            option.optionType,
            msg: widget.message,
          );
        } else {
          chatInfoController?.onDeleteOptionTap(
            context,
            option.optionType,
            msg: widget.message,
          );
        }
        break;
      default:
        break;
    }
  }

  void onClick(String title) async {
    EasyDebounce.debounce(
        'chat_pop_menu_sheet_click', const Duration(milliseconds: 200),
        () async {
      if (_selectedMore(title)) {
        return;
      }

      final ToolOptionModel option = optionList.firstWhere((element) {
        return element.optionType == title;
      });

      if (isSubList) {
        onTapSecondMenu(option, widget.message);
        isSubList = false;
        return;
      }

      /// 获取到指定的option
      if (option.hasSubOption) {
        final List<ToolOptionModel>? subList;
        if (widget.chat.isGroup) {
          groupInfoController?.getDeleteOptionsList(widget.message);
          subList = groupInfoController?.deleteOptions;
        } else {
          chatInfoController?.getDeleteOptionsList(widget.message);
          subList = chatInfoController?.deleteOptions;
        }
        optionList = subList!;
        isSubList = true;
        setState(() {});
      } else {
        /// 实现对应逻辑
        switch (title) {
          case 'findInChat':
            _findInChatAction();
            break;
          case 'forward': //转发
            await _forwardAction();
            break;
        }
      }
    });
  }

  bool _selectedMore(String title) {
    if (title == MessagePopupOption.select.optionType) {
      if (widget.chat.isGroup) {
        groupInfoController?.onMoreSelect.value = true;
        groupInfoController?.selectedMessageList.add(widget.message);
      } else {
        chatInfoController?.onMoreSelect.value = true;
        chatInfoController?.selectedMessageList.add(widget.message);
      }
      widget.menuClick?.call('select');
      return true;
    }
    return false;
  }

  void _findInChatAction() {
    widget.menuClick?.call('findInChat');

    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.chat.isGroup) {
        dynamic msg = widget.message;
        if (msg is Message) {
          groupInfoController?.onMoreSelectCallback!(msg);
        } else if (msg is AlbumDetailBean) {
          groupInfoController?.onMoreSelectCallback!(msg.currentMessage);
        } else {
          throw "不知道的类型数据";
        }
      } else {
        chatInfoController?.onMoreSelectCallback!(widget.message);
      }
    });
  }

  Future<void> _forwardAction() async {
    widget.menuClick?.call('forward');
    if (widget.chat.isGroup) {
      groupInfoController?.onForwardMessageMenu(context, widget.message);
    } else {
      chatInfoController?.onForwardMessageMenu(context, widget.message);
    }
  }

  int getMenuNum() {
    int num = optionList.length;
    return num + 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.only(
          left: objectMgr.userMgr.isMe(widget.message.send_id) ||
                  widget.chat.isSingle
              ? 0
              : 40,
        ),
        width: 240,
        child: ChatPopMenuSheetMenuEffect(
          num: getMenuNum(),
          index: touchIndex,
          isShowSeen: false,
          isShowMore: true,
          itemTouch: (index) {
            setState(() {
              touchIndex = index;
            });
          },
          itemTouchEnd: (index) {
            if (index < 0 || index >= getMenuNum()) {
              return;
            }
            if (index == (getMenuNum() - 1)) {
              // 最后一个是否是更多，点击
              onClick(MessagePopupOption.select.optionType);
            } else {
              onClick(optionList[index].optionType);
            }
            touchIndex = -1;
          },
          child: Container(
            decoration: jxDimension.chatPopMenuDecoration(),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: optionList.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (optionList[index].isShow == false) {
                      return const SizedBox();
                    }
                    final Widget childWidget = OverlayEffectMenu(
                      isHighLight: index == touchIndex,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: optionList[index].optionType == 'delete' ||
                                    (optionList.length - 1) == index
                                ? BorderSide.none
                                : BorderSide(
                                    color: colorBorder,
                                    width: (optionList[index].largeDivider !=
                                                null &&
                                            optionList[index].largeDivider!)
                                        ? 5.0
                                        : 1.0,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                optionList[index].title,
                                style: jxTextStyle.textStyle17(
                                  color: optionList[index].color ?? themeColor,
                                ),
                              ),
                            ),
                            if (optionList[index].icon != null)
                              Icon(
                                optionList[index].icon,
                                color: optionList[index].color ?? themeColor,
                                size: 24.0,
                              ),
                            if (optionList[index].imageUrl != null)
                              SvgPicture.asset(
                                optionList[index].imageUrl!,
                                width: 24,
                                height: 24,
                                color: optionList[index].color ?? themeColor,
                              ),
                          ],
                        ),
                      ),
                    );
                    if (isMobile) {
                      return GestureDetector(
                        onTap: () => onClick(optionList[index].optionType),
                        child: childWidget,
                      );
                    } else {
                      return ElevatedButtonTheme(
                        data: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: colorBorder,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0.0,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            onClick(optionList[index].optionType);
                          },
                          child: childWidget,
                        ),
                      );
                    }
                  },
                ),
                if (!isSubList && _hasSelect)
                  GestureDetector(
                    onTap: () => onClick(MessagePopupOption.select.optionType),
                    child: OverlayEffectMenu(
                      isHighLight: touchIndex == getMenuNum() - 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorBorder,
                              width: 7.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              widget.message.typ == messageTypeNewAlbum
                                  ? localized(chatOptionsSelectAll)
                                  : localized(select),
                              style: jxTextStyle.textStyle16(
                                color: colorTextPrimary,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/svgs/menu_select.svg',
                              width: 24,
                              height: 24,
                              color: colorTextPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
