import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/toast.dart';

class OnBoardingController extends GetxController {
  final isLoading = false.obs;
  final needLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  _initData() async {
    isLoading.value = true;

    try {
      if (!serversUriMgr.isInit) {
        objectMgr.initKiwi();
      }
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }

    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('fromSetLanguage')) {
      isLoading.value = true;
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentState!.context,
          objectMgr.loginMgr.isMobile ? RouteName.home : RouteName.desktopHome,
          (route) => false,
        );
      });
    } else {
      isLoading.value = false;
      if(objectMgr.loginMgr.isDesktop){
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            objectMgr.initCompleted();
          });
        });
      }

    }
  }


  ///Desktop Version ====================================================
  Future<void> generateDesktopQR() async {
    try {
      objectMgr.loginMgr.desktopSecret.value = await desktopGenerateQR();
      Get.toNamed(RouteName.desktopLoginQR);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }

    isLoading.value = false;
  }
}
