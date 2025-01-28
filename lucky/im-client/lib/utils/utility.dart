// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

// base64库
import 'dart:convert' as convert;
import 'dart:convert' show Utf8Encoder;

// 文件相关
import 'dart:io' as io;
import 'dart:math';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pasteboard/flutter_pasteboard.dart';
import 'package:get/get.dart';
import 'package:image_compression_flutter/flutter_image_compress.dart';
import 'package:image_compression/image_compression.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import "package:pointycastle/export.dart";
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:scan/scan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';

import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;

/// 配对类型
class Pair<E, F> {
  E first;
  F? last;

  Pair(this.first, this.last);
}

int nowUnixTime() {
  return DateTime.now().millisecondsSinceEpoch;
}

//时间戳
int nowUnixTimeSecond() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

/// 随机整数
int randomInt({int? min, int? max}) {
  final Random gRandom = Random();
  min = min ?? 0;
  max = max ?? 2147483647;
  return min + gRandom.nextInt(max - min);
}

//通过时间戳显示时间。
String getZeroNum(int val) {
  if (val < 10) {
    return "0" + val.toString();
  }
  return val.toString();
}

// 正确截取utf8字符串
String subUtf8String(String str, int len, {bool needPoint = false}) {
  var sRunes = str.runes;
  return sRunes.length > len
      ? String.fromCharCodes(sRunes, 0, len) + (needPoint ? "..." : "")
      : str;
}

//复制字符串
copyToClipboard(String str) async {
  Clipboard.setData(ClipboardData(text: str));

  if (io.Platform.isIOS) {
    ImBottomToast(Routes.navigatorKey.currentContext!,
        title: localized(toastCopyToClipboard), icon: ImBottomNotifType.copy);
  } else {
    if (io.Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      if (int.parse(androidInfo.version.release) < 13) {
        ImBottomToast(Routes.navigatorKey.currentContext!,
            title: localized(toastCopyToClipboard),
            icon: ImBottomNotifType.copy);
      }
    }
  }
}

//复制内容
Future<bool> copyContent(dynamic obj, [bool showTips = true]) async {
  bool _isSucc = false;
  if (obj is AssetEntity) {
    io.File? f = await obj.originFile;
    if (f != null) {
      await FlutterPasteboard.writeImage(f);
      _isSucc = true;
    }
  } else if (obj is int) {
    if (obj != 0) {
      var rep = await RemoteImageData.create(obj.toString(), 0, 0, null);
      io.File? f = rep.cacheFile?.file;
      if (f != null) {
        await FlutterPasteboard.writeImage(f);
        _isSucc = true;
      }
      rep.dispose();
    }
  } else if (obj is io.File) {
    await FlutterPasteboard.writeImage(obj);
    _isSucc = true;
  } else if (obj is String) {
    copyToClipboard(obj);
    _isSucc = true;
  }
  if (showTips) {
    if (_isSucc)
      Toast.showToast(localized(toastCopySuccess));
    else
      Toast.showToast(localized(toastCopySuccess));
  }
  return _isSucc;
}

Future<Size> getImageCompressedSize(
  int width,
  int height,
) async {
  int minWidth = -1;
  int minHeight = -1;

  try {
    if ((width < 1600 && height < 1600)) {
      //原图
      minWidth = width;
      minHeight = height;
    } else {
      final ratio = width / height;
      if (width > height) {
        minWidth = (1600 * ratio).floor();
        minHeight = 1600;
      } else {
        minWidth = 1600;
        minHeight = (1600 / ratio).floor();
      }
    }

    return Size(minWidth.toDouble(), minHeight.toDouble());
  } catch (e) {
    pdebug("Invalid Image Data: $e");
    throw e;
  }
}

Future<io.File> getThumbImageWithPath(
  io.File data,
  int width,
  int height, {
  int quality = 80,
  required String savePath,
  required String sub,
}) async {
  Uint8List? _imageData = null;
  Uint8List initialImageData;
  int minWidth = -1;
  int minHeight = -1;

  initialImageData = data.readAsBytesSync();

  if (!notBlank(initialImageData)) return data;

  try {
    Size tempSize = await getImageCompressedSize(width, height);
    minWidth = tempSize.width.toInt();
    minHeight = tempSize.height.toInt();

    if (objectMgr.loginMgr.isMobile) {
      _imageData = await FlutterImageCompress.compressWithFile(
        data.absolute.path,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
      );
    } else {
      ///电脑压缩会用很长的时间
      final io.File file = io.File(data.absolute.path);
      final ImageFile input = ImageFile(
        filePath: file.path,
        rawBytes: file.readAsBytesSync(),
      );
      _imageData = compress(ImageFileConfiguration(input: input)).rawBytes;
    }

    if (_imageData != null) {
      String path = await downloadMgr.getTmpCachePath(
        savePath,
        sub: sub,
      );

      return await File(path).writeAsBytes(_imageData);
    } else {
      return data;
    }
  } catch (e) {
    Toast.showToast(localized(invalidImage));
    pdebug("Invalid Image Data: $e");
    throw e;
  }
}

