import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemChromeUtils {
  /// 设置浅色状态栏
  static void setLightThemeStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark,
    );
  }

  /// 设置深色状态栏
  static void setDarkThemeStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light,
    );
  }

  /// 设置透明色状态栏
  static void setTransparentStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 隐藏状态栏
  static void setStatusBarInvisible() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
  }

  /// 显示状态栏
  static void setStatusBarVisible() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
