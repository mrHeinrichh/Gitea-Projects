/// 管理器接口
abstract class MgrInterface {
  /// 注册
  Future<void> register();
  /// 初始化
  Future<void> init();

  Future<void> reloadData();

  /// 用户登出
  Future<void> logout();
}

/// 关心模版的管理器接口
abstract class TemplateMgrInterface {
  /// 注册模版
  Future<void> registerModel();
}

/// 关心sqflite的管理器接口
abstract class SqfliteMgrInterface {
  /// 注册sqflite
  Future<void> registerSqflite();
}
