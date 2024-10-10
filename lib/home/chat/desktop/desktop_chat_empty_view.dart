import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class DesktopChatEmptyView extends StatelessWidget {
  const DesktopChatEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: colorDesktopChatBg,
          image: DecorationImage(
            image: AssetImage(
              "assets/images/chat_bg.png",
            ),
            fit: BoxFit.none,
            opacity: 0.8,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Center(
          child: Material(
            color: Colors.white,
            elevation: 1.0,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 330,
              height: 175,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: SvgPicture.asset(
                      'assets/svgs/welcome_image.svg',
                      width: 74,
                      height: 74,
                    ),
                  ),
                  Text(
                    localized(welcomeToHeyTalkDesktop,params: [Config().appName]),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: MFontWeight.bold5.value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localized(clickOnChatToStartMessaging),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
