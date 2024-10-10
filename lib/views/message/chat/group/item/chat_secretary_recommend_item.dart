import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class ChatSecretaryRecommendItem extends StatefulWidget {
  const ChatSecretaryRecommendItem({
    super.key,
    required this.chat,
    required this.message,
    required this.messageSecretary,
  });
  final Chat chat;
  final Message message;
  final MessageSecretaryRecommend messageSecretary;

  @override
  State<ChatSecretaryRecommendItem> createState() =>
      _ChatSecretaryRecommendItemState();
}

class _ChatSecretaryRecommendItemState extends State<ChatSecretaryRecommendItem>
    with MessageWidgetMixin {
  bool _isPush = false;

  _onPush() async {
    if (_isPush) {
      return;
    }
    _isPush = true;
    if (widget.messageSecretary.urlTyp == 1) {
      var urlStr = widget.messageSecretary.url;
      if (!widget.messageSecretary.url.startsWith('http')) {
        urlStr = 'http://${widget.messageSecretary.url}';
      }
      await linkToWebView(urlStr);
    } else {
      if (widget.messageSecretary.page_id == 0) return;
      // pageMgr.openPage(widget.messageSecretary.page_id,
      //     pageArgs: [widget.messageSecretary.page_params]);
    }
    _isPush = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.w, 56.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: SecretaryMessageIcon(size: 32.w)),
          widget.messageSecretary.cover != 0
              ? _buildImageText()
              : _buildNormalText(),
        ],
      ),
    );
  }

  Widget _buildNormalText() {
    return Flexible(
      child: GestureDetector(
        onTap: _onPush,
        child: Container(
          constraints: BoxConstraints(
            minWidth: 38.w,
          ),
          decoration: BoxDecoration(
            color: hexColor(0xF5F5F5),
            borderRadius: BorderRadius.circular(8.w),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
          child: RichText(
            text: TextSpan(
              children: _buildTexts(),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTexts() {
    List<InlineSpan> list = [];
    for (int i = 0; i < widget.messageSecretary.text.length; i++) {
      String itemText = widget.messageSecretary.text[i];
      if (i == (widget.messageSecretary.urlIndex - 1)) {
        list.add(
          BuildTextUtil.buildText(
            itemText,
            themeColor,
            isLink: true,
            isSender: true,
          ),
        );
      } else {
        list.add(
          BuildTextUtil.buildText(
            itemText,
            hexColor(0x161A22),
            isSender: true,
          ),
        );
      }
    }
    return list;
  }

  Widget _buildImageText() {
    return GestureDetector(
      onTap: _onPush,
      child: Container(
        width: 256.w,
        decoration: BoxDecoration(
          color: hexColor(0xF5F5F5),
          borderRadius: BorderRadius.circular(8.w),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 10.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6.w),
              child: RemoteImage(
                src: widget.messageSecretary.cover.toString(),
                width: double.infinity,
                height: 130.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12.w),
            Text(
              widget.messageSecretary.text.join(''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorTextPrimary,
                fontSize: 14.sp,
                height: 1.35,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12.w),
            Container(
              height: 35.w,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 0.5, color: colorWhite),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localized(chatCheckDetails),
                      style: TextStyle(
                        color: colorTextPrimary,
                        fontSize: 12.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/message_new/next_setting.png',
                    width: 20.w,
                    height: 20.w,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
