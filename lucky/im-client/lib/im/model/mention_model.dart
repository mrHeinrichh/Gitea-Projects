class MentionModel {
  String userName = '';
  int userId = 0;
  Role role = Role.none;

  MentionModel({
    required this.userName,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.userName;
    data['uid'] = this.userId;
    data['role'] = this.role.value;
    return data;
  }

  MentionModel.fromJson(Map<String, dynamic> json) {
    userName = json['username'];
    userId = json['uid'];
    role = Role.values[json['role']];
  }
}

enum Role {
  none(0),
  admin(1),
  member(2),
  owner(3);

  const Role(this.value);

  final int value;
}
