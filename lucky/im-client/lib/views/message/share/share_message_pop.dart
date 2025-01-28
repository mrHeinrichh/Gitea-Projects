import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/message/chat/custom_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/theme/text_styles.dart';


class ShareMessagePop extends StatefulWidget {
  ShareMessagePop({
    Key? key,
    required this.title,
    required this.chatList,
    required this.onSend,
  }) : super(key: key);
  final String title;
  final List<Chat> chatList;
  final Function(String msg) onSend;

  @override
  State<ShareMessagePop> createState() => _ShareMessagePopState();
}

class _ShareMessagePopState extends State<ShareMessagePop> {
  final TextEditingController _textEditingController = TextEditingController();

  _send() {
    Get.back();
    widget.onSend(_textEditingController.text.isNotEmpty
        ? _textEditingController.text
        : '');
  }

  _close() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: EdgeInsets.only(left: 38.w, right: 38.w),
          padding:
              EdgeInsets.only(left: 20.w, right: 20.w, top: 24.w, bottom: 24.w),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localized(chatCardSend),
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                    height: 1,
                    decoration: TextDecoration.none,
                    fontWeight: MFontWeight.bold6.value),
              ),

              SizedBox(height: 12.w),
              //用户数据
              widget.chatList.length == 1 ? userData() : _userDataList(),
              SizedBox(height: 20.w),
              _relayType(),
              SizedBox(height: 24.w),
              //文本框
              textField(),
              SizedBox(height: 32.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 96.w,
                        height: 40.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: colorF7F7F7,
                            borderRadius: BorderRadius.circular(100.r)),
                        child:Text(
                          localized(chatCardSendCancel),
                          style: jxTextStyle.textStyleBold14(
                            color: color666666,
                            fontWeight: MFontWeight.bold6.value
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    CustomGradientButton(
                      onPress: _send,
                      width: 96.w,
                      height: 40.w,
                      gradientColor: [accentColor, accentColor],
                      textColor: Colors.white,
                      fontSize: 14.sp,
                      radius: 100.r,
                      title: localized(chatCardSendSend),
                      fontWeight: MFontWeight.bold6.value,
                      enable: true,
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

  Widget userData() {
    Chat _chat = widget.chatList.first;
    return Row(
      children: [
        _buildUserDataHead(_chat),
        SizedBox(width: 13.w),
        Expanded(
          child: Text(
            _chat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              color: color1A1A1A,
              height: 1.2,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDataHead(Chat chat) {
    // if (chat.typ == chatTypeDiscuss && chat.icons.isNotEmpty) {
    //   return CustomNineGridView(icons: chat.icons, size: 52.w);
    // } else {
    // }
    return CustomAvatar(
      uid: chat.typ == chatTypeSingle ? chat.friend_id : chat.chat_id,
      size: 52.w,
      isGroup: chat.typ == chatTypeGroup ? true : false,
    );
  }

  Widget _userDataList() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.chatList.length,
      padding: EdgeInsets.all(0.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1,
          crossAxisCount: 5,
          crossAxisSpacing: 5.w,
          mainAxisSpacing: 5.w),
      itemBuilder: _buildHeadView,
    );
  }

  Widget _buildHeadView(context, index) {
    return CustomAvatar(
      uid: widget.chatList[index].typ == chatTypeSingle
          ? widget.chatList[index].friend_id
          : widget.chatList[index].chat_id,
      size: 52.w,
      isGroup: widget.chatList[index].typ == chatTypeGroup ? true : false,
    );
  }

  Widget textField() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 38.w,
        decoration: BoxDecoration(
          color: colorF7F7F7,
          borderRadius: BorderRadius.circular(5.w),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          contextMenuBuilder: textMenuBar,
          controller: _textEditingController,
          autofocus: false,
          cursorColor: color1A1A1A,
          style: TextStyle(
            color: color1A1A1A,
            fontSize: 14.sp,
            height: 1.2,
            decoration: TextDecoration.none,
          ),
          maxLength: 200,
          maxLines: null,
          decoration: InputDecoration(
            hintText: localized(chatCardSendNoteHint),
            hintStyle:
                TextStyle(color: colorB3B3B3, fontSize: 14.sp, height: 1),
            counterText: "",
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.fromLTRB(8.w, 0.0, 8.w, 0.0),
          ),
        ),
      ),
    );
  }

  Widget _relayType() {
    return Container(
      child: Text(
        widget.title,
        style: TextStyle(
            color: color999999,
            fontSize: 12.sp,
            height: 1,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.normal),
      ),
    );
  }
}
