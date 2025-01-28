import 'package:bot_toast/bot_toast.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/views/message/qrcode.dart';
import 'package:jxim_client/views/mypage/set/account_and_safe.dart';
import 'package:jxim_client/views/mypage/set/privacy.dart';
import 'package:jxim_client/views/mypage/set/rule_description.dart';
import 'package:jxim_client/views/mypage/user_list_page/friends.dart';

final PageMgr pageMgr = PageMgr();

///页面管理器
class PageMgr {
  //主页相关
  static const home = 10000; //主页[0,0]
  static const groupRankPage = 10001; //群排行榜[0]
  static const homePartyPage = 10002; //欢乐派对大厅界面[1]
  static const partySearchPage = 10003; //欢乐派对搜索界面

  //亲密度相关
  static const loverIntimacyRoute = 20001; //亲密度界面[对象id]
  static const loverSpaceRoute = 20002; //亲密空间界面[对象id]
  static const loverRankPage = 20003; //情侣榜界面
  static const loverDescAlert = 20004; //亲密度说明
  static const loverLevelAlert = 20005; //亲密度等级

  //活动相关
  static const activitySelectGroup = 20101; //创建活动选择群列表
  static const createActivityRoute = 20102; //创建活动界面[好友群id]
  static const createActivitySmall = 20103; //创建聚会界面[好友群id]
  static const activityDetailRoute = 20104; //活动详情界面[活动id]
  static const activityDetailSmall = 20105; //聚会详情界面[活动id]
  static const activityMyList = 20106; //我的活动界面
  static const activityNearMap = 20107; //附近活动地图[0]
  static const activityNearList = 20108; //附近活动列表界面[0]
  static const activityRecommendList = 20109; //推荐活动列表
  static const activitySmallList = 20110; //聚会界面[0]
  static const activitySmallMylist = 20111; //我的聚会界面[0]

  //好友群/消息相关
  static const circleDetailRoute = 30001; //好友群详情界面[好友群id]
  static const voiceMatch = 30002; //语音匹配
  static const joinLive = 30003; //加入直播间
  static const joinVoice = 30004; //加入语音房
  static const circleList = 30005; //交际圈
  static const carFriend = 30006; //找好友
  static const recommendCircle = 30007; //推荐好群
  static const chatSingle = 30008; //单聊
  static const chatGroup = 30009; //群聊
  static const chatDiscuss = 30010; //讨论组聊天
  static const chatSystem = 30011; //系统通知
  static const chatDynamic = 30012; //动态通知
  static const callUserList = 30013; //讨论组通话选人

  //个人相关
  static const personalMessage = 40001; //个人信息
  static const userVoice = 40002; //录制语音签名
  static const userName = 40003; //编辑昵称
  static const qrCode = 40004; //我的二维码
  static const userWechat = 40005; //我的二维码
  static const userLabel = 40006; //我的标签
  static const userLevelItem = 40007; //财富魅力等级
  static const userHistory = 40008; //财富魅力等级历史记录
  static const friends = 40009; //我的好友
  static const seenMe = 40010; //我的遇见
  static const carPort = 40011; //车库
  static const createCar = 40012; //车辆认证
  static const recharge = 40013; //我的币
  static const goldRechargeHistory = 40014; //币历史记录
  static const myearnings = 40015; //我的收益
  static const earnings = 40016; // 我的收益说明
  static const withdrawal = 40017; //收益提现
  static const withdrawaldetails = 40018; //收益提现说明
  static const token = 40019; //兑换币
  static const exchangeRecord = 40020; //兑换币记录
  static const task = 40021; //日常活跃
  static const ruleDescription = 40022; //日常活跃规则
  static const myApprove = 40023; //我的认证
  static const realCertification = 40024; //真人认证
  static const realName = 40025; //实名认证
  static const myListData = 40026; //我的发布
  static const myListDataCollection = 40027; //我的收藏
  static const otherFeatures = 40028; //其他功能
  static const mypageSet = 40029; //个人设置
  static const accountAndSafe = 40030; //账户与安全
  static const retrievePassword = 40031; //账户与安全-设置密码
  static const messageNotification = 40032; //消息设置
  static const disturbList = 40033; //消息免打扰
  static const blackList = 40034; //黑名单
  static const bindPhone = 40035; //手机认证
  static const privacy = 40036; //隐私设置
  static const sendDynamic = 40037; //发送动态选择话题

