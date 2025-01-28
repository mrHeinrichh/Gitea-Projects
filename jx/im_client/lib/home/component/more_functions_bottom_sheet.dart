import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

import 'package:mini_app_service/mini_app_service.dart';

class MoreFunctionsBottomSheet extends StatelessWidget {
  const MoreFunctionsBottomSheet({
    super.key,
    required this.app,
    required this.onClickRefresh,
    required this.onClickShare,
    required this.onClickCopyLink,
    required this.onClickAdd,
    required this.onClickClose,
  });

  final Apps app;
  final Function(Apps app) onClickRefresh;
  final Function(Apps app) onClickShare;
  final Function(Apps app) onClickCopyLink;
  final Function(Apps app) onClickAdd;
  final Function(Apps app) onClickClose;

  @override
  Widget build(BuildContext context) {
    // 判断横竖屏
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final List<ChatAttachmentOption> samples = [
      ChatAttachmentOption(
        icon: 'assets/svgs/miniapp_reopen.svg',
        title: localized(miniAppReOpen),
        onTap: () {
          onClickRefresh(app);
        },
      ),
      ChatAttachmentOption(
        icon: 'assets/svgs/miniapp_collect.svg',
        title: localized(saved),
        onTap: () {
          onClickAdd(app);
        },
      ),
      ChatAttachmentOption(
        icon: 'assets/svgs/miniapp_share.svg',
        title: localized(chatOptionsShare),
        onTap: () {
          onClickShare(app);
        },
      ),
      ChatAttachmentOption(
        icon: 'assets/svgs/miniapp_score.svg',
        title: localized(miniAppScore),
        onTap: () {
          // Toast.showToast(localized(homeToBeContinue));
          imBottomToast(
            context,
            icon: ImBottomNotifType.warning,
            title: localized(homeToBeContinue),
            margin: const EdgeInsets.only(
                bottom: 15,
                left: 12,
                right: 12),
          );
          MoreFunctionsBottomSheetTool.dismiss(null, null);
        },
      ),
      ChatAttachmentOption(
        icon: 'assets/svgs/miniapp_feedback.svg',
        title: localized(miniAppFeedback),
        onTap: () {
          // Toast.showToast(localized(homeToBeContinue));
          imBottomToast(
            context,
            icon: ImBottomNotifType.warning,
            title: localized(homeToBeContinue),
            margin: const EdgeInsets.only(
                bottom: 15,
                left: 12,
                right: 12),
          );
          MoreFunctionsBottomSheetTool.dismiss(null, null);
        },
      ),
    ];

    return Container(
      clipBehavior: Clip.hardEdge,
      width: isLandscape ? 1.sh : 1.sw,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
            decoration: BoxDecoration(
              border: customBorder,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: RemoteImageV2(
                        src: app.icon ?? "",
                        width: 40,
                        height: 40,
                        mini: Config().messageMin,
                        fit: BoxFit.cover,
                        enableShimmer: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: jxTextStyle.textStyleBold15(
                              fontWeight: MFontWeight.bold6.value,
                            )
                          ),
                          Text(
                            app.companyName,
                            style: jxTextStyle.textStyle13(
                              color: colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      localized(miniAppEvaluation),
                      style: jxTextStyle.textStyle14(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      app.appScore,
                      style: jxTextStyle.textStyleBold14(),
                    ),
                    // 樣式需求臨時改變,所以"分"跟評分分開,下面params留空
                    Text(
                      localized(miniAppPoints,
                          params: [
                            ''
                          ]
                      ),
                      style: jxTextStyle.textStyle14(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      app.evaluateNum,
                      style: jxTextStyle.textStyle14(
                        color: colorTextSecondary,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          /// Azman part
          Container(
            decoration: BoxDecoration(
              border: customBorder,
            ),
            child: SizedBox(
              height: 130,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 23, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: samples.map((sample) {
                    return GestureDetector(
                      onTap: () {
                        sample.onTap.call();
                      },
                      child: OpacityEffect(
                        child: Column(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SvgPicture.asset(
                                height: 32,
                                color: Colors.black,
                                sample.icon,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(sample.title,
                                style: const TextStyle(
                                    color: colorTextSecondary, fontSize: 12))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          GestureDetector(
              onTap: () {
                onClickClose(app);
              },
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    localized(cancel),
                    style: const TextStyle(color: colorReadColor, fontSize: 17),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}

class MoreFunctionsBottomSheetTool {
  static bool isShowing = false; // 用于控制弹框显示状态
  static OverlayEntry? overlayEntry;

  static Future<String?> show(BuildContext context,
      {required Apps app,
      required Function(Apps app) onClickShare,
      required Function(Apps app) onClickCopyLink,
      required Function(Apps app) onClickAdd}) async {
    // 如果已经在显示，直接返回 null
    if (isShowing) {
      return null;
    }

    isShowing = true; // 标记为正在显示

    final overlay = Overlay.of(context);
    final completer = Completer<String?>(); // 用于返回值的 Completer

    overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            dismiss(completer, null); // 点击背景关闭
          },
          child: Material(
            color: Colors.black.withOpacity(0.4), // 半透明背景
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    dismiss(completer, null); // 点击背景关闭
                  },
                  child: Container(
                    color: Colors.transparent, // 背景透明
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter, // 底部对齐
                  child: MoreFunctionsBottomSheet(
                    app: app,
                    onClickRefresh: (app) {
                      dismiss(completer, MiniAppConstants.refreshMiniApp);
                    },
                    onClickShare: (app) {
                      dismiss(completer, null);
                      onClickShare(app);
                    },
                    onClickCopyLink: (app) {
                      dismiss(completer, null);
                      onClickCopyLink(app);
                    },
                    onClickAdd: (app) {
                      dismiss(completer, null);
                      onClickAdd(app);
                    },
                    onClickClose: (app) {
                      dismiss(completer, null);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry!); // 插入 Overlay

    return completer.future; // 返回 Future
  }

  // 统一的关闭方法
  static void dismiss(Completer<String?>? completer, String? result) {
    overlayEntry?.remove(); // 移除 Overlay
    overlayEntry = null;
    isShowing = false; // 标记为未显示
    completer?.complete(result); // 返回结果
  }
}

class ChatAttachmentOption {
  final String icon;
  final String title;
  final VoidCallback onTap;

  ChatAttachmentOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class OverlayToast {
  static void showToast({
    required BuildContext context,
    required String title,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    const double toastHeight = 40; // 设置 Toast 的高度
    const double borderRadius = toastHeight / 2; // 圆角半径等于高度的一半

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50, // Toast 距离底部的位置
        left: MediaQuery.of(context).size.width * 0.26,
        right: MediaQuery.of(context).size.width * 0.26,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: toastHeight, // 设置高度
            padding: const EdgeInsets.symmetric(horizontal: 16), // 水平内边距
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(borderRadius),
                right: Radius.circular(borderRadius),
              ),
            ),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    // 插入 Overlay
    overlay.insert(overlayEntry);

    // 定时移除 Toast
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
