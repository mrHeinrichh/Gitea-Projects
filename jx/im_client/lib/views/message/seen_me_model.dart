class SeenMeModel {
  int createTime = 0;
  int id = 0;
  int targetId = 0;
  int userId = 0;
  UserData userData = UserData();
  int count = 0;

  SeenMeModel();

  SeenMeModel.fromJson(Map<String, dynamic> json) {
    createTime = json['create_time'];
    id = json['id'];
    targetId = json['target_id'];
    userId = json['user_id'];
    userData =
        json['user_data'] != null ? UserData.fromJson(json['user_data']) : UserData();
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['create_time'] = createTime;
    data['target_id'] = targetId;
    data['user_id'] = userId;
      data['user_data'] = userData.toJson();
    data['count'] = count;
    return data;
  }
}

class SeenMeTotal {
  int dayCount = 0;
  int monthCount = 0;

  SeenMeTotal();

  SeenMeTotal.fromJson(Map<String, dynamic> json){
    dayCount = json['day_count'];
    monthCount = json['month_count'];
  }

  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day_count'] = dayCount;
    data['month_count'] = monthCount;
    return data;
  }
}

class UserData {
  int id = 0;
  int mainCarSeries = 0;
  int head = 0;
  int gender = 0;
  String nickName = '';
  int birthday = 0;
  String flags = '';
  int cityCode = 0;
  int actionType = 0;

  UserData();

  UserData.fromJson(Map<String, dynamic> json) {
    id = (json['id'] != null) ? json['id'] : 0;
    nickName = (json['nick_name'] != null) ? json['nick_name'] : '';
    mainCarSeries =
        (json['main_car_series'] != null) ? json['main_car_series'] : 0;
    gender = (json['gender'] != null) ? json['gender'] : 0;
    birthday = (json['birthday'] != null) ? json['birthday'] : 0;
    head = (json['head'] != null) ? json['head'] : 0;
    cityCode = (json['city_code'] != null) ? json['city_code'] : 0;
    flags = (json['flags'] != null) ? json['flags'] : '';
    actionType = (json['action_type'] != null) ? json['action_type'] : 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['main_car_series'] = mainCarSeries;
    data['id'] = id;
    data['head'] = head;
    data['gender'] = gender;
    data['nick_name'] = nickName;
    data['birthday'] = birthday;
    data['flags'] = flags;
    data['city_code'] = cityCode;
    return data;
  }
}
