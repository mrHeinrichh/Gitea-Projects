import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomBottomSheetDialog {
  static Future showCustomModalBottomSheet({
    required BuildContext ctx,
    required String title,
    double? titleSize,
    Color? titleColor,
    List<CustomBottomSheetItem>? items,
    FontWeight? cancelFontWeight,
  }) {
    return showModalBottomSheet(
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: ctx,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: im.ImBorderRadius.borderRadius12,
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 56.w,
                        alignment: Alignment.center,
                        child: im.ImText(
                          title,
                          color: titleColor,
                          fontSize: titleSize ?? im.ImFontSize.large,
                        ),
                      ),
                      ...?items,
                    ],
                  ),
                ),
                im.ImGap.vGap8,
                // Cancel Btn
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  child: ForegroundOverlayEffect(
                    radius: im.ImBorderRadius.borderRadius12,
                    child: Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: 56.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                      child: im.ImText(
                        localized(cancel),
                        color: themeColor,
                        fontSize: im.ImFontSize.large,
                        fontWeight: cancelFontWeight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomBottomSheetItem extends StatelessWidget {
  const CustomBottomSheetItem({
    super.key,
    required this.name,
    this.fontSize,
    this.onTap,
    this.color,
    this.fontWeight,
  });

  final String name;
  final double? fontSize;
  final VoidCallback? onTap;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OverlayEffect(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: im.ImColor.black6,
                width: 1,
              ),
            ),
          ),
          height: 56.w,
          alignment: Alignment.center,
          child: im.ImText(
            name,
            fontSize: fontSize ?? im.ImFontSize.large,
            color: color ?? themeColor,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
