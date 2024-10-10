import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:simple_shadow/simple_shadow.dart';

enum ReelEditTypeEnum { nickname, bio }

final reelUtils = ReelUtils();

class ReelUtils {
  getToastAlignment() {
    switch (Get.currentRoute) {
      case RouteName.reel:
        return const Alignment(0.0, 0.8);
      default:
        return null;
    }
  }

  void hasTextOverflow({
    required String text,
    required TextStyle style,
    double minWidth = 0,
    double maxWidth = double.infinity,
    int maxLines = 2,
    required void Function(bool) isTxtOverflowing,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isTxtOverflowing(textPainter.didExceedMaxLines);
    });
  }

  getDescTagsTxtSize({required String descTxt, tags}) {
    var tagsTxt = descTxt;
    for (var i = 0; i < tags.length; i++) {
      tagsTxt += ' #${tags[i]}';
    }
    return tagsTxt;
  }

  reelShadow({child}) {
    return SimpleShadow(
      opacity: 0.5,
      color: colorTextPrimary,
      offset: const Offset(0, 1.5),
      sigma: 1.5,
      child: child,
    );
  }

  Widget reelGradientBox() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0.05, 0.5, 1.0],
        ),
      ),
    );
  }

  videoDescription({
    required txtWidth,
    required txt,
    required tags,
    required RxBool isExpendTxt,
  }) {
    return Obx(() {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 248,
        ),
        child: SizedBox(
          width: txtWidth,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            children: [
              RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: isExpendTxt.value ? 1000 : 2,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: txt,
                      style: jxTextStyle.textStyle15(
                        color: Colors.white,
                      ),
                    ),
                    tags,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  TextSpan tagsWidget({
    required List<String>? tags,
    Function()? onTapTag,
    ReelTagBackFromEnum? fromTagPage,
    Function()? onBack,
  }) {
    if (tags == null || tags.isEmpty) {
      return const TextSpan();
    }

    List<TextSpan> tagSpans = [];
    for (var tag in tags) {
      tagSpans.add(
        TextSpan(
          text: ' #$tag',
          style: jxTextStyle.textStyle15(
            color: Colors.white,
          ),
        ),
      );
    }

    return TextSpan(children: tagSpans);
  }
}
