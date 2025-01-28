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

/// text color
const Color colorTextPrimary = Color(0xFF000000); // 100%
const Color colorTextLevelTwo = Color(0x8F000000); // 56%, 用在输入框的上下说明文字
const Color colorTextSecondary = Color(0x70000000); // 44%
const Color colorTextSecondarySolid = Color(0xFF8F8F8F); // 44% solid color
const Color colorTextSupporting = Color(0x61000000); // 38%
const Color colorTextPlaceholder = Color(0x33000000); // 20%

/// For text with dark background
const Color colorBrightPrimary = Color(0xFFFFFFFF); // 100%
const Color colorBrightLevelTwo = Color(0x99FFFFFF); // 60%
const Color colorBrightSecondary = Color(0x70FFFFFF); // 44%
const Color colorBrightPlaceholder = Color(0x33FFFFFF); // 20%

/// Overlay Color
const Color colorOverlay90 = Color(0xE6000000); // 添加说明
const Color colorOverlay82 = Color(0xD1000000); // toast
const Color colorOverlay60 = Color(0x99000000); // 预览遮罩
const Color colorOverlay50 = Color(0x80000000); // 扫描遮罩
const Color colorOverlay40 = Color(0x66000000); // 通用遮罩

/// neutral
const Color colorRed = Color(0xFFEB4B35);
const Color colorGreen = Color(0xFF5AC63A);
const Color colorWhite = Color(0xFFFFFFFF);
const Color colorGrey = Color(0xFFABABAB);
const Color colorOrange = Color(0xFFE49E4C);
const Color colorYellow = Color(0xFFC97C38);

/// background color
const Color colorBackground = Color(0xFFF3F3F3);
const Color colorSurface = Color(0xFFFFFFFF);
const Color colorBackground8 = Color(0x14000000); // 8%, hover背景
const Color colorBackground6 = Color(0x0f000000); // 6%, 搜索栏与hover背景
const Color colorBackground3 = Color(0x08000000); // 3%, 置顶消息背景

const Color colorDivider = Color(0x33000000);

/// red packet
const Color colorRedPacketLucky = Color(0xFFE57519);
const Color colorRedPacketExclusive = Color(0xFFA68633);
const Color colorRedPacketNormal = Color(0xFFB73229);

/// special color
const Color colorUserGuide = Color(0xFF5AC8FA); // toast action 文字颜色
const Color colorLink = Color(0xFF1D49A7);
const Color colorReadColor = Color(0xFF007AFF); // 已读
const Color colorRecordDelete = Color(0xFFFFC0BD);
const Color colorQrCode = Color(0xFF268EA4);
const Color colorTaskPurple = Color(0xFF6D84FF);
const Color colorBgPin = Color(0xFFF7F7F7);
const Color colorDesktopChatBg = Color(0xFFE6E2DA);
const Color colorDesktopChatBlue = Color(0xFF4685BC);
const Color colorDesktopDarkGrey = Color(0xFFDDDDDD);
