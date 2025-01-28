import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:provider/provider.dart';
import '../custom_input/custom_input_controller.dart';

class ChatBottomWidget extends StatefulWidget {
  ChatBottomWidget({Key? key, required this.tag}) : super(key: key);
  final dynamic tag;

  @override
  ChatBottomWidgetState createState() => ChatBottomWidgetState();
}

class ChatBottomWidgetState extends State<ChatBottomWidget>
    with TickerProviderStateMixin {
  //原生鍵盤是否顯示
  bool isKeyboardShow = false;

  //text flight
  late final inputTextController =
      Get.find<CustomInputController>(tag: widget.tag);

  late final GroupChatController chatController =
      Get.find<GroupChatController>(tag: widget.tag);

  Widget? keyboard;

  Widget? emptyWidget;

  Widget? body;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    GameManager.shared.onShowBetPanel(KeyboardInteractionType.none);
    super.dispose();
  }

  void onEnd(bool isShowBetPanel) {
    if (isShowBetPanel) {
      chatController.isShowGameKeyboard.value = true;
      inputTextController.isCurrentShowGamePanel.value = true;
    } else {
      //隱藏輸入框
      body = null;

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: groupBottomWidgetProvider),
        ],
        child: Selector<GroupChatBottomNotifier, bool>(
          selector: (_, model) => model.isShowBetPanel,
          builder: (_, isShowBetPanel, __) {
            if (isShowBetPanel) {
              body = buildBody();
            }
            return ClipRRect(
              child: body,
              // child: AnimatedAlign(
              //   alignment: Alignment.bottomCenter,
              //   duration: Duration(
              //     milliseconds: isShowBetPanel ? 233 : 180,
              //   ),
              //   curve: Curves.easeOut,
              //   heightFactor: isShowBetPanel ? 1.0 : 0.0,
              //   onEnd: () => onEnd(isShowBetPanel),
              //   child: body,
              // ),
            );
          },
        ));
  }

  Widget? buildBody() {
    FocusScope.of(context).unfocus();
    return betPanelWidget(tag: widget.tag.toString());
  }
}
