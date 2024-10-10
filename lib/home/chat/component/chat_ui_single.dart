import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_ui_component.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class ChatUiSingle extends ChatUIComponent {
  const ChatUiSingle({
    super.key,
    required super.chat,
    required super.index,
    required super.animation,
    required super.tag,
  });

  @override
  Widget buildHeadView(BuildContext context) {
    final enableAudio = chat.enableAudioChat.value;

    return Stack(
      children: <Widget>[
        CustomAvatar.chat(
          key: ValueKey('chat_single_avatar_${chat.id}'),
          chat,
          size: jxDimension.chatListAvatarSize(),
          headMin: Config().headMin,
          fontSize: 24.0,
          shouldAnimate: false,
        ),
        if (controller.autoDeleteInterval.value > 0 && !enableAudio)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: colorTextPlaceholder,
                shape: BoxShape.circle,
              ),
              height: 20,
              width: 20,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/svgs/icon_auto_delete.svg',
                    fit: BoxFit.contain,
                    height: 19,
                    width: 19,
                  ),
                  Text(
                    parseAutoDeleteInterval(
                      controller.autoDeleteInterval.value,
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: MFontWeight.bold6.value,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (controller.isOnline.value && !enableAudio)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              height: 16,
              width: 16,
            ),
          )
        else if (enableAudio)
          Positioned(
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/svgs/agora_mark_icon.svg',
              width: 20,
              height: 20,
            ),
          ),
      ],
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Obx(
      () => Row(
        children: <Widget>[
          if (chat.isEncrypted)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: SvgPicture.asset(
                'assets/svgs/chat_icon_encrypted.svg',
                width: 16,
                height: 16,
              ),
            ),
          Flexible(
            child: NicknameText(
              uid: chat.friend_id,
              displayName: chat.name,
              fontSize: MFontSize.size16.value,
              fontWeight: MFontWeight.bold5.value,
              color: colorTextPrimary.withOpacity(1),
              isTappable: false,
              overflow: TextOverflow.ellipsis,
              fontSpace: 0,
            ),
          ),
          if (controller.isMuted.value)
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: SvgPicture.asset(
                'assets/svgs/mute_icon3.svg',
                width: 16,
                height: 16,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }
}
