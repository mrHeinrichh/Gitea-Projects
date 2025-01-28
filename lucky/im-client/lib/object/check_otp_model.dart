class CheckOtpModel {
  String? token;

  CheckOtpModel({
    this.token,
  });

  factory CheckOtpModel.fromJson(Map<String, dynamic> json) => CheckOtpModel(
        token: json["token"],
      );
}
