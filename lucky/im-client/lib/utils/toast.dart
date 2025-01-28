import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/code_define.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/page_mgr.dart';
import 'package:get/get.dart';
import 'im_toast/im_gap.dart';

class Toast {
  static Timer? _showTimer;

  static show({bool allowClick = false}) {
    if (_showTimer != null && _showTimer!.isActive) {
      _showTimer!.cancel();
    }
    _showTimer = new Timer(const Duration(milliseconds: 100), () {
      BotToast.showCustomLoading(
        allowClick: allowClick,
        toastBuilder: (CancelFunc cancelFunc) {
          return const CupertinoActivityIndicator();
        },
        backgroundColor: Colors.transparent,
      );
    });
    //BotToast.showLoading();
  }

  static hide() {
    if (_showTimer != null && _showTimer!.isActive) {
      _showTimer!.cancel();
    }
    BotToast.closeAllLoading();
  }

  /*底部弹出框*/
  static showBottomSheet(
      {required BuildContext context,
      required Widget container,
      bool? isDismissible,
      Color? colors}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: colors ?? Colors.black.withAlpha(80),
      isScrollControlled: true,
      isDismissible: isDismissible ?? true,
      routeSettings: pageMgr.savePage(container),
      builder: (context) {
        return container;
      },
    );
  }

  /*中间弹出框*/
  static showAlert(
      {required BuildContext context,
      bool dismissible = true,
      int alpha = 80,
      required Widget container}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor:
          alpha == 0 ? Colors.transparent : Colors.black.withAlpha(alpha),
      routeSettings: pageMgr.savePage(container),
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

  /*发动态发视频弹出框 */
  static showAlerts(
      {required BuildContext context,
      bool dismissible = true,
      required Widget container}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor: hexColor(0x000000, alpha: 0.8),
      routeSettings: pageMgr.savePage(container),
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
              color: JXColors.primaryTextBlack.withOpacity(0.2),
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
                  style: jxTextStyle.textStyle14(color: JXColors.white),
                )
              ],
            ),
          ),
        );
      },
    );
  }

// 創群成功toast
  static showCreateGroupToast() {
    Widget _buildText(txt) {
      return Row(
        children: [
          SvgPicture.asset(
            'assets/svgs/check.svg',
            width: 16.w,
            height: 16.w,
            color: JXColors.white,
            fit: BoxFit.fill,
          ),
          ImGap.hGap8,
          Expanded(
            child: Text(
              txt,
              style: jxTextStyle.textStyle14(color: JXColors.white),
            ),
          )
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
              color: JXColors.black40,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  localized(youCreatedAGroup),
                  style: jxTextStyle.textStyleBold16(color: JXColors.white),
                ),
                ImGap.vGap8,
                Text(
                  localized(groupCanHave),
                  style: jxTextStyle.textStyle14(color: JXColors.white),
                ),
                ImGap.vGap8,
                _buildText(
                    localized(maximumOfMemberWithParam, params: ['200'])),
                ImGap.vGap8,
                _buildText(localized(historyRecordsAreKeepPermanently)),
                ImGap.vGap8,
                _buildText(localized(inviteFriendsToGroupForFree)),
                ImGap.vGap8,
                _buildText(localized(adminAbleToSetupPermission)),
              ],
            ),
          ),
        );
      },
    );
  }

// 提示浮层
  static showToast(String text,
      {Duration? duration, int code = 0, bool isStickBottom = true}) {
    //服务端返回的超速 非调试模式下
    if (code == CodeDefine.codeTimeQuick && !kDebugMode) {
      // text = "超速啦～";
      return;
    } else if (code == CodeDefine.codeHttpDefault) {
      text = localized(toastNetworkError);
    }

    if (text == '') return;
    ImBottomToast(Routes.navigatorKey.currentContext!,
        title: localized(text),
        icon: ImBottomNotifType.empty,
        isStickBottom: isStickBottom);
  }

  static showToastMessage(String text,
      {Duration? duration, Alignment align = Alignment.bottomCenter}) {
    BotToast.showCustomText(
      toastBuilder: (_) {
        return Container(
          decoration: BoxDecoration(
              color: JXColors.primaryTextBlack.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8)),
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
      align: align
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
        duration: const Duration(seconds: 2));
  }

  /*弹出SnackBar*/
  static showSnackBar(
      {required BuildContext context, required String message}) {
    final snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

// static VapPlayerView? _vapPlayerView;
//
// ///显示vap动画播放
// static showVapPlayer(
//   String src,
//   String Function(String path) getAbsolutePath, {
//   int? videoMode,
//   bool isAsset = false,
// }) async {
//   if (_vapPlayerView == null) {
//     BotToast.showWidget(
//       toastBuilder: (cancelFunc) {
//         _vapPlayerView = VapPlayerView(
//           onComplete: () {
//             _vapPlayerView = null;
//             cancelFunc();
//           },
//           downloadFunc: (String src) => downloadMgr
//               .downloadLite(getAbsolutePath(src), isCheckImage: false),
//         );
//         _vapPlayerView!.addVapPlayerTask(src, videoMode, isAsset);
//         return _vapPlayerView!;
//       },
//     );
//   } else {
//     _vapPlayerView!.addVapPlayerTask(src, videoMode, isAsset);
//   }
// }
//
// ///取消vap动画播放
// static cancelVapPlayer() {
//   if (_vapPlayerView == null) return;
//   _vapPlayerView!.cancelVapPlayerTask();
//   _vapPlayerView = null;
// }
}

/// ## 开启跟随追踪的OverlayEntry
///
/// 该组件风格更偏向cupertino组件的风格
///
/// [**context**] 用于获取Overlay的context
///
/// [**targetWidget**] 被追踪的widget
///
/// [**followerWidget**] 跟随追踪widget
///
/// [**layerLink**] 绑定 [**targetWidget**] 和 [**followerWidget**] 的 [**LayerLink**].
///
/// [**left**] || [**top**] || [**right**] || [**bottom**] 被追踪的widget的坐标。 根据想要的位子输入
///
/// [**targetAnchor**] 被追踪的widget的锚点
///
/// [**followerAnchor**] 跟随追踪widget的锚点
///
/// [**targetAnchor**] 和 [**followerAnchor**] 会根据设置的Alignment进行 锚点绑定
///
/// 具体请查看 [**CompositedTransformTarget**] 和 [**CompositedTransformFollower**] 的源码关于 [**Anchor**] 的说明
///
/// [**dismissible**] 是否可以点击空白区域关闭
///
/// [**dismissibleCallback**] 点击空白区域的回调
///
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
                    offset: const Offset(
                      0.0,
                      10.0,
                    ),
                    targetAnchor: targetAnchor,
                    followerAnchor: followerAnchor,
                    link: layerLink,
                    child: followerWidget),
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
