import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:get/get.dart';

class DraggableImageIcon extends StatefulWidget {
  final List<Apps> list;
  final String? title;
  final bool enableDrag;
  final bool hasMoreButton;
  final bool hasTitle;
  final String instanceId;
  final Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragStarted;
  final Function(Velocity, Offset)? onDraggableCanceled;
  final Function(DraggableDetails)? onDragEnd;
  final Function(Apps app)? onDragCompleted;
  final Function(Apps app)? onTapItem;
  final VoidCallback? onTapMore;

  const DraggableImageIcon({
    super.key,
    required this.list,
    required this.instanceId,
    this.title,
    this.enableDrag = true,
    this.hasMoreButton = false,
    this.hasTitle = true,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.onTapItem,
    this.onTapMore,
  });

  @override
  State<DraggableImageIcon> createState() => _DraggableImageIconState();
}

class _DraggableImageIconState extends State<DraggableImageIcon> {
  PullDownAppletController miniAppController =
      Get.find<PullDownAppletController>();

  @override
  void initState() {
    super.initState(); // 调用父类的 initState 方法
    globalKeys = List.generate(widget.list.length, (index) => GlobalKey());
  }

  List<GlobalKey> globalKeys = [];

  @override
  void didUpdateWidget(DraggableImageIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (globalKeys.length != widget.list.length) {
      globalKeys = List.generate(widget.list.length, (index) => GlobalKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.hasTitle)
              Text(
                widget.title ?? localized(myMiniApp),
                style: jxTextStyle.textStyle13(
                    color: colorWhite.withOpacity(0.44)),
              ),
            if (widget.hasMoreButton)
              InkWell(
                child: Row(
                  children: [
                    Text(
                      localized(searchMore),
                      style: jxTextStyle.textStyle13(
                          color: colorWhite.withOpacity(0.44)),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: colorWhite.withOpacity(0.44),
                    )
                  ],
                ),
                onTap: () {
                  widget.onTapMore?.call();
                },
              )
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: (1.sw - (68 * 4) - (32 * 2)) / 3,
            mainAxisSpacing: 16,
            crossAxisCount: 4,
            childAspectRatio: 68 / 74,
          ),
          semanticChildCount: 8,
          itemCount: widget.list.length,
          itemBuilder: (BuildContext context, int index) {
            final item = widget.list[index];
            Widget childItem = Obx(() => Opacity(
                  opacity: widget.enableDrag &&
                          miniAppController.currentDragInstanceId.value ==
                              widget.instanceId &&
                          miniAppController.currentDragIndex.value == index
                      ? 0 // 只有当前实例中正在拖动的项才隐藏
                      : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: RemoteImage(
                          src: item.icon ?? '',
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 62.w,
                        child: Text(
                          item.name ?? '',
                          style: jxTextStyle.textStyle13(color: colorWhite),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ));

            if (widget.enableDrag) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  widget.onTapItem?.call(item);
                },
                child: LongPressDraggable(
                  key: globalKeys[index],
                  data: index,
                  onDragStarted: () {
                    miniAppController.currentDragInstanceId.value =
                        widget.instanceId;
                    miniAppController.currentDragIndex.value = index;
                    widget.onDragStarted?.call();
                  },
                  onDragUpdate: widget.onDragUpdate,
                  onDragCompleted: () {
                    widget.onDragCompleted?.call(item);
                    miniAppController.currentDragInstanceId.value = '';
                    miniAppController.currentDragIndex.value = null;
                  },
                  onDragEnd: widget.onDragEnd,
                  delay: const Duration(milliseconds: 150),
                  onDraggableCanceled: (velocity, offset) {
                    final RenderBox? renderBox = globalKeys[index]
                        .currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (renderBox == null) {
                      debugPrint('Unable to find RenderBox');
                      return;
                    }

                    // 获取子项的尺寸和位置
                    final size = renderBox.size;
                    final position = renderBox.localToGlobal(Offset.zero);

                    // 计算图标部分的中心点位置（图标在Column顶部）
                    final targetPosition = Offset(
                      position.dx + (size.width - 48) / 2, // 水平居中
                      position.dy, // 直接使用顶部位置
                    );

                    OverlayEntry? entry;

                    entry = OverlayEntry(
                      builder: (context) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            final currentOffset =
                                Offset.lerp(offset, targetPosition, value)!;
                            final scale = 1.5 - (value * 0.5);

                            return Positioned(
                              left: currentOffset.dx,
                              top: currentOffset.dy,
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: .8,
                                  child: ClipOval(
                                    child: RemoteImage(
                                      src: item.icon ?? '',
                                      height: 48.0, // 固定为原始大小
                                      width: 48.0, // 固定为原始大小
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            entry?.remove(); // 动画完成后移除
                            // 重置拖动状态
                            miniAppController.currentDragInstanceId.value = '';
                            miniAppController.currentDragIndex.value = null;
                          },
                        );
                      },
                    );

                    Overlay.of(context).insert(entry);

                    widget.onDraggableCanceled?.call(velocity, offset);
                  },
                  feedback: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0), // 动画从 0.5 缩放到 1.0
                    duration: const Duration(milliseconds: 250), // 动画时长
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Opacity(
                      opacity: .8,
                      child: ClipOval(
                        child: RemoteImage(
                          src: item.icon ?? '',
                          height: 72.0,
                          width: 72.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  child: childItem,
                ),
              );
            }
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                widget.onTapItem?.call(item);
              },
              child: childItem,
            );
          },
        ),
      ],
    );
  }
}
