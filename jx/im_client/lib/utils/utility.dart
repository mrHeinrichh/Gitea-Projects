import 'dart:async'; // base64库
import 'dart:convert' as convert;
import 'dart:convert' show Utf8Encoder;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' as io;
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_compression/image_compression.dart';
import 'package:image_compression_flutter/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jxim_client/home/component/more_functions_bottom_sheet.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart' as file_util;
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:language_code/language_code.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import "package:pointycastle/export.dart" hide Digest;
import 'package:scan/scan.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:video_compress/video_compress.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:zxing2/qrcode.dart';

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
    return "0$val";
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
copyToClipboard(String str, {String? toastMessage, bool isOverlayToast = false}) async {
  Clipboard.setData(ClipboardData(text: str));
  bool showToast = false;
  if (io.Platform.isIOS) {
    showToast = true;
  } else {
    if (io.Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      if (int.parse(androidInfo.version.release) < 13) {
        showToast = true;
      } else {
        String brand = androidInfo.brand.toLowerCase();
        if (brand == 'vivo' ||
            brand == 'honor' ||
            brand == 'xiaomi' ||
            brand == 'realme') {
          showToast = true;
        }
      }
    }
  }
  if (isOverlayToast) {
    OverlayToast.showToast(
      context: navigatorKey.currentContext!,
      title: toastMessage ?? localized(toastCopyToClipboard),
    );
  } else if (showToast) {
    imBottomToast(
      navigatorKey.currentContext!,
      title: toastMessage ?? localized(toastCopyToClipboard),
      icon: ImBottomNotifType.copy,
    );
  }
}

Size getResolutionSize(int width, int height, int resolution) {
  double ratio = width / height;

  double newHeight = 0;
  double newWidth = 0;

  if (ratio > 1) {
    newHeight = min(height.toDouble(), resolution.toDouble());
    newWidth = newHeight * ratio;
  } else {
    newWidth = min(width.toDouble(), resolution.toDouble());
    newHeight = newWidth / ratio;
  }

  return Size(newWidth, newHeight);
}

Size getImageCompressedSize(
  int width,
  int height,
) {
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
    rethrow;
  }
}

Future<io.File> getThumbImageWithPath(
  io.File data,
  int width,
  int height, {
  required String savePath,
  required String sub,
  int quality = 80,
  CompressFormat format = CompressFormat.jpeg,
}) async {
  Uint8List? imageData;
  Uint8List initialImageData;

  initialImageData = data.readAsBytesSync();

  if (!notBlank(initialImageData)) return data;

  try {
    if (objectMgr.loginMgr.isMobile) {
      imageData = await FlutterImageCompress.compressWithFile(
        data.absolute.path,
        minWidth: width,
        minHeight: height,
        quality: quality,
        format: format,
      );
    } else {
      ///电脑压缩会用很长的时间
      final io.File file = io.File(data.absolute.path);
      final ImageFile input = ImageFile(
        filePath: file.path,
        rawBytes: file.readAsBytesSync(),
      );
      imageData = compress(ImageFileConfiguration(input: input)).rawBytes;
    }

    if (imageData != null) {
      String path = await downloadMgr.getTmpCachePath(
        savePath,
        sub: sub,
      );

      return await io.File(path).writeAsBytes(imageData);
    } else {
      return data;
    }
  } catch (e) {
    Toast.showToast(localized(invalidImage));
    pdebug("Invalid Image Data: $e");
    rethrow;
  }
}

/*
 * 获取压缩视频
 */
Future<io.File?> getThumbVideo(
  io.File f, {
  Function(double)? onProgress,
}) async {
  VideoCompress.setLogLevel(1000);
  await VideoCompress.deleteAllCache();
  Subscription subscription =
      VideoCompress.compressProgress$.subscribe((progress) {
    onProgress?.call(progress);
  });
  try {
    final MediaInfo? info = await VideoCompress.compressVideo(
      f.path,
      quality: VideoQuality.Res960x540Quality,
      includeAudio: true,
    ).timeout(const Duration(seconds: 5)).catchError((onError) {
      if (onError is TimeoutException) {
        pdebug('接口超时');
      }
      return onError;
    });
    if (info != null && info.filesize != null && info.path != null) {
      final compressedFilePath = await downloadMgr.getTmpCachePath(
        "${path.basenameWithoutExtension(f.path)}_540${path.extension(f.path)}",
      );
      final compressedFile = await io.File(compressedFilePath)
          .writeAsBytes(info.file!.readAsBytesSync());

      return compressedFile;
    }
  } catch (e) {
    pdebug(["utility.getThumbVideo:$e"]);
  } finally {
    subscription.unsubscribe();
  }

  return f;
}

Future<io.File?> generateThumbnailWithPath(
  String videoPath, {
  String? savePath,
  String? sub,
}) async {
  String filePath = await downloadMgr.getTmpCachePath(
    savePath ?? videoPath,
    sub: sub ?? 'generateThumbnailWithPath',
  );
  try {
    final io.File imageFile = await VideoCompress.getFileThumbnail(
      videoPath,
      quality: 80,
      position: 1,
    ).timeout(const Duration(seconds: 5)).catchError((onError) {
      if (onError is TimeoutException) {
        pdebug('接口超时');
      }
      return onError;
    });
    final imageData = await imageFile.readAsBytes();

    return await io.File(filePath).writeAsBytes(imageData);
  } catch (e) {
    pdebug('generateThumbnailWithPath: $e');
  }

  return null;
}

