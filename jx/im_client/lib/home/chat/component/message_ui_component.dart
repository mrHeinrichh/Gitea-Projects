import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/home/chat/component/message_ui_base.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/home/chat/controllers/message_item_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class MessageUIComponent extends MessageUIBase<MessageItemController> {
  final double _maxChatCellHeight = 76;

  const MessageUIComponent({
    super.key,
    required super.chat,
    required super.message,
    required super.searchText,
  });

  @override
  Widget build(BuildContext context) {
    return createItemView(context);
  }

  @override
  Widget createItemView(BuildContext context) {
    return OverlayEffect(
      child: Container(
        padding: jxDimension.messageCellPadding(),
        height: _maxChatCellHeight,
        child: Row(
          children: [
            /// 頭像
            Padding(
              padding: const EdgeInsets.only(
                left: 2.0,
                right: 10.0,
              ),
              child: buildHeadView(context),
            ),

            /// 內容
            Expanded(
              child: Container(
                height: _maxChatCellHeight,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    titleBuilder(context),
                    const SizedBox(height: 4.0),
                    contentBuilder(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildHeadView(BuildContext context) {
    return CustomAvatar.chat(
      key: ValueKey('${chat.id}_${Config().headMin}_24'),
      chat,
      size: jxDimension.chatListAvatarSize(),
      headMin: Config().headMin,
      fontSize: 24.0,
      shouldAnimate: false,
    );
  }

  Widget titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: buildNameView(context)),
        const SizedBox(width: 12.0),
        buildTimeView(context),
      ],
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Row(
      children: <Widget>[
        Visibility(
          visible: chat.isEncrypted,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: SvgPicture.asset(
              'assets/svgs/chat_icon_encrypted.svg',
              width: 16,
              height: 16,
            ),
          ),
        ),
        if (chat.isChatTypeMiniApp)
          Flexible(
            child: Text(
              chat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: MFontWeight.bold5.value,
                fontSize: MFontSize.size17.value,
                color: colorTextPrimary.withOpacity(1),
                decoration: TextDecoration.none,
                letterSpacing: 0,
                overflow: TextOverflow.ellipsis,
                height: 1.2,
              ),
            ),
          )
        else
          Flexible(
            child: NicknameText(
              uid: chat.isSingle ? chat.friend_id : chat.id,
              displayName: chat.name,
              fontSize: MFontSize.size17.value,
              fontWeight: MFontWeight.bold5.value,
              color: colorTextPrimary.withOpacity(1),
              isTappable: false,
              isGroup: chat.isGroup,
              overflow: TextOverflow.ellipsis,
              fontSpace: 0,
            ),
          ),
        if (chat.isTmpGroup)
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: SvgPicture.asset(
              'assets/svgs/temporary_indicator.svg',
              width: 16,
              height: 16,
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                themeColor,
                BlendMode.srcIn,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget buildTimeView(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (chat.showMessageReadIcon &&
            message.hasReadView &&
            message.sendState == MESSAGE_SEND_SUCCESS &&
            objectMgr.userMgr.isMe(message.send_id))
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: SvgPicture.asset(
              chat.other_read_idx >= message.chat_idx && message.isSendOk
                  ? 'assets/svgs/done_all_icon.svg'
                  : 'assets/svgs/unread_tick_icon.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                colorReadColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        if (message.create_time > 0)
          Text(
            FormatTime.chartTime(
              message.create_time,
              true,
              todayShowTime: true,
              dateStyle: DateStyle.MMDDYYYY,
            ),
            style: jxTextStyle
                .headerSmallText(color: colorTextSecondary)
                .useSystemChineseFont(),
          ),
      ],
    );
  }

  Widget contentBuilder(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: buildContentView(context)),
      ],
    );
  }

  @override
  Widget buildContentView(BuildContext context) {
    return ChatCellContentFactory.createComponent(
      chat: chat,
      lastMessage: message,
      messageSendState: message.sendState,
      searchText: searchText ?? '',
    );
  }
}
