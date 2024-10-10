import 'package:flutter/material.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

class FileIcon extends StatelessWidget {
  final String fileName;
  final double? width;
  final double? height;
  final double? fontSize;

  const FileIcon({
    super.key,
    required this.fileName,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 40,
      height: height ?? 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(getFileIconBg(fileName)),
          fit: BoxFit.fill,
        ),
      ),
      child: Text(
        getFileExtension(fileName).replaceAll('.', '').toLowerCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? MFontSize.size12.value,
          fontWeight: MFontWeight.bold7.value,
        ),
      ),
    );
  }
}