/// 需要移除
/// 获取压缩视频
Future<io.File?> videoCompress(
  io.File f, {
  required VideoQuality quality,
  Function(double)? onProgress,
  required String savePath,
}) async {
  VideoCompress.setLogLevel(1000);
  await VideoCompress.deleteAllCache();
  Subscription subscription =
      VideoCompress.compressProgress$.subscribe((progress) {
    onProgress?.call(progress);
  });
  try {
    final MediaInfo? info = await VideoCompress.compressVideo(
      f.path,
      quality: quality,
      includeAudio: true,
    ).timeout(const Duration(seconds: 5)).catchError((onError) {
      if (onError is TimeoutException) {
        pdebug('接口超时');
      }
      return onError;
    });
    if (info != null && info.filesize != null && info.path != null) {
      String path = await downloadMgr.getTmpCachePath(
        savePath,
        sub: 'compress_video',
      );

      return await io.File(path).writeAsBytes(info.file!.readAsBytesSync());
    }
  } catch (e) {
    pdebug(["utility.videoCompress:$e"]);
    await f.delete().catchError((_) => f);
  } finally {
    subscription.unsubscribe();
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
      activeControlsWidgetColor: themeColor,
      showCropGrid: false,
      initAspectRatio: CropAspectRatioPreset.square,
      lockAspectRatio: false,
    ),
    iosUiSettings: IOSUiSettings(
      minimumAspectRatio: 1.0,
      title: localized(editPhoto),
      doneButtonTitle: localized(popupConfirm),
      cancelButtonTitle: localized(popupCancel),
      aspectRatioPickerButtonHidden: true,
    ),
  );
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
Future<String?> calculateMD5FromPath(String filePath) async {
  if (Platform.isMacOS) {
    final result = await calculateMd5LinuxOrMac(filePath);
    if (result != null) return result;
  }
  final stopwatch = Stopwatch()..start();
  var file = File(filePath);
  var md5Hash = md5; // 获取 MD5 哈希算法对象
  var digest = AccumulatorSink<Digest>(); // 用于存储最后的哈希值
  var sink = md5Hash.startChunkedConversion(digest); // 启动分块处理

  // 以流方式读取文件并计算MD5
  await for (var chunk in file.openRead()) {
    sink.add(chunk); // 逐块添加数据
  }

  sink.close(); // 关闭 sink 以完成 MD5 计算
  final md5Str = digest.events.single.toString();
  pdebug(
      'calculateMD5FromPath execution_time: ${stopwatch.elapsedMilliseconds} ms} md5: $md5Str');
  return md5Str; // 返回最终的哈希值
}

Future<String?> calculateMd5LinuxOrMac(String filePath) async {
  try {
    // Linux 使用 md5sum，macOS 使用 md5
    var result =
        await Process.run(Platform.isLinux ? 'md5sum' : 'md5', [filePath]);

    if (result.exitCode == 0) {
      String output = result.stdout.toString().trim();

      // 使用正则表达式提取 MD5 值
      RegExp regExp = RegExp(r'= ([a-fA-F0-9]{32})');
      Match? match = regExp.firstMatch(output);
      if (match != null) {
        String md5 = match.group(1)!;
        pdebug("calculateMd5LinuxOrMac MD5 hash of the file: $md5");
        return md5;
      } else {
        pdebug("calculateMd5LinuxOrMac 未能提取到 MD5 值，请检查输出格式。");
      }
    } else {
      pdebug("calculateMd5LinuxOrMac 计算 MD5 失败: ${result.stderr}");
    }
  } catch (e) {
    pdebug("calculateMd5LinuxOrMac 执行命令出错: $e");
  }

  return null;
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

Future<Map<String, int>> getImageFromAsset(io.File oriFile) async {
  var image = Image.file(oriFile);
  Completer<ui.Image> completer = Completer<ui.Image>();
  late final ImageStreamListener listener;
  final imageStream = image.image.resolve(const ImageConfiguration());

  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      completer.complete(info.image);
      imageStream.removeListener(listener);
    },
    onError: (Object error, StackTrace? stackTrace) {
      completer.completeError(error, stackTrace);
      imageStream.removeListener(listener);
    },
  );
  imageStream.addListener(listener);

  ui.Image info = await completer.future;

  return <String, int>{
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
    RegExp regexp = RegExp(
      "[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]",
    );
    String breakWord = '';
    for (var element in runes) {
      var byte = String.fromCharCode(element);
      breakWord += byte;
      if (!regexp.hasMatch(byte)) {
        breakWord += '\u200B';
      }
    }
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

TextPainter textIsExpandable({
  required BuildContext context,
  required String value,
  required double maxWidth,
  TextStyle? style,
  int? maxLines,
}) {
  return TextPainter(
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: value,
      style: style,
    ),
  )..layout(maxWidth: maxWidth);
}

///跳转内部连接
Future<void> linkToWebView(
  String link, {
  bool useInternalWebView = true,
}) async {
  String path = link;
  path = path[0].toLowerCase() + path.substring(1);
  if (!path.startsWith('http')) path = 'http://$link';
  var uri = Uri.parse(path);

  try {
    launchUrl(
      uri,
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

/// 判断两个数组是否相等
/// @param array1
/// @param array2
/// @return
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
int bitCall(int val, bool isOk, int type) {
  if (isOk) {
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
    return '${fileSize.toStringAsFixed(1)} KB';
  } else {
    fileSize = length / (k * k);
    return '${fileSize.toStringAsFixed(1)} MB';
  }
}

String fileMB(int length) {
  var k = 1024.0;
  var fileSize = 0.0;

  fileSize = length / (k * k);
  return '${fileSize.toStringAsFixed(2)} MB';
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
  SecureRandom secureRandom, {
  int bitLength = 2048,
}) {
// Create an RSA key generator and initialize it

// final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(
    ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom,
    ),
  );

//   // Use the generator
// final parser = RSAKeyParser();
// parser.parse(key)
  final pair = keyGen.generateKeyPair();

// Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
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
    return '$formattedHours${localized(chatHour)}$formattedMinutes${localized(chatMinute)}$formattedSeconds${localized(chatSecond)}';
  } else if (minute > 0) {
    return '$formattedMinutes${localized(chatMinute)}$formattedSeconds${localized(chatSecond)}';
  } else {
    return '$formattedSeconds${localized(chatSecond)}';
  }
}

String formatTime(int timeNum) =>
    timeNum < 10 ? '0$timeNum' : timeNum.toString();

// type 0 = camera, 1 = photo
Future<bool> checkCameraOrPhotoPermission({int type = 0}) async {
  var permissions = [Permission.photos];
  // CamerawesomePage.openImCamera need photo permission to save to gallery
  if (type != 0) permissions.insert(0, Permission.camera);
  return await Permissions.request(permissions);
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
    } else {
      return aChar.compareTo(bChar);
    }
  }

  if (isWord.hasMatch(aChar) && !isWord.hasMatch(bChar)) {
    return -1;
  } else if (!isWord.hasMatch(aChar) && isWord.hasMatch(bChar)) {
    return 1;
  } else if (isWord.hasMatch(aChar) && isWord.hasMatch(bChar)) {
    if (mandarinWord.hasMatch(aChar) && mandarinWord.hasMatch(bChar)) {
      if (convertToPinyin(aChar) == convertToPinyin(bChar)) {
        return multiLanguageSort(a.substring(1), b.substring(1));
      } else {
        return multiLanguageSort(
          convertToPinyin(aChar),
          convertToPinyin(bChar),
        );
      }
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
    } else {
      return b.last_time - a.last_time;
    }
  });
}

