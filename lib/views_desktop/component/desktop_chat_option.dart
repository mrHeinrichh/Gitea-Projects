import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

class DesktopChatOptionDialog extends StatelessWidget {
  const DesktopChatOptionDialog({
    super.key,
    required this.chat,
    required this.title,
    required this.subtitle,
    required this.function,
  });
  final Chat chat;
  final String title;
  final String subtitle;
  final Function() function;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                        bottom: 15,
                      ),
                      child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: subtitle,
                          style: jxTextStyle.alertDialogContent(),
                          children: [
                            chat.name.isNotEmpty
                                ? TextSpan(
                                    text: chat.name,
                                    style: jxTextStyle.alertDialogContentBold(),
                                  )
                                : TextSpan(
                                    text: localized(thisChat),
                                    style: jxTextStyle.alertDialogContent(),
                                  ),
                            TextSpan(
                              text: localized(chatThisActionCannotBeUndo),
                              style: jxTextStyle.alertDialogContent(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(
                      height: 0,
                    ),
                    DesktopGeneralButton(
                      horizontalPadding: 0,
                      onPressed: function,
                      child: Container(
                        width: 400,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            localized(buttonConfirm),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DesktopGeneralButton(
              onPressed: () => Get.back(),
              child: Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    localized(buttonCancel),
                    style: TextStyle(color: themeColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
