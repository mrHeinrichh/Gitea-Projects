import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/code_define.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';

class Toast {
  static Timer? _showTimer;

  static show({bool allowClick = false}) {
    if (_showTimer != null && _showTimer!.isActive) {
      _showTimer!.cancel();
    }
    _showTimer = Timer(const Duration(milliseconds: 100), () {
      BotToast.showCustomLoading(
        allowClick: allowClick,
        toastBuilder: (CancelFunc cancelFunc) {
          return const CupertinoActivityIndicator();
        },
        backgroundColor: Colors.transparent,
      );
    });
  }

  static hide() {
    if (_showTimer != null && _showTimer!.isActive) {
      _showTimer!.cancel();
    }
    BotToast.closeAllLoading();
  }

  static showBottomSheet({
    required BuildContext context,
    required Widget container,
    bool? isDismissible,
    Color? colors,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: colors ?? Colors.black.withAlpha(80),
      isScrollControlled: true,
      isDismissible: isDismissible ?? true,
      useSafeArea: true,
      builder: (context) {
        return container;
      },
    );
  }

  static showAlert({
    required BuildContext context,
    bool dismissible = true,
    int alpha = 80,
    required Widget container,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor:
          alpha == 0 ? Colors.transparent : Colors.black.withAlpha(alpha),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          child: container,
          onWillPop: () async {
            return Future.value(dismissible);
          },
        );
      },
    );
  }

  static showAlerts({
    required BuildContext context,
    bool dismissible = true,
    required Widget container,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor: hexColor(0x000000, alpha: 0.8),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          child: container,
          onWillPop: () async {
            return Future.value(dismissible);
          },
        );
      },
    );
  }

  static showAgoraToast({required msg, required svg}) {
    return BotToast.showCustomNotification(
      align: const Alignment(0, 0.6),
      duration: const Duration(milliseconds: 1600),
      toastBuilder: (cancelFunc) {
        return IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: colorTextPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  svg,
                  color: Colors.white,
                  width: 20.21,
                  height: 13.72,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  msg,
                  style: jxTextStyle.textStyle14(color: colorWhite),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static showCreateGroupToast(int groupTypeNum) {
    Widget buildText(txt) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/svgs/check.svg',
            width: 16.w,
            height: 16.w,
            color: colorWhite,
            fit: BoxFit.fill,
          ),
          ImGap.hGap8,
          Expanded(
            child: Text(
              txt,
              style: jxTextStyle.textStyle14(color: colorWhite),
            ),
          ),
        ],
      );
    }

    return BotToast.showCustomNotification(
      duration: const Duration(milliseconds: 1600),
      toastBuilder: (cancelFunc) {
        return Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 15.w),
            constraints: BoxConstraints(maxWidth: 250.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  localized(youCreatedAGroup),
                  style: jxTextStyle.textStyleBold16(color: colorWhite),
                ),
                ImGap.vGap8,
                Text(
                  localized(groupCanHave),
                  style: jxTextStyle.textStyle14(color: colorWhite),
                ),
                ImGap.vGap8,
                buildText(
                  localized(maximumOfMemberWithParam, params: ['200']),
                ),
                ImGap.vGap8,
                buildText(
                  localized(
                    groupTypeNum == GroupType.TMP.num
                        ? historyRecordsLostForever
                        : historyRecordsAreKeepPermanently,
                  ),
                ),
                ImGap.vGap8,
                buildText(localized(inviteFriendsToGroupForFree)),
                ImGap.vGap8,
                buildText(localized(adminAbleToSetupPermission)),
              ],
            ),
          ),
        );
      },
    );
  }

  static showToast(
    String text, {
    Duration? duration,
    int code = 0,
    bool isStickBottom = true,
  }) {
    if (code == CodeDefine.codeTimeQuick && !kDebugMode) {
      return;
    } else if (code == CodeDefine.codeHttpDefault) {
      return;
    }

    if (text == '') return;
    imBottomToast(
      navigatorKey.currentContext!,
      title: text,
      isStickBottom: isStickBottom,
    );
  }

  static showToastMessage(
    String text, {
    Duration? duration,
    Alignment align = Alignment.bottomCenter,
  }) {
    BotToast.showCustomText(
      toastBuilder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: colorTextPrimary.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          width: MediaQuery.of(Get.context!).size.width,
          child: Text(
            text,
            style: jxTextStyle.textStyle14(
              color: Colors.white,
            ),
          ),
        );
      },
      duration: duration ?? const Duration(milliseconds: 1000),
      align: align,
    );
  }

  static showIcon() {
    BotToast.showCustomLoading(
      toastBuilder: (value) {
        return SizedBox(
          width: 110.w,
          child: Image.asset(
            'assets/images/common/icon_saved_successfully.png',
            fit: BoxFit.cover,
          ),
        );
      },
      duration: const Duration(seconds: 2),
    );
  }

  static showSnackBar({
    required BuildContext context,
    required String message,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

OverlayEntry createOverlayEntry(
  BuildContext context,
  Widget targetWidget,
  Widget followerWidget,
  LayerLink layerLink, {
  double? left,
  double? top,
  double? right,
  double? bottom,
  Alignment targetAnchor = Alignment.topLeft,
  Alignment followerAnchor = Alignment.topLeft,
  bool shouldBlurBackground = true,
  bool dismissible = true,
  VoidCallback? dismissibleCallback,
  Offset? followerWidgetOffset,
}) {
  assert((dismissible && dismissibleCallback != null) || !dismissible);
  OverlayEntry overlayChild = OverlayEntry(
    builder: (BuildContext context) {
      return Positioned(
        left: 0,
        top: 0,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GestureDetector(
          onTap: dismissible ? dismissibleCallback : null,
          child: Material(
            color: shouldBlurBackground
                ? Colors.grey.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0.w),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: left,
                  top: top,
                  right: right,
                  bottom: bottom,
                  child: CompositedTransformTarget(
                    link: layerLink,
                    child: targetWidget,
                  ),
                ),
                CompositedTransformFollower(
                  offset: followerWidgetOffset ??
                      const Offset(
                        0.0,
                        10.0,
                      ),
                  targetAnchor: targetAnchor,
                  followerAnchor: followerAnchor,
                  link: layerLink,
                  child: followerWidget,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Overlay.of(context).insert(overlayChild);

  return overlayChild;
}
