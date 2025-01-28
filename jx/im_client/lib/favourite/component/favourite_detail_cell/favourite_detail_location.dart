import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/location_detail.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteDetailLocation extends StatelessWidget {
  final FavouriteLocation data;

  const FavouriteDetailLocation({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          builder: (BuildContext ctx) {
            return LocationDetail(
              title: data.name,
              detail: data.address,
              latitude: data.latitude,
              longitude: data.longitude,
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: colorTextPrimary.withOpacity(0.03),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: notBlank(data.url)
                    ? RemoteGaussianImage(
                        src: data.url,
                        gaussianPath: data.gausPath,
                        fit: BoxFit.cover,
                        mini: Config().messageMin,
                        width: 74,
                        height: 74,
                      )
                    : Image.file(
                        File(data.filePath),
                        fit: BoxFit.cover,
                        width: 74,
                        height: 74,
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: jxTextStyle.headerText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.address,
                    style: jxTextStyle.normalText(color: colorTextSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
