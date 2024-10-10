import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/config.dart';

import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';

class MomentMyPostsPictureWidget extends StatelessWidget {
  final String? videoPath;
  final List<MomentContentDetail>? momentContentDetail;
  final double lRSpace; // 外部設定的左右間距
  final bool isHandleFour;
  final double width;
  final double space; // 上下左右間距
  final ScrollController _scrollController = ScrollController();

  MomentMyPostsPictureWidget({
    super.key,
    required this.width,
    this.videoPath,
    this.momentContentDetail,
    this.lRSpace = 0.0,
    this.isHandleFour = true,
    this.space = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    if (momentContentDetail != null && momentContentDetail!.isNotEmpty) {
      return Offstage(
        offstage: momentContentDetail!.isEmpty,
        child: SizedBox(
          height: 80,
          child: customGridView(momentContentDetail!.length),
        ),
      );
    } else {
      return const Text("");
    }
  }

  GridView customGridView(int length) {
    return GridView.custom(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: length == 1
            ? 1
            : //1張照片
            length < 5
                ? 2
                : //2,3,4張照片
                3, //5,6,7,8,9張照片
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        pattern: tilePattern(length),
      ),
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double height = constraints.maxHeight;
              return _itemCell(
                context,
                index,
                width,
                height,
                momentContentDetail!.length == 1 ? true : false,
              );
            },
          );
        },
        childCount: length,
      ),
    );
  }

  _itemCell(context, index, width, height, bool originalSize) {
    var img = momentContentDetail![index];
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        GaussianImage(
          src: img.type == "video" ? img.cover! : img.url,
          width: width,
          height: height,
          gaussianPath: img.gausPath,
          mini: Config().messageMin,
          fit: BoxFit.cover,
        ),
        if (img.type == "video")
          SvgPicture.asset(
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          ),
      ],
    );
  }

  List<QuiltedGridTile> tilePattern(int number) {
    List<QuiltedGridTile> tilesPattern = [];
    switch (number) {
      case 1:
        tilesPattern = [const QuiltedGridTile(1, 1)];
        break;
      case 2:
        tilesPattern = [
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(2, 1),
        ];
        break;
      case 3:
        tilesPattern = [
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 4:
        tilesPattern = [
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 5:
        tilesPattern = [
          const QuiltedGridTile(2, 2),
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 6:
        tilesPattern = [
          const QuiltedGridTile(2, 2),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 7:
        tilesPattern = [
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 8:
        tilesPattern = [
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
      case 9:
        tilesPattern = [
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ];
        break;
    }

    return tilesPattern;
  }
}
