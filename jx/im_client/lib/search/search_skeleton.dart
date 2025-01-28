import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:skeletonizer/skeletonizer.dart';

Widget buildSkeleton(BuildContext context, Widget item, double dividerIndent) {
  return Skeletonizer(
    effect: const ShimmerEffect(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      duration: Duration(milliseconds: 2000),
      highlightColor: colorWhite,
    ),
    textBoneBorderRadius: const TextBoneBorderRadius.fromHeightFactor(0.5),
    containersColor: colorBackground3,
    ignorePointers: false,
    enabled: true,
    child: ListView.separated(
      itemCount: MediaQuery.of(context).size.height ~/ 83 + 1,
      itemBuilder: (context, index) {
        return item;
      },
      separatorBuilder: (_, __) =>
          CustomDivider(thickness: 1, indent: dividerIndent),
    ),
  );
}

Widget CircleSkeleton(BuildContext context) {
  return Container(
    height: 76,
    width: MediaQuery.of(context).size.width,
    padding: jxDimension.messageCellPadding(),
    child: Row(
      children: <Widget>[
        Bone.circle(
          indentEnd: 10.0,
          size: jxDimension.chatListAvatarSize(),
        ),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Bone.text(width: 60.0, fontSize: 8.0),
                  Spacer(),
                  Bone.text(width: 30.0, fontSize: 8.0),
                ],
              ),
              SizedBox(height: 12.0),
              Row(
                children: [
                  Bone.text(width: 120.0, fontSize: 8.0),
                  SizedBox(width: 12.0),
                  Bone.text(width: 60.0, fontSize: 8.0),
                ],
              )
            ],
          ),
        ),
      ],
    ),
  );
}

Widget SquareSkeleton(BuildContext context) {
  return Container(
    height: 83,
    width: MediaQuery.of(context).size.width,
    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12, right: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const Bone.square(
            size: 40,
          ),
        ),
        const SizedBox(width: 12.0),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Bone.text(width: 60.0, fontSize: 8.0),
              SizedBox(height: 16.0),
              Bone.text(width: 207, fontSize: 8.0),
              SizedBox(height: 16.0),
              Bone.text(width: 106, fontSize: 8.0),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget VoiceSkeleton(BuildContext context) {
  return Container(
    height: 60,
    width: MediaQuery.of(context).size.width,
    padding: const EdgeInsets.only(top: 8, bottom: 12, left: 12),
    child: const Row(
      children: <Widget>[
        Bone.circle(
          indentEnd: 12.0,
          size: 40,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Bone.text(width: 60.0, fontSize: 8.0),
              SizedBox(height: 12.0),
              Bone.text(width: 207.0, fontSize: 8.0)
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildIcon(Chat chat, double size) {
  if (chat.isSecretary) {
    return SecretaryMessageIcon(
      size: size,
    );
  } else if (chat.isSaveMsg) {
    return SavedMessageIcon(
      size: size,
    );
  } else if (chat.isSystem) {
    return SystemMessageIcon(
      size: size,
    );
  } else {
    return CustomAvatar.chat(
      key: ValueKey('${chat.id}_${Config().headMin}_24'),
      chat,
      size: size,
      headMin: Config().headMin,
      fontSize: 24,
      shouldAnimate: false,
    );
  }
}

Widget buildChatName(Chat chat, double fontSize, FontWeight fontWeight,
    int maxLine, String searchText) {
  String title = chat.name;
  if (chat.isSpecialChat) {
    if (chat.isSecretary) {
      title = localized(chatSecretary);
    } else if (chat.isSystem) {
      title = localized(chatSystem);
    } else if (chat.isSaveMsg) {
      title = localized(homeSavedMessage);
    }
  }

  return RichText(
    maxLines: maxLine,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    text: TextSpan(
      children: getHighlightSpanList(
        title,
        searchText,
        TextStyle(
          color: colorTextPrimary,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: appFontFamily,
        ),
      ),
    ),
  );
}
