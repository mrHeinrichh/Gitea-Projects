import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class HomeNetworkBar<T> extends StatelessWidget {
  const HomeNetworkBar({
    super.key,
    required this.controller,
  });

  final ChatListController controller;

  @override
  Widget build(BuildContext context) {
    if (objectMgr.loginMgr.isDesktop) return const SizedBox();
    return Obx(
      () => SliverToBoxAdapter(
        child: Visibility(
          visible: objectMgr.appInitState.value == AppInitState.no_connect ||
              objectMgr.appInitState.value == AppInitState.no_network,
          child: GestureDetector(
            onTap: () {
              Get.toNamed(RouteName.networkDiagnose,
                  arguments: {'startDiagnose': true});
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  colorYellow.withOpacity(0.12),
                  colorSurface,
                ),
                border: const Border(
                    bottom: BorderSide(
                  color: colorDivider,
                  width: 0.33,
                )),
              ),
              child: OverlayEffect(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Transform.rotate(
                            angle: 3.15,
                            child: const Icon(
                              Icons.info,
                              color: colorOrange,
                              size: 24,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              localized(cantConnectCheckNetwork),
                              style: jxTextStyle.headerSmallText(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SvgPicture.asset(
                        'assets/svgs/right_arrow_thick.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          colorTextSupporting,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
