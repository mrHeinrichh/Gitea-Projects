library maps_flutter;

import 'dart:async';

import 'maps_flutter_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part './apple_map.dart';

part './apple_map_controller.dart';

class MapsFlutter {
  Future<String?> getPlatformVersion() {
    return MapsFlutterPlatform.instance.getPlatformVersion();
  }
}
