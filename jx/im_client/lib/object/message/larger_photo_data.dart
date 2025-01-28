import 'package:events_widget/event_dispatcher.dart';

class LargerPhotoData extends EventDispatcher {
  static const String eventShowPage = 'show_page';
  static const String eventPageChange = 'page_change';

  static const String eventScaleChange = 'scale_change';

  // 媒体类型
  // 0: 图片
  // 1: 视频
  // 2: 相册照片
  // 3: 相册视频
  // -1: 未知
  int type = -1;

  // 缩放尺寸
  double _scale = 1.0;

  double get scale => _scale;

  set scale(double value) {
    _scale = value;
    event(this, eventScaleChange);
  }

  /// 判断是否正在切换页面
  bool _isShowPage = false;

  bool get isShowPage => _isShowPage;

  set isShowPage(bool value) {
    _isShowPage = value;
    event(this, eventShowPage);
  }

  /// 当前PageController页面数
  int _currentPage = 0;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    _currentPage = value;
    event(this, eventPageChange);
  }

  Map<String, bool> loadedOriginMap = {};

  bool shouldShowOriginal = false;

  bool showOriginal = false;
}
