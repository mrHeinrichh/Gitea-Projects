import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/number_pad.dart';

/*
  使用
  在controller
  里面定义下面3个，如果需用页面随着键盘移动而移动可以只写第一行
  final KeyboardController keyboardController = KeyboardController();
  late Rx<Animation<Offset>?> offsetAnimation = Rx<Animation<Offset>?>(null);
  final GlobalKey globleKey1 = GlobalKey();
  var moreSpace = 0.0.obs;

  onClose 里面要dispose掉
  void onClose() {
    keyboardController.dispose();
    super.onClose();
  }

    updateBottomSpace(double space) {
    moreSpace.value = space;
    update();
  }

  在view中
            包裹整个页面，用于动画
            body: controller.offsetAnimation.value != null ? SlideTransition(
            position: controller.offsetAnimation.value!,
            child: content(),
            ): content(),

            注意textfiled要绑定一个globleKey1
            globalKey: controller.globleKey1,

            展示键盘
            controller.keyboardController.showKeyboard(
            globalKey: controller.globleKey1,
            textController: controller.commentController,
            focusNode: controller.markFocusNode,
            updateAnimation: (animation){
              controller.offsetAnimation.value = animation;
            },
            updateMoreSpace: (space){
               controller.updateBottomSpace(space);
            },
            onNumTap: (num,allString) {},
            );

            整个listview的最后面放一个

              // 使用 AnimatedContainer 进行动画过渡
              AnimatedContainer(
                duration: Duration(milliseconds: 100),
                height: controller.moreSpace.value,
              ),
* */
class KeyboardController extends GetxController
    with GetTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  TextEditingController? _textController;
  FocusNode? _focusNode;
  late void Function(String num, String allString) _onNumTap;
  void Function(Animation<Offset> animation)? _updateAnimation;
  void Function(double moreSpace)? _updateMoreSpace;
  GlobalKey? _globalKey;
  bool _showDot = true;
  VoidCallback? _onDone;
  VoidCallback? _onCancel;
  void Function(String num, String allString)? _onDeleteTap;

  final StreamController<bool> _showDotStreamController =
      StreamController<bool>.broadcast();

  AnimationController? _animationController;
  Animation<Offset>? _offsetAnimation;

  void showKeyboard({
    required TextEditingController textController,
    required FocusNode focusNode,
    required void Function(String num, String allString) onNumTap,
    void Function(Animation<Offset> animation)? updateAnimation,
    void Function(double moreSpace)? updateMoreSpace,
    GlobalKey? globalKey,
    bool showDot = true,
    VoidCallback? onDone,
    VoidCallback? onCancel,
    void Function(String num, String allString)? onDeleteTap,
  }) {
    if (_overlayEntry != null && _showDot != showDot) {
      // 说明键盘的样式发生了变化
      _showDotStreamController.add(showDot);
    }

    _focusNode?.removeListener(_focusNodeListener);

    // 先赋值
    _textController = textController;
    _focusNode = focusNode;
    _onNumTap = onNumTap;
    _updateAnimation = updateAnimation;
    _updateMoreSpace = updateMoreSpace;
    _globalKey = globalKey;
    _showDot = showDot;
    _onDone = onDone;
    _onCancel = onCancel;
    _onDeleteTap = onDeleteTap;

    const int waitMilliseconds = 120;

    if (_globalKey != null) {
      // 这里是控制整体UI上移的，防止键盘挡住输入框
      // 等系统键盘的动画结束后，才能拿到准确的值
      Future.delayed(const Duration(milliseconds: waitMilliseconds), () {
        // 获取 TextField 的 RenderBox
        final RenderBox renderBox =
            _globalKey!.currentContext!.findRenderObject() as RenderBox;

        // 获取 TextField 的位置
        final Offset offset = renderBox.localToGlobal(Offset.zero);

        // 计算 TextField 底部到屏幕底部的距离, 让键盘的顶部离textfiled的底部有10的间距
        final double textFieldBottomY = offset.dy + renderBox.size.height + 10;
        final double screenHeight = MediaQuery.of(Get.context!).size.height;

        // 这个自定义的键盘高度是280 基于此开始计算
        final double keyboardTopY =
            screenHeight - CustomKeyboard.keyboardHeight;
        double diff = 0;
        if (keyboardTopY < textFieldBottomY) {
          // 说明键盘挡住了textfield
          // diff 代表整体需要移动的距离
          diff = (keyboardTopY - textFieldBottomY) / screenHeight;
        }

        _animationController = AnimationController(
          duration: const Duration(
            milliseconds: CustomKeyboard.keyboardAnimationMilliseconds,
          ),
          vsync: this,
        );

        _offsetAnimation = Tween<Offset>(
          begin: Offset.zero, // 初始位置
          end: Offset(0, diff), // 终点位置，向上移动 100 像素
        ).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeInOut, // 使用平滑的曲线
          ),
        );

        if (_updateAnimation != null) {
          _updateAnimation!(_offsetAnimation!);
          _moveUp();
        }
      });
    }

    Future.delayed(const Duration(milliseconds: waitMilliseconds), () {
      if (_overlayEntry != null) return; // 如果键盘已显示，直接返回
      BuildContext context = navigatorKey.currentContext!;
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 0,
          right: 0,
          child: CustomKeyboard(
            showDotStream: _showDotStreamController.stream,
            showDot: _showDot,
            onDone: () {
              if (_onDone != null) {
                _onDone!();
              }
              _unfocus();
            },
            onCancel: () {
              if (_onCancel != null) {
                _onCancel!();
              }
              _unfocus();
            },
            onDeleteTap: () {
              String deleteChar = "";
              if (_textController!.text.isNotEmpty) {
                deleteChar = _textController!.text.substring(
                  _textController!.text.length - 1,
                  _textController!.text.length,
                );
                _textController!.text = _textController!.text
                    .substring(0, _textController!.text.length - 1);
              }
              if (_onDeleteTap != null) {
                _onDeleteTap!(deleteChar, _textController!.text);
              }
            },
            onNumTap: (String num) {
              String tempString = "${_textController!.text}$num";
              RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');
              if (!pattern.hasMatch(tempString) && tempString.isNotEmpty) {
                tempString = tempString.isNotEmpty
                    ? tempString.substring(0, tempString.length - 1)
                    : tempString;
              }
              if (tempString.indexOf("0") == 0 &&
                  tempString.indexOf(".") != 1 &&
                  tempString.length > 1) {
                tempString = tempString.substring(1);
              }
              _textController!.text = tempString;
              _onNumTap(num, tempString);
            },
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    });
    _focusNode?.addListener(_focusNodeListener);
    _focusNode?.requestFocus();
    _updateMoreSpace?.call(CustomKeyboard.keyboardHeight);
  }

  void _focusNodeListener() {
    if (_focusNode == null) {
      _hideKeyboard();
      return;
    }
    if (!_focusNode!.hasFocus) {
      // 失去聚焦就要隐藏键盘
      _hideKeyboard();
    }
  }

  // 失去聚焦
  void _unfocus() {
    Future.delayed(
        const Duration(
          milliseconds: CustomKeyboard.keyboardAnimationMilliseconds,
        ), () {
      _focusNode?.unfocus();
      _hideKeyboard();
    });
  }

  // 隐藏键盘
  void _hideKeyboard() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _updateMoreSpace?.call(0);
    _moveBack();
  }

  void _moveUp() {
    _animationController?.forward(); // 向前播放动画，触发向上移动
  }

  void _moveBack() {
    _animationController?.reverse(); // 反向播放动画，触发复位
  }

  @override
  void dispose() {
    // 记得在销毁控制器时清理 AnimationController
    _focusNode?.removeListener(_focusNodeListener);
    _animationController?.dispose();
    _showDotStreamController.close();
    _hideKeyboard();
    super.dispose();
  }
}

