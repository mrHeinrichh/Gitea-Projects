import 'package:im/widget/common_widget/common_pipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/game_custom_input_controller.dart';

import '../../../api/group.dart';
import '../../../main.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/dimension_styles.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../utils/throttle.dart';
import '../../../utils/toast.dart';
import '../../../views/component/click_effect_button.dart';
import '../../base/base_chat_controller.dart';
import '../../bet_msg_filter/bet_msg_filter_config.dart';
import '../../bet_msg_filter/bet_msg_filter_manager.dart';
import '../../model/group/group.dart';
import 'input_ui_component.dart';

class GameTextInputView extends InputUIComponent {
  const GameTextInputView({
    super.key,
    super.onMoreOpen = false,
    super.isTextingAllowed = true,
    super.isShowSticker = true,
    super.isShowAttachment = true,
    required super.tag,
    super.showBottomAttachment = true,
  });

  @override
  List<Widget> buildContent(BuildContext context) {
    return [
      //顯示更多資訊
      _buildMoreMsg(),
      Obx(
        () => controller.isShowGameKeyboard.value &&
                controller.isCurrentShowGamePanel.value
            ? const SizedBox(
                width: 12,
              )
            : const SizedBox(),
      ),
      Obx(() {
        if (!controller.isShowMoreAction.value) {
          return _defaultInputLayout(context);
        } else {
          return _showKeyboardMenu(context);
        }
      }),
    ];
  }

