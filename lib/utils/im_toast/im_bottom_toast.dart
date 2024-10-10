import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/im_toast/c_icon.dart';
import 'package:jxim_client/utils/im_toast/circular_count_downtimer.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:lottie_tgs/lottie.dart';

imBottomToast(BuildContext context,
    {required String title, //Text message
    ImBottomNotifType icon = ImBottomNotifType.none, //Select icon
    VoidCallback? timerFunction, // if timer complete, do the function
    VoidCallback? undoFunction,
    VoidCallback? actionFunction,
    int duration = 2, //duration
    bool withCancel = false, //with 撤销 button
    bool withAction = false,
    bool isStickBottom = true, // if toast will not move upwards
    String actionButtonText = "view",
    Alignment? alignment,
    EdgeInsets? margin,
    Color? backgroundColor,
    Color textColor = colorWhite,
    bool actionArrow = false,
    Color? actionTxtColor,
    Color? actionArrowColor}) async {
  getIconWidget(ImBottomNotifType type) {
    double iconSize = 24;

    switch (type) {
      case (ImBottomNotifType.auto_delete):
        return CIcon(
          icon: 'bn_auto_delete',
          width: iconSize,
        );
      case (ImBottomNotifType.unauto_delete):
        return CIcon(
          icon: 'bn_unauto_delete',
          width: iconSize,
        );
      case (ImBottomNotifType.snooze):
        return CIcon(
          icon: 'bn_snooze',
          width: iconSize,
        );
      case (ImBottomNotifType.timer):
        return CircularCountDownTimer(
          height: iconSize,
          width: iconSize,
          duration: duration,
          fillColor: const Color(0xD1121212),
          ringColor: colorWhite,
          isReverse: true,
          strokeWidth: 2,
          textStyle: const TextStyle(color: colorWhite),
          onComplete: timerFunction,
        );
      case (ImBottomNotifType.unmute):
        return CIcon(
          icon: 'bn_unmute',
          width: iconSize,
        );
      case (ImBottomNotifType.mute):
        return CIcon(
          icon: 'bn_mute',
          width: iconSize,
        );
      case (ImBottomNotifType.copy):
        return CIcon(
          icon: 'bn_copy',
          width: iconSize,
        );
      case (ImBottomNotifType.delete):
        return CIcon(
          icon: 'bn_trash',
          width: iconSize,
        );
      case (ImBottomNotifType.warning):
        return CIcon(
          icon: 'bn_warning',
          width: iconSize,
        );
      case (ImBottomNotifType.success):
        return CIcon(
          icon: 'bn_success',
          width: iconSize,
          colorFilter: textColor,
        );
      case (ImBottomNotifType.add_friend):
        return CIcon(
          icon: 'bn_add_friend',
          width: iconSize,
        );
      case (ImBottomNotifType.unfriend):
        return CIcon(
          icon: 'bn_unfriend',
          width: iconSize,
        );
      case (ImBottomNotifType.saved):
        return CIcon(
          icon: 'bn_save',
          width: iconSize,
        );
      case (ImBottomNotifType.archive):
        return CIcon(
          icon: 'bn_archive',
          width: iconSize,
        );
      case (ImBottomNotifType.pin):
        return CIcon(
          icon: 'bn_pin',
          width: iconSize,
        );
      case (ImBottomNotifType.loading):
        return CustomImage(
          'assets/svgs/bn_loading.svg',
          size: iconSize,
          color: colorWhite,
        );
      case (ImBottomNotifType.INFORMATION):
        return CustomImage(
          'assets/svgs/informationIcon.svg',
          size: iconSize,
          color: colorWhite,
        );
      case (ImBottomNotifType.download):
      case (ImBottomNotifType.qrSaved):
        return CustomImage(
          'assets/svgs/media_download.svg',
          size: iconSize,
          color: colorWhite,
        );
      case (ImBottomNotifType.saving):
        assert(notBlank(ImBottomNotifType.saving.path), 'Path cannot be empty');

        return Lottie.asset(
          ImBottomNotifType.saving.path,
          width: iconSize,
          height: iconSize,
          repeat: false,
        );
      case (ImBottomNotifType.unfriendSuccess):
        return CustomImage(
          'assets/svgs/unfriend_icon.svg',
          size: iconSize,
          color: colorWhite,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget desktopDialog = Dialog(
    backgroundColor: const Color(0xD1121212),
    alignment: const Alignment(0.0, 0.8),
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
              style: const TextStyle(
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
                  color: themeSecondaryColor,
                ),
              ),
            ),
          if (withAction)
            GestureDetector(
              onTap: () => actionFunction?.call(),
              child: Text(
                localized(actionButtonText),
                style: TextStyle(
                  color: themeSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  const double bottomNavAndInputHeight = 52;
  final keyboardHeight = MediaQuery.of(Get.context!).viewInsets.bottom;
  double bottomSpacing = 12;

  if (!isStickBottom) {
    bottomSpacing += bottomNavAndInputHeight + keyboardHeight;
  }

  showWidgetToast(
    objectMgr.loginMgr.isDesktop
        ? desktopDialog
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(minHeight: 48),
            margin: margin ?? EdgeInsets.fromLTRB(12, 12, 12, bottomSpacing),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: backgroundColor ?? colorTextPrimary.withOpacity(0.82),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                getIconWidget(icon),
                if (icon != ImBottomNotifType.none) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: jxTextStyle.textStyle14(color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (withCancel)
                  CustomTextButton(
                    localized(undo),
                    fontSize: MFontSize.size14.value,
                    color: themeSecondaryColor,
                    padding: const EdgeInsets.only(
                      left: 12,
                      top: 12,
                      bottom: 12,
                    ),
                    onClick: undoFunction?.call,
                  ),
                if (withAction)
                  GestureDetector(
                    onTap: actionFunction?.call,
                    behavior: HitTestBehavior.opaque,
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localized(actionButtonText),
                              style: jxTextStyle.textStyle14(
                                  color: actionTxtColor ?? themeSecondaryColor),
                            ),
                            if (actionArrow)
                              CustomImage(
                                'assets/svgs/red_arrow.svg',
                                color: actionArrowColor ?? colorRed,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
    alignment: alignment,
    milliseconds: duration * 1000,
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
  loading,
  INFORMATION,
  download,
  saving(path: "assets/lottie/save.json"),
  qrSaved,
  unfriendSuccess;

  const ImBottomNotifType({this.path = ""});

  final String path;
}
