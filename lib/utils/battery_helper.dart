import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class BatteryHelper {
  final methodChannel = const MethodChannel("jxim/battery");
  final Battery _battery = Battery();
  final Map<Object, Function(BatteryInfo info)> callbacks = {};
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  BatteryState _batteryState = BatteryState.unknown;
  int _currentLevel = -1;


  static final BatteryHelper _instance = BatteryHelper._internal();
  factory BatteryHelper() {
    return _instance;
  }

  BatteryHelper._internal() {
    methodChannel.setMethodCallHandler(nativeCallback);
    init();
  }

  init() async {
    _currentLevel = await _battery.batteryLevel;
    _batteryState = await _battery.batteryState;
    _battery.batteryState.then(_updateBatteryState);
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(_updateBatteryState);
  }

  Future<void> nativeCallback(MethodCall call) async {
    switch(call.method){
      case "batteryLevel":
        int level = call.arguments["level"] ?? -1;
        if(level < 0){
          level = await _battery.batteryLevel;
        }
        _onBatteryChanged(level);
        break;
      default:
        break;
    }
  }

  _onBatteryChanged(int level){
    if(_currentLevel != level){
      _currentLevel = level;
      notifyBatteryChanged();
    }
  }

  void notifyBatteryChanged(){
    callbacks.forEach((key, value) {
      value.call(BatteryInfo(uid: objectMgr.userMgr.mainUser.uid, state: _batteryState, level: _currentLevel));
    });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    _batteryState = state;
    notifyBatteryChanged();
  }

  BatteryState? getCurrentBatteryState(){
    return _batteryState;
  }

  Future<int> getCurrentBatteryLevel() async {
     return _battery.batteryLevel;
  }

  Future<BatteryInfo> getCurrentBatteryInfo() async {
    if(_batteryState == BatteryState.unknown || _currentLevel == -1){
        await init();
    }

    return BatteryInfo(uid: objectMgr.userMgr.mainUser.uid, state: _batteryState, level: _currentLevel);
  }

  addBatteryListener(Object sender, Function(BatteryInfo info) listener){
    callbacks[sender] = listener;
  }

  removeBatteryListener(String sender){
    callbacks.remove(sender);
  }

  clearListeners(){
    callbacks.clear();
  }

  onClose() async {
    clearListeners();
    if (_batteryStateSubscription != null) {
      _batteryStateSubscription!.cancel();
    }
  }
}

class BatteryInfo{
  final BatteryState state;
  final int level;
  final int uid;

  BatteryInfo({required this.uid, required this.state, required this.level});


  factory BatteryInfo.fromJson(Map<String, dynamic> json) =>
      BatteryInfo(
        state: json["state"] == "charging" ? BatteryState.charging : json["state"] == "full" ? BatteryState.full : json["state"] == "connectedNotCharging" ? BatteryState.connectedNotCharging : json["state"] == "discharging" ? BatteryState.discharging : BatteryState.unknown,
        level: json["level"] ?? 0,
        uid: json["uid"] ?? 0,
      );

  BatteryState getBatteryState(String str){
    if(str == "charging"){
      return BatteryState.charging;
    }else{
      return BatteryState.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'state': state.name,
      'level': level,
    };
  }
}
