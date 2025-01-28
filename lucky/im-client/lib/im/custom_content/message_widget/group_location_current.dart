
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/component/location_item.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'group_location_current_map.dart';

class GroupLocationCurrent extends StatefulWidget {
  final MessageMyLocation messageLocation;

  const GroupLocationCurrent({
    super.key,
    required this.messageLocation,
  });

  @override
  State<GroupLocationCurrent> createState() => _GroupLocationCurrentState();
}

class _GroupLocationCurrentState extends State<GroupLocationCurrent> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildCloseBtn(context),
          Expanded(
            child: GroupLocationCurrentMap(
              messageLocation: widget.messageLocation,
            ),
          ),
          LocationItem(
              pngPath: 'assets/icons/icon_currentLocation.png',
              // onClick: () async {
              //   GoogleMapController controller =
              //   await GroupLocationCurrentMap.googleMapController.future;
              //   controller.animateCamera(
              //     CameraUpdate.newLatLng(
              //       LatLng(
              //         double.parse(widget.messageLocation.latitude),
              //         double.parse(widget.messageLocation.longitude),
              //       ),
              //     ),
              //   );
              // },
              title: '${widget.messageLocation.name}',
              subTitle: '${widget.messageLocation.address}',
              showDivider: false,
          ),
          ImGap.vGap8
        ],
      ),
    );
  }

  Container _buildCloseBtn(BuildContext context) {
    return Container(
      height: 50,
      color: JXColors.white,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(walletInformationClose),
                  style: jxTextStyle.textStyle16(color: accentColor),
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
