import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';

class HomeGetMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isLoggedIn = objectMgr.loginMgr.isLogin;
    if (!isLoggedIn) {
      final isDesktop = objectMgr.loginMgr.isDesktop;
      String routeName =
          isDesktop ? RouteName.desktopBoarding : RouteName.boarding;
      return RouteSettings(name: routeName);
    }

    return null;
  }
}
