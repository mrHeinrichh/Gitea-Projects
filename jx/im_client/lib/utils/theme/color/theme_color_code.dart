import 'package:flutter/material.dart';

class ThemeColors {
  final Color themeColor;
  final Color themeSecondaryColor;
  final Color bubblePrimary;
  final Color bubbleSecondary;
  final Color chatBGPrimary;
  final Color chatBGTopLeft;
  final Color chatBGBottomLeft;
  final Color chatBGTopRight;
  final Color chatBGBottomRight;

  ThemeColors({
    required this.themeColor,
    required this.themeSecondaryColor,
    required this.bubblePrimary,
    required this.bubbleSecondary,
    required this.chatBGPrimary,
    required this.chatBGTopLeft,
    required this.chatBGBottomLeft,
    required this.chatBGTopRight,
    required this.chatBGBottomRight,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      themeColor: _fromHex(json['theme']) ?? const Color(0xFF007AFF),
      themeSecondaryColor: _fromHex(json['themeSecondary']) ?? const Color(0xFF76B7FF),
      bubblePrimary: _fromHex(json['bubblePrimary']) ?? const Color(0xFF5AC63A),
      bubbleSecondary: _fromHex(json['bubbleSecondary']) ?? const Color(0xFFE1FFC7),
      chatBGPrimary: _fromHex(json['chatBGPrimary']) ?? const Color(0xFF84BA88),
      chatBGTopLeft: _fromHex(json['chatBGTopLeft']) ?? const Color(0xFFC9D481),
      chatBGBottomLeft: _fromHex(json['chatBGBottomLeft']) ?? const Color(0xFF61AB83),
      chatBGTopRight: _fromHex(json['chatBGTopRight']) ?? const Color(0xFF84BD84),
      chatBGBottomRight: _fromHex(json['chatBGBottomRight']) ?? const Color(0xFFCAD6AF),
    );
  }

  static Color? _fromHex(String? hexString) {
    final buffer = StringBuffer();
    if (hexString == null) {
      return null;
    } else {
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
  }
}
