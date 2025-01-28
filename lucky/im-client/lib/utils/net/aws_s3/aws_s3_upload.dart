library aws_s3_upload;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/net/upload_link_info.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/aws_s3/file_uploader.dart';

import '../request.dart';

class AwsS3 {
  static final AwsS3 _instance = AwsS3._internal();

  factory AwsS3() {
    return _instance;
  }

  AwsS3._internal() {}

  Future<String?> uploadFile(
    String uploadKey,
    UploadLinkInfo urlInfo,
    File file, {
    bool enableCipher = false,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final fileStream = file.openRead();

    int totalBytes = file.lengthSync();

    final httpClient = getHttpClient();

    final String url = urlInfo.url;
    final Uri uploadUri;

    // 上传固定KIWI域名替换
    if (serversUriMgr.uploadUri != null) {
      uploadUri = Uri.parse(url).replace(
        scheme: serversUriMgr.uploadUri!.scheme,
        host: serversUriMgr.uploadUri!.host,
        port: serversUriMgr.uploadUri!.port,
      );
    } else {
      uploadUri = Uri.parse(url);
    }

    final request = await httpClient.putUrl(uploadUri);

    request.headers.add('Content-Type', 'application/octet-stream');

    request.contentLength = totalBytes;

    int sentBytes = 0;

    UploadFile? fileInfo = FileUploader.shared.uploadFileMap[uploadKey];
    Stream<List<int>> streamUpload = fileStream.transform(
      new StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sentBytes += data.length;
          fileInfo?.sentBytes += data.length;
          if (onProgress != null) {
            pdebug("【上传文件】上传进度: ${(sentBytes / totalBytes)} %");
            onProgress(sentBytes, totalBytes);
          }

          if (FileUploader.shared.uploadIsCancel(
            fileInfo!.originalFileName ?? '',
            fileInfo.sendTime,
          )) {
            pdebug("【上传文件】上传取消");
            sink.close();
            request.close();
            httpClient.close(force: true);
            return;
          }

          sink.add(data);
        },
        handleError: (error, stack, sink) {
          pdebug("【上传文件】上传错误 : ${error.toString()}");
        },
        handleDone: (sink) {
          sink.close();
        },
      ),
    );

    await request.addStream(streamUpload);

    final httpResponse = await request.close();

    if (httpResponse.statusCode != 200) {
      return null;
    } else {
      return urlInfo.path;
    }
  }
}

class JXHttpRequest extends http.Request {
  JXHttpRequest(
    String method,
    Uri url, {
    this.onProgress,
    this.uploadKey = '',
  }) : super(method, url);

  final String uploadKey;
  final Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = contentLength;
    var bytes = 0;

    UploadFile? fileInfo = FileUploader.shared.uploadFileMap[uploadKey];
    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        fileInfo?.sentBytes += data.length;
        onProgress?.call(bytes, total);
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}
