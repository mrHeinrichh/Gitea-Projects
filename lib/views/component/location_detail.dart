import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_current_map.dart';
import 'package:jxim_client/im/custom_input/component/location_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class LocationDetail extends StatelessWidget {
  final String title;
  final String detail;
  final String latitude;
  final String longitude;

  const LocationDetail({
    super.key,
    required this.title,
    required this.detail,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildCloseBtn(),
            Expanded(
              child: GroupLocationCurrentMap(
                latitude: latitude,
                longitude: longitude,
              ),
            ),
            LocationItem(
              pngPath: 'assets/icons/icon_currentLocation.png',
              title: title,
              subTitle: detail,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseBtn() {
    return Container(
      height: 50,
      color: colorBackground,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(buttonClose),
                  style: jxTextStyle.textStyle16(color: themeColor),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              localized(location),
              style: jxTextStyle.textStyleBold16(),
            ),
          ),
        ],
      ),
    );
  }
}
