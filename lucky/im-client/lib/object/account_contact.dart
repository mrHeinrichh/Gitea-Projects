class AccountContactList {
  List<AccountContact>? contact;

  AccountContactList({ this.contact});

  AccountContactList.fromJson(Map<String, dynamic> json) {
    contact = <AccountContact>[];
    for(dynamic map in json['contact']){
      contact!.add(AccountContact.fromJson(map));
    }
  }

  List<Map<String, dynamic>> toJson() {
    List<Map<String, dynamic>> list = List.empty(growable: true);
    if (this.contact != null) {
      this.contact!.forEach((element) {
        list.add(element.toJson());
      });
    }
    return list;
  }
}

class AccountContact {
  int? uid;
  String? uuid;
  int? lastOnline;
  String? profilePic;
  String? nickname;
  String? contact;
  String? countryCode;
  String? email;
  String? username;
  String? bio;
  int? relationship;
  String? userAlias;
  int? requestAt;
  int? deletedAt;

  AccountContact({
    this.uid,
    this.uuid,
    this.lastOnline,
    this.profilePic,
    this.nickname,
    this.contact,
    this.countryCode,
    this.email,
    this.username,
    this.bio,
    this.relationship,
    this.userAlias,
    this.requestAt,
    this.deletedAt,
  });

  static AccountContact fromJson(dynamic data) {
    return AccountContact(
      uid: data['uid'],
      uuid: data['uuid'],
      lastOnline: data['last_online'],
      profilePic: data['profile_pic'],
      nickname: data['nickname'],
      contact: data['contact'],
      countryCode: data['country_code'],
      email: data['email'],
      username: data['username'],
      bio: data['bio'],
      relationship: data['relationship'],
      userAlias: data['user_alias'],
      requestAt: data['request_at'],
      deletedAt: data['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['uuid'] = uuid;
    data['last_online'] = lastOnline;
    data['profile_pic'] = profilePic;
    data['nickname'] = nickname;
    data['contact'] = contact;
    data['country_code'] = countryCode;
    data['email'] = email;
    data['username'] = username;
    data['bio'] = bio;
    data['relationship'] = relationship;
    data['user_alias'] = userAlias;
    data['request_at'] = requestAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
