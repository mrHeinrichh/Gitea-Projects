import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/call_log/component/call_bottom_modal.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import '../../../utils/config.dart';
import '../../../utils/lang_util.dart';

class CallLogEmpty extends StatelessWidget {
  const CallLogEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 57),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SvgPicture.asset('assets/svgs/call_log_empty.svg'),
          ),
          Text(
            localized(stayConnectedWithFriend,params: [Config().appName]),
            style: jxTextStyle.textStyleBold16(fontWeight: MFontWeight.bold6.value),
          ),
          const SizedBox(
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              localized(clickToStartCall),
              style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
            ),
          ),
          GestureDetector(
            onTap: () => showCallBottomModalSheet(context),
            child: OverlayEffect(
              radius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
              child: Container(
                height: 50,
                width: 131,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: JXColors.outlineColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SvgPicture.asset('assets/svgs/call_outline.svg',color: accentColor,),
                      Text(
                        localized(startACall),
                        style: jxTextStyle.textStyleBold14(fontWeight: MFontWeight.bold6.value),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
