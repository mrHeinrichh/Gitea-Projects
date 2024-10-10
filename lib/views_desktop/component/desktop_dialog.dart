import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

const kDialogSize = Size(350, 500);

class DesktopDialog extends StatelessWidget {
  final Widget child;
  final Size dialogSize;

  const DesktopDialog({
    super.key,
    required this.child,
    this.dialogSize = kDialogSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, dimens) {
        return Center(
          child: SizedBox.fromSize(
            size: dialogSize,
            child: AspectRatio(
              aspectRatio: 1,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class DesktopDialogWithButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String buttonLeftText;
  final void Function()? buttonLeftOnPress;
  final String buttonRightText;
  final void Function()? buttonRightOnPress;

  const DesktopDialogWithButton({
    super.key,
    required this.title,
    required this.buttonLeftText,
    required this.buttonLeftOnPress,
    required this.buttonRightOnPress,
    required this.buttonRightText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorDesktopDarkGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: MFontWeight.bold7.value,
              color: colorTextPrimary,
            ),
          ),
          if (subtitle != null) ...{
            const SizedBox(height: 10),
            SizedBox(
              height: 57,
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:MFontWeight.bold4.value,
                  color: colorTextPrimary,
                ),
              ),
            )
          } else ...{
            const SizedBox(height: 17)
          },
          ElevatedButtonTheme(
            data: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                surfaceTintColor: colorBorder,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                elevation: 0.0,
                textStyle: TextStyle(
                    fontSize: 13,
                    color: colorTextPrimary,
                    fontWeight:MFontWeight.bold4.value),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: buttonLeftOnPress,
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(colorBorder)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        buttonLeftText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: buttonRightOnPress,
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(themeColor)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        buttonRightText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: colorWhite),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