String getWordAtOffset(String input, int index) {
  if (index < 0 || index > input.length) {
// Handle out-of-bounds index if needed
    return "";
  }

  int startIndex = max(index - 1, 0);

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
  if (seconds != 0) {
    milliseconds = seconds * 1000;
  } else {
    milliseconds = DateTime.now().millisecondsSinceEpoch;
  }

  return intl.DateFormat(
    isTimestampToday(milliseconds) ? 'HH:mm' : 'dd MMM, HH:mm',
  ).format(
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

String formatVideoDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String formattedHours = hours > 0 ? hours.toString().padLeft(2, '0') : '';
  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');

  String duration = '';

  if (formattedHours.isNotEmpty) {
    duration += '$formattedHours:';
  }

  duration += '$formattedMinutes:$formattedSeconds';

  return duration;
}

/// Temporary Group related

String formatToLocalTime(int gmtTimestamp) {
  DateTime gmtDateTime =
      DateTime.fromMillisecondsSinceEpoch(gmtTimestamp * 1000, isUtc: true);
  DateTime localDateTime = gmtDateTime.toLocal();
  intl.DateFormat formatter = intl.DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(localDateTime);
}

int calculateEndOfDayTimestamp(int? value) {
  DateTime now = DateTime.now();
  DateTime newTime = now.add(Duration(milliseconds: value ?? 0));
  DateTime endOfDay =
      DateTime(newTime.year, newTime.month, newTime.day, 23, 59, 59);
  int expiryTime = endOfDay.millisecondsSinceEpoch ~/ 1000;

  return expiryTime;
}

int setCustomizeExpiryDuration(DateTime newTime) {
  DateTime endOfDay =
      DateTime(newTime.year, newTime.month, newTime.day, 23, 59, 59);
  return endOfDay.millisecondsSinceEpoch ~/ 1000;
}

String countDownDuration(Duration duration) {
  // Format duration as hh:mm:ss
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

bool isLessThan24hrsUTC(int timestamp) {
  DateTime currentTime = DateTime.now();
  DateTime timeToCheck =
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);

  Duration difference = timeToCheck.difference(currentTime);
  return difference.inHours < 24 && !difference.isNegative;
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
          .asInt32List(),
    );
    try {
      final BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      return QRCodeReader().decode(bitmap).text;
    } catch (e) {
      pdebug(e.toString());
    }
  } else {
    return null;
  }
  return null;
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

  assert(io.Directory(saveDir).existsSync());

  return fileFullName;
}

int stringToInt(String str) {
  var bytes = convert.utf8.encode(str); // 将字符串编码为字节流
  var digest = sha256.convert(bytes); // 计算 SHA-256 哈希值
  return int.parse(digest.toString(), radix: 16); // 将哈希值转换为整数
}

// 复制图片文件
Future<io.File> copyImageFile(io.File imageFile) async {
  Future<void> copyFile(io.File source, io.File destination) async {
    await destination.create(recursive: true);
    await source.copy(destination.path);
  }

  final appCacheRootPath = AppPath.appCacheRootPath;
  final newFile = await io.File(
    '$appCacheRootPath/${md5.convert(convert.utf8.encode(DateTime.now().toString()))}.jpg',
  ).create();
  await copyFile(imageFile, newFile);
  return newFile;
}

