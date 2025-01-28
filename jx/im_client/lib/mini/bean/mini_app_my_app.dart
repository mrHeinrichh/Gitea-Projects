import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';

class MiniAppMyApp {
  List<Apps>? favoriteList;
  List<Apps>? recentList;

  MiniAppMyApp({this.favoriteList, this.recentList});

  MiniAppMyApp copyWith(List<Apps>? list1, List<Apps>? list2) {
    return MiniAppMyApp(favoriteList: list1, recentList: list2);
  }
}
