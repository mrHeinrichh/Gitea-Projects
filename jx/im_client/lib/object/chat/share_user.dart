class ShareUser {
  int userId = 0;
  String nickname = '';
  String profilePicture = '';

  ShareUser();

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('user_id')) userId = json['user_id'];
    if (json.containsKey('profile_picture')) {
      profilePicture = json['profile_picture'];
    }
    if (json.containsKey('nick_name')) nickname = json['nick_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'profile_picture': profilePicture,
      'nick_name': nickname,
    };
  }
}
