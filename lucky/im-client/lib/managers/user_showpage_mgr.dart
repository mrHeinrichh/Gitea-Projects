import 'package:jxim_client/im/model/group/group.dart';
import 'package:events_widget/event_dispatcher.dart';

class UserShowPageMgr extends EventDispatcher {
  static const String eventOffSet = 'scroll_off_set';
  static const String eventCurrentIndex = 'current_index';
  static const String eventShowAll = 'show_all';
  static const String eventShowdelete = 'show_delete';
  static const String eventUpdateClickDt = 'update_click_dynamic';
  static const String eventTabBarOffSet = 'tabBar_off_set';
  static const String eventImageExtendHeight = 'image_extend_height'; //图片的拉伸
  static const String eventDynamicList = 'dynamic_list'; //更新动态列表
  static const String eventUpdateBackground = 'update_background'; //更新背景图
  static const String eventPullDown = 'pull_down'; //下拉距离
  static const String eventHideContent = 'hide_content'; //下拉隐藏内容
  static const String eventUpdateActivityList = 'update_activity_list'; //更新活动列表
  static const String eventUpdateCarList = 'update_car_list'; //更新车数据
  static const String eventUpdateGroupList = 'update_group_list'; //更新车数据

  double _offSet = 0.0;
  int _currentIndex = 0;
  bool _isShowAll = false;
  bool _isShowDelete = false; //备注的删除输入框内容判断
  int _clickDynamicId = 0;
  double _tabBarOffSet = 0.0;
  double _imageExtendHeight = 0;
  int _backgroundId = 0;
  double _pullDownOffset = 0;
  bool _isHide = false;
  List<Group> _groupList = [];

  double get offSet => _offSet;
  int get currentIndex => _currentIndex;
  bool get isShowAll => _isShowAll;
  bool get isShowDelete => _isShowDelete;
  int get clickDynamicId => _clickDynamicId;
  double get tabBarOffSet => _tabBarOffSet;
  double get imageExtendHeight => _imageExtendHeight;
  int get backgroundId => _backgroundId;
  double get pullDownOffset => _pullDownOffset;
  bool get isHide => _isHide;
  List<Group> get groupList => _groupList;

  set isHide(bool value) {
    _isHide = value;
    event(this, eventHideContent);
  }

  set pullDownOffset(double value) {
    _pullDownOffset = value;
    event(this, eventPullDown);
  }

  set offSet(double value) {
    _offSet = value;
    event(this, eventOffSet);
  }

  set currentIndex(int value) {
    _currentIndex = value;
    event(this, eventCurrentIndex);
  }

  set isShowAll(bool value) {
    _isShowAll = value;
    event(this, eventShowAll);
  }

  set isShowDelete(bool value) {
    _isShowDelete = value;
    event(this, eventShowdelete);
  }

  set tabBarOffSet(double value) {
    _tabBarOffSet = value;
    event(this, eventTabBarOffSet);
  }

  set imageExtendHeight(double value) {
    _imageExtendHeight = value;
    event(this, eventImageExtendHeight);
  }

  set backgroundId(int value) {
    _backgroundId = value;
    event(this, eventUpdateBackground);
  }

  set groupList(List<Group> value) {
    _groupList = value;
    event(this, eventUpdateGroupList);
  }
}
