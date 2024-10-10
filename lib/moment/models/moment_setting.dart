part of '../index.dart';

class MomentSetting {
  int? userId;
  int? availableDay;
  String? backgroundPic;

  MomentSetting({
    this.userId,
    this.availableDay,
    this.backgroundPic,
  });

  MomentSetting.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    availableDay = json['available_day'];
    backgroundPic = json['background_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['available_day'] = availableDay;
    data['background_pic'] = backgroundPic;
    return data;
  }
}
