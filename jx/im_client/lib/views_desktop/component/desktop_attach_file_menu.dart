import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class AttachFileMenu extends StatelessWidget {
  const AttachFileMenu({
    super.key,
    required this.desktopPicker,
  });

  final Function(FileType) desktopPicker;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.back(),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: const EdgeInsets.only(left: 339, right: 5, bottom: 26),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 2, // 陰影擴散半徑
                  blurRadius: 10, // 陰影模糊半徑
                  offset: const Offset(0, 3), // 陰影偏移量
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 60,
                child: ElevatedButtonTheme(
                  data: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: colorBackground6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AttachFileBtn(
                        onTap: () {
                          desktopPicker(FileType.allMedia);
                        },
                        title: localized(attachedFileMedia),
                        svgPath: 'assets/svgs/attached_image.svg',
                      ),
                      AttachFileBtn(
                        onTap: () {
                          desktopPicker(FileType.document);
                        },
                        title: localized(chatFolder),
                        svgPath: 'assets/svgs/attached_doc.svg'
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttachFileBtn extends StatefulWidget {
  const AttachFileBtn({
    required this.onTap,
    required this.title,
    required this.svgPath,
    this.bottomLine = false,
    super.key,
  });

  final Function() onTap;
  final String title;
  final String svgPath;
  final bool bottomLine;

  @override
  State<AttachFileBtn> createState() => _AttachFileBtnState();
}

class _AttachFileBtnState extends State<AttachFileBtn> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          width: 150,
          height: 30,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFEBEBEB) : const Color(0xFFf7f7f7),
            border: Border(
              bottom: BorderSide(
                color: widget.bottomLine ? colorTextPlaceholder : Colors.transparent,
                width: 0.3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    color: colorTextPrimary,
                    decoration: TextDecoration.none,
                  ),),
              ),
              SvgPicture.asset(
                widget.svgPath,
              ),
            ],
          ),
        ),
      ),
    );

  }
}
