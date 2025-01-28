import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/chat_info/components/file_icon.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteDetailDocument extends StatelessWidget {
  final FavouriteFile data;

  const FavouriteDetailDocument({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        openFileDocument(data.url, data.fileName);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorTextPrimary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: EdgeInsets.all(notBlank(data.cover) ? 8 : 16),
        child: Row(
          children: [
            _buildIcon(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.fileName,
                    style: jxTextStyle.headerText(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fileSize(data.length),
                    style: jxTextStyle.normalText(color: colorTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    Widget iconWidget = const SizedBox();
    String filename = '';
    bool ableShowCover = false;

    if (data.cover != '') {
      filename = data.cover;
      ableShowCover = true;
    } else {
      filename = data.fileName;
      ableShowCover = false;
    }

    if (data.isEncrypt == 1) {
      iconWidget = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorBorder,
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
    } else {
      if (filename.isNotEmpty && ableShowCover == true) {
        iconWidget = Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: RemoteGaussianImage(
              src: filename,
              gaussianPath: data.gausPath,
              fit: BoxFit.cover,
              mini: Config().messageMin,
              width: 74,
              height: 74,
            ),
          ),
        );
      } else {
        iconWidget = Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: FileIcon(
            fileName: filename,
            width: 40,
            height: 40,
            fontSize: MFontSize.size12.value,
          ),
        );
      }
    }
    return iconWidget;
  }
}
