import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/color.dart';

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

  const ThemedAlertDialog(
      {Key? key,
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
      this.cancelButtonColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = accentColor;
    return CupertinoAlertDialog(
      title: Text(title!),
      content: contentWidget ?? Text(content ?? ""),
      actions: overallButtonText != null
          ? [
              CupertinoDialogAction(
                  child: Text(
                    overallButtonText ?? "Sure",
                    style: TextStyle(color: buttonColor),
                  ),
                  onPressed: overallButtonCallback)
            ]
          : [
              CupertinoDialogAction(
                  child: Text(
                    cancelButtonText ?? "Don't allow",
                    style: TextStyle(
                        color: cancelButtonColor != null
                            ? cancelButtonColor
                            : JXColors.primaryTextBlack),
                  ),
                  onPressed: cancelButtonCallback),
              CupertinoDialogAction(
                  child: Text(
                    confirmButtonText ?? "OK",
                    style: TextStyle(
                        color: confirmButtonColor != null
                            ? confirmButtonColor
                            : accentColor),
                  ),
                  onPressed: confirmButtonCallback),
            ],
    );
  }
}