Future<io.File> generateThumbnailWithPath(
  String videoPath, {
  required String savePath,
  required String sub,
}) async {
  final io.File imageFile = await VideoCompress.getFileThumbnail(
    videoPath,
    quality: 80,
    position: 1,
  );
  final _imageData = await imageFile.readAsBytes();

  String path = await downloadMgr.getTmpCachePath(
    savePath,
    sub: sub,
  );

  return await File(path).writeAsBytes(_imageData);
}

/// 需要移除
/// 获取压缩视频
@deprecated
Future<io.File?> videoCompress(
  io.File f, {
  required VideoQuality quality,
  Function(double)? onProgress,
  required String savePath,
}) async {
  VideoCompress.setLogLevel(1000);
  await VideoCompress.deleteAllCache();
  Subscription _subscription =
      VideoCompress.compressProgress$.subscribe((progress) {
    onProgress?.call(progress);
  });
  try {
    final MediaInfo? info = await VideoCompress.compressVideo(
      f.path,
      quality: quality,
      includeAudio: true,
    );
    if (info != null && info.filesize != null && info.path != null) {
      String path = await downloadMgr.getTmpCachePath(
        savePath,
        sub: 'compress_video',
      );

      return await File(path).writeAsBytes(await info.file!.readAsBytesSync());
    }
  } catch (e) {
    pdebug(["utility.videoCompress:$e"]);
    await f.delete().catchError((_) => f);
  } finally {
    _subscription.unsubscribe();
  }

  return f;
}

/*
 * 裁剪图片
 */
Future<io.File?> cropImage(io.File file) async {
  io.File? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      cropStyle: CropStyle.circle,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: localized(editPhoto),
          toolbarColor: Colors.white,
          cropFrameColor: Colors.transparent,
          activeControlsWidgetColor: JXColors.indigo,
          showCropGrid: false,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
        title: localized(editPhoto),
        doneButtonTitle: localized(popupConfirm),
        cancelButtonTitle: localized(popupCancel),
        aspectRatioPickerButtonHidden: true,
      ));
  if (croppedFile != null) {
    return croppedFile;
  }
  return null;
}

