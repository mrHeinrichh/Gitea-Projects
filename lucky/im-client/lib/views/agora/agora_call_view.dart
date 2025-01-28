import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/native_video_widget.dart';

class AgoraCallView extends GetView<AgoraCallController> {
  const AgoraCallView({Key? key}) : super(key: key);

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false, // prevent button came up (keyboard)
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: GestureDetector(
                  onTap: () => controller.showButton(),
                  child: Stack(
                    children: <Widget>[
                      GetBuilder<AgoraCallController>(
                        builder: (ctx) {
                          return Obx(() => _nativeVideoView());
                        },
                      ),
                      SlideTransition(
                        position: Tween<Offset>(
                                begin: Offset.zero, end: const Offset(0, -1))
                            .animate(
                          CurvedAnimation(
                            parent: controller.animationController!,
                            curve: Curves.fastOutSlowIn,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: kToolbarHeight),

                              ///頂部位置
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, top: 4.0),
                                    child: CustomLeadingIcon(
                                      buttonOnPressed: () =>
                                          controller.onBackBtnClicked(),
                                      backButtonColor: Colors.white,
                                      withBackTxt: true,
                                    ),
                                  ),
                                  Obx(() {
                                    if (controller.shouldShowCallingView()) {
                                      return const SizedBox();
                                    } else {
                                      return Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                objectMgr.callMgr.floatWindowIsMe.value ? objectMgr.userMgr.getUserTitle(
                                                    objectMgr.callMgr.opponent) : objectMgr.userMgr.mainUser.nickname,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 17,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Visibility(
                                                    visible: objectMgr.callMgr
                                                            .currentState.value ==
                                                        CallState.InCall,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 4.0),
                                                      child: SvgPicture.asset(
                                                        controller
                                                            .networkSignalIcon
                                                            .value,
                                                        color: JXColors.white,
                                                        fit: BoxFit.fill,
                                                        width: 16,
                                                        height: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Obx(() => Text(
                                                      objectMgr
                                                                      .callMgr
                                                                      .currentState
                                                                      .value ==
                                                                  CallState
                                                                      .InCall &&
                                                              controller
                                                                  .callTimeDuration
                                                                  .value
                                                                  .isNotEmpty
                                                          ? controller
                                                              .callTimeDuration
                                                              .value
                                                          : controller
                                                              .callStatusString
                                                              .value,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: offWhite,
                                                          fontWeight: MFontWeight
                                                              .bold5.value))),
                                                ])
                                          ],
                                        ),
                                      );
                                    }
                                  })
                                ],
                              ),

                              ///內容位置
                              Obx(() {
                                if (controller.shouldShowCallingView()) {
                                  double clampedSize = (ObjectMgr.screenMQ!.size.width / 3).clamp(100.0, 160.0);
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 100),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svgs/avatar_wave.svg',
                                              width: clampedSize + 40,
                                              height: clampedSize + 40,
                                            ),
                                            CustomAvatar(
                                              uid: objectMgr.callMgr.floatWindowIsMe.value ? objectMgr.callMgr.opponent?.uid ?? 0 : objectMgr.userMgr.mainUser.uid,
                                              size: clampedSize,
                                              borderRadius: 100,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        //user name
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                          child: Text(
                                            objectMgr.callMgr.floatWindowIsMe.value ? objectMgr.userMgr.getUserTitle(
                                                objectMgr.callMgr.opponent) : objectMgr.userMgr.mainUser.nickname,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 28,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        //status
                                        Obx(() {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Visibility(
                                                visible: objectMgr.callMgr
                                                        .currentState.value ==
                                                    CallState.InCall,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(
                                                      right: 4.0),
                                                  child: SvgPicture.asset(
                                                      controller.networkSignalIcon
                                                          .value,
                                                      color: JXColors.white,
                                                      fit: BoxFit.fill),
                                                ),
                                              ),
                                              Text(
                                                  objectMgr.callMgr
                                                                  .currentState.value ==
                                                              CallState.InCall &&
                                                          controller
                                                              .callTimeDuration
                                                              .value
                                                              .isNotEmpty
                                                      ? controller
                                                          .callTimeDuration.value
                                                      : controller
                                                          .callStatusString.value,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: offWhite,
                                                      fontWeight: MFontWeight
                                                          .bold5.value)),
                                            ],
                                          );
                                        })
                                      ],
                                    ),
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              })
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SlideTransition(
                          position: Tween<Offset>(
                                  begin: Offset.zero, end: const Offset(0, 1))
                              .animate(
                            CurvedAnimation(
                              parent: controller.animationController!,
                              curve: Curves.fastOutSlowIn,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(height: 32),
                              Obx(() {
                                return Center(
                                    child: Text(
                                        objectMgr.callMgr.networkStatus.value,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: offWhite,
                                        )));
                              }),

                              /// 操作按钮
                              Obx(() {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30.0,
                                      right: 30.0,
                                      bottom: 30,
                                      top: 20),
                                  child: onCallAction(
                                      objectMgr.callMgr.currentState.value),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }

  Widget callingView() {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: const Alignment(0.00, -1.00),
            end: const Alignment(0, 1),
            colors: objectMgr.callMgr.currentState.value == CallState.InCall &&
                    controller.callTimeDuration.value.isNotEmpty
                ? [const Color(0xFF5CE6EF), const Color(0xFF1EAECD)] //已接通
                : [const Color(0xFF7EC2F4), const Color(0xFF3B90E1)] //尚未接通,
            ),
      ),
    );
  }

  /// 接听 ｜｜ 挂断
  Widget onCallAction(CallState curCallState) {
    if (curCallState == CallState.Idle) {
      return const SizedBox();
    }

    /// 接听方 UI -> 检查 权限， 权限操作 决定 -》 接听 或者 发起通话
    if (!objectMgr.callMgr.selfCameraOn.value &&
        !objectMgr.callMgr.isInviter &&
        (curCallState == CallState.Waiting ||
            curCallState == CallState.Init ||
            curCallState == CallState.Connecting)) {
      return answerCallButton();
    }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (objectMgr.callMgr.currentState.value == CallState.InCall) {
                        objectMgr.callMgr.switchOnOffCam();
                      }
                    },
                    child: !objectMgr.callMgr.selfCameraOn.value
                        ? Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: buttonBackgroundColor(
                              objectMgr.callMgr.selfCameraOn.value)),
                      child: OpacityEffect(
                        child: SvgPicture.asset(
                          'assets/svgs/call_video_icon.svg',
                          color: buttonIconColor(
                              objectMgr.callMgr.selfCameraOn.value),
                          fit: BoxFit.none,
                        ),
                      ),
                    )
                        : OpacityEffect(
                          child: SvgPicture.asset(
                      'assets/svgs/call_video_icon_transparent.svg',
                      width: 52,
                      height: 52,
                    ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      localized(objectMgr.callMgr.selfCameraOn.value
                          ? cameraOn
                          : cameraOff),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            Column(
              children: [
                GestureDetector(
                    onTap: () {
                      objectMgr.callMgr.toggleMic();
                      if (objectMgr.callMgr.isMute.value)
                        Toast.showAgoraToast(
                            msg: localized(mutedCall),
                            svg: 'assets/svgs/call_microphone_icon.svg');
                    },
                    child: objectMgr.callMgr.isMute.value
                        ? OpacityEffect(
                          child: SvgPicture.asset(
                              'assets/svgs/call_microphone_icon_transparent.svg',
                              width: 52,
                              height: 52,
                            ),
                        )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: buttonBackgroundColor(
                                  objectMgr.callMgr.isMute.value),
                            ),
                            child: OpacityEffect(
                              child: SvgPicture.asset(
                                'assets/svgs/call_microphone_icon.svg',
                                color: buttonIconColor(
                                    objectMgr.callMgr.isMute.value),
                                fit: BoxFit.none,
                              ),
                            ))),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    localized(notifMuteType
                        // objectMgr.callMgr.isMute.value ?
                        // callMute : callUnmute
                        ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (!objectMgr.callMgr.selfCameraOn.value)
              Column(
                children: [
                  GestureDetector(
                    onTap: objectMgr.callMgr.toggleSpeaker,
                    child: !objectMgr.callMgr.isSpeaker.value
                        ? Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: buttonBackgroundColor(
                                  objectMgr.callMgr.isSpeaker.value),
                            ),
                            child: OpacityEffect(
                              child: SvgPicture.asset(
                                'assets/svgs/call_speaker_icon.svg',
                                color: buttonIconColor(
                                    objectMgr.callMgr.isSpeaker.value),
                                fit: BoxFit.none,
                              ),
                            ),
                          )
                        : OpacityEffect(
                          child: SvgPicture.asset(
                              'assets/svgs/call_speaker_icon_transparent.svg',
                              width: 52,
                              height: 52,
                            ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      localized(callSpeaker
                          // objectMgr.callMgr.isSpeaker.value
                          //     ? callSpeakerOn
                          //     : callSpkearOff
                          ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            if (objectMgr.callMgr.selfCameraOn.value)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => objectMgr.callMgr.flipCamera(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Color(0xFFFFFFFF).withOpacity(0.2),
                      ),
                      child: OpacityEffect(
                        child: SvgPicture.asset(
                          'assets/svgs/flip.svg',
                          color: Color(0xFFFFFFFF),
                          fit: BoxFit.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      localized(callFlip),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            secondRowCallButton(curCallState)
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget answerCallButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: objectMgr.callMgr.rejectCall,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB73229),
            ),
            padding: const EdgeInsets.all(13),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        GestureDetector(
          onTap: () async {
            objectMgr.callMgr.acceptCall(informCallKit: true);
          },
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF318330),
            ),
            padding: const EdgeInsets.all(13),
            child: const Icon(
              Icons.call,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget secondRowCallButton(CallState curCallState) {
    return curCallState == CallState.Waiting && !objectMgr.callMgr.isInviter
        ? answerCallButton()
        : Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (curCallState != CallState.InCall) {
                    objectMgr.callMgr.cancelCall();
                  } else {
                    controller.callStatusString.value =
                        localized(chatEndedCall);
                    objectMgr.callMgr.endCall();
                  }
                },
                child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: const Color(0xFFB73229),
                    ),
                    child: OpacityEffect(
                      child: SvgPicture.asset(
                        'assets/svgs/call_endcall_icon.svg',
                        fit: BoxFit.none,
                        color: Colors.white,
                      ),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  localized(endCall),
                  style: const TextStyle(fontSize: 12),
                ),
              )
            ],
          );
  }

  Color buttonIconColor(bool isTurnOn) {
    if (isTurnOn) {
      return const Color(0xFF707070);
    } else {
      return const Color(0xFFFFFFFF);
    }
  }

  Color buttonBackgroundColor(bool isTurnOn) {
    if (isTurnOn) {
      return Colors.white;
    } else {
      return const Color(0xFFFFFFFF).withOpacity(0.2);
    }
  }

  Widget _nativeVideoView() {
    var children = <Widget>[];

    if (objectMgr.callMgr.opponent != null) {
      children.add(
          NativeVideoWidget(uid: objectMgr.callMgr.opponent!.uid, isBigScreen: true));
    }

    if (controller.shouldShowCallingView()) {
      children.add(callingView());
    }

    children.add(Positioned.fill(
      child: InkWell(
          onTap: () {
            controller.showButton();
          },
          child: const SizedBox()),
    ));

    return Stack(
      children: children,
    );
  }
}
