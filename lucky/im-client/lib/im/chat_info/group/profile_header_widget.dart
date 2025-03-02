import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    Key? key,
    required this.paddingTop,
    required this.isCollapse,
    required this.ableEdit,
    this.editCallBack,
  }) : super(key: key);

  final double paddingTop;
  final bool isCollapse;
  final VoidCallback? editCallBack;
  final bool ableEdit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 2,
      left: 0,
      width: MediaQuery.of(context).size.width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OpacityEffect(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 9),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SvgPicture.asset(
                          'assets/svgs/Back.svg',
                          width: 24,
                          height: 24,
                          color: isCollapse ? ImColor.white : accentColor,
                        ),
                      ),
                      Text(
                        localized(buttonBack),
                        style: TextStyle(
                          fontSize: MFontSize.size17.value,
                          color: isCollapse ? ImColor.white : accentColor,
                          height: 1.2,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (ableEdit)
              OpacityEffect(
                child: GestureDetector(
                  onTap: editCallBack,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(top: 3, right: 16),
                    child: Text(
                      localized(buttonEdit),
                      style: jxTextStyle.textStyle17(
                          color: isCollapse ? ImColor.white : accentColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
