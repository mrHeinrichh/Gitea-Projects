import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/sticker/attachment_keyboard_component.dart';
import 'package:jxim_client/im/sticker/facial_expression_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/file_type_util.dart' as file_type_util;
import 'package:jxim_client/utils/input/desktop_new_line_input.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views_desktop/component/attach_file_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_attach_file_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_share_contact.dart';
import 'dart:io';


abstract class InputUIComponent extends GetView<CustomInputController> {
  final bool onMoreOpen;
  @override
  final String tag;
  final bool isTextingAllowed;
  final bool isShowSticker;
  final bool isShowAttachment;
  final bool isNormalUserCanInput;
  final bool showBottomAttachment;

  const InputUIComponent({
    super.key,
    this.onMoreOpen = false,
    this.isTextingAllowed = true,
    this.isShowSticker = true,
    this.isShowAttachment = true,
    this.isNormalUserCanInput = false,
    required this.tag,
    this.showBottomAttachment = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextButtonTheme(
      data: TextButtonThemeData(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          overlayColor: MaterialStateProperty.all(colorBorder),
          shape: MaterialStateProperty.all(const CircleBorder()),
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: buildContent(context),
      ),
    );
  }

  InputDecoration getInputDecoration(
    CustomInputController controller,
    bool isDesktop,
  );

  void getFileFromDesktop(
    file_type_util.FileType fileType,
    BuildContext context,
    CustomInputController controller,
    bool isGettingFile,
  ) async {
    if (isGettingFile) return;

    if (fileType == file_type_util.FileType.allMedia ||
        fileType == file_type_util.FileType.document) {
      isGettingFile = true;
      FilePickerResult? r = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: fileType == file_type_util.FileType.allMedia
            ? FileType.media
            : FileType.any,
      );

      FilePickerResult? result = await renameFiles(r) ?? r;
      isGettingFile = false;
      Get.back();
      if (result == null) return;

      List<XFile> fileList =
          result.files.map((file) => XFile(file.path!)).toList();

      ///显示发送文件的详情
      desktopGeneralDialog(
        context,
        widgetChild: AttachFileDialog(
          title:
              fileType == file_type_util.FileType.allMedia ? 'Media' : 'File',
          file: fileList,
          fileType: fileType,
          chatId: controller.chatId,
        ),
      );
    } else {
      Get.back();
      desktopGeneralDialog(
        context,
        color: const Color.fromRGBO(0, 0, 0, 0.5),
        widgetChild: DesktopShareContact(
          controller: controller,
        ),
      );
    }
  }