/// 通过 [Uint8List] 生成 [ui.Image]
Future<ui.Image> createUiImage(Uint8List data) async {
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromList(data, (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

String removeEndPoint(String url) {
  return url.replaceAll('${serversUriMgr.download2Uri}/', '');
}

/*
  * Base64加密
  */
String base64Encode(String data) {
  var content = convert.utf8.encode(data);
  var digest = convert.base64Encode(content);
  return digest;
}

/*
  * Base64解密
  */
String base64Decode(String data) {
  List<int> bytes = convert.base64Decode(data);
// 网上找的很多都是String.fromCharCodes，这个中文会乱码
//String txt1 = String.fromCharCodes(bytes);
  String result = convert.utf8.decode(bytes);
  return result;
}

//  /*
//   * 将Base64字符串的图片转换成图片
//   */
//   Image Future base642Image(String base64Txt) async {
//     String decodeTxt = convert.base64.decode(base64Txt) as String;
//     return Image.memory(decodeTxt,
//             width:100,fit: BoxFit.fitWidth,
//             gaplessPlayback:true, //防止重绘
//             );
//    }

// md5 加密
String makeMD5(String data) {
  var content = const Utf8Encoder().convert(data);
  var digest = md5.convert(content);
// 这里其实就是 digest.toString()
  return hex.encode(digest.bytes);
}

String calculateMD5(Uint8List fileBytes) {
  return hex.encode(md5.convert(fileBytes).bytes);
}

String calculateMD5List(List<int> fileBytes) {
  return hex.encode(md5.convert(fileBytes).bytes);
}

Uint8List calculateMD5Bytes(Uint8List fileBytes) {
  final md5Hash = md5.convert(fileBytes);
  return Uint8List.fromList(md5Hash.bytes);
}

/// Should use in [compute] OR [Isolate.spawn] to avoid UI blocking
String? calculateMD5FromPath(String path) {
  final f = io.File(path);
  if (!f.existsSync()) return null;

  return hex.encode(md5.convert(f.readAsBytesSync()).bytes);
}

/// 获取图片编辑参数
Future<Map<String, dynamic>?> getUiImageFromAsset(io.File oriFile) async {
  Uint8List bytes = oriFile.readAsBytesSync();

  ui.Image uiImage = await createUiImage(bytes);

  double canvasHeight = 0.0;
  double canvasWidth = 0.0;
  final screenHeight = ObjectMgr.screenMQ!.size.height;
  final screenWidth = ObjectMgr.screenMQ!.size.width;
  final viewPadding = ObjectMgr.viewPadding!;
  final maxHeight = screenHeight -
      viewPadding.top -
      viewPadding.bottom -
      (kToolbarHeight * 3);

  if (uiImage.height > uiImage.width) {
    canvasHeight = maxHeight;
    final hRatio = canvasHeight / uiImage.height;
    if (uiImage.width * hRatio > screenWidth) {
      final minusRatio = uiImage.width * hRatio / screenWidth;
      canvasHeight = canvasHeight / minusRatio;
      canvasWidth = min(uiImage.width * hRatio, screenWidth);
    } else {
      canvasWidth = min(uiImage.width * hRatio, screenWidth);
    }
  } else {
    canvasWidth = screenWidth;
    final wRatio = canvasWidth / uiImage.width;
    if (uiImage.height * wRatio > maxHeight) {
      final minusRatio = uiImage.height * wRatio / maxHeight;
      canvasWidth = canvasWidth / minusRatio;
      canvasHeight = min(uiImage.height * wRatio, maxHeight);
    } else {
      canvasHeight = min(uiImage.height * wRatio, maxHeight);
    }
  }

  return {
    'uiImage': uiImage,
    'width': canvasWidth,
    'height': canvasHeight,
  };
}

Future<Map<String, dynamic>?> getImageFromAsset(io.File oriFile) async {
  var image = Image.file(oriFile);
  Completer<ui.Image> completer = new Completer<ui.Image>();
  image.image
      .resolve(const ImageConfiguration())
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
    completer.complete(info.image);
  }));

  ui.Image info = await completer.future;

  return {
    'width': info.width,
    'height': info.height,
  };
}

//获取信息ID
String getMessageAssetId(Message message) {
  if (message.asset is AssetEntity) {
    if (objectMgr.loginMgr.isMobile) {
      return message.asset.id;
    } else {
      return message.asset.toString();
    }
  }

  return message.asset.hashCode.toString();
}

// Use Extension
extension BreakWord on String {
  String get breakWord {
    RegExp _regexp = RegExp(
        "[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]");
    String breakWord = '';
    runes.forEach((element) {
      var _byte = String.fromCharCode(element);
      breakWord += _byte;
      if (!_regexp.hasMatch(_byte)) {
        breakWord += '\u200B';
      }
    });
    return breakWord;
  }
}

double calculateTextHeight2({
  required BuildContext context,
  required String value,
  required double maxWidth,
  TextStyle? style,
  int? maxLines,
}) {
  TextPainter painter = TextPainter(
//locale: Localizations.localeOf(context),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: value,
      style: style,
    ),
  );
  painter.layout(maxWidth: maxWidth);
  return painter.height;
}

///计算文本高度
double calculateTextHeight({
  required BuildContext context,
  required String value,
  required fontSize,
  required double maxWidth,
  FontWeight? fontWeight,
  int? maxLines,
  double? height,
}) {
  TextPainter painter = TextPainter(
//locale: Localizations.localeOf(context),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: value,
      style: TextStyle(
        fontWeight: fontWeight,
        fontSize: fontSize,
        height: height,
      ),
    ),
  );
  painter.layout(maxWidth: maxWidth);
  return painter.height;
}

///跳转内部连接
Future<void> linkToWebView(
  String link, {
  bool useInternalWebView = true,
}) async {
  String path = link;
  if (!path.startsWith('http')) path = 'http://$link';
  var _uri = Uri.parse(path);

  try {
    launchUrl(
      _uri,
      mode: useInternalWebView
          ? LaunchMode.inAppWebView
          : LaunchMode.externalApplication,
      webViewConfiguration: const WebViewConfiguration(
        enableDomStorage: true,
        enableJavaScript: true,
      ),
    );
    objectMgr.navigatorMgr.showAllScreen();
  } catch (error) {
    Toast.showToast(localized(toastLinkInvalid));
  }
}

