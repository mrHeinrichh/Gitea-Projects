import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/sticker/gifs_component.dart';
import 'package:jxim_client/im/sticker/sticker_component.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/im/sticker/emoji_component.dart';

enum FacialExpression {
  emoji,
  stickers,
  gifs,
}

extension FacialExpressionExtension on FacialExpression {
  String get title {
    switch (this) {
      case FacialExpression.emoji:
        return 'Emoji';
      case FacialExpression.stickers:
        return 'Stickers';
      case FacialExpression.gifs:
        return 'GIFs';
      default:
        return '';
    }
  }
}

class FacialExpressionComponent extends StatefulWidget {
  final Chat chat;
  final bool isShowSticker;
  final bool isShowStickerPermission;
  final bool isFocus;
  final bool isShowAttachment;
  final VoidCallback? onDeleteLastOne;

  const FacialExpressionComponent({
    super.key,
    required this.chat,
    required this.isShowSticker,
    required this.isShowStickerPermission,
    required this.isFocus,
    this.isShowAttachment = false,
    this.onDeleteLastOne,
  });

  @override
  State<FacialExpressionComponent> createState() =>
      _FacialExpressionComponentState();
}

class _FacialExpressionComponentState extends State<FacialExpressionComponent>
    with SingleTickerProviderStateMixin {
  List<GlobalKey> stickerCollectionKeys = [];
  CustomInputController? controller;
  AutoScrollController scrollController = AutoScrollController();
  late TabController tabController;
  ValueNotifier<int> currentTabIdx = ValueNotifier<int>(0);
  Timer? timer;

  bool isSwitchingBetweenStickerAndKeyboard = false;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());

    tabController = TabController(
      length: tabList.length,
      vsync: this,
    );

    tabController.addListener(() {
      if (currentTabIdx != tabController.index) {
        currentTabIdx.value = tabController.index;
      }
    });
  }

  @override
  void didUpdateWidget(FacialExpressionComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShowSticker != oldWidget.isShowSticker ||
        widget.isFocus != oldWidget.isFocus ||
        widget.isShowAttachment != oldWidget.isShowAttachment) {
      if (widget.isFocus &&
          !oldWidget.isFocus &&
          oldWidget.isShowSticker &&
          !widget.isShowSticker) {
        isSwitchingBetweenStickerAndKeyboard = true;
        controller?.stickerDebounce.call(() {
          isSwitchingBetweenStickerAndKeyboard = false;
          if (mounted) setState(() {});
        });
      } else {
        isSwitchingBetweenStickerAndKeyboard = false;
      }

      if (mounted) setState(() {});
    }

    ever(keyboardHeight, (callback) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.off(StickerMgr.eventStickerChange, onStickerChange);
    timer?.cancel();
    super.dispose();
  }

  void onStickerChange(Object sender, Object type, Object? data) {
    if (stickerCollectionKeys.length != objectMgr.stickerMgr.stickerCount &&
        stickerCollectionKeys.length < objectMgr.stickerMgr.stickerCount) {
      for (int i = stickerCollectionKeys.length;
          i < objectMgr.stickerMgr.stickerCount;
          i++) {
        stickerCollectionKeys.add(GlobalKey());
      }

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsetHeight = MediaQuery.of(context).viewInsets.bottom;

    double bottomHeight = getPanelFixHeight;
    if (widget.isFocus && bottomInsetHeight < keyboardHeight.value) {
      if (isSwitchingBetweenStickerAndKeyboard) {
        bottomHeight = getPanelFixHeight;
      } else {
        bottomHeight = bottomInsetHeight;
      }
    } else if (bottomInsetHeight > keyboardHeight.value) {
      bottomHeight = bottomInsetHeight;
    } else {
      bottomHeight = getPanelFixHeight;
    }

    if (objectMgr.loginMgr.isDesktop) return const SizedBox();
    return Container(
      color: JXColors.bgPrimaryColor,
      height: widget.isShowSticker
          ? bottomHeight
          : widget.isFocus
              ? getPanelFixHeight
              : 0,
      child: GetBuilder<CustomInputController>(
          id: 'emoji_tab',
          init: controller,
          builder: (_) {
            return ClipRRect(
              child: AnimatedAlign(
                alignment: Alignment.bottomCenter,
                duration: Duration(
                  milliseconds:
                      widget.isShowSticker || widget.isFocus ? 233 : 180,
                ),
                curve: Curves.easeOut,
                heightFactor:
                    widget.isShowSticker || widget.isFocus ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: widget.isShowSticker ? 233 : 0,
                  ),
                  curve: Curves.easeOut,
                  height: bottomHeight,
                  child: !widget.isShowSticker
                      ? null
                      : Column(
                          children: <Widget>[
                            Expanded(child: _buildPages()),
                            _buildBottom(),
                          ],
                        ),
                ),
              ),
            );
          }),
    );
  }

  Widget _buildDeleteButton() {
    return _buildIconButton(
      icon: 'delete_input',
      onTap: () => widget.onDeleteLastOne?.call(),
      onLongPress: () {
        timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          widget.onDeleteLastOne?.call();
        });
      },
      onLongPressEnd: (_) => timer?.cancel(),
    );
  }

  Widget _buildIconButton({
    required String icon,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    GestureLongPressEndCallback? onLongPressEnd,
  }) {
    final child = OpacityEffect(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 4.0,
          bottom: 4.0,
          left: 5.0,
          right: 5.0,
        ).w,
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: SvgPicture.asset(
            'assets/svgs/$icon.svg',
            fit: BoxFit.fill,
            colorFilter: const ColorFilter.mode(
              JXColors.black48,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressEnd: onLongPressEnd,
      child: child,
    );
  }

  Widget _buildBottom() {
    return ColoredBox(
      color: JXColors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 50.w,
          width: double.infinity,
          child: ValueListenableBuilder<int>(
            valueListenable: currentTabIdx,
            builder: (_, value, __) => Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2).w,
                  margin: const EdgeInsets.symmetric(vertical: 8).w,
                  decoration: ShapeDecoration(
                    color: backgroundColor,
                    shape: const StadiumBorder(),
                  ),
                  child: TabBar(
                    controller: tabController,
                    isScrollable: true,
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: jxTextStyle.textStyleBold14(),
                    unselectedLabelStyle: jxTextStyle.textStyle14(),
                    indicator: const ShapeDecoration(
                      color: JXColors.white,
                      shape: StadiumBorder(),
                    ),
                    tabs: List<Widget>.generate(
                      tabList.length,
                      (index) {
                        if (!widget.isShowStickerPermission && (index == FacialExpression.stickers.index || index == FacialExpression.gifs.index)) {
                          return const SizedBox();
                        } else {
                          return Container(
                            width: 76.w,
                            alignment: Alignment.center,
                            child: Text("${tabList[index].title}"),
                          );
                        }
                      },
                    ),
                  ),
                ),
                // if (currentTabIdx == FacialExpression.stickers.index)
                //   Positioned(
                //     left: 16.w,
                //     child: _buildIconButton(
                //       icon: 'settings_outlined',
                //       onTap: () {
                //         imShowBottomSheet(
                //             context, (context) => const ImManageStickers());
                //       },
                //     ),
                //   ),
                Positioned(
                    right: 16.w,
                    child: value == FacialExpression.emoji.index
                        ? _buildDeleteButton()
                        : const SizedBox()
                    // _buildIconButton(
                    //         icon: 'search_outlined',
                    //         onTap: () {
                    //           ///TODO: Add logic
                    //         },
                    //       ),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FacialExpression> get tabList {
    return FacialExpression.values.map((e) => e).toList();
  }

  Widget _buildPages() {
    return TabBarView(
      controller: tabController,
      children: List.generate(
        tabList.length,
        (index) {
          FacialExpression type = tabList[index];

          switch (type) {
            case FacialExpression.emoji:
              return EmojiComponent(
                onEmojiClick: (String emoji) {
                  controller?.addEmoji(emoji);
                },
              );
            case FacialExpression.stickers:
              return StickerComponent(chat: widget.chat);
            case FacialExpression.gifs:
              return GifsComponent(chat: widget.chat);
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
