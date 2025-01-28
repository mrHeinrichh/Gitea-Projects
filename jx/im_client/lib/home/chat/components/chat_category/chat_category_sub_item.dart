import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ChatCategorySubItem extends StatefulWidget {
  final void Function(ChatCategoryMenuType type)? onTapCallback;
  final List<ToolOptionModel> chatCategoryMenu;

  const ChatCategorySubItem({
    super.key,
    required this.chatCategoryMenu,
    this.onTapCallback,
  });

  @override
  State<ChatCategorySubItem> createState() => _ChatCategorySubItemState();
}

class _ChatCategorySubItemState extends State<ChatCategorySubItem> {
  final containerKey = GlobalKey();
  Offset localContainerPos = Offset.zero;
  bool hasTap = false;
  final ValueNotifier<int> movingIdx = ValueNotifier<int>(-1);

  void onMenuSelect(ToolOptionModel option, {bool vibrate = false}) {
    if (vibrate) HapticFeedback.mediumImpact();
    final ChatCategoryMenuType type =
        ChatCategoryMenuType.getType(option.optionType);
    widget.onTapCallback?.call(type);
  }

  void onPointerDown(_) {
    hasTap = true;

    RenderBox listRenderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    localContainerPos = listRenderBox.localToGlobal(Offset.zero);
  }

  void onPointerMove(PointerMoveEvent event) {
    if (!hasTap) return;

    // 44.0
    final diff = (event.position - localContainerPos).dy;
    if (diff < 0) {
      movingIdx.value = 0;
      return;
    }

    final movedIdx = diff ~/ 44;
    if (movingIdx.value != movedIdx) {
      HapticFeedback.mediumImpact();
      movingIdx.value = movedIdx;
    }
  }

  void onPointerUp(PointerUpEvent event) {
    final diff = (event.position - localContainerPos);

    movingIdx.value = -1;
    localContainerPos = Offset.zero;
    hasTap = false;

    if (diff.dy < 0 || diff.dy > (44 * widget.chatCategoryMenu.length)) return;
    if (diff.dx < 0 || diff.dx > localContainerPos.dx + 240) return;

    final idx = diff.dy ~/ 44;
    onMenuSelect(widget.chatCategoryMenu[idx], vibrate: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: containerKey,
      width: 240.0,
      decoration: BoxDecoration(
        color: colorSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Listener(
        onPointerDown: onPointerDown,
        onPointerMove: onPointerMove,
        onPointerUp: onPointerUp,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.chatCategoryMenu.length, (index) {
            final ToolOptionModel option = widget.chatCategoryMenu[index];

            final bool isLast = index == widget.chatCategoryMenu.length - 1;
            final bool largeDivider = option.largeDivider ?? false;

            return ValueListenableBuilder<int>(
              valueListenable: movingIdx,
              builder: (BuildContext context, int idx, Widget? child) {
                return ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(index == 0 ? 12.0 : 0.0),
                    topRight: Radius.circular(index == 0 ? 12.0 : 0.0),
                    bottomLeft: Radius.circular(isLast ? 12.0 : 0.0),
                    bottomRight: Radius.circular(isLast ? 12.0 : 0.0),
                  ),
                  child: OverlayEffect(
                    withEffect: idx == -1,
                    child: Container(
                      height: 44.0 + (largeDivider ? 4.0 : 0.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 11.0,
                      ),
                      decoration: BoxDecoration(
                        color: idx == index ? colorBackground6 : null,
                        border: Border(
                          bottom: BorderSide(
                            color: colorDivider,
                            width: largeDivider
                                ? 5.0
                                : isLast
                                    ? 0.0
                                    : 0.33,
                          ),
                        ),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      option.title,
                      style: jxTextStyle.textStyle17(
                          color: option.color ?? colorTextPrimary),
                    ),
                  ),
                  if (option.imageUrl != null)
                    SvgPicture.asset(
                      option.imageUrl!,
                      width: 24.0,
                      height: 24.0,
                      colorFilter: ColorFilter.mode(
                        option.color ?? colorTextPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
