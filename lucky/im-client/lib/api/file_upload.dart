import 'dart:async';

import 'package:jxim_client/object/net/upload_link_info.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<List<UploadLinkInfo>> checkFileExist(String fileHash) async {
  Map<String, dynamic> data = {};
  data['Key'] = [fileHash];

  try {
    final ResponseData res = await Request.doPost(
      '/app/api/file/exist',
      data: data,
    );
    if (res.success()) {
      pdebug("【上传文件】检测文件");
      final List<Map<String, dynamic>> urlInfoListData =
          res.data['urls'].cast<Map<String, dynamic>>();

      return urlInfoListData.map((e) => UploadLinkInfo.fromJson(e)).toList();
    } else {
      throw AppException(res.code, res.message);
    }
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}

Future<List<UploadLinkInfo>> requestUploadLink(
    List<Map<String, dynamic>> params) async {
  Map<String, dynamic> data = {};
  data['files'] = params;

  try {
    final ResponseData res = await Request.doPost(
      '/app/api/file/generate_url/v2',
      data: data,
    );
    if (res.success()) {
      pdebug("【上传文件】请求成功");
      final List<Map<String, dynamic>> urlInfoListData =
          res.data['urls'].cast<Map<String, dynamic>>();

      return urlInfoListData.map((e) => UploadLinkInfo.fromJson(e)).toList();
    } else {
      throw AppException(res.code, res.message);
    }
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}

Future<String> updateUploadStatus(Map<String, dynamic> data) async {
  try {
    final ResponseData res = await Request.doPost(
      '/app/api/file/update_status',
      data: data,
    );
    if (res.success()) {
      pdebug("【上传文件】更新状态成功");
      return res.data['result'];
    } else {
      throw AppException(res.code, res.message);
    }
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}