Future<FilePickerResult?> renameFiles(FilePickerResult? result) async {
  if (result == null) return null;
  List<PlatformFile> renamedFiles = [];

  for (var file in result.files) {
    io.File originalFile = io.File(file.path!);

    String fileHash = DateTime.now().millisecondsSinceEpoch.toString();
    String newDirectoryPath = '${originalFile.parent.path}/$fileHash';
    String newPath = '$newDirectoryPath/${file.name}';

    try {
      await io.Directory(newDirectoryPath).create(recursive: true);
      io.File renamedFile = await originalFile.copy(newPath);
      PlatformFile renamedPlatformFile = PlatformFile(
        name: renamedFile.uri.pathSegments.last,
        path: renamedFile.path,
        size: await renamedFile.length(),
        bytes: await renamedFile.readAsBytes(),
        readStream: renamedFile.openRead(),
      );
      renamedFiles.add(renamedPlatformFile);
    } catch (e) {
      pdebug('Error renaming file: $e');
      return null;
    }
  }

  return FilePickerResult(renamedFiles);
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
  Get.toNamed(
    RouteName.avatarDetail,
    arguments: {
      'nicknameId': nicknameId,
      'avatarId': avatarId,
      'isGroup': isGroup,
    },
  );
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
Uint8List xorEncode(Uint8List inputBytes, String key) {
  int keyLen = key.length;
  Uint8List encodedBytes = Uint8List(inputBytes.length);
  for (int i = 0; i < inputBytes.length; i++) {
    encodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
  }
  return encodedBytes;
}

// XOR Decode Function
Uint8List xorDecode(Uint8List inputBytes, String key) {
  int keyLen = key.length;
  Uint8List decodedBytes = Uint8List(inputBytes.length);
  for (int i = 0; i < inputBytes.length; i++) {
    decodedBytes[i] = inputBytes[i] ^ key.codeUnitAt(i % keyLen);
  }
  return decodedBytes;
}

String getDecodeKey(String url) {
  if (url.isEmpty || !url.contains('secret/')) {
    return '';
  }
  String decodeStr = '';
  RegExp regExp = RegExp(r'secret/[^/]+/(\d+)/');
  Match? match = regExp.firstMatch(url);

  if (match != null) {
    // 提取到的数字
    String result = match.group(1)!;

    final codeIndex = int.tryParse(result);
    if (codeIndex != null && codeIndex >= 0) {
      final assert_list = Config().assert_list;
      if (assert_list.length > codeIndex) {
        decodeStr = assert_list[codeIndex];
        pdebug('decodeStr 下载地址 $url 解密密钥位置：$codeIndex decodeStr:$decodeStr');
      }
    }
  }

  return decodeStr;
}

int getTotalUsage(String dirPath) {
  int totalSize = 0;
  var dir = io.Directory(dirPath);
  try {
    totalSize = _recursiveCalculateTotalSize(dir);
  } catch (e) {
    pdebug(e.toString());
  }
  return totalSize;
}

int _recursiveCalculateTotalSize(Directory dir) {
  int totalSize = 0;
  if (dir.existsSync()) {
    dir
        .listSync(recursive: true, followLinks: false)
        .forEach((io.FileSystemEntity entity) {
      if (entity is io.File) {
        totalSize += entity.lengthSync();
      } else if (entity is io.Directory) {
        Directory directory = entity;
        totalSize += _recursiveCalculateTotalSize(directory);
      }
    });
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
    io.File dbFile = io.File(path);
    if (await dbFile.exists()) {
      int fileSize = await dbFile.length();
      return fileSize;
    } else {
      throw const io.FileSystemException("Database file not found");
    }
  } catch (e) {
    pdebug("Error getting database file size: $e");
    return 0; // Return -1 in case of an error
  }
}

Future<void> clearDirectory(io.Directory dir) async {
  try {
    if (!await dir.exists()) return;
    List<io.FileSystemEntity> entities = dir.listSync();
    for (var entity in entities) {
      if (entity is io.File && await entity.exists()) {
        await entity.delete();
      } else if (entity is io.Directory && await entity.exists()) {
        await entity.delete(recursive: true);
      }
    }
  } catch (e, stackTrace) {
    pdebug("Error clear directory:${e.toString()}", stackTrace: stackTrace);
  }
}

String getMinuteSecond(Duration duration) {
  String time = "00:00";
  int timestamp = duration.inSeconds;
  int min = timestamp ~/ 60;
  int second = timestamp % 60;
  time =
      '${(min.toString().length == 1) ? '0$min' : '$min'}:${(second.toString().length == 1) ? '0$second' : '$second'}';
  return time;
}

Future<void> openSettingPopup(String name, {String? subTitle}) async {
  showCustomBottomAlertDialog(
    Get.context!,
    title: localized(callAccessNeeded),
    subtitle: subTitle ??
        localized(
          openSettingPopUpContent,
          params: [name, Config().appName],
        ),
    confirmText: localized(popupSetting),
    confirmTextColor: themeColor,
    cancelTextColor: themeColor,
    onConfirmListener: () async {
      await openAppSettings();
    },
  );
}

Message createMessageWithImageCaption(Message message, String text) {
  // final message = computedAssets[photoData.currentPage]['message'];
  final newMessage = message.copyWith(null);
  final content = newMessage.content;
  final contentJson = jsonDecode(content);
  contentJson['caption'] = text;
  newMessage.content = jsonEncode(contentJson);
  return newMessage;
}

bool isLess24Hours(int timestamp) {
  DateTime currentTime = DateTime.now();

  DateTime timeToCheck = DateTime.fromMillisecondsSinceEpoch(timestamp);

  Duration difference = currentTime.difference(timeToCheck);
  return difference.inHours < 24;
}

double setWidth(
  bool isPin,
  bool isEdited, {
  bool? isTranslate,
  bool isMe = false,
}) {
/*  double width = isMe ? 60 : 40;
  double pin = 15.0;
  double edited = 35;
  double translate = 20;

  if (isPin) {
    width += pin;
  }
  if (isEdited) {
    width += edited;
  }
  if (isTranslate != null && isTranslate) {
    width += translate;
  }

  return width;*/
  return getNewLineExtraWidth(
    showPinned: isPin,
    isEdit: isEdited,
    isSender: !isMe,
  );
}

bool isWalletEnable() {
  if (Config().enableWallet ||
      objectMgr.localStorageMgr.read('show_wallet') == 1) {
    return true;
  }

  return false;
}

Color getFontThemeColorByIdAndNickname(int userId, String nickName) {
  List<Color> avatarThemes = [
    const Color(0xffBD584E),
    const Color(0xffC97C38),
    const Color(0xffC97C38),
    const Color(0xff4AA42E),
    const Color(0xff8D5FD4),
    const Color(0xff4D87CB),
    const Color(0xff529BB7),
    const Color(0xffB95889),
  ];

  String generateMD5(String data) {
    Uint8List content = const Utf8Encoder().convert(data);
    Digest digest = md5.convert(content);
    return digest.toString();
  }

  int colorThemeFromNickName(String nickName) {
    String md5 = generateMD5(nickName);
    int index = md5.codeUnitAt(0) % 7;
    return index;
  }

  int themeIndex = colorThemeFromNickName(nickName);
  themeIndex = userId % 8;
  Color color = avatarThemes[themeIndex];
  return color;
}

/// 获取 app locale 规范的 language code, example:["en","zh","ja"]
String getAppLanguageCode(String code) {
  String languageCode = "";

  switch (code) {
    case "en_uk":
      languageCode = LanguageCodes.fromCode('en').code;
      break;
    case "jp":
    case "ja":
      languageCode = LanguageCodes.fromCode('ja').code;
      break;
    case "cn_s":
    case "cn_t":
      languageCode = LanguageCodes.fromCode('zh').code;
      break;
    default:
      languageCode = LanguageCodes.fromCode(code).code;
      break;
  }
  return languageCode;
}

/// 获取 server locale 规范的 language code, example:["en_uk","cn_s","ja"]
String getServerLanguageCode(String code) {
  String languageCode = "";

  switch (code) {
    case "en":
      languageCode = "en_uk";
      break;
    case "zh":
      languageCode = "cn_s";
      break;
    default:
      languageCode = code;
      break;
  }
  return languageCode;
}

/// 获取 app locale 规范的 language code, example:[Locale("en","US")]
Locale getAppLocale(String code) {
  Locale? locale;

  switch (code) {
    case "en":
    case "en_uk":
      locale = LanguageCodes.fromCode('en').locale;
      break;
    case "zh":
    case "cn_s":
      locale = LanguageCodes.fromCode('zh').locale;
      break;
    default:
      locale = LanguageCodes.fromCode(code).locale;
      break;
  }

  return locale;
}

String? getAutoDeleteTrailingText(
  bool autoDeleteIntervalEnable,
  int? interval,
) {
  if (autoDeleteIntervalEnable) {
    if (interval != null && interval > 0) {
      if (interval == AutoDeleteDurationOption.tenSecond.duration) {
        return " 10s";
      } else if (interval == AutoDeleteDurationOption.thirtySecond.duration) {
        return ' 30s';
      } else if (interval == AutoDeleteDurationOption.oneMinute.duration) {
        return ' 1min';
      } else if (interval == AutoDeleteDurationOption.fiveMinute.duration) {
        return ' 5min';
      } else if (interval == AutoDeleteDurationOption.tenMinute.duration) {
        return ' 10min';
      } else if (interval == AutoDeleteDurationOption.fifteenMinute.duration) {
        return ' 15min';
      } else if (interval == AutoDeleteDurationOption.thirtyMinute.duration) {
        return ' 30min';
      } else if (interval == AutoDeleteDurationOption.oneHour.duration) {
        return ' 1h';
      } else if (interval == AutoDeleteDurationOption.twoHour.duration) {
        return ' 2h';
      } else if (interval == AutoDeleteDurationOption.sixHour.duration) {
        return ' 6h';
      } else if (interval == AutoDeleteDurationOption.twelveHour.duration) {
        return ' 12h';
      } else if (interval == AutoDeleteDurationOption.oneMonth.duration) {
        return localized(timeOneMonth);
      } else if (interval == AutoDeleteDurationOption.oneDay.duration) {
        return localized(timeOneDay);
      } else if (interval == AutoDeleteDurationOption.oneWeek.duration) {
        return localized(timeOneWeek);
      } else if (interval == AutoDeleteDurationOption.oneMonth.duration) {
        return localized(timeOneMonth);
      }
    }
  }
  return null;
}

vibrate({int? duration}) async {
  if (Platform.isIOS) {
    const generalChannel = 'jxim/general';
    const methodChannel = MethodChannel(generalChannel);
    await methodChannel.invokeMethod('allowVibrateWhileRecording');
  }
  // bool b = await Vibration.hasVibrator() ?? false;
  // if (b) {
  //   await Vibration.vibrate(duration: duration??50);
  // } else {
  await HapticFeedback.mediumImpact();
  // }
}

String getFileIconBg(String filePath) {
  final fileExtension = file_util.getFileExtension(filePath);
  const assetPath = 'assets/icons/file/';
  return switch (fileExtension) {
    // blue bg
    'm3u8' => '${assetPath}blue-file.png',
    'html' => '${assetPath}blue-file.png',
    'xmind' => '${assetPath}blue-file.png',
    'json' => '${assetPath}blue-file.png',
    'psd' => '${assetPath}blue-file.png',
    'mp3' => '${assetPath}blue-file.png',
    'mp4' => '${assetPath}blue-file.png',
    'sh' => '${assetPath}blue-file.png',
    'ttf' => '${assetPath}blue-file.png',
    'txt' => '${assetPath}blue-file.png',
    'aep' => '${assetPath}blue-file.png',
    'fig' => '${assetPath}blue-file.png',
    'png' => '${assetPath}blue-file.png',
    'eps' => '${assetPath}blue-file.png',
    'wpg' => '${assetPath}blue-file.png',
    'mov' => '${assetPath}blue-file.png',
    'rar' => '${assetPath}blue-file.png',
    'csv' => '${assetPath}blue-file.png',
    'avi' => '${assetPath}blue-file.png',
    'doc' => '${assetPath}blue-file.png',
    'docx' => '${assetPath}blue-file.png',
    'dmg' => '${assetPath}blue-file.png',
    'jpg' => '${assetPath}blue-file.png',
    'jpeg' => '${assetPath}blue-file.png',
    'apk' => '${assetPath}blue-file.png',
    'ipa' => '${assetPath}blue-file.png',
    'svg' => '${assetPath}blue-file.png',
    'cur' => '${assetPath}green-file.png',
    'css' => '${assetPath}green-file.png',
    'xls' => '${assetPath}green-file.png',
    'xlsx' => '${assetPath}green-file.png',
    'dxf' => '${assetPath}green-file.png',
    'csl' => '${assetPath}green-file.png',
    // yellow bg
    'ai' => '${assetPath}yellow-file.png',
    'fmv' => '${assetPath}yellow-file.png',
    'wav' => '${assetPath}yellow-file.png',
    'zip' => '${assetPath}yellow-file.png',
    // red bg
    'pdf' => '${assetPath}red-file.png',
    'ppt' => '${assetPath}red-file.png',
    'pptx' => '${assetPath}red-file.png',
    // default
    _ => '${assetPath}blue-file.png',
  };
}

class CustomInputFormatter extends TextInputFormatter {
  final int maxLength = 30; // Adjust this as needed

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= maxLength) {
      return newValue;
    } else {
      var text = String.fromCharCodes(newValue.text.runes.take(maxLength));
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: min(text.length, newValue.selection.end),
        ),
      );
    }
  }
}

class PlusSignInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.text.startsWith('+')) {
      return TextEditingValue(text: '+${newValue.text}');
    }

    return newValue;
  }
}

void sortUsers(List<User> users) {
  users.sort((a, b) {
    String aFirstLetter = getFirstLetter(a.nickname.trim());
    String bFirstLetter = getFirstLetter(b.nickname.trim());

    bool aIsChinese = isChinese(a.nickname.trim());
    bool bIsChinese = isChinese(b.nickname.trim());

    if (!aIsChinese && !bIsChinese) {
      return aFirstLetter.compareTo(bFirstLetter);
    } else if (aIsChinese && bIsChinese) {
      return aFirstLetter.compareTo(bFirstLetter);
    } else if (!aIsChinese && bIsChinese) {
      return -1;
    } else {
      return 1;
    }
  });
}

bool isChinese(String text) {
  if (text.isEmpty) {
    return false;
  }

  int firstCharCode = text.codeUnitAt(0);
  return (firstCharCode >= 0x4e00 && firstCharCode <= 0x9fff);
}

String getFirstLetter(String text) {
  if (text.isEmpty) {
    return '';
  }

  if (isChinese(text)) {
    return getChineseFirstLetter(text);
  } else {
    return text[0].toUpperCase();
  }
}

String getChineseFirstLetter(String text) {
  String pinyin = PinyinHelper.getShortPinyin(text);

  if (pinyin.isNotEmpty) {
    return pinyin[0].toUpperCase();
  }

  return '';
}

String convertSpecialText(String messageText, Message message) {
  // 解析@
  RegExp exp = RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
  RegExpMatch? match = exp.firstMatch(messageText);
  if (match == null) return messageText;

  /// 取ID
  String? uidStr = Regular.extractDigit(match.input)?.group(0);
  if (uidStr == null) return messageText;

  int id = int.parse(uidStr);
  MentionModel? mention =
      message.atUser.firstWhereOrNull((e) => e.userId == id);

  String name = '';
  if (id == 0 || mention != null && mention.role == Role.all) {
    name = localized(mentionAll);
  } else {
    User? u = objectMgr.userMgr.getUserById(id);
    name = objectMgr.userMgr.getUserTitle(u);
  }

  if (name.isEmpty) {
    if (mention == null) {
      name = uidStr.toString();
    } else {
      name = mention.userName;
    }
  }

  String str = messageText.replaceRange(match.start, match.end, "@$name");
  return convertSpecialText(str, message);
}

// 计算文本宽
enum GroupTextMessageReadType { inlineType, beakLineType, none }

