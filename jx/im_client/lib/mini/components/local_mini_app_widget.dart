import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/more_functions_bottom_sheet.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/mini/components/mini_app_extension.dart';
import 'package:jxim_client/special_container/special_container_overlay.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:mini_app_service/mini_app_service.dart';

Function(String error) homePagePopForError = (String error) {};

class LocalMiniAppWidget extends StatefulWidget {
  const LocalMiniAppWidget({
    super.key,
    required this.app,
    required this.startUrl,
    required this.isHorizontalScreen,
    this.isNeedHideOptionView,
    required this.openUid,
    this.route,
    this.bgColor,
    this.isNeedSafeArea,
  });

  final Apps app;

  final String startUrl;
  final String openUid;

  final bool isHorizontalScreen;

  final bool? isNeedHideOptionView;
  final String? route;
  final Color? bgColor;

  final bool? isNeedSafeArea;

  @override
  State<LocalMiniAppWidget> createState() => LocalMiniAppWidgetState();
}

bool appHomePageFistSetState = false;

class LocalMiniAppWidgetState extends State<LocalMiniAppWidget> {
  final toggleDebounce = Debounce(const Duration(milliseconds: 200));

  @override
  void initState() {
    if (widget.isHorizontalScreen) {
      objectMgr.miniAppMgr.setOrientation();
    }
    super.initState();
    init(widget.app);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = MiniAppManager.shared.appPage(
      "${widget.app.id}",
      route: widget.route ?? '',
      startUrl: widget.startUrl,
      bgColor: widget.bgColor,
      isNeedHideOptionView: widget.isNeedHideOptionView,
      isHorizontalScreen: widget.isHorizontalScreen,
      closeCallback: (NewMiniAppServerConfig config) {
        if (widget.app.isNeedCloseMiniApp) {
          SpecialContainerOverlay.closeOverlay();
        } else {
          SpecialContainerOverlay.minOverlay();
        }
      },
      moreCallback: (NewMiniAppServerConfig config) async {
        Apps app = widget.app;
        String? result = await MoreFunctionsBottomSheetTool.show(
          context,
          app: app,
          onClickShare: (Apps app) {
            /// 分享
            onShareLink({
              "url": "${objectMgr.miniAppMgr.miniAppShareUrlPrefix}${app.id}"
            }, false,widget.app);
          },
          onClickCopyLink: (Apps app) {
            /// 拷贝链接
            copyToClipboard(
                "${objectMgr.miniAppMgr.miniAppShareUrlPrefix}${app.id}",
                isOverlayToast: GetPlatform.isIOS);
          },
          onClickAdd: (Apps app) {
            toggleFavorite(app);
          },
        );
        return result ?? '';
      },
    );
    if (widget.isNeedSafeArea ?? false) {
      child = SafeArea(
        child: child,
      );
    }
    return child;
  }

  @override
  void dispose() {
    if (widget.isHorizontalScreen) {
      objectMgr.miniAppMgr.miniAppExit();
    }
    MiniAppManager.shared.stopAppServer("${widget.app.id}");
    super.dispose();
  }
}
