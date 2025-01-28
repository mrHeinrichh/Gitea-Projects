import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/message/share/share_chat_data.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/saved_message_icon.dart';
import '../../component/check_tick_item.dart';
import '../../component/custom_alert_dialog.dart';

class ShareChatItem extends StatefulWidget {
  const ShareChatItem({
    Key? key,
    required this.data,
    required this.shareChatData,
  }) : super(key: key);
  final Chat data;
  final ShareChatData shareChatData;

  @override
  _ShareChatItemState createState() => _ShareChatItemState();
}

class _ShareChatItemState extends State<ShareChatItem> {
  _onChoose() {
    List<Chat> _list = [];
    _list.addAll(widget.shareChatData.selectChatList);
    if (widget.shareChatData.judgeSelect(widget.data.id)) {
      _list.remove(widget.data);
    } else {
      if (_list.length >= 9) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: localized(popupSelectContact),
              confirmText: localized(buttonBlock),
              cancelText: localized(buttonConfirm),
              confirmCallback: () {},
            );
          },
        );
        return;
      }

      _list.add(widget.data);
    }
    widget.shareChatData.selectChatList = _list;
  }

  @override
  Widget build(BuildContext context) {
    return createItemView();
  }

  Widget createItemView() {
    return GestureDetector(
      onTap: _onChoose,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(11.w, 17.w, 15.w, 7.w),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 11.w),
              child: _buildSelect(),
            ),
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _buildHeadView(),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _createTitleView(),
                  // Padding(
                  //   padding: EdgeInsets.only(top: 4.w),
                  //   child: _buildContent(),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelect() {
    return EventsWidget(
      data: widget.shareChatData,
      eventTypes: const [ShareChatData.eventSelectChat],
      builder: (context) {
        return ClipRRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            alignment: Alignment.centerLeft,
            curve: Curves.easeInOutCubic,
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.only(right: 8),
              child: CheckTickItem(
                isCheck: widget.shareChatData.judgeSelect(widget.data.id),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildHeadView() {
    if (widget.data.typ == chatTypeSaved) {
      return SavedMessageIcon(size: 52.w);
    } else {
      return CustomAvatar(
        uid: widget.data.typ == chatTypeSingle
            ? widget.data.friend_id
            : widget.data.chat_id,
        size: 52.w,
        isGroup: widget.data.typ == chatTypeGroup ? true : false,
      );
    }
  }

  Widget _createTitleView() {
    return Row(
      children: [
        Container(
            constraints: BoxConstraints(
              maxWidth: 160.w,
            ),
            child: widget.data.typ == chatTypeSaved
            ? Text(
              localized(homeSavedMessage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jxTextStyle.textStyle14(),
            )
            : NicknameText(
              uid: widget.data.isGroup
                  ? widget.data.chat_id
                  : widget.data.friend_id,
              color: JXColors.primaryTextBlack,
              fontSize: MFontSize.size14.value,
              fontWeight: MFontWeight.bold4.value,
              isGroup: widget.data.isGroup,
              isTappable: false,
            )),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}