// 大写数字
String getChinaNumSingle(int num) {
  if (num > 10) return '';
  List<String> chinaNums = [
    localized(number0),
    localized(number1),
    localized(number2),
    localized(number3),
    localized(number4),
    localized(number5),
    localized(number6),
    localized(number7),
    localized(number8),
    localized(number9),
    localized(number10),
  ];
  return chinaNums[num];
}

//是否是长途 0普通 1 横图 2 长图
int longPic(int width, int height) {
  int maxx = max(width, height);
  if (maxx <= 2048) {
    return 0;
  }
  int minn = min(width, height);
  if (maxx / minn <= 3) return 0;

  return width > height ? 1 : 2;
}

changeLine(String text) {
  text = text.replaceAll(RegExp(r"\n{3,}"), '\n\n');
  return text;
}

/**
 * 判断两个数组是否相等
 * @param array1
 * @param array2
 * @return
 */
bool equalsArray(List<dynamic> array1, List<dynamic> array2) {
  int len = array1.length;
  if (len != array2.length) return false;
  for (int i = 0; i < len; i++) {
    var item = array1[i];
    var item2 = array2[i];
    if (item["isEqual"] && !item["isEqual"](item2)) {
      return false;
    } else if (item != item2) {
      return false;
    }
  }
  return true;
}

///bit计算
int bitCall(int val, bool is_ok, int type) {
  if (is_ok) {
    return val | type;
  } else {
    return val & ~type;
  }
}

//ase 加密
String aseEncode(String text, String k) {
  final key = encrypt.Key.fromUtf8(k);
  final iv = encrypt.IV.fromUtf8(k);
  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  return encrypter.encrypt(text, iv: iv).base64;
}

//ase解密
String aseDecode(String text, String k) {
  final key = encrypt.Key.fromUtf8(k);
  final iv = encrypt.IV.fromUtf8(k);
  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  return encrypter.decrypt64(text, iv: iv);
}

Future<String> aseDecodeAsync(String text, String k) async {
  final key = encrypt.Key.fromUtf8(k);
  final iv = encrypt.IV.fromUtf8(k);
  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  return encrypter.decrypt64(text, iv: iv);
}

//文件图标
String fileIconNameWithSuffix(String suffix, {bool sender = false}) {
  if (suffix == "doc" || suffix == "docx") {
    return sender
        ? "assets/icons/doc_icon_sender.png"
        : "assets/icons/doc_icon.png";
  } else if (suffix == "txt") {
    return sender
        ? "assets/icons/txt_icon_sender.png"
        : "assets/icons/txt_icon.png";
  } else if (suffix == "csv") {
    return sender
        ? "assets/icons/csv_icon_sender.png"
        : "assets/icons/csv_icon.png";
  } else if (suffix == "zip") {
    return sender
        ? "assets/icons/archive_icon_sender.png"
        : "assets/icons/archive_icon.png";
  } else if (suffix == "xls" || suffix == "xlsx") {
    return sender
        ? "assets/icons/xls_icon_sender.png"
        : "assets/icons/xls_icon.png";
  } else if (suffix == "ppt" || suffix == "pptx") {
    return sender
        ? "assets/icons/ppt_icon_sender.png"
        : "assets/icons/ppt_icon.png";
  } else if (suffix == "pdf") {
    return sender
        ? "assets/icons/pdf_icon_sender.png"
        : "assets/icons/pdf_icon.png";
  } else if (suffix == 'jpg' ||
      suffix == 'jpeg' ||
      suffix == 'png' ||
      suffix == 'gif') {
    return sender
        ? "assets/icons/image_icon_sender.png"
        : "assets/icons/image_icon.png";
  } else if (suffix == 'mp4' || suffix == 'avi') {
    return sender
        ? "assets/icons/video_icon_sender.png"
        : "assets/icons/video_icon.png";
  }
  return sender
      ? "assets/icons/empty_icon_sender.png"
      : "assets/icons/empty_icon.png";
}

String fileSize(int length) {
  var k = 1024.0;
  var fileSize = 0.0;
  if (length < k) {
    return '${length.toStringAsFixed(1)} B';
  } else if (length < k * k) {
    fileSize = length / k;
    return fileSize.toStringAsFixed(1) + ' KB';
  } else {
    fileSize = length / (k * k);
    return fileSize.toStringAsFixed(1) + ' MB';
  }
}

