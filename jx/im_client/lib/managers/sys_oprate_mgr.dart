import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

class SysOprateMgr extends EventDispatcher {
  static const groupWelcome = 2; //打开群页面欢迎
  static const groupFoceLeave = 3; //强制离开群（被踢）
  static const groupLiveManager = 4; //直播间设置管理员
  static const liveSpeakProhibit = 5; //直播间禁言
  static const livePullBlack = 6; //直播间拉黑
  static const liveKickOut = 7; //直播间踢出
  static const loverHeartValue = 8; //亲密度心动值
  static const beenFocus = 9; //用户被关注
  static const voiceApplyNumber = 10; //语音房申请人数推送（房主独有）
  static const voiceMatchSuccess = 11; //语音匹配成功
  static const notifyMatchInvite = 12; //语音匹配邀请
  static const notifyMatchPriceUpdate = 13; //语音匹配扣钱通知

  static const livePKMatchTimeout = 17; //直播pk随机匹配超时结束
  static const livePKBeInvite = 18; //直播pk被邀请通知
  static const livePKBeRefuseInvite = 19; //直播pk被拒绝邀请

  static const systemVoiceSign = 21; //语音签名审核结果通知

  static const taskUpdate = 22;

  static const taskFinish = 23; //任务完成通知
  static const notifyCodeChatInput = 24; //对方输入中
  static const notifyMySendGift = 25; //礼物连击操作通知
  static const notifyCallPriceUpdate = 26; //音视频通话扣钱通知
  static const mateMatchOvertime = 27; //语音匹配超时
  static const mateMatchOffline = 28; //语音匹配对方掉线
  static const mateMatchHandUp = 29; //语音匹配挂断
  static const forceLogout = 30; //封号强制退出
  static const livePKRequestUpgrade = 32; //请求直播连屏升为直播pk通知

  static const eventGroupWelcome = 'eventGroupWelcome';
  static const eventLiveManager = 'eventLiveManager';
  static const eventSpeakProhibit = 'eventSpeakProhibit';
  static const eventPullBlack = 'eventPullBlack';
  static const eventKickOut = 'eventKickOut';
  static const eventBeenFocus = 'evenBeenFocus';
  static const eventVoiceApplyNumber = 'eventVoiceApplyNumber';
  static const eventVoiceMatchSuccess = 'eventVoiceMatchSuccess';
  static const eventNotifyMatchInvite = 'eventNotifyMatchInvite';
  static const eventNotifyMatchPriceUpdate = 'eventNotifyMatchPriceUpdate';
  static const eventGoToListen = 'eventGoToListen';
  static const eventTaskFinish = 'eventTaskFinish';
  static const eventChatInput = 'eventChatInput';
  static const eventNotifyMySendGift = 'eventNotifyMySendGift';
  static const eventNotifyCallPriceUpdate = 'eventNotifyCallPriceUpdate';
  static const eventMateMatchOvertime = 'eventMateMatchOvertime';
  static const eventMateMatchHandUp = 'eventMateMatchHandUp';
  static const eventForceLogout = 'eventForceLogout';
  static const eventShowBigGlass = 'eventShowBigGlass';
  static const eventHideInputPop = 'eventHideInputPop';
  static const eventClickChangeColor = 'eventClickChangeColor';

  /// general native channel
  static const _generalChannel = 'jxim/general';
  static const _methodChannel = MethodChannel(_generalChannel);

  Future<void> register() async {
    objectMgr.socketMgr.on(SocketMgr.sysOprateBlock, _onSysOprateBlock);
    _methodChannel.setMethodCallHandler(nativeCallback);
    if (Platform.isIOS) {
      _methodChannel.invokeMethod("syncAssertList", [Config().assert_list]);
    }
  }

  Future<void> logout() async {
    objectMgr.socketMgr.off(SocketMgr.sysOprateBlock, _onSysOprateBlock);
    clear();
  }

  Future<void> nativeCallback(MethodCall call) async {
    // switch (call.method)
  }

  Future<bool> isAudioPlaying() async {
    bool result = await _methodChannel.invokeMethod('isBackgroundAudioPlaying');
    return result;
  }

  //检测手机麦克风是否被其他应用占用
  Future<bool> isMicrophoneInUse() async {
    bool result = await _methodChannel.invokeMethod('isMicrophoneInUse');
    return result;
  }

  ///记录时间
  int recordTime = 0;

  ///是否正在查看大图或视频
  bool showImageOrVideo = false;

  ///群用户信息更新时间
  int groupUserUpdateTime = 0;

  ///输入框放大镜
  bool _showBigGlass = false;

  bool get showBigGlass => _showBigGlass;

  set showBigGlass(bool val) {
    _showBigGlass = val;
    event(this, eventShowBigGlass);
  }

  ///点击变颜色
  String _changeColorId = '';

  String get changeColorId => _changeColorId;

  isChangeColorId(String val) {
    return _changeColorId == val;
  }

  set changeColorId(String val) {
    _changeColorId = val;
    event(this, eventClickChangeColor);
  }

  hideInputPop() {
    event(this, eventHideInputPop);
  }

  /// 发生对象更新
  void _onSysOprateBlock(Object sender, Object type, Object? block) {
    if (block is SysOprate) {
      switch (block.type) {
        case groupWelcome:
          //打开群页面欢迎
          event(this, eventGroupWelcome, data: block.data);
          break;
        case groupFoceLeave:
          objectMgr.myGroupMgr.onLeaveGroup(int.parse(block.data), true);
          break;
        case groupLiveManager:
          event(this, eventLiveManager, data: block.data);
          break;
        case liveSpeakProhibit:
          event(this, eventSpeakProhibit, data: block.data);
          break;
        case livePullBlack:
          event(this, eventPullBlack, data: block.data);
          break;
        case liveKickOut:
          event(this, eventKickOut, data: block.data);
          break;
        case beenFocus:
          event(this, eventBeenFocus, data: block.data);
          break;
        case voiceApplyNumber:
          event(this, eventVoiceApplyNumber, data: block.data);
          break;
        case voiceMatchSuccess:
          event(this, eventVoiceMatchSuccess, data: block.data);
          break;
        case notifyMatchInvite:
          event(this, eventNotifyMatchInvite, data: block.data);
          break;
        case notifyMatchPriceUpdate:
          event(this, eventNotifyMatchPriceUpdate, data: block.data);
          break;

        case taskUpdate:
          objectMgr.socketMgr.sendEvent(SocketMgr.updateTaskBlock, block.data);
          break;
        case taskFinish:
          event(this, eventTaskFinish, data: block.data);
          break;
        case notifyCodeChatInput:
          event(this, eventChatInput, data: block.data);
          break;
        case notifyMySendGift:
          event(this, eventNotifyMySendGift, data: block.data);
          break;
        case notifyCallPriceUpdate:
          event(this, eventNotifyCallPriceUpdate, data: block.data);
          break;
        case mateMatchOvertime:
          event(this, eventMateMatchOvertime, data: block.data);
          break;
        case mateMatchHandUp:
          event(this, eventMateMatchHandUp, data: block.data);
          break;
        case forceLogout:
          event(this, eventForceLogout, data: block.data);
          break;
      }
      pdebug(block);
    }
  }
}
