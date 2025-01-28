import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/component/hover_click_builder.dart';

class MoreVertView extends StatefulWidget {
  final List<ToolOptionModel> optionList;
  final VoidCallback? func;
  final double? radius;

  const MoreVertView({
    required this.optionList,
    super.key,
    this.func,
    this.radius,
  });

  @override
  State<MoreVertView> createState() => _MoreVertViewState();
}

class _MoreVertViewState extends State<MoreVertView> {
  final MoreVertController controller = Get.put(MoreVertController());
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<ToolOptionModel> currentList = [];
  int currentIndex = 100;

  @override
  void initState() {
    super.initState();
    controller.optionList = widget.optionList;
    controller.currentList.value = controller.optionList;
    controller.initItemKeys(controller.currentList);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MoreVertController>(
      init: controller,
      builder: (context) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () async {
              // onPointerUp();
            },
            child: Listener(
              onPointerMove: (event) {
                onPointerMove(event.position);
              },
              onPointerUp: (event) async {
                onPointerMove(event.position);
                onPointerUp();
              },
              onPointerDown: (event) {
                onPointerMove(event.position);
              },
              child: Obx(
                () => ListView.builder(
                  key: controller.listKey,
                  itemCount: controller.currentList.toList().length,
                  padding: objectMgr.loginMgr.isDesktop
                      ? const EdgeInsets.symmetric(vertical: 4)
                      : EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    var currentItem = controller.currentList[index];
                    bool isLargeDivider = (currentItem.largeDivider != null &&
                        currentItem.largeDivider!);
                    return objectMgr.loginMgr.isDesktop
                        ? Column(
                            children: [
                              HoverClickBuilder(
                                builder: (bool isHovered, bool isPressed) {
                                  return Transform.scale(
                                      scale: isPressed ? 0.95 : 1,
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: isHovered || isPressed
                                                ? colorBackground6
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: optionItem(index,
                                              type: controller
                                                  .currentList[index]
                                                  .optionType)));
                                },
                              ),
                              if (isLargeDivider &&
                                  currentItem.title !=
                                      localized(clearChatHistory) &&
                                  index != controller.currentList.length - 1)
                                const CustomDivider(height: 5)
                            ],
                          )
                        : optionItem(index,
                            type: controller.currentList[index].optionType);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void onPointerMove(Offset position) {
    RenderBox listRenderBox =
        controller.listKey.currentContext!.findRenderObject() as RenderBox;
    Offset localOffset = listRenderBox.globalToLocal(position);
    double accumulatedWidth = localOffset.dx;
    if (accumulatedWidth < 0) {
      currentIndex = 100;
      setState(() {});
      return;
    }
    double scrollOffset = localOffset.dy;
    double accumulatedHeight = 0;
    int selectedIndex = 100;
    // 遍历计算累积高度，并判断当前滑动到了哪个 item
    for (int i = 0; i < controller.itemKeys.length; i++) {
      GlobalKey key = controller.itemKeys[i];
      if (key.currentContext != null) {
        RenderBox itemRenderBox =
            key.currentContext!.findRenderObject() as RenderBox;
        double itemHeight = itemRenderBox.size.height;
        accumulatedHeight += itemHeight;

        if (scrollOffset > 0 && scrollOffset < accumulatedHeight) {
          selectedIndex = i;
          break;
        }
      }
    }
    if (selectedIndex != 100) {
      if (selectedIndex != currentIndex) {
        ToolOptionModel model = controller.currentList[selectedIndex];
        if (model.optionType == SecondaryMenuOption.tip.optionType) {
          return;
        }
        vibrate();
        currentIndex = selectedIndex;
        setState(() {});
      } else {
        if (currentIndex != 100 && scrollOffset <= 0) {
          currentIndex = 100;
          setState(() {});
        }
      }
    } else {
      if (currentIndex != 100) {
        currentIndex = 100;
        setState(() {});
      }
    }
  }

  Future<void> onPointerUp() async {
    if (currentIndex >= 0 && currentIndex < controller.currentList.length) {
      if (controller.isNeedCallBack(currentIndex)) {
        widget.func!();
      }
      controller.onTap(currentIndex);
      currentIndex = 100;
    }
  }

  Widget optionItem(int index, {String? type}) {
    BorderRadius radius = BorderRadius.zero;
    bool? withEffect = currentIndex == 100 ? null : currentIndex == index;

    if (type == SecondaryMenuOption.tip.optionType) withEffect = false;
    if (index == 0) {
      radius = BorderRadius.only(
        topLeft: Radius.circular(widget.radius ?? 10),
        topRight: Radius.circular(widget.radius ?? 10),
      );
    } else if (index == controller.currentList.toList().length - 1) {
      radius = BorderRadius.only(
        bottomLeft: Radius.circular(widget.radius ?? 10),
        bottomRight: Radius.circular(widget.radius ?? 10),
      );
    }
    var currentItem = controller.currentList[index];
    bool isLargeDivider =
        (currentItem.largeDivider != null && currentItem.largeDivider!);
    if (!currentItem.isShow) return const SizedBox();
    return Container(
      key: controller.itemKeys[index],
      decoration: BoxDecoration(
        borderRadius: radius,
        color: withEffect == null || objectMgr.loginMgr.isDesktop
            ? null
            : withEffect
                ? colorBackground6
                : null,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                vertical: objectMgr.loginMgr.isDesktop ? 6 : 10,
                horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (currentItem.leftIconUrl != null)
                  SvgPicture.asset(
                    currentItem.leftIconUrl ?? '',
                    width: 24,
                    height: 24,
                    color: currentItem.color ?? colorTextPrimary,
                  ),
                if (currentItem.leftIconUrl != null)
                  const SizedBox(
                    width: 12,
                  ),
                Expanded(
                  child: currentItem.specialTitles == null
                      ? Text(
                          currentItem.title,
                          style: currentItem.titleTextStyle ??
                              jxTextStyle.textStyle17(
                                color: currentItem.color ?? colorTextPrimary,
                              ),
                        )
                      : RichText(
                          text: TextSpan(children: _buildTextSpans(index)),
                        ),
                ),
                if (currentItem.imageUrl != null)
                  SvgPicture.asset(
                    currentItem.imageUrl ?? '',
                    width: 24,
                    height: 24,
                    color: currentItem.color ?? colorTextPrimary,
                  ),
                if (currentItem.trailingText != null)
                  Text(
                    currentItem.trailingText!,
                    style: currentItem.trailingTextStyle ??
                        jxTextStyle.textStyle12(
                            color: colorTextPrimary.withOpacity(0.48)),
                  )
              ],
            ),
          ),
          if (!objectMgr.loginMgr.isDesktop)
            Container(
                decoration: BoxDecoration(
              border: Border(
                bottom: index == controller.currentList.length - 1
                    ? BorderSide.none
                    : BorderSide(
                        color: isLargeDivider
                            ? colorBackground6
                            : colorTextPlaceholder,
                        width: isLargeDivider
                            ? 7
                            : (currentItem.title == localized(deleteChatHistory)
                                ? 0
                                : 0.33),
                      ),
              ),
            )),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextSpans(int index) {
    return controller.buildTextSpans(index);
  }
}
