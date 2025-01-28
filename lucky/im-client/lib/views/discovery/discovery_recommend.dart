import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/views/discovery/discovery_controller.dart';
import 'package:jxim_client/views/discovery/discovery_empty.dart';
import 'package:jxim_client/views/discovery/discovery_recommend_video.dart';

class DiscoveryRecommend extends StatelessWidget {
  const DiscoveryRecommend({super.key});

  @override
  Widget build(BuildContext context) {
    final DiscoveryController controller = Get.find<DiscoveryController>();

    return TabBarView(
      controller: controller.tagsTabControllerRecommend,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        getRecommendGameWidget(),
        const DiscoveryRecommendVideo(),
        const Center(child: DiscoveryEmpty(isRecommend: true)),
        const Center(child: DiscoveryEmpty(isRecommend: true)),
      ],
    );
  }
}
