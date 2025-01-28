part of '../index.dart';

class MomentPictureWidget extends StatefulWidget {
  final String? videoPath;
  final List<MomentContentDetail>? momentContentDetail;
  final double lRSpace; // 外部設定的左右間距
  final bool isHandleFour;
  final double width;
  final double space; // 上下左右間距
  final int userId;
  final int postId;

  const MomentPictureWidget({
    super.key,
    required this.width,
    required this.userId,
    required this.postId,
    this.videoPath,
    this.momentContentDetail,
    this.lRSpace = 0.0,
    this.isHandleFour = true,
    this.space = 5.0,
  });

  @override
  State<StatefulWidget> createState() => MomentPictureWidgetState();
}

class MomentPictureWidgetState extends State<MomentPictureWidget> {
  int heroEffectIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.momentContentDetail != null &&
        widget.momentContentDetail!.isNotEmpty) {
      bool isHandleFourNew =
          widget.isHandleFour && widget.momentContentDetail!.length == 4;
      var bgHeight = 0.0;
      var bgWidth = widget.width;

      if (widget.momentContentDetail!.length == 4) {
        bgHeight = ((bgWidth / 3) * 2) + 5;
      } else if (widget.momentContentDetail!.length > 6) {
        bgHeight = bgWidth + 10;
      } else if (widget.momentContentDetail!.length > 3) {
        bgHeight = ((bgWidth / 3) * 2) + 5;
      } else {
        bgHeight = (bgWidth / 3);
      }

      var crossAxisCount = isHandleFourNew ? 2 : 3;

      if (widget.momentContentDetail!.length == 1) {
        widget.momentContentDetail!.first.height >
                widget.momentContentDetail!.first.width
            ? bgWidth = widget.width * 0.75
            : bgWidth = widget.width * 0.55;
        widget.momentContentDetail!.first.width >
                widget.momentContentDetail!.first.height
            ? bgHeight = widget.width * 0.75
            : bgHeight = widget.width * 0.55;
        crossAxisCount = 1;
      }

      return Offstage(
        offstage: widget.momentContentDetail!.isEmpty,
        child: SizedBox(
          height: bgHeight,
          child: GridView.custom(
            scrollDirection: Axis.vertical,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // 可以直接指定每行（列）顯示多少個Item
              crossAxisCount: crossAxisCount,
              // 一行的Widget數量
              crossAxisSpacing: widget.space,
              //水平間距
              mainAxisSpacing: widget.space,
              //垂直間距
              childAspectRatio: 1,
              mainAxisExtent: widget.momentContentDetail!.length == 1
                  ? bgWidth
                  : (bgWidth / 3),
            ),
            // 禁用滾動事件
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            // GridView內邊距
            childrenDelegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                Widget item = Container(
                  child: _itemCell(
                    context,
                    index,
                    bgWidth,
                    widget.momentContentDetail!.length == 1 ? true : false,
                  ),
                );

                if (heroEffectIndex == -1 || heroEffectIndex == index) {
                  item = Hero(
                    tag: widget.momentContentDetail![index].uniqueId,
                    transitionOnUserGestures: false,
                    child: item,
                  );
                }

                item = Offstage(
                  offstage: heroEffectIndex == index,
                  child: item,
                );

                return item;
              },
              childCount: widget.momentContentDetail!.length,
            ),
          ),
        ),
      );
    } else {
      return const Text("");
    }
  }

  _itemCell(context, index, width, bool originalSize) {
    var img = widget.momentContentDetail![index];
    return GestureDetector(
        onTap: () => _clickItemCell(context, index),
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              MomentCellMedia(
                key: ValueKey("${widget.userId}${widget.postId}"),
                url: img.type == "video" ? img.cover! : img.url,
                width: originalSize ? img.width.toDouble() : width.toDouble(),
                height: originalSize ? img.height.toDouble() : width.toDouble(),
                fit: BoxFit.cover,
                gausPath: img.gausPath,
              ),
              if (img.type == "video")
                SvgPicture.asset(
                  'assets/svgs/video_play_icon.svg',
                  width: 40,
                  height: 40,
                ),
            ],
          ),
        ));
  }

  /// 點擊cell，顯示全圖
  _clickItemCell(
    context,
    index,
  ) {
    if (!notBlank(widget.momentContentDetail)) return;

    Get.find<MomentHomeController>().closeKeyboard();

    if (Get.find<MomentHomeController>().isClickingCover.value) {
      Get.find<MomentHomeController>().isClickingCover.value =
          !Get.find<MomentHomeController>().isClickingCover.value;
      return;
    }

    if (objectMgr.loginMgr.isMobile) {
      Navigator.of(context)
          .push(
        MomentHeroTransparentRoute(
          builder: (BuildContext context) => MomentAssetPreview(
            assets: widget.momentContentDetail!,
            index: index,
            postId: widget.postId,
            userId: widget.userId,
            onPageChange: (index) {
              heroEffectIndex = index;
              setState(() {});
            },
          ),
          settings: const RouteSettings(name: RouteName.momentAssetPreview),
        ),
      )
          .then((value) {
        // It needs to be updated after the animation time ends according to the gesture, otherwise there will be a flashing problem
        Future.delayed(
            const Duration(
                milliseconds:
                    MomentHeroTransparentRoute.TRANSITION_DURATION_TIMES - 50),
            () {
          heroEffectIndex = -1;
          setState(() {});
        });
      });
    }
  }
}
