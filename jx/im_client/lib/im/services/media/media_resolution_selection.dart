import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MediaResolutionSelection extends StatelessWidget {
  final AssetPreviewDetail asset;
  final AssetType type;
  final bool fromCamera;

  const MediaResolutionSelection({
    super.key,
    required this.asset,
    required this.type,
    required this.fromCamera,
  });

  String getResolutionDisplay(MediaResolution resolution) {
    final int width;
    if (asset.editedWidth != null) {
      width = asset.editedWidth!;
    } else {
      width = asset.entity.orientatedWidth;
    }

    final int height;
    if (asset.editedHeight != null) {
      height = asset.editedHeight!;
    } else {
      height = asset.entity.orientatedHeight;
    }
    Size resolutionSize = getResolutionSize(width, height, resolution.minSize);
    return '${resolutionSize.width.toInt()}x${resolutionSize.height.toInt()}';
  }

  bool get isVideo => type == AssetType.video;

  bool get shouldShowHighResolution =>
      (isVideo &&
          min(
                asset.editedHeight ?? asset.entity.orientatedHeight,
                asset.editedWidth ?? asset.entity.orientatedWidth,
              ) >=
              MediaResolution.video_high.minSize) ||
      (!isVideo &&
          min(
                asset.editedHeight ?? asset.entity.orientatedHeight,
                asset.editedWidth ?? asset.entity.orientatedWidth,
              ) >=
              MediaResolution.image_high.minSize);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        children: <Widget>[
          Transform.translate(
            offset: const Offset(0, 1),
            child: Container(
              height: 52,
              decoration: const BoxDecoration(
                color: colorBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Center(
                    child: Text(
                      localized(mediaResolutionTitle),
                      style: jxTextStyle
                          .textStyle17(color: colorTextPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Positioned(
                    left: 0.0,
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 24,
                          ),
                          child: Text(
                            localized(cancel),
                            style: jxTextStyle.textStyle17(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
            ),
            color: colorBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 10.0,
                    bottom: 8.0,
                  ),
                  child: Text(localized(mediaResolutionSelectionText),
                      style: jxTextStyle.normalText(color: colorTextLevelTwo)),
                ),
                buildResolutionOption(
                  context,
                  isVideo
                      ? MediaResolution.video_standard
                      : MediaResolution.image_standard,
                  isVideo,
                  false,
                ),
                if (shouldShowHighResolution)
                  Row(
                    children: [
                      Container(
                        height: 1.0,
                        width: 16.0,
                        color: colorSurface,
                      ),
                      const Divider(
                        height: 1.0,
                        color: colorBackground6,
                      ),
                    ],
                  ),
                if (shouldShowHighResolution)
                  buildResolutionOption(
                    context,
                    isVideo
                        ? MediaResolution.video_high
                        : MediaResolution.image_high,
                    isVideo,
                    true,
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 30.0,
                  ),
                  child: Text(localized(mediaResolutionDesc),
                      style: jxTextStyle.normalText(color: colorTextLevelTwo)),
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResolutionOption(
    BuildContext context,
    MediaResolution resolution,
    bool isVideo,
    bool isHigh,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(resolution);
      },
      child: ForegroundOverlayEffect(
        radius: BorderRadius.vertical(
          top: isHigh ? Radius.zero : const Radius.circular(8.0),
          bottom: shouldShowHighResolution && !isHigh
              ? Radius.zero
              : const Radius.circular(8.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.vertical(
              top: isHigh ? Radius.zero : const Radius.circular(8.0),
              bottom: shouldShowHighResolution && !isHigh
                  ? Radius.zero
                  : const Radius.circular(8.0),
            ),
          ),
          padding: const EdgeInsets.only(
            left: 21.0,
            right: 5.0,
            top: 5.0,
            bottom: 5.0,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localized(
                        resolution == MediaResolution.image_standard ||
                                resolution == MediaResolution.video_standard
                            ? standardResolutionText
                            : highResolutionText,
                      ),
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: colorTextPrimary,
                      ),
                    ),
                    Text(
                      getResolutionDisplay(resolution),
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVideo && asset.videoResolution == resolution ||
                  !isVideo && asset.imageResolution == resolution)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.done,
                    size: 22.0,
                    color: themeColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
