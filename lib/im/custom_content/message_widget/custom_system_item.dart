import 'package:flutter/cupertino.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CustomSystemItem extends StatelessWidget {
  const CustomSystemItem({
    super.key,
    required this.message,
  });
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: jxDimension.systemMessageMargin(context),
        padding: jxDimension.systemMessagePadding(),
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          color: colorTextSupporting,
        ),
        child: Text(
            message.typ == messageTypeInBlock
              ? localized(needRemoveBlackList)
              : localized(messageSentButRejected),
          style: jxTextStyle.textStyle12(
            color: colorWhite,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}