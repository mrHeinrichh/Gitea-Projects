import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:jxim_client/firebase_options.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:location/location.dart';

final liveLocationManager = LiveLocationManager();

class LiveLocationManager {
  LiveLocationManager._internal();

  factory LiveLocationManager() => _instance;

  static final LiveLocationManager _instance = LiveLocationManager._internal();

  StreamSubscription<LocationData>? _locationSubscription;
  final Location location = Location();

  static List<LocationWorker> list = [];
  static Map<int, Duration> durationMap = {};

  static bool enable = false;

  void initFireBase() {
    Firebase.initializeApp(
      name: 'HeyTalk',
      options: DefaultFirebaseOptions.currentPlatform,
    ); // Firebase初始化
  }

  // 添加一条定位记录到数据库
  void addCurLocationToBase() async {
    try {
      final userId = objectMgr.localStorageMgr.userID.toString();
      final LocationData locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc(userId).set(
        {
          'latitude': locationResult.latitude,
          'longitude': locationResult.longitude,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      pdebug(e);
    }
  }

  // 开启共享定位
  void enableLiveLocation({required int friendId, required Duration duration}) {
    addCurLocationToBase();
    updateDurationMap(friendId: friendId, duration: duration);
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      pdebug(onError);
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }).listen((LocationData currentLocation) async {
      final userId = objectMgr.localStorageMgr.userID.toString();
      await FirebaseFirestore.instance.collection('location').doc(userId).set(
        {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
        SetOptions(merge: true),
      );
    });
  }

  // 开启共享定位
  void enableService(int friendId, Duration duration) {
    addCurLocationToBase();
    final worker = list.firstWhereOrNull((item) => item.friendId == friendId);
    if (worker == null) {
      list.add(LocationWorker(friendId, _createListener(), duration));
    }
  }

  StreamSubscription<LocationData> _createListener() {
    final subscription =
        location.onLocationChanged.listen((LocationData currentLocation) async {
      final userId = objectMgr.localStorageMgr.userID.toString();
      await FirebaseFirestore.instance.collection('location').doc(userId).set(
        {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
        SetOptions(merge: true),
      );
    });
    subscription.onError((error) {
      debugPrint('[Live Location]: live location service $error');
      subscription.cancel();
    });
    return subscription;
  }

  // 关闭共享定位
  void disableLiveLocation({required int friendId}) {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    updateDurationMap(friendId: friendId, duration: Duration.zero);
  }

  void disableService(int friendId) {
    final worker = list.firstWhereOrNull((item) => item.friendId == friendId);
    worker?.listener.cancel();
    updateWorkerDuration(friendId, Duration.zero);
  }

  void updateDurationMap({required int friendId, required Duration duration}) {
    durationMap[friendId] = duration;
  }

  void updateWorkerDuration(int friendId, Duration duration) {
    final worker = list.firstWhere((item) => item.friendId == friendId);
    worker.duration = duration;
  }
}

class LocationWorker {
  int friendId;
  StreamSubscription<LocationData> listener;
  Duration duration;

  LocationWorker(this.friendId, this.listener, this.duration);
}