String fileMB(int length) {
  var k = 1024.0;
  var fileSize = 0.0;

  fileSize = length / (k * k);
  return fileSize.toStringAsFixed(2) + ' MB';
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
// Create an RSA key generator and initialize it

// final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

//   // Use the generator
// final parser = RSAKeyParser();
// parser.parse(key)
  final pair = keyGen.generateKeyPair();

// Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom exampleSecureRandom() {
  final secureRandom = SecureRandom('Fortuna')
    ..seed(
        KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}

///数字符号是否相同
///
///target 目标数字
///
///reference 对照数字
bool isSameSymbol(num target, num reference) {
  return (target > 0 && reference > 0) || (target < 0 && reference < 0);
}

///设置数字符号
///
///target 目标数字
///
///reference 对照数字
///
///isSame 是否相同符号
num setSymbol(num target, num reference, [bool isSame = true]) {
  if (target == 0 || reference == 0) return target;
  bool isSymbol = isSameSymbol(target, reference);
  if (isSame) {
    if (isSymbol) return target;
    return -target;
  }
  if (!isSymbol) return target;
  return -target;
}

///设置数字符号
///
///target 目标数字
///
///reference 对照数字
///
///isSame 是否相同符号
int setSymbolInt(int target, num reference, [bool isSame = true]) {
  return setSymbol(target, reference, isSame) as int;
}

///设置数字符号
///
///target 目标数字
///
///reference 对照数字
///
///isSame 是否相同符号
double setSymbolDouble(double target, num reference, [bool isSame = true]) {
  return setSymbol(target, reference, isSame) as double;
}

/// 时间转换字符串
String constructTime(
  int seconds, {
  bool showHour = true,
  bool showMinutes = true,
}) {
  int hour = seconds ~/ 3600;
  int minute = seconds % 3600 ~/ 60;
  int second = seconds % 60;

  StringBuffer sb = StringBuffer();
  if (showHour) {
    sb.write(formatTime(hour));
    sb.write(':');
  }
  if (showMinutes) {
    sb.write(formatTime(minute));
    sb.write(':');
  }
  sb.write(formatTime(second));
  return sb.toString();
}

String constructTimeVerbose(int seconds) {
  int hours = seconds ~/ 3600;
  int remainingSecondsAfterHours = seconds % 3600;
  int minutes = remainingSecondsAfterHours ~/ 60;
  int remainingSeconds = seconds % 60;
  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');

  if (hours > 0) {
    String formattedHours = hours.toString().padLeft(2, '0');
    return '$formattedHours:$formattedMinutes:$formattedSeconds';
  } else if (minutes > 0) {
    return '$formattedMinutes:$formattedSeconds';
  } else {
    return '00:$formattedSeconds';
  }
}

String constructTimeDetail(int second) {
  int hour = second ~/ 3600;
  int remainingSecondsAfterHours = second % 3600;
  int minute = remainingSecondsAfterHours ~/ 60;
  int remainingSeconds = second % 60;
  String formattedMinutes = minute.toString();
  String formattedSeconds = remainingSeconds.toString();

  if (hour > 0) {
    String formattedHours = hour.toString();
    return '$formattedHours ${localized(chatHour)}$formattedMinutes${localized(chatMinute)}$formattedSeconds${localized(chatSecond)}';
  } else if (minute > 0) {
    return '$formattedMinutes${localized(chatMinute)}$formattedSeconds${localized(chatSecond)}';
  } else {
    return '$formattedSeconds${localized(chatSecond)}';
  }
}

String formatTime(int timeNum) =>
    timeNum < 10 ? '0$timeNum' : timeNum.toString();

Future<bool> checkPermission(BuildContext context) async {
  var a = await Permissions.request([Permission.camera], context: context);
  if (!a) {
    return false;
  }
  if (io.Platform.isAndroid) {
    var b = await Permissions.request([Permission.storage], context: context);
    if (!b) {
      return false;
    }
    var c = await Permissions.request([Permission.accessMediaLocation],
        context: context);
    if (!c) {
      return false;
    }
  } else {
    var b = await Permissions.request([Permission.photos], context: context);
    if (!b) {
      return false;
    }
  }
  return true;
}

int getFirstNotContinuousNumber(List<int> numbers) {
  int index = -1;

// 判断如123456
  for (int i = 0; i < numbers.length; i++) {
    if (i > 0) {
      int num = numbers[i];
      int num_ = numbers[i - 1] + 1;
      if (num != num_) {
        index = num_;
        break;
      }
    }
  }
  return index;
}

bool isContinuousIntegers(List<int> numbers) {
  bool flag = true;

// 判断如123456
  for (int i = 0; i < numbers.length; i++) {
    if (i > 0) {
      int num = numbers[i];
      int num_ = numbers[i - 1] + 1;
      if (num != num_) {
        flag = false;
        break;
      }
    }
  }

  if (!flag) {
    for (int i = 0; i < numbers.length; i++) {
      if (i > 0) {
// 判断如654321
        int num = numbers[i];
        int num_ = numbers[i - 1] - 1;
        if (num != num_) {
          flag = false;
          break;
        }
      }
    }
  }

  return flag;
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}

///目前只有中文和英文
int multiLanguageSort(String a, String b) {
  final AppLocalizations currentLanguage =
      AppLocalizations(objectMgr.langMgr.currLocale);
  final RegExp isWord = RegExp(r'[A-Za-z\u4e00-\u9fa5]');
  final RegExp mandarinWord = RegExp(r'[\u4e00-\u9fa5]');

  if (a.isEmpty) return -1;
  if (b.isEmpty) return 1;

  ///开始排列
  final aChar = a.toLowerCase()[0];
  final bChar = b.toLowerCase()[0];

  int otherCase() {
    if (aChar.compareTo(bChar) == 0) {
      if (a.substring(1).isEmpty) {
        return -1;
      } else if (b.substring(1).isEmpty) {
        return 1;
      } else {
        return multiLanguageSort(a.substring(1), b.substring(1));
      }
    } else
      return aChar.compareTo(bChar);
  }

  if (isWord.hasMatch(aChar) && !isWord.hasMatch(bChar)) {
    return -1;
  } else if (!isWord.hasMatch(aChar) && isWord.hasMatch(bChar)) {
    return 1;
  } else if (isWord.hasMatch(aChar) && isWord.hasMatch(bChar)) {
    if (mandarinWord.hasMatch(aChar) && mandarinWord.hasMatch(bChar)) {
      if (convertToPinyin(aChar) == convertToPinyin(bChar)) {
        return multiLanguageSort(a.substring(1), b.substring(1));
      } else
        return multiLanguageSort(
            convertToPinyin(aChar), convertToPinyin(bChar));
    } else if (mandarinWord.hasMatch(aChar) && !mandarinWord.hasMatch(bChar)) {
      if (convertToPinyin(aChar)[0].compareTo(bChar) == 0) {
        return currentLanguage.isMandarin() ? -1 : 1;
      } else {
        return convertToPinyin(aChar)[0].compareTo(bChar);
      }
    } else if (!mandarinWord.hasMatch(aChar) && mandarinWord.hasMatch(bChar)) {
      if (aChar.compareTo(convertToPinyin(bChar)[0]) == 0) {
        return currentLanguage.isMandarin() ? 1 : -1;
      } else {
        return aChar.compareTo(convertToPinyin(bChar)[0]);
      }
    } else {
      return otherCase();
    }
  } else {
    return otherCase();
  }
}

String convertToPinyin(String text) {
  if (RegExp(r'[A-Za-z]').hasMatch(text)) {
    return text;
  }
  try {
    return PinyinHelper.getPinyin(
      text,
      separator: '',
      format: PinyinFormat.WITHOUT_TONE,
    );
  } catch (e) {
    pdebug("Convert to pinyin failed: $text");
  }
  return text;
}

sortSavedFirst(List<Chat> chatList) {
  return chatList.sort((a, b) {
    if (a.typ == chatTypeSaved && b.typ != chatTypeSaved) {
      return -1;
    } else if (a.typ != chatTypeSaved && b.typ == chatTypeSaved) {
      return 1;
    } else
      return b.last_time - a.last_time;
  });
}

String getWordAtOffset(String input, int index) {
  if (index < 0 || index > input.length) {
// Handle out-of-bounds index if needed
    return "";
  }

  int startIndex = index - 1;

  if (input.isEmpty || (index == 0 && input[0] == "@")) {
    return input;
  }

  if (input[startIndex].trim().toString().isEmpty) return '';

// Move backward to find the start of the word
  while (startIndex > 0 && input[startIndex].trim().toString() != "@") {
    startIndex--;
  }

  if (input.substring(startIndex).startsWith(' ')) {
    return input.substring(startIndex + 1, index);
  }

// Extract the word between startIndex and endIndex
  return input.substring(startIndex, index);
}

String displayTime(int seconds) {
  int milliseconds = 0;
  if (seconds != 0)
    milliseconds = seconds * 1000;
  else
    milliseconds = DateTime.now().millisecondsSinceEpoch;

  return intl.DateFormat(
          isTimestampToday(milliseconds) ? 'HH:mm' : 'dd MMM, HH:mm')
      .format(
    DateTime.fromMillisecondsSinceEpoch(milliseconds),
  );
}

bool isTimestampToday(int timestampMillis) {
  DateTime currentDate = DateTime.now();

  DateTime timestampDate = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

  return currentDate.year == timestampDate.year &&
      currentDate.month == timestampDate.month &&
      currentDate.day == timestampDate.day;
}

Future<String?> decodeQRCode(String filePath) async {
  if (io.Platform.isIOS) {
    return scanIOS(filePath);
  } else if (io.Platform.isAndroid) {
    return scanAndroid(filePath);
  } else {
    return null;
  }
}

Future<String?> scanIOS(String filePath) async {
  String? result = await Scan.parse(filePath);
  if (result != null) {
    return result;
  } else {
    return null;
  }
}

Future<String?> scanAndroid(String filePath) async {
  final imageData = await img.decodeImageFile(filePath);
  if (imageData != null) {
    final LuminanceSource source = RGBLuminanceSource(
        imageData.width,
        imageData.height,
        imageData
            .convert(numChannels: 4)
            .getBytes(order: img.ChannelOrder.rgba)
            .buffer
            .asInt32List());
    try {
      final BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      return QRCodeReader().decode(bitmap).text;
    } catch (e) {
      pdebug(e.toString());
    }
  } else {
    return null;
  }
}

String shortNameFromNickName(
  String nickName, {
  bool displayFull = false,
}) {
  if (nickName.isEmpty) return "-";

// return nickName.substring(0, 1).toUpperCase();
  bool isUtf16 = false;
  List<bool> utf16List = [];
  for (final item in nickName.codeUnits) {
    utf16List.add(isUtf16Surrogate(item));
    if (isUtf16Surrogate(item)) {
      isUtf16 = true;
      break;
    }
  }

  final String name;
  if (isUtf16) {
    if (utf16List.first) {
      name = String.fromCharCodes(nickName.runes, 0, 1);
    } else {
      name = nickName.substring(0, 1).toUpperCase();
    }
  } else {
    name = nickName
        .split(" ")
        .map((e) => e.isNotEmpty ? e[0] : nickName[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  return name;
}

bool isUtf16Surrogate(int value) {
  return value & 0xF800 == 0xD800;
}

bool standardResolution(int width, int height) {
  return (width > 0 && width <= 720) || (height > 0 && height <= 720);
}

/// 根据uri取得保存目录
Future<String> mkdirPath(String fileFullName) async {
  ///文件名
  String filename = fileFullName.substring(fileFullName.lastIndexOf('/') + 1);

  ///文件所在文件夹
  String saveDir =
      fileFullName.substring(0, fileFullName.length - filename.length);

//递归创建文件夹
  await DYio.mkDir(saveDir);

  assert(Directory(saveDir).existsSync());

  return fileFullName;
}

int stringToInt(String str) {
  var bytes = convert.utf8.encode(str); // 将字符串编码为字节流
  var digest = sha256.convert(bytes); // 计算 SHA-256 哈希值
  return int.parse(digest.toString(), radix: 16); // 将哈希值转换为整数
}

// 复制图片文件
Future<File> copyImageFile(File imageFile) async {
  Future<void> copyFile(File source, File destination) async {
    await destination.create(recursive: true);
    await source.copy(destination.path);
  }

  final directory = await getTemporaryDirectory();
  final newFile = await File('${directory.path}/' +
          md5
              .convert(convert.utf8.encode(DateTime.now().toString()))
              .toString() +
          '.jpg')
      .create();
  await copyFile(imageFile, newFile);
  return newFile;
}

// 获取文件扩展名
String getFileExtension2(String fileName) {
// 获取文件名中最后一个点之后的部分
  List<String> parts = fileName.split('.');
  if (parts.length > 1) {
    return ".${parts.last.toLowerCase()}"; // 返回小写形式的文件扩展名
  } else {
    return ''; // 如果找不到扩展名，则返回空字符串
  }
}

// 字节分割
List<List<int>> splitBytes(List<int> bytes, int chunkSize) {
  List<List<int>> chunks = [];
  int offset = 0;
  while (offset < bytes.length) {
    int chunkEnd = offset + chunkSize;
    if (chunkEnd > bytes.length) {
      chunkEnd = bytes.length;
    }
    chunks.add(bytes.sublist(offset, chunkEnd));
    offset = chunkEnd;
  }

  return chunks;
}

bool stringToBool(String value) {
  if (value.toLowerCase() == "true") {
    return true;
  } else if (value.toLowerCase() == "false") {
    return false;
  } else {
    throw Exception("Invalid boolean string: $value");
  }
}

void showProfileAvatar(int nicknameId, int avatarId, bool isGroup) {
  Get.toNamed(RouteName.avatarDetail, arguments: {
    'nicknameId': nicknameId,
    'avatarId': avatarId,
    'isGroup': isGroup,
  });
}

String localeToLangCode(Locale locale, String pattern) {
  if (locale.languageCode == LanguageOption.auto.value &&
      locale.countryCode == null) {
    return locale.languageCode;
  }
  return "${locale.languageCode}$pattern${locale.countryCode}";
}

Locale langCodeToLocale(String langCode, String pattern) {
  final data = langCode.split(pattern);
  String code = data.first;
  String country = data.last;
  return Locale(code, country);
}

// List<int> xorEncode(List<int> inputBytes) {
//   String key = Config().secretKey;
//   if (key.isEmpty) {
//     return inputBytes;
//   }
//   int keyLen = key.length;
//   List<int> encodedBytes = List<int>.filled(inputBytes.length, 0);
//   for (int i = 0; i < inputBytes.length; i++) {
//     encodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
//   }
//   return encodedBytes;
// }

// List<int> xorDecode(List<int> inputBytes) {
//   String key = Config().secretKey;
//   if (key.isEmpty) {
//     return inputBytes;
//   }
//   int keyLen = key.length;
//   List<int> decodedBytes = List<int>.filled(inputBytes.length, 0);
//   for (int i = 0; i < inputBytes.length; i++) {
//     decodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
//   }
//   return decodedBytes;
// }

// XOR Encode Function
Uint8List xorEncode(Uint8List inputBytes) {
  bool is_encrypt = Config().is_encrypt;
  if (is_encrypt == false) {
    return inputBytes;
  }
  String key = Config().secretKey;
  if (key.isEmpty) {
    return inputBytes;
  }
  int keyLen = key.length;
  Uint8List encodedBytes = Uint8List(inputBytes.length);
  for (int i = 0; i < inputBytes.length; i++) {
    encodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
  }
  return encodedBytes;
}

// XOR Decode Function
Uint8List xorDecode(Uint8List inputBytes) {
  bool is_encrypt = Config().is_encrypt;
  if (is_encrypt == false) {
    return inputBytes;
  }
  String key = Config().secretKey;
  if (key.isEmpty) {
    return inputBytes;
  }
  int keyLen = key.length;
  Uint8List decodedBytes = Uint8List(inputBytes.length);
  for (int i = 0; i < inputBytes.length; i++) {
    decodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
  }
  return decodedBytes;
}

int getTotalUsage(String dirPath) {
  int totalSize = 0;
  var dir = Directory(dirPath);
  try {
    if (dir.existsSync()) {
      dir
          .listSync(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      });
    }
  } catch (e) {
    pdebug(e.toString());
  }
  return totalSize;
}

double bytesToMB(int bytes) {
  double kilobytes = bytes / 1024;
  double megabytes = kilobytes / 1024;
  return megabytes;
}

Future<int> getDatabaseFileSize(String path) async {
  try {
    File dbFile = File(path);
    if (await dbFile.exists()) {
      int fileSize = await dbFile.length();
      return fileSize;
    } else {
      throw const FileSystemException("Database file not found");
    }
  } catch (e) {
    pdebug("Error getting database file size: $e");
    return 0; // Return -1 in case of an error
  }
}

Future<void> clearDirectory(Directory dir) async {
  try {
    List<FileSystemEntity> entities = dir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        entity.deleteSync();
      } else if (entity is Directory) {
        entity.deleteSync(recursive: true);
      }
    }
  } catch (e) {
    pdebug("Error clear directory:${e.toString()}");
  }
}

String getMinuteSecond(Duration duration){
  String time = "00:00";
  int timestamp = duration.inSeconds;
  int min = timestamp ~/ 60;
  int second = timestamp % 60;
  time = '${(min.toString().length == 1) ? '0$min' : '$min'}:${(second.toString().length == 1) ? '0$second' : '$second'}';
  return time;
}

Future<void> openSettingPopup(String name) async {
  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return CustomConfirmationPopup(
        title: localized(openSettingPopUpContent,params:[name,Config().appName]),
        confirmButtonText: localized(popupSetting),
        cancelButtonText: localized(buttonCancel),
        confirmCallback: () async {
          await openAppSettings();
        },
        cancelCallback: () => Get.back(),
      );
    },
  );
}
