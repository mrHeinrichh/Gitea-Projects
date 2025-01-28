import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class GameProfileHeaderWidget extends StatelessWidget {
  const GameProfileHeaderWidget({
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
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        child: PrimaryAppBar(
          onPressedBackBtn: () => Navigator.pop(context),
          bgColor: Colors.transparent,
          scrolledUnderElevation: 0,
          trailing: [
            if (ableEdit)
              GestureDetector(
                onTap: editCallBack,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 10),
                    child: Text(
                      localized(buttonEdit),
                      style: jxTextStyle.textStyle17(
                          color:
                              isCollapse ? ImColor.white : ImColor.accentColor),
                    ),
                  ),
                ),
              )
          ],
        ));
  }
}
