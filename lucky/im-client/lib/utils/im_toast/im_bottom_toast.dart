import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/circular_count_downtimer.dart';
import 'package:jxim_client/utils/im_toast/im_border_radius.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import '../lang_util.dart';
import 'c_icon.dart';

Future<void> ImBottomToast(
  BuildContext context, {
  required String title, //Text message
  required ImBottomNotifType icon, //Select icon
  bool canPopOutside = false, // dismiss without waiting for timer
  VoidCallback? timerFunction, // if timer complete, do the function
  VoidCallback? undoFunction,
  VoidCallback? actionFunction,
  int duration = 1, //duration
  bool withCancel = false, //with 撤销 button
  bool withAction = false,
  bool isStickBottom = true,
}) async {
  late Timer timer;
  getIconWidget(ImBottomNotifType type) {
    switch (type) {
      case (ImBottomNotifType.auto_delete):
        return const CIcon(
          icon: 'bn_auto_delete',
          width: 24,
        );
      case (ImBottomNotifType.unauto_delete):
        return const CIcon(
          icon: 'bn_unauto_delete',
          width: 24,
        );
      case (ImBottomNotifType.snooze):
        return const CIcon(
          icon: 'bn_snooze',
          width: 24,
        );
      case (ImBottomNotifType.timer):
        return CircularCountDownTimer(
          height: 24,
          width: 24,
          duration: duration,
          fillColor: Color(0xD1121212),
          ringColor: Colors.white,
          isReverse: true,
          strokeWidth: 2,
          textStyle: TextStyle(color: Colors.white),
          onComplete: timerFunction,
        );
      case (ImBottomNotifType.unmute):
        return const CIcon(
          icon: 'bn_unmute',
          width: 24,
        );
      case (ImBottomNotifType.mute):
        return const CIcon(
          icon: 'bn_mute',
          width: 24,
        );
      case (ImBottomNotifType.copy):
        return const CIcon(
          icon: 'bn_copy',
          width: 24,
        );
      case (ImBottomNotifType.delete):
        return const CIcon(
          icon: 'bn_trash',
          width: 24,
        );
      case (ImBottomNotifType.warning):
        return const CIcon(
          icon: 'bn_warning',
          width: 24,
        );
      case (ImBottomNotifType.success):
        return const CIcon(
          icon: 'bn_success',
          width: 24,
        );
      case (ImBottomNotifType.add_friend):
        return const CIcon(
          icon: 'bn_add_friend',
          width: 24,
        );
      case (ImBottomNotifType.unfriend):
        return const CIcon(
          icon: 'bn_unfriend',
          width: 24,
        );
      case (ImBottomNotifType.saved):
        return const CIcon(
          icon: 'bn_save',
          width: 24,
        );
      case (ImBottomNotifType.archive):
        return const CIcon(
          icon: 'bn_archive',
          width: 24,
        );
      case (ImBottomNotifType.pin):
        return const CIcon(
          icon: 'bn_pin',
          width: 24,
        );
      case (ImBottomNotifType.loading):
        return SvgPicture.asset(
          'assets/svgs/bn_loading.svg',
          width: 24,
          height: 24,
          color: Colors.white,
        );
      case (ImBottomNotifType.INFORMATION):
        return SvgPicture.asset(
          'assets/svgs/informationIcon.svg',
          width: 24,
          height: 24,
        );
      case (ImBottomNotifType.download):
        return SvgPicture.asset(
          'assets/svgs/media_download.svg',
          width: 24,
          height: 24,
        );


      default:
        return const SizedBox(
          height: 0,
        );
    }
  }

  Widget desktopDialog = Dialog(
    backgroundColor: const Color(0xD1121212),
    alignment: Alignment(0.0, 0.8),
    shadowColor: Colors.transparent,
    clipBehavior: Clip.hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    insetPadding: const EdgeInsets.symmetric(horizontal: 12),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 10,
      ),
      child: Row(
        children: [
          getIconWidget(icon),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          if (withCancel)
            GestureDetector(
              onTap: () {
                undoFunction?.call();
              },
              child: Text(
                localized(undo),
                style: TextStyle(
                  color: JXColors.toastButtonColor,
                ),
              ),
            ),
          if (withAction)
            GestureDetector(
              onTap: () => actionFunction?.call(),
              child: Text(
                localized(view),
                style: TextStyle(
                  color: JXColors.toastButtonColor,
                ),
              ),
            ),
        ],
      ),
    ),
  );
  showWidgetToast(
    objectMgr.loginMgr.isDesktop
        ? desktopDialog
        : Dialog(
            backgroundColor: const Color(0xD1121212),
            alignment: Alignment(0.0, (isStickBottom ? 0.98 : 0.82)),
            shadowColor: Colors.transparent,
            elevation: 0,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: ImBorderRadius.borderRadius8,
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              child: Row(
                children: [
                  getIconWidget(icon),
                  ImGap.hGap(13),
                  Expanded(
                    child: Text(
                      title,
                      style: jxTextStyle.textStyle14(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (withCancel)
                    GestureDetector(
                      onTap: () {
                        undoFunction?.call();
                      },
                      child: Text(
                        localized(undo),
                        style: jxTextStyle.textStyle14(
                          color: JXColors.toastButtonColor,
                        ),
                      ),
                    ),
                  if (withAction)
                    GestureDetector(
                      onTap: () => actionFunction?.call(),
                      behavior: HitTestBehavior.translucent,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          localized(view),
                          style: jxTextStyle.textStyle14(
                            color: JXColors.toastButtonColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
    milliseconds: duration * 1000,
    // aliment: const Alignment(0.0, 0.85),
  );
}

enum ImBottomNotifType {
  none,
  auto_delete,
  unauto_delete,
  snooze,
  timer,
  mute,
  unmute,
  copy,
  delete,
  warning,
  success,
  add_friend,
  unfriend,
  saved,
  archive,
  pin,
  empty,
  loading,
  INFORMATION,
  download,
}
