import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';

Future<void> reportFileStat(Map<String, dynamic> stat) async {
  try {
    await CustomRequest.doPost(
      '/app/api/report/file_stat',
      data: stat,
    );
  } catch (e) {
    pdebug("Report Upload stat failed: $e");
  }
}

Future<void> reportApiStat(Map<String, dynamic> stat) async {
  try {
    await CustomRequest.doPost(
      '/app/api/report/api_stat',
      data: stat,
    );
  } catch (e) {
    pdebug("Report Upload stat failed: $e");
  }
}
