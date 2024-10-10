part of '../index.dart';

/// 長按回調，返回目前索引和所有圖片數組
// typedef _OnLongPress = void Function(int index, dynamic imgArr);

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

class MomentPictureWidgetState extends State<MomentPictureWidget>{

  late final RxList<String> source = RxList<String>();
  final thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    if (widget.momentContentDetail != null && widget.momentContentDetail!.isNotEmpty) {
      bool isHandleFourNew = widget.isHandleFour && widget.momentContentDetail!.length == 4;
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
        widget.momentContentDetail!.first.height > widget.momentContentDetail!.first.width
            ? bgWidth = widget.width * 0.75
            : bgWidth = widget.width * 0.55;
        widget.momentContentDetail!.first.width > widget.momentContentDetail!.first.height
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
              mainAxisExtent:
              widget.momentContentDetail!.length == 1 ? bgWidth : (bgWidth / 3),
            ),
            // 禁用滾動事件
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            // GridView內邊距
            childrenDelegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return Container(
                  child: _itemCell(
                    context,
                    index,
                    bgWidth,
                    widget.momentContentDetail!.length == 1 ? true : false,
                  ),
                );
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
    return Hero(
      tag: img.uniqueId,
      transitionOnUserGestures: false,
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(toContext).style,
          child: toContext.widget,
        );
      },
      child: GestureDetector(
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              GaussianImage(
                src: img.type == "video" ? img.cover! : img.url,
                 width: originalSize ? img.width.toDouble() : width.toDouble(),
                 height: originalSize ? img.height.toDouble() : width.toDouble(),
                gaussianPath: img.gausPath,
                mini: Config().messageMin,
                fit: BoxFit.cover,
                enableShimmer:false
              ),
              if (img.type == "video")
                SvgPicture.asset(
                  'assets/svgs/video_play_icon.svg',
                  width: 40,
                  height: 40,
                ),
            ],
          ),
        ),
        onTap: () => _clickItemCell(context, index),
      ),
    );
  }

  /// 點擊cell，顯示全圖
  _clickItemCell(
      context,
      index,
      ) {
    // PhotoBrowser.show(context,
    //     data: imgPath!, index: index, onLongPress: onLongPress);
    if (!notBlank(widget.momentContentDetail)) return;

    Get.find<MomentHomeController>().closeKeyboard();

    if (objectMgr.loginMgr.isMobile) {
      Navigator.of(context).push(
        TransparentRoute(
          builder: (BuildContext context) => MomentAssetPreview(
            assets: widget.momentContentDetail!,
            index: index,
            postId: widget.postId,
            userId: widget.userId,
          ),
          settings: const RouteSettings(name: RouteName.momentAssetPreview),
        ),
      );
    }
  }

}
