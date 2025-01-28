import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/invite_friends/components/dotted_line_painter.dart';
import 'package:jxim_client/setting/invite_friends/invite_friends_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriends extends GetView<InviteFriendsController> {
  const InviteFriends({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              bgColor: Colors.transparent,
              title: localized(inviteFriends),
            ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: controller.validityPeriodInviteCode.value.isNotEmpty
                      ? _buildValidityPeriodCode(context)
                      : _buildPermanentCode(),
                ),
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
            color: colorBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  text: localized(InviteFriendShareLink),
                  height: 48,
                  callBack: () {
                    Share.share(controller.downloadLink.value);
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: 16,
                      bottom: MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom + 5
                          : 16),
                  child: CustomTextButton(
                    localized(download),
                    isBold: true,
                    color: themeColor,
                    onClick: () {
                      controller.downloadAppQR(
                        controller.validityPeriodInviteCode.value.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: colorBackground,
                                  borderRadius: BorderRadius.circular(16.w),
                                ),
                                alignment: Alignment.center,
                                width: 300,
                                height: 600,
                                child: _buildValidityPeriodCode(context),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: colorBackground,
                                  borderRadius: BorderRadius.circular(16.w),
                                ),
                                alignment: Alignment.center,
                                width: 300,
                                height: 376.w,
                                child: _buildPermanentCode(),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildValidityPeriodCode(context) {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
            decoration: const BoxDecoration(
              color: colorSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localized(InviteFriendYourQrCode),
                  style: jxTextStyle.headerText(
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    color: colorBackground3,
                  ),
                  child: GestureDetector(
                    onLongPress: () => controller.copyText(needVibrate: true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48),
                          OpacityEffect(
                            child: Text(
                              controller.validityPeriodInviteCode.value,
                              style: jxTextStyle.titleText(
                                color: themeColor,
                                fontWeight: MFontWeight.bold5.value,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.copyText(),
                            child: OpacityEffect(
                              child: Container(
                                width: 48,
                                height: 48,
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: SvgPicture.asset(
                                    'assets/svgs/copyURL_icon.svg',
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localized(InviteFriendRegisterQrCode,
                      params: [controller.inviteCodeExpiryDay]),
                  style: jxTextStyle.normalText(
                    color: colorTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 300,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: colorSurface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      localized(InviteFriendUseApp, params: [Config().appName]),
                      style: jxTextStyle.headerText(
                        fontWeight: MFontWeight.bold5.value,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _buildQRCode(),
                    const SizedBox(height: 12),
                    Text(
                      '${Config().appName}App',
                      style: jxTextStyle.headerText(
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 20),
                  painter: DottedLineWithSemicirclesPainter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermanentCode() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localized(InviteFriendUseApp, params: [Config().appName]),
              style: jxTextStyle.headerText(
                fontWeight: MFontWeight.bold5.value,
              ),
              textAlign: TextAlign.center,
            ),
            ImGap.vGap12,
            _buildQRCode(),
            ImGap.vGap12,
            Text(
              '${Config().appName}App',
              style: jxTextStyle.headerText(
                fontWeight: MFontWeight.bold5.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Obx(
        () {
          if (controller.isLoading.value) {
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: themeColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return QRCode(
            qrData: controller.downloadLink.value,
            qrSize: 180,
            roundEdges: false,
          );
        },
      ),
    );
  }
}
