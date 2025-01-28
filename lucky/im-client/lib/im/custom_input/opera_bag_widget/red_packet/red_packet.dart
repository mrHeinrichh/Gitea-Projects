import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../../utils/color.dart';
import '../../../model/red_packet.dart';
import '../../sheet_title_bar.dart';

class RedPacket extends StatelessWidget {
  late final CustomInputController controller;

   RedPacket({Key? key, required this.tag}) : super(key: key) {
    Get.put(RedPacketController(tag: tag));
    controller = Get.find<CustomInputController>(tag: tag);
  }

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: sheetTitleBarColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.w),
          topRight: Radius.circular(12.w),
        ),
      ),
      child: Column(
        children: [
          SheetTitleBar(
            title: localized(chatRedPacket),
            divider: false,
          ),
          const SizedBox(
            height: 24,
          ),
          (controller.chatController.isSetPassword.value)
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RedPacketTypeTile(
                        title: localized(luckyRedPacket),
                        type: RedPacketType.luckyRedPacket.value,
                        onTap: () {
                          Get.to(
                            () => RedPacketView(
                              redPacketType: RedPacketType.luckyRedPacket,
                            ),
                            preventDuplicates: false,
                          );
                        },
                      ),
                      divide(),
                      RedPacketTypeTile(
                        title: localized(normalRedPacket),
                        type: RedPacketType.normalRedPacket.value,
                        onTap: () {
                          Get.to(
                            () => RedPacketView(
                              redPacketType: RedPacketType.normalRedPacket,
                            ),
                            preventDuplicates: false,
                          );
                        },
                      ),
                      divide(),
                      RedPacketTypeTile(
                        title: localized(exclusiveRedPacket),
                        type: RedPacketType.exclusiveRedPacket.value,
                        onTap: () {
                          Get.to(
                            () => RedPacketView(
                              redPacketType: RedPacketType.exclusiveRedPacket,
                            ),
                            preventDuplicates: false,
                          );
                        },
                      ),
                      divide(),
                    ],
                  ),
                )
              : emptyState(),
        ],
      ),
    );
  }

  Container divide() {
    return Container(
                      height: 1,
                      margin: EdgeInsets.only(left: 60.w),
                      color: JXColors.outlineColor,
                    );
  }
}

class RedPacketTypeTile extends StatelessWidget {
  const RedPacketTypeTile(
      {Key? key, this.onTap, required this.title, required this.type})
      : super(key: key);
  final GestureTapCallback? onTap;
  final String title;
  final String type;

  @override
  Widget build(BuildContext context) {
    String image = "";
    String subTitle = "";

    if (type == 'LUCKY_RP') {
      image = 'assets/images/lucky_redPacket_icon.png';
      subTitle = localized(getMoreOrLessDependOnLuck);
    } else if (type == 'STANDARD_RP') {
      image = 'assets/images/exclusive_redPacket_icon.png';
      subTitle = localized(giveThemDigitalRedPacket);
    } else if (type == 'SPECIFIED_RP') {
      image = 'assets/images/normal_redPacket_icon.png';
      subTitle = localized(specialForSomePeople);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(
              image,
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8.5,),
                  Text(
                    title,
                    style: jxTextStyle.textStyle16(),
                  ),
                  Text(
                    subTitle,
                    style: jxTextStyle.textStyle12(
                        color: JXColors.secondaryTextBlack),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget emptyState() {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/svgs/empty_state_redPacket.svg",
            width: 148,
            height: 148,
          ),
          const SizedBox(height: 16),
          Text(
            localized(walletIsNotReady),
            style: jxTextStyle.textStyleBold16(),
          ),
          const SizedBox(height: 4),
          Text(
            localized(toEnjoyTheFeaturePleaseGoToTheSettingToSetupYourPasscode),
            style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Get.toNamed(
                RouteName.privacySecurity,
                arguments: {
                  'from_view': 'chat_view',
                },
              );
            },
            child: Text(
              localized(goSettings),
              style: jxTextStyle.textStyleBold16(color: accentColor),
            ),
          ),
        ],
      ),
    ),
  );
}
