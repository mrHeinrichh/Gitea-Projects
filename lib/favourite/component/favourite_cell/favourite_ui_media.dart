import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';

class FavouriteUIMedia extends FavouriteUIComponent {
  const FavouriteUIMedia({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget buildContentView() {
    int maxItems = iconPathList.length > 3 ? 3 : iconPathList.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        maxItems,
        (index) => Container(
          margin:
              index == 1 ? const EdgeInsets.symmetric(horizontal: 4.0) : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildImage(iconPathList[index], controller.size),
              ),
              _buildVideoIcon(iconPathList[index]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> iconData, double size) {
    if (iconData['isFake']) {
      return Image.file(
        File(iconData['path'] ?? ""),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      return GaussianImage(
        src: iconData['path'],
        gaussianPath: iconData['gausPath'],
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildVideoIcon(Map<String, dynamic> iconData) {
    if (iconData['typ'] == FavouriteTypeVideo) {
      return SvgPicture.asset(
        'assets/svgs/video_play_icon.svg',
        width: 40,
        height: 40,
      );
    }
    return const SizedBox();
  }
}
