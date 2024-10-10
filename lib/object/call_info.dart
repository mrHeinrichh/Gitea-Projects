import 'package:jxim_client/object/call.dart';

class CallInfo {
  bool inCall;
  Call? call;

  CallInfo({
    required this.inCall,
    required this.call,
  });

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
        inCall: json["in_call"] ?? false,
        call: json["call_log"] == null ? null : Call.fromJson(json["call_log"]),
      );
}
