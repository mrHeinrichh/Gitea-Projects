import 'dart:convert';
import 'dart:ui';

import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/theme_color_code.dart';

Map<String, dynamic> jsonMap = jsonDecode(Config().colorJson);
ThemeColors themeColors = ThemeColors.fromJson(jsonMap);

/// theme color
Color themeColor = themeColors.themeColor;
Color themeSecondaryColor = themeColors.themeSecondaryColor;
Color bubblePrimary = themeColors.bubblePrimary;
Color bubbleSecondary = themeColors.bubbleSecondary;
Color chatBgPrimary = themeColors.chatBGPrimary;
Color chatBgTopLeft = themeColors.chatBGTopLeft;
Color chatBgBottomLeft = themeColors.chatBGBottomLeft;
Color chatBgTopRight = themeColors.chatBGTopRight;
Color chatBgBottomRight = themeColors.chatBGBottomRight;

/// neutral
const Color colorRed = Color(0xFFEB4B35);
const Color colorGreen = Color(0xFF5AC63A);
const Color colorWhite = Color(0xFFFFFFFF);
const Color colorGrey = Color(0xFFABABAB);
const Color colorOrange = Color(0xFFE39E4C);

/// text color
const Color colorTextPrimary = Color(0xFF121212); // 100%
const Color colorTextSecondary = Color(0x7A121212); // 48%
const Color colorTextSecondarySolid = Color(0xFF8A8A8A); // 48% solid color
const Color colorTextSupporting = Color(0x52121212); // 32%
const Color colorTextPlaceholder = Color(0x33121212); // 20%

/// background color
const Color colorBackground = Color(0xFFF3F3F3);
const Color colorSurface = Color(0xFFFFFFFF);
const Color colorMediaBarBg = Color(0xE6121212);

/// border color
const Color colorBorder = Color(0x0f121212); // 6%

/// red packet
const Color colorRedPacketLucky = Color(0xFFE57519);
const Color colorRedPacketExclusive = Color(0xFFA68633);
const Color colorRedPacketNormal = Color(0xFFB73229);

/// special color
const Color colorRecordDelete = Color(0xFFFFC0BD);
const Color colorQrCode = Color(0xFF268EA4);
const Color colorTaskPurple = Color(0xFF6D84FF);
const Color colorMuteContainer = Color(0xFFE57519);
const Color colorBgPin = Color(0xFFF8F8F8);
const Color colorDesktopChatBg = Color(0xFFE6E2DA);
const Color colorDesktopChatBlue = Color(0xFF4685BC);
const Color colorDesktopDarkGrey = Color(0xFFDDDDDD);
const Color colorReadColor = Color(0xFF007AFF);
const Color colorPrimaryYellow = Color(0xFFE49E4C);
const Color colorLink = Color(0xFF1D49A7);
