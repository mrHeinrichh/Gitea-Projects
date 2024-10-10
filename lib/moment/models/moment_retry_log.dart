class MomentRetryLog
{
  List<int>? uuid;

  MomentRetryLog({required this.uuid});

  factory MomentRetryLog.fromJson(Map<String, dynamic> json) => MomentRetryLog(
    uuid: json["uuid"] != null ? List<int>.from(json["uuid"]) : null,
  );

  Map<String, dynamic> toJson() => {"uuid": uuid,};
}