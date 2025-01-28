class MentionModel {
  String userName = '';
  int userId = 0;
  Role role = Role.none;

  MentionModel({
    required this.userName,
    required this.userId,
    this.role = Role.none,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = userName;
    data['uid'] = userId;
    data['role'] = role.value;
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
  all(3);

  const Role(this.value);

  final int value;
}
