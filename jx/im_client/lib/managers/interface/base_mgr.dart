import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/managers/interface/interface_base_mgr.dart';

abstract class BaseMgr extends EventDispatcher implements InterfaceBaseMgr {
  // bool _isRegistered = false;

  /// 一次性注册接口，用于注册必要的资源或依赖。
  @override
  Future<void> registerOnce();

  // bool _isInitialized = false;

  /// 初始化接口，用于加载配置和准备运行环境。
  @override
  Future<void> initialize();

  /// 清理接口，用于释放资源和清理状态。
  @override
  Future<void> cleanup();

  /// 恢复网络连接后的初始化。
  @override
  Future<void> recover();
}
