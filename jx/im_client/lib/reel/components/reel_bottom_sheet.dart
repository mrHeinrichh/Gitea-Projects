import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

var reelBtmSheet = ReelBottomSheet();

class ReelBottomSheet {
  Future<void> showReelBottomFollowSheet({
    required BuildContext ctx,
    required Function() unFollowTap,
  }) async {
    showModalBottomSheet(
      context: ctx,
      barrierColor: colorOverlay40,
      backgroundColor: colorBackground,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFollowItem(
                text: localized(reelAskUnfollow),
                clickEffect: false,
                height: 49,
                textStyle: jxTextStyle.textStyle12(),
              ),
              // const CustomDivider(),
              // _buildFollowItem(
              //   text: '不看 TA 的作品',
              //   onTap: () {},
              // ),
              const CustomDivider(),
              _buildFollowItem(
                text: localized(reelUnfollow),
                textStyle: jxTextStyle.textStyle16(color: colorRed),
                onTap: unFollowTap,
              ),
              _buildFollowItem(
                text: localized(cancelled),
                bgColor: null,
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  _buildFollowItem({
    String? text,
    TextStyle? textStyle,
    Color? bgColor = colorWhite,
    double height = 56,
    bool clickEffect = true,
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ForegroundOverlayEffect(
        withEffect: clickEffect,
        child: Container(
          height: height,
          color: bgColor,
          alignment: Alignment.center,
          child: Text(
            text ?? 'N/A',
            style: textStyle ?? jxTextStyle.textStyle16(),
          ),
        ),
      ),
    );
  }

  Future<void> showShareReelBottomSheet({
    required BuildContext context,
    required ReelPost reel,
  }) async {
    final ReelController controller = Get.find<ReelController>();
    controller.doForward(reel);
  }

  Future<void> showReelLongPressBottomSheet({
    required BuildContext context,
    required ReelPost reelItem,
    required onTapMng,
  }) async {
    showModalBottomSheet(
      context: context,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return CustomBottomSheetContent(
          title: localized(reelVideoMng),
          showCancelButton: true,
          trailing: CustomTextButton(
            localized(buttonDone),
            onClick: () => Navigator.of(ctx).pop(),
          ),
          middleChild: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomRoundContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingItem(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      return showShareReelBottomSheet(
                        context: ctx,
                        reel: reelItem,
                      );
                    },
                    title: localized(share),
                  ),
                  SettingItem(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      onTapMng();
                    },
                    title: localized(reelBatchMng),
                    withBorder: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
