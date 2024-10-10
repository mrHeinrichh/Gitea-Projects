enum STATUS {
  valid,
  invalid,
}

class GroupInviteLink {
  int? id;
  int? groupId;
  int? uid;
  String? name;
  String? link;
  int? used;
  STATUS? status;
  int? duration;
  int? limited;
  int? expireTime;

  GroupInviteLink(
      {this.id,
      this.groupId,
      this.uid,
      this.name,
      this.link,
      this.used,
      this.status,
      this.duration,
      this.limited,
      this.expireTime});

  GroupInviteLink.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['group_id'];
    uid = json['uid'];
    name = json['name'];
    link = json['link'];
    used = json['used'];
    status = json['status'] == 0 ? STATUS.valid : STATUS.invalid;
    duration = json['duration'];
    limited = json['limited'];
    expireTime = json['expire_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['group_id'] = groupId;
    data['uid'] = uid;
    data['name'] = name;
    data['link'] = link;
    data['used'] = used;
    data['status'] = status;
    data['duration'] = duration;
    data['limited'] = limited;
    data['expire_time'] = expireTime;
    return data;
  }
}

class GroupInfo {
  GroupInviteLink? groupLink;
  String? userName;
  String? userIcon;
  String? groupName;
  String? groupIcon;

  GroupInfo(
      {this.groupLink,
      this.userName,
      this.userIcon,
      this.groupName,
      this.groupIcon});

  GroupInfo.fromJson(Map<String, dynamic> json) {
    groupLink = json['group_link'] != null
        ? GroupInviteLink.fromJson(json['group_link'])
        : null;
    userName = json['user_name'];
    userIcon = json['user_icon'];
    groupName = json['group_name'];
    groupIcon = json['group_icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (groupLink != null) {
      data['group_link'] = groupLink!.toJson();
    }
    data['user_name'] = userName;
    data['user_icon'] = userIcon;
    data['group_name'] = groupName;
    data['group_icon'] = groupIcon;
    return data;
  }
}
