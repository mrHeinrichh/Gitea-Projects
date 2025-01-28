import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:im_common/im_common.dart';

import '../../routes.dart';

class DiscoveryRecommendVideo extends StatefulWidget {
  const DiscoveryRecommendVideo({super.key});

  @override
  State<DiscoveryRecommendVideo> createState() =>
      _DiscoveryRecommendVideoState();
}

class _DiscoveryRecommendVideoState extends State<DiscoveryRecommendVideo> {
  Widget _buildVideoItemInfo() {
    return Row(
      children: [
        Container(
            height: 52.w,
            width: 52.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Image(
                image: AssetImage(
              "assets/images/discovery_recommend_video_avatar.png",
            ))),
        ImGap.hGap12,
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ImText(
                '8号乐园',
                fontWeight: FontWeight.w600,
              ),
              ImGap.vGap4,
              ImText(
                '同城约炮 约炮上门',
                fontSize: ImFontSize.small,
                color: ImColor.black48,
              ),
            ],
          ),
        ),
        ImGap.hGap16,
        PrimaryButton(
          width: 80,
          height: 32,
          title: '观看',
          fontWeight: FontWeight.w500,
          fontSize: ImFontSize.small,
          txtColor: ImColor.accentColor,
          bgColor: ImColor.black6,
          borderRadius: 30,
          onPressed: () {
            Get.toNamed(RouteName.reel);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ).w,
      itemCount: 1,
      itemBuilder: (BuildContext context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16).w,
          decoration: BoxDecoration(
            borderRadius: ImBorderRadius.borderRadius16,
            border: Border.all(
              width: 0.3.w,
              color: ImColor.borderColor,
            ),
          ),
          child: ClipRRect(
            borderRadius: ImBorderRadius.borderRadius16,
            child: Column(
              children: [
                Container(
                    height: 200.h,
                    width: double.infinity,
                    child: const Image(
                      image: AssetImage(
                        "assets/images/discovery_recommend_video_pic.png",
                      ),
                      fit: BoxFit.cover,
                    )),
                Container(
                  color: ImColor.systemBg,
                  padding: const EdgeInsets.fromLTRB(20, 12, 13, 12).w,
                  child: _buildVideoItemInfo(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