  popDesktopSticker(BuildContext context, CustomInputController controller) {
    controller.chatController.showFaceView.value = true;
    desktopGeneralDialog(
      context,
      color: const Color.fromRGBO(0, 0, 0, 0),
      widgetChild: Container(
        padding: const EdgeInsets.only(
          top: 200,
          bottom: 80,
          left: 10,
          right: 10,
        ),
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 233),
            curve: Curves.easeOut,
            height: 600,
            width: 400,
            child: Stack(
              children: [
                FacialExpressionComponent(
                  isShowAttachment:
                  controller.chatController.showAttachmentView.value,
                  chat: controller.chatController.chat,
                  isShowSticker: controller.chatController.showFaceView.value,
                  isShowStickerPermission:
                  controller.chatController.showTextStickerEmoji,
                  isFocus: controller.inputFocusNode.hasFocus,
                  onDeleteLastOne: () {
                    final originalText = controller.inputController.text;
                    final newText = originalText.characters.skipLast(1).string;
                    controller.inputController.text = newText;
                  },
                ),
                AttachmentKeyboardComponent(
                  tag: tag,
                  chat: controller.chatController.chat,
                  isShowSticker: controller.chatController.showFaceView.value,
                  isFocus: controller.inputFocusNode.hasFocus,
                  isShowAttachment:
                  controller.chatController.showAttachmentView.value,
                  options: controller.chatController.attachmentOptions,
                  onHideAttachmentView: () =>
                  controller.chatController.showAttachmentView.value = false,
                )
              ],
            ),
          ),
        ),
      )
      // widgetChild: StickerDialog(
      //   chatID: controller.chatId,
      // ),
    );
  }

  List<Widget> buildContent(BuildContext context);

  Widget buildAddWidget(BuildContext context) {
    return AbsorbPointer(
      absorbing: notBlank(objectMgr.chatMgr.editMessageMap[
          controller.chatController.chat.chat_id]), // 消息编辑的时候不能发送附件
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          bool b = CoolDownManager.handler(key: 'add', duration: 200);
          if (b) {
            onAddClick(context);
            controller.isVoiceMode.value = false;
          }
        },
        child: Container(
          padding: objectMgr.loginMgr.isDesktop
              ? const EdgeInsets.all(8)
              : const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: OpacityEffect(
            child: SvgPicture.asset(
              controller.chatController.showAttachmentView.value
                  ? 'assets/svgs/nav.svg'
                  : 'assets/svgs/paper_clip.svg',
              width: 24.0,
              height: 24.0,
              colorFilter: ColorFilter.mode(
                notBlank(objectMgr.chatMgr
                        .editMessageMap[controller.chatController.chat.chat_id])
                    ? colorTextPlaceholder
                    : colorTextSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onAddClick(BuildContext context) {
    if (isDesktop) {
      desktopGeneralDialog(
        context,
        color: Colors.transparent,
        widgetChild: AttachFileMenu(
          desktopPicker: (file_type_util.FileType fileType) {
            getFileFromDesktop(fileType, context, controller, isGettingFile);
          },
        ),
      );
    } else {
      if (isShowAttachment && !onMoreOpen) {
        if (controller.chatController.showAttachmentView.value) {
          controller.inputFocusNode.requestFocus();
        } else {
          controller.onMore(context);
        }
      } else {
        Toast.showToast(
          localized(errorNoAttachmentsAllowed),
          isStickBottom: false,
        );
      }
    }
  }

  bool get isDesktop => controller.isDesktop;

  bool get isGettingFile => controller.isGettingFile;

  set isGettingFile(bool isGettingFile) {
    controller.isGettingFile = isGettingFile;
  }

  Widget buildDesktopSend() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton(
          onPressed: () => controller
              .onSendButtonClick(controller.inputController.text.trim()),
          child: Container(
            margin: const EdgeInsets.all(8),
            child: ForegroundOverlayEffect(
              radius: const BorderRadius.vertical(
                top: Radius.circular(100),
                bottom: Radius.circular(100),
              ),
              overlayColor:
                  controller.sendState.value ? themeColor : colorTextSecondary,
              child: SvgPicture.asset(
                'assets/svgs/send.svg',
                width: 22,
                height: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRightWidget() {
    return Obx(
      () => AnimatedCrossFade(
        firstChild: Row(
          children: <Widget>[
            IgnorePointer(
              ignoring: !isTextingAllowed,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.toggleVoiceMode,
                child: controller.isVoiceMode.value
                    ? OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 14,
                            top: 14,
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/input_keyboard.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      )
                    : OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 14,
                            top: 14,
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/mic_outlined.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        secondChild: Obx(() {
          return GestureDetector(
            onTap: () => controller
                .onSendButtonClick(controller.inputController.text.trim()),
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                right: 10.0,
                bottom: 12,
                top: 12,
              ),
              child: ClipOval(
                child: Container(
                  color: controller.isSending.value
                      ? colorTextSecondary
                      : themeColor,
                  width: 28,
                  height: 28,
                  padding: const EdgeInsets.all(6.0),
                  child: SvgPicture.asset(
                    'assets/svgs/send_arrow.svg',
                  ),
                ),
              ),
            ),
          );
        }),
        crossFadeState: controller.sendState.value ||
                controller.chatController.chat.isSecretary
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstCurve: Curves.easeInOutCubic,
        secondCurve: Curves.easeInOutCubic,
        duration: const Duration(milliseconds: 50),
      ),
    );
  }

  Widget buildEmojiWidget(BuildContext context) {
    return Visibility(
      visible: !onMoreOpen,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // if (isShowSticker) {
          bool b = CoolDownManager.handler(key: 'emoji', duration: 200);
          if (b) {
            controller.onOpenFace();
          }
          // } else {
          //   Toast.showToast(localized(errorNoStickersAllowed),
          //       isStickBottom: false);
          // }
        },
        child: OpacityEffect(
          child: Container(
            padding: jxDimension.emojiIconPadding(),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/svgs/${controller.chatController.showFaceView.value ? 'input_keyboard' : 'emoji'}.svg',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDesktopEmoji(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: TextButton(
        onPressed: () => popDesktopSticker(context, controller),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            'assets/svgs/emoji.svg',
            width: 22,
            height: 22,
            color: colorTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget buildInput(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(
        minHeight: 36,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.symmetric(
        vertical: objectMgr.loginMgr.isDesktop ? 5 : 0.0,
      ),
      child: buildTextFormField(context),
    );
  }

  Widget buildTextFormField(BuildContext context) {
    return TextFormField(
      textAlignVertical: TextAlignVertical.center,
      textAlign: TextAlign.left,
      maxLines: 10,
      minLines: 1,
      maxLength: 4096,
      scrollController: controller.scrollController,
      contextMenuBuilder: textMenuBarForClipBoard,//textMenuBar,
      onTap: () async {
        await controller.checkIOSClipboard();
      },
      autofocus: objectMgr.loginMgr.isDesktop ? true : false,
      focusNode: controller.inputFocusNode,
      controller: controller.inputController,
      keyboardType: objectMgr.loginMgr.isDesktop
          ? TextInputType.none
          : TextInputType.multiline,
      textInputAction:
          objectMgr.loginMgr.isDesktop ? TextInputAction.send : null,
      onFieldSubmitted: (value) {
        if (objectMgr.loginMgr.isDesktop) {
          if (!HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.shiftLeft) &&
              !HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.shiftRight)) {
            controller.onSendButtonClick(value.trim());
          }
          controller.inputFocusNode.requestFocus();
        }
      },
      scrollPhysics: const ClampingScrollPhysics(),
      readOnly: getReadOnly(),
      enabled: getEnabled(),
      enableInteractiveSelection: true,
      inputFormatters: [
        LengthLimitingTextInputFormatter(4096),
      ],
      cursorColor: themeColor,
      style: TextStyle(
        fontSize: isDesktop ? MFontSize.size14.value : MFontSize.size17.value,
        decoration: TextDecoration.none,
        color: getInputFieldColor(),
        height: 1.3,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: -0.5,
      ),
      decoration: getInputDecoration(controller, isDesktop),
      cursorHeight: isDesktop ? 14 : null,
    );
  }

  Widget textMenuBarForClipBoard(context,EditableTextState editableTextState) {
    final buttonItems = editableTextState.contextMenuButtonItems;

    return CustomizeAdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        if(Platform.isIOS &&
            controller.hasImageInClipBoardInIOS.value &&
            !buttonItems.any((element) => element.type == ContextMenuButtonType.paste)
        )
          ContextMenuButtonItem(
              onPressed: () async {
                // 点击了粘贴，然后去控制器做逻辑处理
                controller.clickPastImage();
                // 隐藏上下文菜单
                editableTextState.hideToolbar();
              },
              label: MaterialLocalizations.of(context).pasteButtonLabel
          ),
        ...buttonItems,
      ],
    );
  }

  Color getInputFieldColor();

  Widget buildAutoDeleteIntervalText(BuildContext context) {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.bounceOut,
        switchOutCurve: Curves.fastOutSlowIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(animation),
          child: child,
        ),
        child: (controller.sendState.value ||
                    !controller.chatController.chat.autoDeleteEnabled) &&
                controller.autoDeleteInterval.value == 0
            ? const SizedBox.shrink()
            : GestureDetector(
                onTap: () {
                  controller.showAutoDeletePopup(controller.chatController);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    parseAutoDeleteInterval(
                      controller.autoDeleteInterval.value,
                    ),
                    style: const TextStyle(
                      color: colorTextSecondary,
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildHoldToTalk(BuildContext context) {
    return GestureDetector(
      onLongPress: () => controller.startRecording(context),
      onLongPressMoveUpdate: (details) =>
          controller.updateLongPressRecording(context, details),
      onLongPressEnd: (_) =>
          controller.endRecording(!controller.isDeleteSelected.value),
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ForegroundOverlayEffect(
              radius: const BorderRadius.vertical(
                top: Radius.circular(20),
                bottom: Radius.circular(20),
              ),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: jxDimension.textInputRadius(),
                  border: Border.all(
                    color: const Color.fromRGBO(174, 174, 174, 0.3),
                  ),
                ),
                child: Text(
                  localized(holdToTalk),
                  style: TextStyle(
                    fontSize: isDesktop
                        ? MFontSize.size14.value
                        : MFontSize.size17.value,
                    decoration: TextDecoration.none,
                    color: getInputFieldColor(),
                    height: 1.2,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onKey(RawKeyEvent event, BuildContext context) {
    if (event is RawKeyDownEvent) {
      if ((event.isShiftPressed) &&
          (event.logicalKey.keyId == 4294967309 ||
              event.logicalKey.keyId == 8589935117)) {
        int cursorPosition = controller.inputController.selection.baseOffset;
        String text = controller.inputController.text;
        String newText =
            '${text.substring(0, cursorPosition)}\n${text.substring(cursorPosition)}';
        controller.inputController.text = newText;
        controller.inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + 1),
        );
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.scrollController.animateTo(
            controller.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      } else if (getCombinationKey()) {
        if (event.logicalKey == LogicalKeyboardKey.keyV) {
          controller.pasteImage(context);
        }
      }
    }
  }

  bool getReadOnly();

  bool getEnabled();
}
