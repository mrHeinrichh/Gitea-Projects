enum SoundTrackType {
  SoundTypeDefault(0),
  SoundTypeIncomingCall(1),
  SoundTypeOutgoingCall(2),
  SoundTypeWaitingCall(3),
  SoundTypePickUpCall(4),
  SoundTypeHangUpCall(5),
  SoundTypeNotification(6),
  SoundTypeSendMessage(7),
  SoundTypeDialing(8),
  SoundTypeGroupNotification(9);

  const SoundTrackType(this.value);
  final int value;
}

class SoundData {
  int? id;
  String? filePath;
  int? typ;
  String? name;
  int? createdAt;
  int? updatedAt;
  int? deletedAt;
  int? channelGroupId;
  int? isDefault;

  SoundData({
    this.id,
    this.filePath,
    this.typ,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.channelGroupId,
    this.isDefault,
  });

  factory SoundData.fromJson(Map<String,dynamic> json) {
    return SoundData(
      id: json['id'],
      filePath: json['file_path'] ?? "",
      typ: json['typ'],
      name: json['name'] ?? "",
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      channelGroupId: json['channel_group_id'],
      isDefault: json['is_default'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_path': filePath,
      'typ': typ,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'channel_group_id': channelGroupId,
      'is_default': isDefault,
    };
  }
}