  Widget _buildMoreMsg() {
    return Obx(
      () => Visibility(
        visible: controller.isShowGameKeyboard.value &&
            !controller.isCurrentShowGamePanel.value &&
            controller.type == 2,
        child: TextButton(
          onPressed: controller.showMoreClick,
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(
                isDesktop ? 44 : 46,
                isDesktop ? 22 : 24,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.center),
          child: Obx(
            () => Container(
              height: 50,
              padding: controller.isNormalUser.value &&
                      !controller.isNormalUserCanInput.value
                  ? const EdgeInsets.only(left: 12.0, right: 12.0)
                  : const EdgeInsets.only(left: 12.0),
              child: SvgPicture.asset(
                controller.isShowMoreAction.value
                    ? 'assets/svgs/hide_action.svg'
                    : 'assets/svgs/show_action.svg',
                width: 24.0,
                height: 24.0,
                // color: ImColor.black48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultInputLayout(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPaperClip(context),
          Expanded(
            child: Obx(() {
              if (controller.isVoiceMode.value) {
                return GestureDetector(
                  onLongPress: () => controller.startRecording(context),
                  onLongPressMoveUpdate: (details) =>
                      controller.updateLongPressRecording(context, details),
                  onLongPressEnd: (_) => controller
                      .endRecording(!controller.isDeleteSelected.value),
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 36,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        // padding: const EdgeInsets.symmetric(vertical: 9.0),
                        decoration: BoxDecoration(
                          color: JXColors.lightShade,
                          borderRadius: jxDimension.textInputRadius(),
                          border: Border.all(
                            color: const Color(0x33121212),
                          ),
                        ),
                        child: Text(
                          localized(holdToTalk),
                          style: TextStyle(
                            fontSize: isDesktop
                                ? MFontSize.size14.value
                                : MFontSize.size17.value,
                            decoration: TextDecoration.none,
                            color: JXColors.primaryTextBlack,
                            height: 1.2,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 0 : 4),
                child: RawKeyboardListener(
                    focusNode: FocusNode(onKeyEvent: (node, event) {
                      if ((HardwareKeyboard.instance.logicalKeysPressed
                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                              HardwareKeyboard.instance.logicalKeysPressed
                                  .contains(LogicalKeyboardKey.shiftRight)) &&
                          event.logicalKey.keyId == 8589935117) {
                        return KeyEventResult.handled;
                      } else
                        return KeyEventResult.ignored;
                    }),
                    onKey: (RawKeyEvent event) {
                      onKey(event, context);
                    },
                    child: Stack(
                      children: [
                        _buildInputWidget(context),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 10,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3.0),
                                child: buildAutoDeleteIntervalText(context),
                              ),
                              _buildShortTalk(context),
                              if (objectMgr.loginMgr.isDesktop)
                                buildDesktopEmoji(context)
                              else ...{
                                _buildEmojiIcon(),
                              },
                            ],
                          ),
                        )
                      ],
                    )),
              );
            }),
          ),
          if (!isDesktop)
            Container(
              child: Obx(
                () => AnimatedCrossFade(
                  firstChild: Row(
                    children: <Widget>[
                      _getVoiceWidget(context),
                      //遊戲鍵盤icon
                      _buildGameIcon(),
                    ],
                  ),
                  secondChild: Row(
                    children: [
                      _getVoiceWidget(context),
                      _buildSendIcon(),
                    ],
                  ),
                  crossFadeState: controller.sendState.value ||
                          controller.chatController.chat.isSecretary
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 50),
                ),
              ),
            ),
          if (isDesktop) buildDesktopSend(),
        ],
      ),
    );
  }

  Container _buildInputWidget(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          minHeight: 36,
          maxHeight: MediaQuery.of(context).size.height -
              keyboardHeight.value -
              188 -
              MediaQuery.of(context).padding.top),
      margin: const EdgeInsets.only(top: 5, bottom: 2),
      padding:
          EdgeInsets.symmetric(vertical: objectMgr.loginMgr.isDesktop ? 5 : 0),
      child: !controller.isCurrentShowGamePanel.value &&
              controller.isShowGameKeyboard.value &&
              (controller.isNormalUser.value &&
                  !controller.isNormalUserCanInput.value)
          ? GestureDetector(
              onTap: () {
                //跳出快捷短語彈窗
                _showShortcutTalkView(context);
              },
              child: buildTextFormField(),
            )
          : buildTextFormField(),
    );
  }

  Visibility _buildEmojiIcon() {
    return Visibility(
      visible: !onMoreOpen && (!controller.isCurrentShowGamePanel.value),
      child: TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(isDesktop ? 22 : 24, isDesktop ? 22 : 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.center),
        onPressed: () async {
          if (controller.isCurrentShowGamePanel.value) {
            //如果當前開啟遊戲鍵盤就先關閉遊戲鍵盤
            _openGameKeyboard(false);
          }
          if (isShowSticker) {
            controller.onOpenFace();
          } else {
            Toast.showToast(localized(errorNoStickersAllowed),
                isStickBottom: false);
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (controller.isShowShortTalk.value) {
            //如果有開啟快捷短語就關閉快捷短語
            controller.onOpenShortTalk(controller.assetPickerProvider);
            controller.inputFocusNode.unfocus();
          }
        },
        child: Container(
          // color: Colors.red,
          padding: jxDimension.emojiIconPadding(),
          alignment: Alignment.bottomCenter,
          child: SvgPicture.asset(
            'assets/svgs/emoji.svg',
            width: isDesktop ? 22 : 24,
            height: isDesktop ? 22 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPaperClip(BuildContext context) {
    return Obx(
      () => Visibility(
        visible: !controller.isShowGameKeyboard.value ||
            !(controller.isNormalUser.value &&
                    !controller.isNormalUserCanInput.value) &&
                !controller.isCurrentShowGamePanel.value,
        child: Padding(
          padding: controller.isShowGameKeyboard.value
              ? const EdgeInsets.only(right: 4, bottom: 13)
              : const EdgeInsets.only(left: 8, right: 6, bottom: 13),
          child: TextButton(
            onPressed: () {
              onAddClick(context);
            },
            style: jxDimension.textInputButtonStyle(),
            child: Padding(
              padding: EdgeInsets.all(objectMgr.loginMgr.isDesktop ? 8.0 : 0),
              child: SvgPicture.asset(
                controller.chatController.showAttachmentView.value
                    ? 'assets/svgs/nav.svg'
                    : 'assets/svgs/paper_clip.svg',
                width: 24.0,
                height: 24.0,
                // color: inputHintTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Visibility _buildShortTalk(BuildContext context) {
    return Visibility(
      visible: controller.isShowGameKeyboard.value &&
          (controller.isNormalUser.value &&
              !controller.isNormalUserCanInput.value) &&
          !controller.isCurrentShowGamePanel.value,
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              //跳出快捷短語彈窗
              _showShortcutTalkView(context);
            },
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(isDesktop ? 8 : 10, isDesktop ? 8 : 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.center),
            child: SvgPicture.asset(
              !controller.isShowShortTalk.value
                  ? 'assets/svgs/arrow_up.svg'
                  : 'assets/svgs/arrow_down.svg',
              width: isDesktop ? 8 : 24,
              height: isDesktop ? 8 : 24,
              fit: BoxFit.contain,
              colorFilter:
                  const ColorFilter.mode(JXColors.black24, BlendMode.srcIn),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 6),
            child: SvgPicture.asset(
              'assets/svgs/input_line_v.svg',
              width: 8,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendIcon() {
    return OverlayEffect(
      child: Container(
        margin: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 14),
        child: GestureDetector(
          onTap: () {
            controller.onSend(controller.inputController.text.trim());
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: controller.inputController.text.trim().isNotEmpty
                  ? accentColor
                  : JXColors.secondaryTextBlack,
              borderRadius: BorderRadius.circular(100),
            ),
            child: SvgPicture.asset(
              'assets/svgs/send.svg',
              // width: 12.56,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    );
  }

  Visibility _buildGameIcon() {
    return Visibility(
      visible: controller.isShowGameKeyboard.value && controller.type == 2,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextButton(
          onPressed: () {
            if (controller.isCurrentShowGamePanel.value &&
                !controller.sendState.value) {
              if (controller.isNormalUser.value &&
                  !controller.isNormalUserCanInput.value) {
                //一般用戶開啟快捷用語
                //先關閉遊戲鍵盤
                _openGameKeyboard(false);
                controller.onOpenShortTalk(controller.assetPickerProvider);
                controller.inputFocusNode.unfocus();
              } else {
                //其他開啟原生鍵盤
                _switchGameKeyboardToKeyboard();
              }
            } else {
              if (controller.isShowShortTalk.value) {
                //如果有開啟快捷短語就關閉快捷短語
                controller.onOpenShortTalk(controller.assetPickerProvider);
                controller.inputFocusNode.unfocus();
              }
              if (controller.chatController.showFaceView.value) {
                //如果有開啟貼圖就關閉貼圖
                controller.onOpenFace();
                controller.inputFocusNode.unfocus();
              }
              if (controller.isVoiceMode.value) {
                //如果有開啟語音就關閉語音
                controller.toggleVoiceMode();
              }
              if (!controller.isCurrentShowGamePanel.value) {
                gameManager.isFromGroupChatGameClick = true;
                _openGameKeyboard(true);
              } else {
                _openGameKeyboard(false);
              }
            }
          },
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(
                isDesktop ? 44 : 46,
                isDesktop ? 22 : 24,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.center),
          child: Container(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: SvgPicture.asset(
              controller.isCurrentShowGamePanel.value
                  ? 'assets/svgs/input_keyboard.svg'
                  : 'assets/svgs/game_keyboard.svg',
              width: 28.0,
              height: 28.0,
              // color: ImColor.black48,
            ),
          ),
        ),
      ),
    );
  }

  _showKeyboardMenu(BuildContext context) {
    return Expanded(
      child: Container(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CPipe(
              color: controller.clickMenuKeyboard.value != 0 &&
                      controller.clickMenuKeyboard.value != 1
                  ? ImColor.black6
                  : Colors.transparent,
              height: 24.w,
              margin: EdgeInsets.only(left: 12.w),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                color: controller.clickMenuKeyboard.value == 1
                    ? ImColor.black6
                    : Colors.transparent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (_) => controller.clickMenuKeyboard.value = -1,
                      onTapDown: (_) => controller.clickMenuKeyboard.value = 1,
                      onTap: () {
                        showBottomWarningToast("排行榜功能正在维护中...",
                            bgColor: const Color(0xFF31352E));
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/menu_rounded.svg',
                            width: 8,
                            height: 7,
                          ),
                          ImGap.hGap8,
                          const Text(
                            '排行榜',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff121212),
                                height: 1.1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            CPipe(
              color: controller.clickMenuKeyboard.value != 1 &&
                      controller.clickMenuKeyboard.value != 2
                  ? ImColor.black6
                  : Colors.transparent,
              height: 24.w,
            ),
            _buildMsgFilter(context),
          ],
        ),
      ),
    );
  }

  Expanded _buildMsgFilter(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        color: controller.clickMenuKeyboard.value == 2
            ? ImColor.black6
            : Colors.transparent,
        child: GestureDetector(
          onDoubleTap: () {
            _onTapShowMsgFilterDialog(context);
          },
          onTapUp: (_) => controller.clickMenuKeyboard.value = -1,
          onTapDown: (_) => controller.clickMenuKeyboard.value = 2,
          onTap: () {
            _onTapShowMsgFilterDialog(context);
          },
          behavior: HitTestBehavior.translucent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/menu_rounded.svg',
                width: 8,
                height: 7,
              ),
              ImGap.hGap8,
              const Text(
                '消息过滤',
                style: TextStyle(
                    fontSize: 14, color: Color(0xff121212), height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //從遊戲鍵盤切換到原生鍵盤
  _switchGameKeyboardToKeyboard() {
    controller.inputState = 1;
    controller.isCloseGamePanelState.value = false;
    controller.isCurrentShowGamePanel.value = false;
    controller.assetPickerProvider?.selectedAssets = [];
    controller.inputFocusNode.requestFocus();

    controller.inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.inputController.text.length));
    //關閉遊戲鍵盤
    _openGameKeyboard(false);
  }

  //顯示快捷短語畫面
  _showShortcutTalkView(BuildContext context) async {
    // controller.isShowShortTalk.value = !controller.isShowShortTalk.value;
    if (controller.isCurrentShowGamePanel.value) {
      //如果當前開啟遊戲鍵盤就先關閉遊戲鍵盤
      _openGameKeyboard(false);
    }
    controller.onOpenShortTalk(controller.assetPickerProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    if (controller.chatController.showFaceView.value) {
      //如果有開啟貼圖就關閉貼圖
      controller.inputFocusNode.unfocus();
      controller.onOpenFace();
    }
  }

  //開關遊戲鍵盤
  _openGameKeyboard(bool isOpen) {
    controller.chatController.showAttachmentView.value = false;
    gameManager.panelController(
        entrance: ImConstants.gameBetsOptionList, control: isOpen);
    controller.isCloseGamePanelState.value = isOpen;
    controller.isCurrentShowGamePanel.value = isOpen;
    if (isOpen) {
      /// 移除输入法焦点
      if (controller.inputFocusNode.hasFocus) {
        controller.inputState = 1;
      } else {
        controller.inputState = 2;
      }
      controller.inputFocusNode.unfocus();
    }
    controller.update(['game_keyboard_tab'].toList());
    controller.update();
    controller.chatController.update();
  }

  _getVoiceWidget(BuildContext context) {
    return Visibility(
      visible: (!controller.isShowGameKeyboard.value ||
              !(controller.isNormalUser.value &&
                  !controller.isNormalUserCanInput.value) ||
              ((controller.isNormalUser.value &&
                      !controller.isNormalUserCanInput.value) &&
                  ((controller.sendState.value &&
                      controller.isCurrentShowGamePanel.value)))) &&
          ((controller.sendState.value &&
                  controller.isCurrentShowGamePanel.value) ||
              !controller.isCurrentShowGamePanel.value),
      child: IgnorePointer(
        ignoring: !isTextingAllowed,
        child: TextButton(
          onPressed: () async {
            if (controller.isCurrentShowGamePanel.value) {
              if (controller.isNormalUser.value &&
                  !controller.isNormalUserCanInput.value) {
                //一般用戶開啟快捷用語
                //先關閉遊戲鍵盤
                _openGameKeyboard(false);
                controller.onOpenShortTalk(controller.assetPickerProvider);
                controller.inputFocusNode.unfocus();
              } else {
                //其他開啟原生鍵盤
                _switchGameKeyboardToKeyboard();
              }
            } else {
              //先關閉遊戲鍵盤
              _openGameKeyboard(false);
              //沒有開遊戲鍵盤才顯示語音
              controller.toggleVoiceMode();
            }
          },
          style: TextButton.styleFrom(
              padding: controller.isShowGameKeyboard.value ||
                      controller.sendState.value
                  ? const EdgeInsets.symmetric(horizontal: 0)
                  : const EdgeInsets.symmetric(horizontal: 8.0),
              minimumSize: const Size(24, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.center),
          child: controller.isVoiceMode.value ||
                  (controller.isCurrentShowGamePanel.value)
              ? Padding(
                  padding: controller.isShowGameKeyboard.value
                      ? const EdgeInsets.only(left: 8, bottom: 14)
                      : const EdgeInsets.only(left: 8, right: 6, bottom: 14),
                  child: SvgPicture.asset(
                    'assets/svgs/input_keyboard.svg',
                    width: 24,
                    height: 24,
                  ),
                )
              : Padding(
                  padding: controller.isShowGameKeyboard.value
                      ? const EdgeInsets.only(left: 8, bottom: 14)
                      : const EdgeInsets.only(left: 8, right: 6, bottom: 14),
                  child: SvgPicture.asset(
                    'assets/svgs/mic_outlined.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
        ),
      ),
    );
  }

  _onTapShowMsgFilterDialog(BuildContext context) => EasyThrottle.throttle(
        'message_filter',
        const Duration(milliseconds: 500),
        () {
          _showMsgFilterDialog(context);
        },
      );

  void _showMsgFilterDialog(BuildContext context) async {
    returnColorToTransParent() {
      Future.delayed(const Duration(milliseconds: 100),
          () => controller.clickMenuKeyboard.value = -1);
    }

    final config = betMsgFilterMgr.getGroupConfig(
      groupId: controller.chatId,
    );
    final showAllBettingMsgTime = config.showAllBettingMsgTime;
    final filterBetMsg = config.filterBetMsg;

    bool hasBanPermission = false;
    final groupLocalBean = sharedDataManager.groupLocalData;
    if (groupLocalBean != null) {
      final isOwn = groupLocalBean.isOwner == true;
      // final isShareholder = groupLocalBean.isShareholder == true;
      // final isAdmin = groupLocalBean.isAdmin == true;
      hasBanPermission = isOwn; // || isAdmin; // isShareholder;
    }

    bool originalBan = false;
    final group =
        await objectMgr.myGroupMgr.getLocalGroup(sharedDataManager.groupId);
    final permission = group?.permission ?? 0;
    // debugPrint("TAG_TIF, permission: $permission");
    originalBan =
        !GameGroupPermissionMap.groupPermissionSendMsg.isAllow(permission);

    final onSave = (
      bool isBan,
      int? showAllBettingMsgTime,
      Map<int, int>? filterBetMsg,
    ) async {
      final config = BetMsgFilterConfig(
        showAllBettingMsgTime: showAllBettingMsgTime,
        filterBetMsg: filterBetMsg,
      );

      final chatId = controller.chatId;

      // debugPrint("TAG_TIF, config: ${config.toJson()}");
      betMsgFilterMgr.setGroupConfig(
        groupId: chatId,
        config: config,
      );

      if (originalBan == isBan) return;

      final permission =
          isBan ? 0 : GameGroupPermissionMap.groupPermissionSendMsg.value;

      final resp = await updateGroupPermission(
        groupId: chatId,
        permission: permission,
        type: 1, // 認證群
      );
      // debugPrint("TAG_TIF, resp: $resp, data: ${resp.data}");
    };

    showMsgFilterDialog(
      context,
      hasBanPermission: hasBanPermission,
      isBaned: originalBan,
      showAllBettingMsgTime: showAllBettingMsgTime,
      filterBetMsg: filterBetMsg,
      onSave: onSave,
    );
    returnColorToTransParent();
  }

  @override
  bool getEnabled() {
    return isTextingAllowed &&
        (!controller.isShowGameKeyboard.value ||
            !(controller.isNormalUser.value &&
                !controller.isNormalUserCanInput.value) ||
            controller.isCurrentShowGamePanel.value);
  }

  @override
  bool getReadOnly() {
    return (controller.isCurrentShowGamePanel.value &&
            controller.isCloseGamePanelState.value) ||
        (controller.isShowGameKeyboard.value &&
            (controller.isNormalUser.value &&
                !controller.isNormalUserCanInput.value) &&
            controller.isCurrentShowGamePanel.value);
  }

  @override
  Color getInputFieldColor() {
    return (!controller.isShowGameKeyboard.value ||
            !(controller.isNormalUser.value &&
                !controller.isNormalUserCanInput.value))
        ? JXColors.primaryTextBlack
        : JXColors.secondaryTextBlack;
  }

  @override
  InputDecoration getInputDecoration(
      CustomInputController controller, bool isDesktop) {
    final borderStyle = OutlineInputBorder(
      borderRadius: jxDimension.textInputRadius(),
      borderSide: const BorderSide(
        color: JXColors.borderPrimaryColor,
        width: 0.3,
      ),
    );

    return InputDecoration(
      prefixIcon: isTextingAllowed
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text(
                  localized(textNotAllowed),
                  style: TextStyle(
                      fontSize: MFontSize.size14.value,
                      color: inputHintTextColor.withOpacity(0.48)),
                )
              ],
            ),
      hintText: !controller.isShowGameKeyboard.value ||
              !(controller.isNormalUser.value &&
                  !controller.isNormalUserCanInput.value) ||
              controller.isCurrentShowGamePanel.value
          ? isTextingAllowed
              ? localized(isDesktop
                  ? enterMessage
                  : (controller.isShowGameKeyboard.value &&
                          controller.isCurrentShowGamePanel.value
                      ? chatBetInputting
                      : chatInputting))
              : null
          : localized(chatShortcut),
      hintStyle: isDesktop
          ? jxTextStyle.textStyle14(color: JXColors.iconTertiaryColor)
          : jxTextStyle.textStyle16(color: JXColors.iconTertiaryColor),
      isDense: true,
      fillColor: ImColor.white,
      filled: true,
      isCollapsed: isDesktop ? false : true,
      counterText: '',
      contentPadding: jxDimension.chatTextFieldInputPadding().copyWith(
            top: 6.5,
            bottom: 8.5,
            right: controller.chatController.chat.autoDeleteEnabled &&
                    controller.autoDeleteInterval != 0
                ? 41.0 + 34.0
                : 41.0,
          ),
      focusedBorder: borderStyle,
      enabledBorder: borderStyle,
      disabledBorder: borderStyle,
    );
  }
}