GroupTextMessageReadType caculateLastLineTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth, // 已读或发消息日子
  required Message message,
}) {
  if (messageText.isEmpty || maxWidth < 1 || extraWidth < 1) {
    return GroupTextMessageReadType.none;
  }

  messageText = newConvertSpecialText(messageText, message); // 处理@

  // 创建TextPainter对象
  TextStyle textStyle = jxTextStyle.normalBubbleText(bubblePrimary);
  TextPainter textPainter = TextPainter(
    text: TextSpan(text: messageText, style: textStyle),
    maxLines: null, // 限制文本显示在一行
    textDirection: TextDirection.ltr,
  );

  // 进行布局，并获取文本宽度
  textPainter.layout(maxWidth: maxWidth);
  int numberOfLines = textPainter.computeLineMetrics().length;
  if (numberOfLines != 0) {}

  if (numberOfLines < 2) {
  } else {
    textPainter = TextPainter(
      text: TextSpan(text: messageText, style: textStyle),
      maxLines: numberOfLines - 1, // 限制文本显示在一行
      textDirection: TextDirection.ltr,
    );

    // 进行布局，并获取文本宽度
    textPainter.layout(maxWidth: maxWidth);

    // 获取文本的最后一个字符在文本中的索引
    int lastCharacterIndex = textPainter
        .getPositionForOffset(Offset(textPainter.width, textPainter.height))
        .offset;

    // 获取文本的最后一行文本
    String lastLineText = messageText.substring(lastCharacterIndex);

    textPainter = TextPainter(
      text: TextSpan(text: lastLineText, style: textStyle),
      maxLines: 1, // 限制文本显示在一行
      textDirection: TextDirection.ltr,
    );

    // 进行布局，并获取文本宽度
    textPainter.layout(maxWidth: maxWidth);
  }

  return GroupTextMessageReadType.inlineType;

  // if (isSingleLine) {
  //   if (maxWidth - (extraWidth + lastLineTextWidth) > 0)
  //     return GroupTextMessageReadType.inlineType;

  //   return GroupTextMessageReadType.beakLineType;
  // } else {
  //   if (maxWidth - (extraWidth + lastLineTextWidth) > 0 &&
  //       maxWidth - (extraWidth + firstLineWidth) > 0)
  //     return GroupTextMessageReadType.inlineType;

  //   if (maxWidth - (extraWidth + lastLineTextWidth) > 0)
  //     return GroupTextMessageReadType.none;

  //   return GroupTextMessageReadType.beakLineType;
  // }
}

Future<void> openFileDocument(String url, String fileName) async {
  bool success = await Permissions.request([Permission.photos]);
  if (!success) return;

  downloadMgrV2
      .download(url, timeout: const Duration(seconds: 3000))
      .then((result) async {
    final path = result.localPath;
    if (path == null) {
      Toast.showToast('Downloading or File is Not exist');
      return;
    }
    File? document = File(path);

    final fileWithFileName =
        File("${downloadMgr.appDocumentRootPath}/$fileName");

    try {
      if (!fileWithFileName.existsSync()) {
        fileWithFileName.createSync(recursive: true);
        fileWithFileName.writeAsBytesSync(document.readAsBytesSync());
        document.deleteSync();
      }
      document = fileWithFileName;
    } catch (e, s) {
      pdebug('Error: $e', stackTrace: s);
    }

    if (document?.existsSync() ?? false) {
      final result = await OpenFilex.open(document!.path);
      if (result.type == ResultType.noAppToOpen) {
        Toast.showToast(result.message);
      } else if (result.type == ResultType.fileNotFound) {
        Toast.showToast(result.message);
      } else if (result.type != ResultType.done) {
        Toast.showToast(result.message);
      }
    } else {
      Toast.showToast('Downloading or File is Not exist');
    }
  });

  // downloadMgr
  //     .downloadFile(url, timeout: const Duration(seconds: 3000))
  //     .then((String? path) async {
  //   if (path == null) {
  //     Toast.showToast('Downloading or File is Not exist');
  //     return;
  //   }
  //   File? document = File(path);
  //
  //   final fileWithFileName =
  //       File("${downloadMgr.appDocumentRootPath}/$fileName");
  //
  //   try {
  //     if (!fileWithFileName.existsSync()) {
  //       fileWithFileName.createSync(recursive: true);
  //       fileWithFileName.writeAsBytesSync(document.readAsBytesSync());
  //       document.deleteSync();
  //     }
  //     document = fileWithFileName;
  //   } catch (e) {
  //     pdebug('Error: $e', toast: false);
  //   }
  //
  //   if (document?.existsSync() ?? false) {
  //     final result = await OpenFilex.open(document!.path);
  //     if (result.type == ResultType.noAppToOpen) {
  //       Toast.showToast(result.message);
  //     } else if (result.type == ResultType.fileNotFound) {
  //       Toast.showToast(result.message);
  //     } else if (result.type != ResultType.done) {
  //       Toast.showToast(result.message);
  //     }
  //   } else {
  //     Toast.showToast('Downloading or File is Not exist');
  //   }
  // });
}

int getTextMessageBubbleLines(
  String messageText,
  double maxWidth,
  double extraWidth,
  Message message,
) {
  if (messageText.isEmpty || maxWidth < 1 || extraWidth < 1) return 0;

  messageText = convertSpecialText(messageText, message); // 处理@

  // 创建TextPainter对象
  TextStyle textStyle = jxTextStyle.normalBubbleText(bubblePrimary);
  TextPainter textPainter = TextPainter(
    text: TextSpan(text: messageText, style: textStyle),
    maxLines: null, // 限制文本显示在一行
    textDirection: TextDirection.ltr,
  );

  // 进行布局，并获取文本宽度
  textPainter.layout(maxWidth: maxWidth);
  int numberOfLines = textPainter.computeLineMetrics().length;
  return numberOfLines;
}

// 带超时机制的while
FutureOr<dynamic> whilet(
  bool Function() condition,
  Future<dynamic> Function() function, {
  Duration duration = const Duration(seconds: 10),
}) async {
  bool timeout = false;
  final Future<bool> future = Future.delayed(duration, () {
    timeout = true;
    return true;
  });
  while (condition()) {
    try {
      bool b = await Future.any([
        future,
        Future(() async {
          return (await function()) ?? false;
        }),
      ]);
      if (timeout) {
        break;
      }
      if (b) {
        break;
      }
    } catch (e) {
      rethrow;
    }
  }
}

