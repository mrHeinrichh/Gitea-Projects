class JurisdictionMode {
  int type = 0;
  int status = 2; //2.未授权 1.通过 0.拒绝

  JurisdictionMode({
    required this.type,
    required this.status,
  });

   JurisdictionMode.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    status = json['status'];
  }


  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
    };
  }
}
