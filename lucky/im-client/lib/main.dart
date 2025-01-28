import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fconsole/core/fconsole.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/views/page_mgr.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:jxim_client/utils/log.dart';

import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jxim_client/utils/plugin_manager.dart';

// 对象管理器，全局对象根
final objectMgr = ObjectMgr();
UploadProgressOverlay? overlayScreen;

Future<void> main(List<String> args) async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 在此处处理错误，如显示全局错误提示
    MyErrorHandler.showError(details.exceptionAsString());
  };

  runAppWithFConsole(const MyApp(), beforeRun: () async {
    await init();
    SentryFlutter.init((options) {
      options.environment = kReleaseMode ? 'product' : 'profile';
      options.dsn = Config().sentryCdn;
      options.enableTracing = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    });
  }, callback: (e, s) {
    debugInfo.printErrorStack(e, s, toast: Config().isDebug);
  }, errHandler: (Zone self, ZoneDelegate parent, Zone zone, Object error,
      StackTrace stackTrace) {
    debugInfo.printErrorStack(error, stackTrace, toast: Config().isDebug);
  });
}

/// app 启动时的初始化
Future<void> init() async {
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  objectMgr.pushMgr.initChannel();
  objectMgr.pushMgr.setup();

  await objectMgr.localStorageMgr.init();
  await objectMgr.loginMgr.checkNeedLogin();
  List<Future> futures = [
    MyLog.init(),
    downloadMgr.init(),
    objectMgr.init(),
    debugInfo.init(),
    agoraLangMgr.init(),
    objectMgr.langMgr.init(),
    PlatformUtils.init(),
    appVersionUtils.init(),
  ];
  await Future.wait(futures);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Locale locale = objectMgr.langMgr.currLocale;

  changeLanguage(Locale loc, {bool fromSetLanguage = false}) {
    if (locale.languageCode != loc.languageCode) {
      setState(() {
        locale = loc;
        Get.locale = locale;
      });
    }

    if (fromSetLanguage) {
      Get.offAllNamed(
          objectMgr.loginMgr.isDesktop
              ? RouteName.desktopBoarding
              : RouteName.boarding,
          arguments: {'fromSetLanguage': true});
    }
  }

  @override
  void initState() {
    super.initState();

    //禁止手机横屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    objectMgr.langMgr.on(LangMgr.eventUpdateLang, (_, __, ___) {
      changeLanguage(objectMgr.langMgr.currLocale);
    });
    if (!objectMgr.loginMgr.isDesktop) {
      PushManager.cancelVibrate();
    }
    // initUserSkin();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageMgr.init();
    });

    agoraHelper.imInit();
    sharedDataManager.lookupLocalStr = (String str) {
      return localized(str);
    };

    PluginManager.shared.init();
  }

  @override
  Widget build(BuildContext context) {
    BotToastNavigatorObserver botToastNavigatorObserver =
        BotToastNavigatorObserver();

    final isDesktop = objectMgr.loginMgr.isDesktop;
    final isLogin = objectMgr.loginMgr.isLogin;

    String routeName;

    if (isDesktop) {
      routeName = isLogin ? RouteName.desktopHome : RouteName.desktopBoarding;
    } else if (isLogin) {
      routeName = RouteName.home;
    } else {
      routeName = RouteName.boarding;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      child: InAppNotification(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) {
          return ProviderScope(
            child: GetMaterialApp(
              key: _formKey,
              navigatorKey: Routes.navigatorKey,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                CommonAppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.appSupportedLocales,
              debugShowCheckedModeBanner: false,
              locale: locale,

              /// _CN
              builder: (context, widget) {
                ObjectMgr.screenMQ = MediaQuery.of(context);
                ObjectMgr.viewPadding = MediaQuery.of(context).viewPadding;
                return Overlay(
                  initialEntries: [
                    OverlayEntry(builder: (context) {
                      if (overlayScreen == null) {
                        overlayScreen = UploadProgressOverlay.of(context);
                      }
                      return BotToastInit()(context, widget);
                    })
                  ],
                );
              },
              title: Config().appName,
              navigatorObservers: [
                SentryNavigatorObserver(),
                botToastNavigatorObserver,
              ],
              theme: themeData(),
              // darkTheme: darkThemeData(),
              initialRoute: routeName,
              getPages: Routes.routes(),
              // onGenerateRoute: (RouteSettings setting) {},
            ),
            );
          },
        ),
      ),
      value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor:
              Platform.isAndroid ? JXColors.black : Colors.black),
    );
  }

  @override
  void dispose() {
    super.dispose();

    objectMgr.langMgr.off(LangMgr.eventUpdateLang, (_, __, ___) {
      setState(() {});
    });
  }
}