class CustomKeyboard extends StatefulWidget {
  static const int keyboardAnimationMilliseconds = 238;
  static const double keyboardHeight = 280;
  final VoidCallback? onDone;
  final VoidCallback? onCancel;
  final void Function() onDeleteTap;
  final void Function(String num) onNumTap;
  final bool showDot;
  final Stream<bool> showDotStream; // 添加Stream参数

  const CustomKeyboard({
    super.key,
    required this.onDone,
    required this.onCancel,
    required this.onNumTap,
    required this.onDeleteTap,
    required this.showDot,
    required this.showDotStream, // 初始化Stream参数
  });

  @override
  CustomKeyboardState createState() => CustomKeyboardState();
}

class CustomKeyboardState extends State<CustomKeyboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _showDot = true;
  late StreamSubscription<bool> _showDotSubscription;
  @override
  void initState() {
    super.initState();
    _showDot = widget.showDot;
    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: CustomKeyboard.keyboardAnimationMilliseconds,
      ),
      vsync: this,
    );

    // 监听Stream的变化
    _showDotSubscription = widget.showDotStream.listen((newShowDot) {
      setState(() {
        _showDot = newShowDot;
      });
    });

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _showKeyboard();
  }

  @override
  void dispose() {
    _showDotSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showKeyboard() {
    _animationController.forward();
  }

  void _hideKeyboard() {
    // 开始反向播放动画
    _animationController.reverse().then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: buildKeyboard(),
    );
  }

  Widget buildKeyboard() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 5,
      ),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 243, 243, 243),
        border: Border(
          top: BorderSide(
            width: 1,
            color: colorBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 243, 243, 243),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _hideKeyboard();
                      widget.onCancel?.call();
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ), // 去掉点击效果
                    ),
                    child: Text(
                      localized(buttonCancel),
                      style: jxTextStyle.textStyleBold14(
                        color: themeColor,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _hideKeyboard();
                      widget.onDone?.call();
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ), // 去掉点击效果
                    ),
                    child: Text(
                      localized(buttonDone),
                      style: jxTextStyle.textStyleBold14(
                        color: themeColor,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // NumberPad 控件，和之前一样
          NumberPad(
            showDot: _showDot,
            bottomColor: const Color.fromARGB(255, 243, 243, 243),
            noNumberBackgroundColor: const Color.fromARGB(255, 238, 238, 238),
            onNumTap: widget.onNumTap,
            onDeleteTap: widget.onDeleteTap,
          ),
        ],
      ),
    );
  }
}
