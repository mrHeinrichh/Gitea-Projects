import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/edit_note_controller.dart';
import 'package:jxim_client/favourite/favourite_detail_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteDetailMedia extends StatefulWidget {
  final FavouriteDetailData data;

  const FavouriteDetailMedia({
    super.key,
    required this.data,
  });

  @override
  State<FavouriteDetailMedia> createState() => _FavouriteDetailMediaState();
}

class _FavouriteDetailMediaState extends State<FavouriteDetailMedia> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Get.isRegistered<EditNoteController>()) {
          Get.find<EditNoteController>().onTapMedia(widget.data.id!);
        } else {
          Get.find<FavouriteDetailController>().onTapMedia(widget.data);
        }
      },
      child:
          widget.data.typ == FavouriteTypeImage ? _buildImage() : _buildVideo(),
    );
    // if (widget.isUploaded) {
    //   return widget.data.typ == FavouriteTypeImage
    //       ? _buildRemoteImage()
    //       : _buildRemoteVideo();
    // } else {
    //   return GestureDetector(
    //     onTap: () {
    //       FocusManager.instance.primaryFocus!.unfocus();
    //     },
    //     behavior: HitTestBehavior.opaque,
    //     // child: ElTooltip(
    //     //   showModal: false,
    //     //   showChildAboveOverlay: false,
    //     //   color: colorTextPrimary,
    //     //   position: ElTooltipPosition.bottomCenter,
    //     //   content: GestureDetector(
    //     //     onTap: () {
    //     //       // controller.removeDetail(data);
    //     //     },
    //     //     child: Column(
    //     //       mainAxisSize: MainAxisSize.min,
    //     //       children: [
    //     //         SvgPicture.asset(
    //     //           'assets/svgs/delete2_icon.svg',
    //     //           width: 24,
    //     //           height: 24,
    //     //           fit: BoxFit.fill,
    //     //         ),
    //     //         Text(
    //     //           localized(chatDelete),
    //     //           style: jxTextStyle.textStyle14(color: colorWhite),
    //     //         ),
    //     //       ],
    //     //     ),
    //     //   ),
    //     //   child: widget.data.typ == FavouriteTypeImage
    //     //       ? _buildImageFile()
    //     //       : _buildVideoFile(),
    //     // ),
    //     child: widget.data.typ == FavouriteTypeImage
    //         ? _buildImageFile()
    //         : _buildVideoFile(),
    //   );
    // }
  }

  _buildImage() {
    FavouriteImage image =
        FavouriteImage.fromJson(jsonDecode(widget.data.content!));
    if (notBlank(image.url)) {
      return RemoteGaussianImage(
        src: image.url,
        gaussianPath: image.gausPath,
        width: image.width.toDouble(),
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(image.filePath),
        width: image.width.toDouble(),
        fit: BoxFit.fitWidth,
      );
    }
  }

  _buildVideo() {
    FavouriteVideo video =
        FavouriteVideo.fromJson(jsonDecode(widget.data.content!));
    if (notBlank(video.url)) {
      return Stack(
        alignment: Alignment.center,
        children: [
          RemoteGaussianImage(
            src: video.cover.isNotEmpty ? video.cover : video.coverPath,
            gaussianPath: video.gausPath,
            width: video.width.toDouble(),
            fit: BoxFit.fitWidth,
          ),
          SvgPicture.asset(
            key: ValueKey("edit_${video.cover}"),
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          ),
        ],
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          video.cover.isEmpty
              ? Image.file(
                  File(video.coverPath),
                  width: video.width.toDouble(),
                  fit: BoxFit.fitWidth,
                )
              : RemoteGaussianImage(
                  src: video.cover,
                  gaussianPath: video.gausPath,
                  width: video.width.toDouble(),
                  fit: BoxFit.fitWidth,
                ),
          SvgPicture.asset(
            key: ValueKey("edit_${video.cover}"),
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          ),
        ],
      );
    }
  }
}
