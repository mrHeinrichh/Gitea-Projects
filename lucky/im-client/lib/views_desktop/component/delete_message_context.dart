import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import '../../im/chat_info/tool_option_model.dart';
import '../../main.dart';
import '../../object/chat/message.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import 'desktop_general_button.dart';

class DeleteMessageContext extends StatelessWidget {
  DeleteMessageContext({
    Key? key,
    required this.onTapSecondMenu,
    required this.message,
  }) : super(key: key);

  final void Function(ToolOptionModel, Message) onTapSecondMenu;
  final Message message;

  final ToolOptionModel deleteEveryoneModel = ToolOptionModel(
    title: localized(deleteForEveryone),
    optionType: DeletePopupOption.deleteForEveryone.optionType,
    largeDivider: false,
    color: Colors.red,
    isShow: true,
    tabBelonging: 1,
  );

  final ToolOptionModel deleteMeModel = ToolOptionModel(
    title: localized(deleteForMe),
    optionType: DeletePopupOption.deleteForMe.optionType,
    color: Colors.red,
    largeDivider: false,
    isShow: true,
    tabBelonging: 1,
  );

  bool checkDeletePermission() {
    return objectMgr.userMgr.isMe(message.send_id) &&
        DateTime.now().millisecondsSinceEpoch - (message.create_time * 1000) <
            const Duration(days: 1).inMilliseconds;
  }

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
                          localized(deleteMessage),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        localized(areYouSureYouWantToDeleteThisMessage),
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        if (checkDeletePermission())
                          const Divider(
                            height: 0,
                          ),
                        if (checkDeletePermission())
                          DesktopGeneralButton(
                            horizontalPadding: 0,
                            onPressed: () => onTapSecondMenu(
                              deleteEveryoneModel,
                              message,
                            ),
                            child: Container(
                              width: 400,
                              height: 50,
                              color: Colors.white,
                              child: Center(
                                child: Text(
                                  localized(deleteForEveryone),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        const Divider(
                          height: 0,
                        ),
                        DesktopGeneralButton(
                          horizontalPadding: 0,
                          onPressed: () => onTapSecondMenu(
                            deleteMeModel,
                            message,
                          ),
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
                                localized(deleteForMe),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    style: TextStyle(color: accentColor),
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
