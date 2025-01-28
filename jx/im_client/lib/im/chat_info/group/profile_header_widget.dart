import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.paddingTop,
    required this.ableEdit,
    this.editCallBack,
    this.isModalBottomSheet = false,
  });

  final double paddingTop;
  final VoidCallback? editCallBack;
  final bool ableEdit;
  final bool isModalBottomSheet;

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
                onTap: () {
                  Navigator.pop(context);
                  VolumePlayerService.sharedInstance.resetState();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 9),
                  child: isModalBottomSheet
                      ? Text(
                          localized(cancel),
                          style: TextStyle(
                            fontSize: MFontSize.size17.value,
                            color: themeColor,
                            height: 1.2,
                          ),
                        )
                      : const CustomLeadingIcon(),
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
                      style: jxTextStyle.textStyle17(color: themeColor),
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
