import 'package:jxim_client/object/video.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<bool> checkM3u8(String hash, {String type = "Video"}) async {
  final Map<String, dynamic> dataBody = {
    "file_id": hash,
    "file_typ": type,
    'file_ext': "mp4",
    'is_encrypt': false,
    'is_original': false,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/file/check_file',
      data: dataBody,
    );

    if (res.success()) {
      if (res.data['target_files'] == null) {
        return false;
      }

      VideoData d = VideoData.fromJson(res.data['target_files']);
      return d.hls?.first.isEnd ?? false;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}
