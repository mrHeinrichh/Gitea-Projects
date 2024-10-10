import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class ThemedAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? contentWidget;
  final String? cancelButtonText;
  final VoidCallback? cancelButtonCallback;
  final String? confirmButtonText;
  final VoidCallback? confirmButtonCallback;
  final String? overallButtonText;
  final VoidCallback? overallButtonCallback;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;

  const ThemedAlertDialog({
    super.key,
    this.title,
    this.content,
    this.contentWidget,
    this.cancelButtonText,
    this.confirmButtonText,
    this.overallButtonText,
    this.cancelButtonCallback,
    this.confirmButtonCallback,
    this.overallButtonCallback,
    this.confirmButtonColor,
    this.cancelButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = themeColor;
    return CupertinoAlertDialog(
      title: Text(title!),
      content: contentWidget ?? Text(content ?? ""),
      actions: overallButtonText != null
          ? [
              CupertinoDialogAction(
                onPressed: overallButtonCallback,
                child: Text(
                  overallButtonText ?? "Sure",
                  style: TextStyle(color: buttonColor),
                ),
              ),
            ]
          : [
              CupertinoDialogAction(
                onPressed: cancelButtonCallback,
                child: Text(
                  cancelButtonText ?? "Don't allow",
                  style:
                      TextStyle(color: cancelButtonColor ?? colorTextPrimary),
                ),
              ),
              CupertinoDialogAction(
                onPressed: confirmButtonCallback,
                child: Text(
                  confirmButtonText ?? "OK",
                  style: TextStyle(color: confirmButtonColor ?? themeColor),
                ),
              ),
            ],
    );
  }
}
