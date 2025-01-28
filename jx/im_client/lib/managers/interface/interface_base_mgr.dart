abstract class InterfaceBaseMgr {
  /// 一次性注册接口，用于注册必要的资源或依赖。
  Future<void> registerOnce();

  /// 初始化接口，用于加载配置和准备运行环境。
  Future<void> initialize();

  /// 清理接口，用于释放资源和清理状态。
  Future<void> cleanup();

  /// 恢复网络连接后的初始化。
  Future<void> recover();
}
