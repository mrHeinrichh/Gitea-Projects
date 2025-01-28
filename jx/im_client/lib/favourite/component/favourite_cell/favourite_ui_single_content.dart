import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/chat_info/components/file_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteUISingleContent extends FavouriteUIComponent {
  const FavouriteUISingleContent({
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
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: title,
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(
                contentList.length,
                (index) => RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: contentList[index],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildIcon(),
      ],
    );
  }

  Widget _buildIcon() {
    if (iconPathList.isEmpty) {
      return const SizedBox();
    }

    final iconPath = iconPathList.first;
    final int typ = iconPath['typ'];
    final String fileName = iconPath['fileName'] ?? "";
    final String path = iconPath['path'];
    final int isEncrypt =
        (typ == FavouriteTypeDocument) ? iconPath['isEncrypt'] : 0;
    final bool isFake = iconPath['isFake'] ?? false;
    final String gausPath = iconPath['gausPath'] ?? "";

    switch (typ) {
      case FavouriteTypeAudio:
        return _buildAudioIcon(path);
      case FavouriteTypeDocument:
        return isEncrypt == 1
            ? _buildEncryptedDocumentIcon()
            : _buildDocumentIcon(fileName, path, isFake, gausPath);
      case FavouriteTypeLocation:
        return _buildLocationIcon(path, gausPath, isFake);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAudioIcon(String path) {
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorBackground6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SvgPicture.asset(
        path,
        colorFilter: const ColorFilter.mode(
          colorTextPlaceholder,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildEncryptedDocumentIcon() {
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorBackground6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SvgPicture.asset(
        'assets/svgs/pdf_encrypt_lock_outlined.svg',
        colorFilter: ColorFilter.mode(
          themeColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildDocumentIcon(
      String fileName, String path, bool isFake, String gausPath) {
    if (path.isNotEmpty) {
      return _buildMediaIcon(isFake, path, gausPath);
    } else {
      return FileIcon(
        fileName: fileName,
        width: 68,
        height: 68,
        fontSize: MFontSize.size16.value,
      );
    }
  }

  Widget _buildLocationIcon(String path, String gausPath, bool isFake) {
    return ClipRRect(
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
              ));
  }

  Widget _buildMediaIcon(bool isFake, String icon, String gausPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: isFake
          ? Image.file(
              File(icon),
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            )
          : RemoteGaussianImage(
              src: icon,
              gaussianPath: gausPath,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
    );
  }
}