  //广场相关
  static const topicSquare = 40038; //话题广场
  static const contentDetail = 40039; //动态详情
  static const topicDetailRoute = 40040; //话题详情

  ///页面类型
  final _pageTypes = {
    chatSingle: SingleChatView,
    chatGroup: GroupChatView,
    chatDiscuss: GroupChatView,
    // chatSystem: SystemMessageRoute,

    //个人相关
    qrCode: QrCode,
    friends: Friends,
    ruleDescription: RuleDescription,
    accountAndSafe: AccountAndSafe,
    privacy: Privacy,
  };

  ///检测并关闭聊天窗口
  bool checkRemoveChat(BuildContext context,
      {bool Function(Chat chat)? checkHold}) {
    var chatPage = _getChatPage();
    var data = _getChatPageData(chatPage);
    bool isRemove = false;
    if (data != null) {
      if (checkHold != null && checkHold(data)) return false;
      Navigator.popUntil(context, (route) {
        if (isRemove) return true;
        var page = _getPage(route.settings);
        isRemove = page == chatPage;
        return false;
      });
    }
    return isRemove;
  }

  Chat? _getChatPageData(Widget? chatPage) {
    if (chatPage == null) return null;
    return null;
  }

  ///关闭直到指定页面
  // popUntilPage(int pageId, [BuildContext? context]) {
  //   if (context == null)
  //     context = Routes.navigatorKey.currentState!.overlay!.context;
  //   Navigator.popUntil(context, (route) => getRoutePageId(route) == pageId);
  // }

  ///获取最顶的指定界面
  Widget? getOpenedPage(int pageId) {
    if (_routes.isEmpty) return null;
    String pagekey = pageId.toString();
    for (int i = _routes.length - 1; i >= 0; i--) {
      if (_routes[i].settings.name != pagekey) continue;
      return _getPage(_routes[i].settings);
    }
    return null;
  }

  Widget? _getChatPage() {
    if (_routes.isEmpty) return null;
    List<String> chatPageKeys = [
      chatSingle.toString(),
      chatGroup.toString(),
      chatDiscuss.toString(),
    ];
    for (int i = _routes.length - 1; i >= 0; i--) {
      String pageKey = _routes[i].settings.name ?? '';
      if (chatPageKeys.indexOf(pageKey) == -1) continue;
      return _getPage(_routes[i].settings);
    }
    return null;
  }

  ///获取最顶界面
  Widget? getTopPage() {
    if (_routes.isEmpty) return null;
    return _getPage(_routes.last.settings);
  }

  ///界面是否打开
  bool isPageOpened(int pageId) {
    String pagekey = pageId.toString();
    return _pages.containsKey(pagekey);
  }

  ///保存当前界面
  RouteSettings? savePage(Widget page, [RouteSettings? settings]) {
    int? pageId = getPageId(page);
    if (pageId == null) return null;
    if (settings == null) settings = createPageSettings(pageId, isSave: false);
    dynamic arguments = settings.arguments;
    String pagekey = pageId.toString();
    String guid = arguments['guid'];
    if (!_pages.containsKey(pagekey)) _pages[pagekey] = {};
    _pages[pagekey]![guid] = page;
    return settings;
  }

  ///创建指定页面路由参数
  RouteSettings createPageSettings(
    int pageId, {
    String? name,
    bool isSave = true,
  }) {
    String pagekey = pageId.toString();
    int curTime = DateTime.now().millisecondsSinceEpoch;
    String guid = pagekey + ',' + curTime.toString();
    var arguments = {};
    arguments['page'] = pagekey;
    arguments['guid'] = guid;
    var settings = RouteSettings(name: name ?? pagekey, arguments: arguments);

    return settings;
  }

  ///获取路由对应页面id
  int? getRoutePageId(Route route) {
    if (route.settings.name != null && route.settings.name == RouteName.home) {
      return home;
    }
    if (route.settings.arguments == null) return null;
    dynamic arguments = route.settings.arguments;
    return int.parse(arguments['page']);
  }

  ///获取页面对应id
  int? getPageId(Widget page) {
    int? pageId = null;
    Type type = page.runtimeType;
    _pageTypes.forEach((key, value) {
      if (value == type) pageId = key;
    });

    return pageId;
  }

