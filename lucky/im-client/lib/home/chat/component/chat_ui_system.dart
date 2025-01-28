
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_ui_component.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ChatUISystem extends ChatUIComponent {
  ChatUISystem({
    super.key,
    required super.chat,
    required super.tag,
    required super.index,
    required super.animation,
  });

  @override
  Widget buildHeadView(BuildContext context) {
    return SystemMessageIcon(
      size: jxDimension.chatListAvatarSize(),
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Obx(
      () => Row(
        children: <Widget>[
          Flexible(
            child: Text(
              localized(chatSystem),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: MFontWeight.bold5.value,
                fontSize: MFontSize.size16.value,
                color: JXColors.primaryTextBlack.withOpacity(1),
                decoration: TextDecoration.none,
                letterSpacing: 0,
                overflow: TextOverflow.ellipsis,
                height: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SvgPicture.asset(
              'assets/svgs/secretary_check_icon.svg',
              width: 15,
              height: 15,
              color: accentColor,
              fit: BoxFit.fitWidth,
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
