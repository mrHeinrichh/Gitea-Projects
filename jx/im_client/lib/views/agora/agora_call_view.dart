import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/native_video_widget.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:lottie_tgs/lottie.dart';

class AgoraCallView extends GetView<AgoraCallController> {
  AgoraCallView({super.key});

  @override
  final AgoraCallController controller = Get.put(AgoraCallController());

  @override
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
          child: DefaultTextStyle(
            style: const TextStyle(color: colorWhite),
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
                      begin: Offset.zero,
                      end: const Offset(0, -1),
                    ).animate(
                      CurvedAnimation(
                        parent: controller.animationController!,
                        curve: Curves.fastOutSlowIn,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ///頂部位置
                          Stack(
                            children: [
                              Obx(
                                () => Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(
                                          controller.shouldShowCallingView()
                                              ? 0
                                              : 0.3,
                                        ),
                                        Colors.black.withOpacity(
                                          controller.shouldShowCallingView()
                                              ? 0
                                              : 0.2,
                                        ),
                                        Colors.black.withOpacity(
                                          controller.shouldShowCallingView()
                                              ? 0
                                              : 0.1,
                                        ),
                                        Colors.black.withOpacity(
                                          controller.shouldShowCallingView()
                                              ? 0
                                              : 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: kToolbarHeight,
                                    bottom: 40,
                                  ),
                                  child: CustomLeadingIcon(
                                    buttonOnPressed: () {
                                      controller.onBackBtnClicked();
                                    },
                                    backButtonColor: colorWhite,
                                    withBackTxt: true,
                                  ),
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
                                        const SizedBox(
                                          height: kToolbarHeight,
                                        ),
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            (objectMgr.callMgr.floatWindowIsMe
                                                        .value ||
                                                    objectMgr
                                                            .callMgr
                                                            .currentState
                                                            .value !=
                                                        CallState.InCall)
                                                ? objectMgr.userMgr
                                                    .getUserTitle(
                                                    objectMgr.callMgr.opponent,
                                                  )
                                                : objectMgr
                                                    .userMgr.mainUser.nickname,
                                            textAlign: TextAlign.center,
                                            style: jxTextStyle
                                                .headerText(
                                                  fontWeight: FontWeight.w500,
                                                  color: colorBrightPrimary,
                                                )
                                                .copyWith(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            maxLines: 1,
                                          ),
                                        ),
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
                                                padding: const EdgeInsets.only(
                                                  right: 4.0,
                                                ),
                                                child: SvgPicture.asset(
                                                  controller
                                                      .networkSignalIcon.value,
                                                  color: colorBrightPrimary,
                                                  fit: BoxFit.fill,
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ),
                                            ),
                                            Obx(
                                              () => Text(
                                                objectMgr.callMgr.currentState
                                                            .value ==
                                                        CallState.InCall
                                                    ? controller
                                                        .callTimeDuration.value
                                                    : controller
                                                        .callStatusString.value,
                                                style:
                                                    jxTextStyle.normalSmallText(
                                                  color: colorBrightPrimary,
                                                  fontWeight:
                                                      MFontWeight.bold5.value,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }),
                            ],
                          ),

                          ///內容位置
                          Obx(() {
                            if (controller.shouldShowCallingView()) {
                              double clampedSize =
                                  (ObjectMgr.screenMQ!.size.width / 3)
                                      .clamp(100.0, 160.0);
                              bool showOpp =
                                  objectMgr.callMgr.floatWindowIsMe.value ||
                                      controller.isEnding.value;
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 100),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Lottie.asset(
                                          "assets/lottie/calling_wave.json",
                                          height: clampedSize + 50,
                                          width: clampedSize + 50,
                                          frameRate: FrameRate.max,
                                          fit: BoxFit.cover,
                                        ),
                                        CustomAvatar.user(
                                          key: ValueKey(showOpp
                                              ? objectMgr.callMgr.opponent!.uid
                                              : objectMgr.userMgr.mainUser.uid),
                                          showOpp
                                              ? objectMgr.callMgr.opponent!
                                              : objectMgr.userMgr.mainUser,
                                          size: clampedSize,
                                          borderRadius: 100,
                                          headMin: Config().headMin,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    //user name
                                    if (!controller.isEnding.value)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0,
                                        ),
                                        child: Text(
                                          objectMgr
                                                  .callMgr.floatWindowIsMe.value
                                              ? objectMgr.userMgr.getUserTitle(
                                                  objectMgr.callMgr.opponent,
                                                )
                                              : objectMgr
                                                  .userMgr.mainUser.nickname,
                                          style: jxTextStyle
                                              .titleText(
                                                fontWeight:
                                                    MFontWeight.bold5.value,
                                                color: colorBrightPrimary,
                                              )
                                              .copyWith(
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                          maxLines: 1,
                                        ),
                                      ),
                                    if (!controller.isEnding.value)
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
                                                right: 4.0,
                                              ),
                                              child: SvgPicture.asset(
                                                controller
                                                    .networkSignalIcon.value,
                                                color: colorWhite,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                controller.getStateDesc(),
                                                style: controller.isEnding.value
                                                    ? const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 28,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      )
                                                    : const TextStyle(
                                                        fontSize: 17,
                                                        color: colorWhite,
                                                      ),
                                              ),
                                              Offstage(
                                                offstage: !(controller
                                                        .isEnding.value &&
                                                    controller.isInCallEnded()),
                                                child: Text(
                                                  controller
                                                      .callTimeDuration.value,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    color: colorWhite,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              );
                            } else {
                              return const SizedBox();
                            }
                          }),
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
                        begin: Offset.zero,
                        end: const Offset(0, 1),
                      ).animate(
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
                                controller.getNetworkBrief(),
                                style: jxTextStyle.textStyle14(
                                  color: colorWhite,
                                ),
                              ),
                            );
                          }),

                          Obx(
                            () => Visibility(
                              visible: controller.showMeBatteryAlert.value ||
                                  controller.showCalleeBatteryAlert.value,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 19.0,
                                  left: 20.0,
                                  right: 20.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: SvgPicture.asset(
                                        'assets/svgs/battery_low.svg',
                                        color: colorWhite,
                                        fit: BoxFit.cover,
                                        width: 16,
                                        height: 16,
                                      ),
                                    ),
                                    Text(
                                      controller.getBatteryBrief(),
                                      style: jxTextStyle.textStyle14(
                                        color: colorWhite,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// 操作按钮
                          Obx(() {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                right: 30.0,
                                bottom: 30,
                                top: 20,
                              ),
                              child: onCallAction(
                                context,
                                objectMgr.callMgr.currentState.value,
                              ),
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
      ),
    );
  }

  Widget callingView() {
    return Obx(
      () => Image(
        image: AssetImage(
          objectMgr.callMgr.currentState.value != CallState.InCall
              ? 'assets/images/calling_bg.jpg'
              : 'assets/images/incall_bg.jpg',
        ),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }

  /// 接听 ｜｜ 挂断
  Widget onCallAction(BuildContext context, CallState curCallState) {
    pdebug(
        "onCallAction======> $curCallState, ${objectMgr.callMgr.selfCameraOn.value}, ${objectMgr.callMgr.isInviter}");
    if (curCallState == CallState.Idle) {
      if (controller.retryInfo.value != null) {
        return retryRowWidget(context);
      } else {
        return const SizedBox();
      }
    }

    /// 接听方 UI -> 检查 权限， 权限操作 决定 -》 接听 或者 发起通话
    if (!objectMgr.callMgr.isInviter &&
        (curCallState == CallState.Waiting ||
            curCallState == CallState.Init ||
            curCallState == CallState.Requesting)) {
      return answerCallButton(context);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        color: const Color(0xFFFFFFFF).withOpacity(0.2),
                      ),
                      child: OpacityEffect(
                        child: SvgPicture.asset(
                          'assets/svgs/flip.svg',
                          color: const Color(0xFFFFFFFF),
                          fit: BoxFit.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      localized(callFlip),
                      style: jxTextStyle.normalSmallText(
                          color: colorBrightPrimary),
                    ),
                  ),
                ],
              ),
            Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    objectMgr.callMgr.isSpeaker.value =
                        !objectMgr.callMgr.isSpeaker.value;
                    objectMgr.callMgr.setAudioSound(
                        objectMgr.callMgr.isSpeaker.value
                            ? SoundType.speaker
                            : SoundType.reciever);
                  },
                  child: !objectMgr.callMgr.isSpeaker.value
                      ? OpacityEffect(
                          opacity: 0.4,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: buttonBackgroundColor(
                                  objectMgr.callMgr.isSpeaker.value),
                            ),
                            child: SvgPicture.asset(
                              'assets/svgs/call_speaker_icon.svg',
                              color: buttonIconColor(
                                  objectMgr.callMgr.isSpeaker.value),
                              fit: BoxFit.none,
                            ),
                          ),
                        )
                      : OpacityEffect(
                          opacity: 0.4,
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
                    localized(callSpeaker),
                    style:
                        jxTextStyle.normalSmallText(color: colorBrightPrimary),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (objectMgr.callMgr.currentState.value ==
                        CallState.InCall) {
                      objectMgr.callMgr.switchOnOffCam();
                    }
                  },
                  child: !objectMgr.callMgr.selfCameraOn.value
                      ? OpacityEffect(
                          opacity: 0.4,
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: buttonBackgroundColor(
                                objectMgr.callMgr.selfCameraOn.value,
                              ),
                            ),
                            child: SvgPicture.asset(
                              'assets/svgs/call_video_icon.svg',
                              color: buttonIconColor(
                                objectMgr.callMgr.selfCameraOn.value,
                              ),
                              fit: BoxFit.none,
                            ),
                          ),
                        )
                      : OpacityEffect(
                          opacity: 0.4,
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
                    localized(
                      objectMgr.callMgr.selfCameraOn.value
                          ? cameraOn
                          : cameraOff,
                    ),
                    style:
                        jxTextStyle.normalSmallText(color: colorBrightPrimary),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    objectMgr.callMgr.toggleMic();
                    if (objectMgr.callMgr.isMute.value) {
                      Toast.showAgoraToast(
                        msg: localized(mutedCall),
                        svg: 'assets/svgs/call_microphone_icon.svg',
                      );
                    }
                  },
                  child: objectMgr.callMgr.isMute.value
                      ? OpacityEffect(
                          opacity: 0.4,
                          child: SvgPicture.asset(
                            'assets/svgs/call_microphone_icon_transparent.svg',
                            width: 52,
                            height: 52,
                          ),
                        )
                      : OpacityEffect(
                          opacity: 0.4,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: buttonBackgroundColor(
                                objectMgr.callMgr.isMute.value,
                              ),
                            ),
                            child: SvgPicture.asset(
                              'assets/svgs/call_microphone_icon.svg',
                              color: buttonIconColor(
                                objectMgr.callMgr.isMute.value,
                              ),
                              fit: BoxFit.none,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    localized(
                      notifMuteType,
                      // objectMgr.callMgr.isMute.value ?
                      // callMute : callUnmute
                    ),
                    style:
                        jxTextStyle.normalSmallText(color: colorBrightPrimary),
                  ),
                ),
              ],
            ),
            secondRowCallButton(context, curCallState),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget retryRowWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => controller.doClosePage(),
          child: Column(
            children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorBrightPlaceholder,
                  ),
                  child: const OpacityEffect(
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: colorSurface,
                        size: 28,
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Text(localized(cancel),
                  style: jxTextStyle.normalSmallText(
                    color: colorBrightPrimary,
                  ))
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            controller.doRetry();
          },
          child: Column(
            children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorGreen,
                  ),
                  child: const OpacityEffect(
                    child: Center(
                      child: Icon(
                        Icons.call,
                        color: colorBrightPrimary,
                        size: 24,
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Text(localized(retryCall),
                  style: jxTextStyle.normalSmallText(
                    color: colorBrightPrimary,
                  ))
            ],
          ),
        ),
      ],
    );
  }

  Widget answerCallButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: objectMgr.callMgr.rejectCall,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: colorRed,
            ),
            padding: const EdgeInsets.all(13),
            child: const Icon(
              Icons.call_end,
              color: colorWhite,
              size: 24,
            ),
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        GestureDetector(
          onTap: () async {
            InAppNotification.dismiss(context: context);
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
              color: colorWhite,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget secondRowCallButton(BuildContext context, CallState curCallState) {
    return (curCallState == CallState.Waiting && !objectMgr.callMgr.isInviter)
        ? answerCallButton(context)
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
                child: OpacityEffect(
                  opacity: 0.4,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: colorRed,
                    ),
                    child: SvgPicture.asset(
                      'assets/svgs/call_endcall_icon.svg',
                      fit: BoxFit.none,
                      color: colorWhite,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  localized(endCall),
                  style: jxTextStyle.normalSmallText(color: colorBrightPrimary),
                ),
              ),
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
      return colorWhite;
    } else {
      return colorWhite.withOpacity(0.2);
    }
  }

  Widget _nativeVideoView() {
    var children = <Widget>[];

    if (objectMgr.callMgr.opponent != null) {
      children.add(
        NativeVideoWidget(
          uid: objectMgr.callMgr.opponent!.uid,
          isBigScreen: true,
          retryCount: controller.retryInfo.value?.times ?? 0,
        ),
      );
    }
    final showCallingView = controller.shouldShowCallingView();
    if (showCallingView) {
      children.add(callingView());
    }

    children.add(
      Positioned.fill(
        child: InkWell(
          onTap: () {
            controller.showButton();
          },
          child: const SizedBox(),
        ),
      ),
    );

    return Stack(
      children: children,
    );
  }
}
