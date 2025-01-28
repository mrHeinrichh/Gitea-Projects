class BobiShopModel {
  String? url;

  BobiShopModel({
    this.url,
  });

  static BobiShopModel fromJson(dynamic data) {
    return BobiShopModel(
      url: data['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    return data;
  }
}