  ///获取页面
  Widget? _getPage(RouteSettings settings) {
    if (settings.arguments == null) return null;
    dynamic arguments = settings.arguments;
    String pagekey = arguments['page'];
    if (!_pages.containsKey(pagekey)) return null;
    String guid = arguments['guid'];
    return _pages[pagekey]![guid];
  }

  ///移除页面
  void _removePage(RouteSettings settings) {
    if (settings.arguments == null) return;
    dynamic arguments = settings.arguments;
    String pagekey = arguments['page'];
    if (!_pages.containsKey(pagekey)) return;
    String guid = arguments['guid'];
    _pages[pagekey]!.remove(guid);
    if (_pages[pagekey]!.isEmpty) _pages.remove(pagekey);
  }

  final Map<String, Map<String, Widget>> _pages = {}; //页面列表
  // final Map<String, List<RouteSettings>> _pageSettings = {};
  final List<Route<dynamic>> _routes = []; //路由列表
  BotToastNavigatorObserverProxy? _observerProxy;

  ///代理注册
  void init() {
    if (_observerProxy != null) {
      BotToastNavigatorObserver.unregister(_observerProxy!);
    }
    _routes.clear();
    _pages.clear();
    // _pageSettings.clear();
    _observerProxy = BotToastNavigatorObserverProxy(
      didPush: (route, previousRoute) {
        if (previousRoute != null) {
          String? routeName = previousRoute.settings.name;
          if (routeName != null) {
            if (routeName.contains('chat/private_chat') ||
                routeName.contains('chat/group_chat')) {
              int chatID = extractDigitsFromString(routeName);
              if (Get.isRegistered<CustomInputController>(
                  tag: chatID.toString())) {
                Get.find<CustomInputController>(tag: chatID.toString())
                    .removeScreenshotCallback();
              }
            }
          }
        }
      },
      didReplace: (newRoute, oldRoute) {
        // int index = -1;
        // if (oldRoute != null) {
        //   _removePage(oldRoute.settings);
        //   index = _routes.indexOf(oldRoute);
        //   if (index != -1) _routes.removeAt(index);
        // }
        // if (newRoute != null) {
        //   if (index != -1)
        //     _routes.insert(index, newRoute);
        //   else
        //     _routes.add(newRoute);
        // }
      },
      didRemove: (route, previousRoute) {
        // _removePage(route.settings);
        // _routes.remove(route);
      },
      didPop: (previousRoute, route) {
        if (route != null) {
          if (route.settings.name == "/home") {
            objectMgr.chatMgr.updateLocalTotalUnreadNumFromDB();
          } else if (route.settings.name != null) {
            if (route.settings.name!.contains('chat/private_chat') ||
                route.settings.name!.contains('chat/group_chat')) {
              int chatID = extractDigitsFromString(route.settings.name!);
              if (Get.isRegistered<CustomInputController>(
                  tag: chatID.toString())) {
                Get.find<CustomInputController>(tag: chatID.toString())
                    .setupScreenshotCallback();
              }
            }
          }
        }
      },
    );
    BotToastNavigatorObserver.register(_observerProxy!);
  }
}

int extractDigitsFromString(String input) {
  final regex = RegExp(r'\d+');
  final matches = regex.allMatches(input);

  final digits = matches.map((match) => int.parse(match.group(0)!)).toList();

  return digits.first;
}

///页面分页信息
class PageTabData extends EventDispatcher {
  static const eventUpdateTab = 'eventUpdateTab'; //更新tab页信息
  int _tabIndex = 0; //当前分页
  dynamic _args; //当前页数据
  PageTabData? _subData; //下一级分页信息
  int get tabIndex => _tabIndex;
  dynamic get args => _args;
  PageTabData? get subData => _subData;

  PageTabData(
    int tabIndex, {
    dynamic args,
    PageTabData? subData,
  }) {
    _tabIndex = tabIndex;
    _args = args;
    _subData = subData;
  }

  ///更新分页信息
  void updateTab(PageTabData? data) {
    if (data == null) return;
    _updateTab(data.tabIndex, args: data.args, subData: data.subData);
  }

  ///更新分页信息
  void _updateTab(
    int tabIndex, {
    dynamic args,
    PageTabData? subData,
  }) {
    _tabIndex = tabIndex;
    _args = args;
    _subData = subData; //暂存
    event(this, eventUpdateTab);
  }
}
