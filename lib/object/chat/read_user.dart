class ReadUser {
  int gender = 0;
  int birthday = 0;
  String profilePicture = '';
  int mainCarSeries = 0;
  int id = 0;
  String nickName = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('gender')) gender = json['gender'];
    if (json.containsKey('birthday')) birthday = json['birthday'];
    if (json.containsKey('profile_picture')) {
      profilePicture = json['profile_picture'];
    }
    if (json.containsKey('main_car_series')) {
      mainCarSeries = json['main_car_series'];
    }
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gender': gender,
      'birthday': birthday,
      'profile_picture': profilePicture,
      'main_car_series': mainCarSeries,
      'nick_name': nickName,
    };
  }
}