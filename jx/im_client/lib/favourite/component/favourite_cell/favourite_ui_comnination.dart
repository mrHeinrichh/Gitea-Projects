import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteUICombination extends FavouriteUIComponent {
  const FavouriteUICombination({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget buildContentView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_shouldShowTitle()) _buildTitle(),
              _buildContentList(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildIcon(iconPathList),
      ],
    );
  }

  bool _shouldShowTitle() {
    return title.isNotEmpty && notBlank(title.first.toPlainText());
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: title,
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        contentList.length,
        (index) => RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: contentList[index],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(List<Map<String, dynamic>> iconPathList) {
    if (iconPathList.isEmpty) return const SizedBox();

    final Map<String, dynamic> iconMap = iconPathList.first;
    String path = iconMap['path'];
    String gausPath = iconMap['gausPath'];
    bool isFake = iconMap['isFake'] ?? false;
    int typ = iconMap['typ'];

    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: isFake
                  ? Image.file(
                      File(path),
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    )
                  : RemoteGaussianImage(
                      src: path,
                      gaussianPath: gausPath,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    )),
          Visibility(
            visible: typ == FavouriteTypeVideo,
            child: SvgPicture.asset(
              'assets/svgs/video_play_icon.svg',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
    );
  }
}
