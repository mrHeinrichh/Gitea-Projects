class MassUnblockModel{
  List<dynamic>? errors;
  List<dynamic>? successUuids;
  int? successCount;
  Map<String, dynamic>? relationships;
  int? failedCount;

  MassUnblockModel({
    this.errors,
    this.successUuids,
    this.successCount,
    this.relationships,
    this.failedCount,
  });

  factory MassUnblockModel.fromJson(Map<String, dynamic> json) => MassUnblockModel(
    errors: json["errors"] ?? [],
    successUuids: json["success_uuids"] ?? [],
    successCount: json["success_count"] ?? 0,
    relationships: json["relationships"] ?? {},
    failedCount: json["failed_count"] ?? 0,
  );
}
