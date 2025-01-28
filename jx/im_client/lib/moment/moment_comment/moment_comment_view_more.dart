import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class MomentCommentViewMore extends StatelessWidget {
  final String name;
  final String content;

  const MomentCommentViewMore({
    super.key,
    required this.name,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        withBackTxt: false,
        backButtonColor: colorTextPrimary,
        bgColor: colorBackground,
        centerTitle: true,
        leadingWidth: 28,
        titleWidget: Text(
          "$name ${localized(momentComment)}",
          style: jxTextStyle.textStyleBold17(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Container(
          padding:
              const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
          width: MediaQuery.of(context).size.width,
          child: Text(
            content,
          ),
        ),
      ),
    );
  }
}
