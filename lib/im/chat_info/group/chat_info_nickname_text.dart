import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class ChatInfoNicknameText extends StatelessWidget {
  final int? uid;
  final int? chatType;
  final double size;
  final bool? showIcon;
  final bool? showEncrypted;

  const ChatInfoNicknameText({
    this.uid = -1,
    this.chatType,
    required this.size,
    this.showIcon = false,
    this.showEncrypted = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    String name = getSpecialChatName(chatType);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Visibility(
          visible: showEncrypted == true,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: SvgPicture.asset(
              'assets/svgs/chatroom_icon_encrypted.svg',
              width: size,
              height: size,
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose, //佔用最小空間
          child: NicknameText(
            textAlign: TextAlign.center,
            uid: uid ?? -1,
            isGroup: chatType != null && chatType == chatTypeGroup,
            fontSize: size,
            fontWeight: MFontWeight.bold6.value,
            overflow: TextOverflow.ellipsis,
            isTappable: false,
            displayName: name,
          ),
        ),
        Visibility(
          visible: showIcon == true,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SvgPicture.asset(
              'assets/svgs/secretary_check_icon.svg',
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(
                themeColor,
                BlendMode.srcIn,
              ),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ],
    );
  }
}
