import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/file_type_util.dart';

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
        child: Padding(
          padding: const EdgeInsets.only(left: 322, right: 5, bottom: 55),
          child: SizedBox(
            height: 130,
            child: ElevatedButtonTheme(
              data: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: colorBorder,
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
                  AttachFileButton(
                    onPressed: () {
                      desktopPicker(FileType.allMedia);
                    },
                    title: 'Medias',
                    widgetChild: SvgPicture.asset(
                      'assets/svgs/attach_media.svg',
                    ),
                  ),
                  AttachFileButton(
                    onPressed: () {
                      desktopPicker(FileType.document);
                    },
                    title: 'Files',
                    widgetChild: SvgPicture.asset(
                      'assets/svgs/attach_document.svg',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttachFileButton extends StatefulWidget {
  const AttachFileButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.color = Colors.white,
    this.widgetChild = const SizedBox(),
  });

  final Function() onPressed;
  final String title;
  final Color color;
  final Widget widgetChild;

  @override
  State<AttachFileButton> createState() => _AttachFileButtonState();
}

class _AttachFileButtonState extends State<AttachFileButton> {
  bool onHoverOver = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onHover: (value) {
            setState(() {
              onHoverOver = value;
            });
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(10),
            fixedSize: const Size(50, 50),
            elevation: 0,
            shape: const CircleBorder(),
          ),
          onPressed: widget.onPressed,
          child: widget.widgetChild,
        ),
        Visibility(
          visible: onHoverOver,
          child: Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  child: Text(
                    widget.title,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