// 是否是本地地址
bool isLocalhost(String host) {
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

String getSpecialChatName(int? chatType) {
  switch (chatType) {
    case chatTypeSmallSecretary:
      return localized(chatSecretary);
    case chatTypeSystem:
      return localized(chatSystem);
    case chatTypeSaved:
      return localized(homeSavedMessage);
    default:
      return '';
  }
}

List<InlineSpan> getHighlightSpanList(
  String text,
  String? regexText,
  TextStyle textStyle, {
  needCut = false,
}) {
  List<InlineSpan> spanList = List.empty(growable: true);
  text = text.replaceAll('\n', ' ');
  if (regexText != '') {
    try {
      RegExp regex = RegExp(regexText!, caseSensitive: false);

      /// special case when search "."
      if (regexText == ".") {
        regex = RegExp(r'\.');
      }

      Iterable<Match> matches = regex.allMatches(text);

      /// 最终文本
      List<RegexTextModel> spanMapsList = [];

      /// 开始和结尾的文本
      List<RegexTextModel> firstLastSpanMapsList = [];

      /// 普通文本
      List<RegexTextModel> textSpanMapsList = [];

      ///--------------------------处理特别文本----------------------------///

      /// 检查搜索文本

      if (matches.isNotEmpty) {
        for (var match in matches) {
          String originalMatchText = text.substring(match.start, match.end);
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.search.value,
            text: originalMatchText,
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }

        spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

        ///-------------------------- 处理开头和结尾文本----------------------------///
        /// 如果开头字不是特别文本，补上开头的文本
        if (spanMapsList.first.start > 0) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.text.value,
            text: text.substring(0, spanMapsList.first.start),
            start: 0,
            end: spanMapsList.first.start,
          );
          firstLastSpanMapsList.add(spanMap);
        }

        /// 如果结尾字不是特别文本，补上结尾的文本
        if (spanMapsList.last.end < text.length) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.text.value,
            text: text.substring(spanMapsList.last.end, text.length),
            start: spanMapsList.last.end,
            end: text.length,
          );
          firstLastSpanMapsList.add(spanMap);
        }
        spanMapsList.addAll(firstLastSpanMapsList);

        /// 排序开头结尾文本
        spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

        ///-------------------------- 处理最终文本 ----------------------------///
        for (int i = 0; i < spanMapsList.length; i++) {
          if (i != spanMapsList.length - 1) {
            int firstEnd = spanMapsList[i].end;
            int secondStart = spanMapsList[i + 1].start;

            /// 如果中间字不是特别文本，补上中间的文本
            if (secondStart != firstEnd) {
              RegexTextModel spanMap = RegexTextModel(
                type: RegexTextType.text.value,
                text: text.substring(firstEnd, secondStart),
                start: firstEnd,
                end: secondStart,
              );
              textSpanMapsList.add(spanMap);
            }
          }
        }
        spanMapsList.addAll(textSpanMapsList);

        /// 排序最终文本
        spanMapsList.sort((a, b) => (a.start).compareTo(b.start));
      }

      ///-------------------------- 处理字体样本 ----------------------------///
      if (spanMapsList.isNotEmpty) {
        if (needCut) {
          List<RegexTextModel> newList = [];
          int highlightIndex = spanMapsList.indexWhere(
              (element) => element.type == RegexTextType.search.value);

          if (highlightIndex != -1) {
            int previousIndex = highlightIndex > 0 ? highlightIndex - 1 : 0;
            int nextIndex = highlightIndex < spanMapsList.length - 1
                ? highlightIndex + 1
                : spanMapsList.length - 1;

            /// content组合 [4种]:
            /// 1. content == searchText
            /// 2. searchText + content
            /// 3. ...content + searchText
            /// 4. ...content + searchText + content...

            if (highlightIndex == previousIndex) {
              /// type:1
              newList.add(spanMapsList[highlightIndex]);
              if (highlightIndex != nextIndex &&
                  spanMapsList[nextIndex] != null) {
                /// type:2
                newList.addAll(
                  spanMapsList.sublist(nextIndex, spanMapsList.length),
                );
              }
            } else if (highlightIndex == nextIndex) {
              /// type:3
              if (spanMapsList[previousIndex] != null) {
                RegexTextModel span = spanMapsList[previousIndex];
                String text = span.text;
                if (text.length > 10) {
                  text = '...' +
                      text.substring(spanMapsList[highlightIndex].start - 10,
                          spanMapsList[highlightIndex].start);
                }
                newList.add(
                  RegexTextModel(
                    type: span.type,
                    text: text,
                    start: span.start,
                    end: span.end,
                  ),
                );
                newList.add(spanMapsList[highlightIndex]);
              }
            } else {
              /// type:4
              if (spanMapsList[previousIndex] != null) {
                RegexTextModel span = spanMapsList[previousIndex];
                String text = span.text;
                if (text.length > 6) {
                  text = '...' +
                      text.substring(spanMapsList[highlightIndex].start - 6,
                          spanMapsList[highlightIndex].start);
                }
                newList.add(
                  RegexTextModel(
                    type: span.type,
                    text: text,
                    start: span.start,
                    end: span.end,
                  ),
                );
              }
              newList.add(spanMapsList[highlightIndex]);

              if (spanMapsList[nextIndex] != null) {
                newList.addAll(
                  spanMapsList.sublist(nextIndex, spanMapsList.length),
                );
              }
            }
            spanMapsList = newList;
          }
        }

        for (int i = 0; i < spanMapsList.length; i++) {
          String subText = spanMapsList[i].text;
          if (spanMapsList[i].type == RegexTextType.search.value) {
            spanList.add(
              TextSpan(
                text: subText,
                style: textStyle.copyWith(color: themeColor),
              ),
            );
          } else {
            /// 普通文本
            spanList.add(
              TextSpan(
                text: subText,
                style: textStyle,
              ),
            );
          }
        }
      } else {
        spanList.add(
          TextSpan(
            text: text,
            style: textStyle,
          ),
        );
      }
    } catch (e) {
      spanList.add(
        TextSpan(
          text: text,
          style: textStyle,
        ),
      );
    }
  } else {
    spanList.add(
      TextSpan(
        text: text,
        style: textStyle,
      ),
    );
  }
  return spanList;
}

bool get isMirrorFrontCamera {
  return objectMgr.localStorageMgr
          .globalRead<bool>(LocalStorageMgr.MIRROR_FRONT_CAMERA) ??
      true;
}

/// 微微震动
void littleVibrate() async {
  if (Platform.isIOS) {
    HapticFeedback.lightImpact();
  } else {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40);
    }
  }
}

