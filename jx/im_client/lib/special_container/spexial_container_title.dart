import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/special_container/special_container_overlay.dart';
import 'package:jxim_client/special_container/special_container_title_extension.dart';
import 'package:jxim_client/special_container/special_container_util.dart';

class SpecialContainerTitle extends StatelessWidget {
  const SpecialContainerTitle({
    super.key,
    required this.type,
  });

  final SpecialContainerType type;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (scStatus.value == SpecialContainerStatus.max.index) {
          sheetHeight.value = 0;
          _showContainerMax(context);
        } else if (scStatus.value == SpecialContainerStatus.min.index) {
          sheetHeight.value = kSheetHeightMin;
        } else {
          sheetHeight.value = 0;
        }
        return Offstage(
          offstage: scStatus.value == SpecialContainerStatus.none.index,
          child: AnimatedContainer(
            margin: EdgeInsets.only(top: 4.w),
            duration: kAnimationTime,
            height: sheetHeight.value == 0 ? 0 : sheetHeight.value,
            // : MediaQuery.of(context).padding.bottom + sheetHeight.value,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Material(
                child: Container(
                  height: kSheetHeightMin,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      if (scStatus.value == SpecialContainerStatus.min.index)
                        if (objectMgr.miniAppMgr.isAwesomeApp.value
                            && objectMgr.miniAppMgr.isH5SpecialMiniAppLoadingDone.value)
                          SizedBox(
                            height: kSheetTitleHeight,
                            child: getNoToolBarMiniAppWidget(context),
                          )
                        else
                          Container(
                            alignment: Alignment.center,
                            height: kSheetTitleHeight,
                            child: Text(
                              objectMgr.miniAppMgr.currentApp?.name ?? '',
                              style: jxTextStyle.appTitleStyle(
                                  color: colorTextPrimary),
                            ),
                          ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          if (!CoolDownManager.handler(
                              key: "onMenuTap", duration: 700)) {
                            return;
                          }
                          await objectMgr.miniAppMgr.onBottomMiniAppClick();
                          _showContainerMax(context);
                        },
                        child: Container(
                          alignment: Alignment.centerRight,
                          width: MediaQuery.of(context).size.width,
                          height: kSheetTitleHeight,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _closeContainer();
                        },
                        child: Container(
                          padding: EdgeInsets.only(top: 10.w, left: 16.w),
                          width: kSheetTitleHeight,
                          height: kSheetTitleHeight,
                          alignment: Alignment.topLeft,
                          child: SvgPicture.asset(
                            'assets/svgs/close_icon.svg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContainerMax(BuildContext context) {
    final child = getFullScreenMiniAppWidget(
      context,
    );
    scStatus.value = SpecialContainerStatus.max.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (type == SpecialContainerType.full) {
        SpecialContainerOverlay.addSpecialContainerOverlay(
          type: type,
          child: child,
        );
      } else {
        SpecialContainerOverlay.addSpecialContainerOverlay(
          type: type,
          child: child,
        );
      }
    });
  }

  void _closeContainer() {
    objectMgr.miniAppMgr.closeMiniApp();
  }
}
