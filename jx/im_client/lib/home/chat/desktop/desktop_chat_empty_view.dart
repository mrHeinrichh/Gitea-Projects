import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

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
          child: Container(
            width: 330,
            height: 169,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
              BoxShadow(
                color: colorTextPrimary.withOpacity(0.15),
                spreadRadius: 0,
                blurRadius: 8,
              ),
            ]),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorTextPrimary,
                  ),
                ),
                Text(
                  localized(clickOnChatToStartMessaging),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorTextPrimary.withOpacity(0.48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
