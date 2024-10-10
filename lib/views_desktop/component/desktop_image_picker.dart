import 'package:flutter/material.dart';

import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class DesktopImagePicker extends StatelessWidget {
  final Offset offset;
  final void Function()? onFilePicker;
  final void Function()? onDelete;

  const DesktopImagePicker({
    super.key,
    required this.offset,
    this.onFilePicker,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          key: GlobalKey(),
          left: offset.dx,
          top: offset.dy,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButtonTheme(
                data: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: colorBorder,
                    padding: EdgeInsets.zero,
                    elevation: 0.0,
                  ),
                ),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: onFilePicker,
                      child: Container(
                        width: 200,
                        height: 30,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        child: Text(
                          'Choose from Gallery',
                          style: jxTextStyle.slidableTextStyle(),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onDelete,
                      child: Container(
                        width: 200,
                        height: 30,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        child: Text(
                          'Delete Photo',
                          style: jxTextStyle.slidableTextStyle(
                            color: colorRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
