import 'dart:convert' as convert;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/dio/dio_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TestPageController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    //
    // debugInfo.printErrorStack('错误的信息', '错误的堆栈');
    pdebug([
      ...[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    ]);
    // test();

    // String url = './image/a.pngs';
    // pdebug(
    //     "TestPageController isAbsolute: ${path.isAbsolute(url)} | isRelative: ${path.isRelative(url)} | isRootRelative: ${path.isRootRelative(url)}");
    // pdebug(
    //     'TestPageController ${Uri.parse(url)} | scheme: ${Uri.parse(url).scheme} | host: ${Uri.parse(url).host} | port: ${Uri.parse(url).port} ');
    // List<int> input = convert.utf8.encode("Hello, World!"); // Example input

    // // Encode
    // Uint8List encodedBytes = xorEncode(Uint8List.fromList(input));
    // pdebug("Encoded: ${convert.base64.encode(encodedBytes)}");

    // // Decode
    // Uint8List decoded = xorDecode(Uint8List.fromList(encodedBytes));
    // pdebug("Decoded: ${convert.utf8.decode(decoded)}");

    // downloadText();
    // downloadMgr.downloadFile('https://jtalk.s3.ap-southeast-1.amazonaws.com/enc/Video/f0/d3/f0d319268ae34745425a7c9514eaad56/thumbnail.jpeg?is_encrypt=1');

    // for (var i = 0; i < 10; i++) {
    //   queueUploadTaskMgr.addTask(QueueTask(
    //     timeout: const Duration(minutes: 30),
    //     id: "$i",
    //     task: (cancelToken, _) async {
    //       await Future.delayed(const Duration(seconds: 1));
    //       return TaskResult(success: true);
    //     },
    //     cancelToken: null,
    //     onComplete: onTaskComplete,
    //     onStart: onTaskStart,
    //   ));
    // }
  }

  void onTaskComplete(QueueUploadTaskEnum status, String str) {
    pdebug("QUEUE upload Task completed ID:$str status: $status");
  }

  // 创建一个任务开始回调函数
  void onTaskStart(String str) {
    pdebug("QUEUE upload Task started ID:$str");
  }

  Future<void> test() async {
    final file = File("${downloadMgr.appDocumentRootPath}/test/test.mp4");
    const partSize = 100 * 1024 * 1024; // 100MB per chunk

    try {
      final fileLength = await file.length();
      final List<Future<Uint8List>> partMd5s = List<Future<Uint8List>>.generate(
        (fileLength / partSize).ceil(),
        (index) async {
          final start = index * partSize;
          final end = start + partSize;
          final partData = await file.openRead(start, end).toList();
          final combinedData = partData.expand((element) => element).toList();
          return compute<Uint8List, Uint8List>(
              calculateMd5, Uint8List.fromList(combinedData));
        },
      );

      final md5Results = await Future.wait(partMd5s);

      for (int i = 0; i < md5Results.length; i++) {
        final base64Md5 = convert.base64Encode(md5Results[i]);
        // 这个是分片base64 checksums[]
        pdebug('TestPageController Part ${i + 1} MD5 hash: $base64Md5');
      }

      // Compute multipart ETag
      final md5HashConcat = BytesBuilder();
      for (final hash in md5Results) {
        md5HashConcat.add(hash);
      }
      final finalMd5 = calculateMD5(md5HashConcat.toBytes());
      // 这个是源文件id md5
      pdebug('TestPageController Multipart ETag: $finalMd5-${partMd5s.length}');

      // final fileMd5 = calculateMD5(file.readAsBytesSync());
      // pdebug('TestPageController Multipart fileMd5: $fileMd5');
    } catch (e) {
      pdebug('TestPageController Failed to process file: $e');
    }
  }

  Uint8List calculateMd5(Uint8List data) {
    final md5Hash = md5.convert(data);
    return Uint8List.fromList(md5Hash.bytes);
  }

  void downloadText() async {
    String url =
        'Image/23/78/2378e38118c2b187c6a4fc8088ae81ad/2378e38118c2b187c6a4fc8088ae81ad.jpeg?image_size=512&encrypt=1';
    var res = await DioUtil.instance.downloadUriFile(
        Uri.parse("${serversUriMgr.download2Uri}/$url"),
        '${downloadMgr.appDocumentRootPath}/test/$url',
        cancelToken: CancelToken());

    pdebug(res);
  }

  void runShell() {
    // 指定要运行的Shell脚本命令
    String shellScript = 'your_shell_script.sh';

    // 使用Process类执行Shell命令
    Process.start(shellScript, []).then((Process process) {
      // 处理Shell命令的标准输出
      process.stdout.transform(convert.utf8.decoder).listen((data) {
        pdebug('stdout: $data');
      });

      // 处理Shell命令的标准错误输出
      process.stderr.transform(convert.utf8.decoder).listen((data) {
        pdebug('stderr: $data');
      });

      // 处理Shell命令的退出状态
      process.exitCode.then((int code) {
        pdebug('Exit code: $code');
      });
    });
  }
}
