/// 关心模版的管理器接口
abstract class TemplateMgrInterface {
  /// 注册模版
  Future<void> registerModel();
}

abstract class InterfaceMgr {
  Future<void> init();

  Future<void> clear();
}

abstract class JsonSerializable {
  Map<String, dynamic> toJson();
}
