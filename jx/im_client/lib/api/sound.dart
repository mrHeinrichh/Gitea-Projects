import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<List<SoundData>> getSoundList() async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      '/im/sound/get_list',
    );
    if (res.success()) {
      return res.data['sounds']
          .map<SoundData>((e) => SoundData.fromJson(e))
          .toList();
    } else {
      throw AppException(res.message);
    }
  } on AppException {
    //Toast.showToast(e.getMessage());
    rethrow;
  } catch (e) {
    rethrow;
  }
}

Future<bool> setUserSound(int? soundId, int? typ) async {
  final Map<String, dynamic> dataBody = {};
  dataBody['sound_id'] = soundId;
  dataBody['typ'] = typ;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/im/sound/set_user_sound',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  } catch (e) {
    rethrow;
  }
}
