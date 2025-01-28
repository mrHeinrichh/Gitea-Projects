import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/home/component/custom_divider.dart';

const double kTitleHeight = 44.0;
const double kSearchHeightMax = 36.0;
const double kSearchVerticalSpacing = 8.0;
const double kSearchBorderWidth = 1.0;
RxDouble kSearchHeight = 0.0.obs;

double getTopBarHeight() =>
    kTitleHeight +
    kSearchHeightMax +
    (kSearchVerticalSpacing * 2) +
    getTotalPinHeight() +
    kSearchBorderWidth;

class ChatViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget titleWidget;
  final Widget leading;
  final Widget trailing;
  final bool isSearchingMode;
  final Widget searchWidget;
  final Widget bottomWidget;

  const ChatViewAppBar({
    super.key,
    required this.height,
    required this.titleWidget,
    required this.leading,
    required this.trailing,
    required this.searchWidget,
    required this.isSearchingMode,
    required this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                alignment: Alignment.bottomCenter,
                duration: const Duration(milliseconds: 300),
                clipBehavior: Clip.none,
                child: SizedBox(
                  height: isSearchingMode ? 0 : kTitleHeight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSearchingMode ? 0 : 1,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        titleWidget,
                        Positioned(
                          left: 16,
                          child: leading,
                        ),
                        Positioned(
                          right: 0,
                          child: trailing,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              searchWidget,
              bottomWidget,
            ],
          ),
        ),
        const Positioned(
          right: 0,
          left: 0,
          bottom: 0,
          child: CustomDivider(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