Future<bool> saveFileToGallery(String path,
    {bool isReturnPathOfIOS = false}) async {
  // 检查一下权限
  bool ps = await Permissions.request([Permission.photos]);
  if (!ps) return false;

  final result = await ImageGallerySaver.saveFile(path,
      isReturnPathOfIOS: isReturnPathOfIOS);

  bool isSuccess = result != null && result["isSuccess"];

  final fileType = file_util.getFileType(path);
  String toastMessage = '';
  switch (fileType) {
    case file_util.FileType.video:
      toastMessage = localized(theVideoHasBeenSavedToTheAlbum);
      break;
    case file_util.FileType.image:
      toastMessage = localized(thePictureHasBeenSavedToTheAlbum);
      break;
    default:
      toastMessage = localized(toastSaveSuccess);
      break;
  }

  String title = isSuccess ? toastMessage : localized(toastSaveUnsuccessful);

  imBottomToast(
    Get.context!,
    title: title,
    icon: ImBottomNotifType.saving,
    duration: 1,
  );

  return isSuccess;
}

Future<String?> saveImageWidgetToGallery({
  required Widget imageWidget,
  String? cachePath,
  String? subDir,
  String? imgName,
  String? downloadLink,
  Function? beforeSaveCallBack,
  Function? afterSaveCallBack,
  int imgQuality = 100,
  bool isShare = false,
}) async {
  // 检查Photo权限
  if (!isShare) {
    bool ps = await Permissions.request([Permission.photos]);
    if (!ps) return null;
  }

  Uint8List bytes = await ScreenshotController()
      .captureFromWidget(Material(child: imageWidget));

  // 保存到本地
  String tmpCachePath = "";
  if (cachePath != null && cachePath.isNotEmpty) {
    tmpCachePath =
        await downloadMgr.getTmpCachePath(cachePath, sub: subDir, create: true);
    File file = File(tmpCachePath);
    await file.writeAsBytes(bytes);
  }

  // 分享
  if (isShare) {
    if (tmpCachePath.isEmpty) return null;
    String? str;
    if (downloadLink != null && downloadLink.isNotEmpty) {
      var params = [Config().appName, downloadLink];
      str = localized(invitationWithLink, params: params);
    }
    await Share.shareXFiles([XFile(tmpCachePath)], text: str);
    return tmpCachePath;
  }

  // 弹窗【保存中】
  beforeSaveCallBack?.call();

  // 保存到相册
  if (!isImage(imgName)) imgName = null;
  String name = imgName ?? 'image_${DateTime.now().microsecondsSinceEpoch}.png';
  ImageGallerySaver.saveImage(bytes, quality: imgQuality, name: name);

  // 弹窗【保存成功】
  afterSaveCallBack?.call() ??
      imBottomToast(navigatorKey.currentContext!,
          title: localized(imageSaved), icon: ImBottomNotifType.qrSaved);

  return tmpCachePath;
}

// 图片类型
bool isImage(String? filePath) {
  if (filePath == null || filePath.isEmpty) return false;
  return filePath.toLowerCase().endsWith('.jpg') ||
      filePath.toLowerCase().endsWith('.jpeg') ||
      filePath.toLowerCase().endsWith('.png') ||
      filePath.toLowerCase().endsWith('.gif') ||
      filePath.toLowerCase().endsWith('.bmp') ||
      filePath.toLowerCase().endsWith('.webp');
}

Future<PermissionState> requestAssetPickerPermission(
    {bool showToast = true}) async {
  /* Apps that run on Android 11 but target Android 10 (API level 29)
       can still request the requestLegacyExternalStorage attribute.
      ...After you update your app to target Android 11,
       the system ignores the requestLegacyExternalStorage flag. */
  if (Platform.isAndroid &&
      await objectMgr.callMgr.getAndroidTargetVersionApi() >= 33) {
    var p = await PhotoManager.requestPermissionExtend();
    if (p == PermissionState.denied) {
      if (showToast) {
        var name = Permissions().getPermissionsName([Permission.photos]);
        openSettingPopup(name);
      } else {
        openAppSettings();
      }
    }
    return p;
  } else {
    var p = Permission.photos;
    bool isSuccess = await Permissions.request([p], isShowToast: showToast);
    if (!isSuccess) return PermissionState.denied;
    return await p.isLimited
        ? PermissionState.limited
        : PermissionState.authorized;
  }
}

Future<MessageImage> adjustGifDimensionByMessageImage(MessageImage gif) async {
  final fileName = gif.url;
  String? filePath = downloadMgrV2.getLocalPath(fileName);
  if (filePath != null) {
    final Map<String, dynamic> size = await getImageFromAsset(File(filePath));
    gif.width = size['width'] ?? 300;
    gif.height = size['height'] ?? 338;
  }
  return gif;
}

Future<Gifs> adjustGifDimensionByGif(Gifs gif) async {
  final fileName = gif.name;
  String? filePath = downloadMgrV2.getLocalPath(fileName);
  if (filePath != null) {
    final Map<String, dynamic> size = await getImageFromAsset(File(filePath));
    gif = gif.copyWith(
      width: size['width'] ?? 300,
      height: size['height'] ?? 338,
    );
  }
  return gif;
}

Map<String, dynamic> deepCopy(Map<String, dynamic> original) {
  return original.map((key, value) {
    if (value is Map<String, dynamic>) {
      // 如果是 Map，遞迴深複製
      return MapEntry(key, deepCopy(value));
    } else if (value is List) {
      // 如果是 List，對每個元素進行處理
      return MapEntry(
        key,
        value.map((item) {
          if (item is Map<String, dynamic>) {
            return deepCopy(item);
          }
          return item;
        }).toList(),
      );
    } else {
      // 對於其他類型，直接複製
      return MapEntry(key, value);
    }
  });
}

Map<String, String> getChatNameMap(Message message) {
  Map<String, String> map = {};

  Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
  User? user = objectMgr.userMgr.getUserById(message.send_id);

  if (chat != null) {
    if (chat.isGroup) {
      if (objectMgr.userMgr.isMe(message.send_id)) {
        map['first'] = localized(chatInfoYou);
        map['second'] = chat.name;
      } else {
        if (user != null) {
          map['first'] = objectMgr.userMgr.getUserTitle(user);
        } else {
          Future<User?> newUser = objectMgr.userMgr.loadUserById(
            message.send_id,
            remote: true,
            notify: false,
          );
          newUser.then(
            (value) => map['first'] = objectMgr.userMgr.getUserTitle(value),
          );
        }
        map['second'] = chat.name;
      }
    } else {
      if (objectMgr.userMgr.isMe(message.send_id)) {
        map['first'] = localized(chatInfoYou);
        map['second'] = chat.name;
      } else {
        map['first'] = chat.name;
        map['second'] = localized(chatInfoYou);
      }
    }
  }
  return map;
}
