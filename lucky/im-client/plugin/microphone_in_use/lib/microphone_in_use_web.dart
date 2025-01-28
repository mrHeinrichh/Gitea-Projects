// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'microphone_in_use_platform_interface.dart';

/// A web implementation of the MicrophoneInUsePlatform of the MicrophoneInUse plugin.
class MicrophoneInUseWeb extends MicrophoneInUsePlatform {
  /// Constructs a MicrophoneInUseWeb
  MicrophoneInUseWeb();

  static void registerWith(Registrar registrar) {
    MicrophoneInUsePlatform.instance = MicrophoneInUseWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = html.window.navigator.userAgent;
    return version;
  }
}
