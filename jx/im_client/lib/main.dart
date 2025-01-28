import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/reel/components/upload_progress_overlay.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/special_container/special_container.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

UploadProgressOverlay? overlayScreen;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  runZonedGuarded(() async {
    // 初始化 Sentry
    await SentryFlutter.init(
      (options) {
        options.environment = kDebugMode ? 'debug' : 'product';
        options.dsn = Config().sentryCdn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = kDebugMode ? 1.0 : 0.5;
        options.enableAppHangTracking = true;
        options.appHangTimeoutInterval = const Duration(seconds: 2);
        options.navigatorKey = navigatorKey;
        options.beforeSend = (event, hint) {
          // 忽略特定异常
          if (event.throwable is NetworkException) {
            return null;
          }
          if (event.throwable is MissingPluginException) {
            return null;
          }
          return event;
        };
      },
      appRunner: () async {
        FlutterError.onError = (FlutterErrorDetails details) {
          pdebug(details.exception,
              stackTrace: details.stack, isError: true, writeSentry: true);
        };
        // 确保Flutter绑定初始化
        WidgetsFlutterBinding.ensureInitialized();
        //禁止手机横屏
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        // 初始化你的其他服务或配置
        await init();
        return runApp(const MyApp());
      }, // 运行你的应用
    );
  }, (error, stackTrace) {
    // 错误处理
    pdebug(error, stackTrace: stackTrace, isError: true, writeSentry: true);
  });
}

/// app 启动时的初始化
Future<void> init() async {
  bool init = await AppPath.init();
  if (!init) return;

  commonThemeManager.syncColorJson(Config().colorJson);

  SystemChannels.textInput.invokeMethod('TextInput.hide');

  objectMgr.pushMgr.initChannel();
  objectMgr.pushMgr.setup();

  await PlatformUtils.init();
  await objectMgr.localStorageMgr.init();
  await objectMgr.loginMgr.checkNeedLogin();

  List<Future> futures = [
    downloadMgr.init(),
    objectMgr.init(),
    objectMgr.langMgr.initialize(),
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
  Locale locale = objectMgr.langMgr.currLocale;

  changeLanguage(Locale loc, {bool fromSetLanguage = false}) async {
    if (locale.languageCode != loc.languageCode) {
      setState(() {
        locale = loc;
        Get.locale = locale;
      });
    }

    if (fromSetLanguage) {
      await Get.offAllNamed(
        objectMgr.loginMgr.isDesktop
            ? RouteName.desktopBoarding
            : RouteName.boarding,
        arguments: {'fromSetLanguage': true},
      );
    }
  }

  @override
  void initState() {
    super.initState();
    commonLangMgr.init();

    objectMgr.langMgr.on(LangMgr.eventUpdateLang, (_, __, ___) {
      changeLanguage(objectMgr.langMgr.currLocale);
    });
    if (!objectMgr.loginMgr.isDesktop) {
      PushManager.cancelVibrate();
    }

    agoraHelper.imInit();

    sharedDataManager.applyColorTheme(
      themeColor: themeColor,
    );
  }

  Size get defaultFontSize {
    Size designSize;
    if (Platform.isIOS) {
      // Apple IOS 14 Size
      designSize = const Size(390, 844);
    } else if (Platform.isAndroid) {
      // 安卓 设计尺寸
      designSize = const Size(360, 690);
    } else if (Platform.isWindows) {
      // Desktop 设计尺寸
      designSize = const Size(1440, 1024);
    } else if (Platform.isMacOS) {
      // MacBook Air Size
      designSize = const Size(1280, 720);
    } else {
      designSize = const Size(360, 690);
    }
    return designSize;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
      child: InAppNotification(
        child: ScreenUtilInit(
          designSize: defaultFontSize,
          splitScreenMode: true,
          builder: (BuildContext context, Widget? child) {
            return Obx(
                  () => Column(
                children: [
                  Expanded(
                      child: ClipRRect(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(
                              scStatus.value == SpecialContainerStatus.none.index
                                  ? 0
                                  : 16.0),
                          bottomRight: Radius.circular(
                              scStatus.value == SpecialContainerStatus.none.index
                                  ? 0
                                  : 16.0),
                        ),
                        child: GetMaterialApp(
                          navigatorKey: navigatorKey,
                          localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          supportedLocales: AppLocalizations.appSupportedLocales,
                          debugShowCheckedModeBanner: false,
                          locale: locale,
                          fallbackLocale: const Locale('en', 'US'),
                          // 备用语言
                          /// _CN
                          builder: (context, widget) {
                            ObjectMgr.screenMQ = MediaQuery.of(context);
                            ObjectMgr.viewPadding = MediaQuery.of(context).viewPadding;
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                textScaleFactor: 1.0,
                              ),
                              child: Overlay(
                                initialEntries: [
                                  OverlayEntry(
                                    builder: (context) {
                                      overlayScreen ??= UploadProgressOverlay.of(context);
                                      return BotToastInit()(context, widget);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          title: Config().appName,
                          navigatorObservers: [
                            SentryNavigatorObserver(),
                            BotToastNavigatorObserver(),
                            // MyGetObserver(),
                          ],
                          theme: themeData(),
                          initialRoute: objectMgr.loginMgr.isDesktop
                              ? RouteName.desktopHome
                              : RouteName.home,
                          getPages: Routes.routes(),
                        ),
                      )),
                  const SpecialContainer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    objectMgr.langMgr.off(LangMgr.eventUpdateLang);
    super.dispose();
  }
}

class MyGetObserver extends GetObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    pdebug('Pushed route: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    pdebug('Popped route: ${route.settings.name}');
    if (previousRoute != null) {
      if (previousRoute.settings.name == RouteName.home) {
        objectMgr.chatMgr.updateLocalTotalUnreadNumFromDB();
      }
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    pdebug(
      'Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    pdebug('Removed route: ${route.settings.name}');
  }
}
