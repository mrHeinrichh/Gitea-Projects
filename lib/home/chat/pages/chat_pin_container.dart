import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';

const double kAudioPinHeightFix = 36.0;
double kAudioPinHeight = 0.0;
final isShowAudioPin = false.obs;

const double kGamePinHeightFix = 36.0;
double kGamePinHeight = 0.0;
bool isShowGamePin = false;

// 语音置顶
double getAudioPinHeight() {
  double height = 0.0;
  if (isShowAudioPin.value) {
    height = kAudioPinHeightFix;
  }
  return height;
}

// 游戏置顶
double getGamePinHeight() {
  double height = 0.0;
  if (isShowGamePin) {
    height = kAudioPinHeightFix;
  }
  return height;
}

double getTotalPinHeight() {
  double height = getAudioPinHeight() + getGamePinHeight();
  return height;
}

class ChatPinContainer extends StatelessWidget {
  const ChatPinContainer({
    super.key,
    this.isFromHome = false,
  });

  final bool isFromHome;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecordAudioControlItem(
          isFromHome: isFromHome,
        ),
      ],
    );
  }
}
