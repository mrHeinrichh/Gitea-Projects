import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_bottom_sheet_dialog.dart';
import 'package:jxim_client/managers/live_location_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';

class LocationSharingBtn extends StatefulWidget {
  final Chat chat;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LocationSharingBtn({
    super.key,
    required this.chat,
    required this.value,
    required this.onChanged,
  });

  @override
  State<LocationSharingBtn> createState() => _LocationSharingBtnState();
}

class _LocationSharingBtnState extends State<LocationSharingBtn> {
  bool _isSharing = false;

  @override
  void initState() {
    _isSharing = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSharing) {
          _disableShareBottomSheet(context);
        } else {
          _enableShareBottomSheet(context);
        }
      },
      child: Container(
        height: 56.w,
        decoration: const BoxDecoration(
          color: ImColor.white,
          border: Border(
            top: BorderSide(
              color: ImColor.black6,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svgs/stop_sharing_pin.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _isSharing ? ImColor.primaryRed : ImColor.accentColor,
                BlendMode.srcIn,
              ),
            ),
            ImGap.hGap4,
            ImText(
              _isSharing ? 'Stop Sharing Location' : 'Share Live Location',
              color: _isSharing ? ImColor.primaryRed : ImColor.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: ImFontSize.large,
            )
          ],
        ),
      ),
    );
  }

  void _disableShareBottomSheet(BuildContext context) {
    CustomBottomSheetDialog.showCustomModalBottomSheet(
      ctx: context,
      title: 'Stop Sharing Location?',
      cancelFontWeight: FontWeight.w500,
      items: [
        CustomBottomSheetItem(
          name: 'Stop',
          color: ImColor.primaryRed,
          fontWeight: FontWeight.w500,
          onTap: () {
            setState(() {
              _isSharing = !_isSharing;
            });
            liveLocationManager.disableLiveLocation(
              friendId: widget.chat.friend_id,
            );
            LiveLocationManager.enable = false;
            widget.onChanged(_isSharing);
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  void _enableShareBottomSheet(BuildContext context) {
    CustomBottomSheetDialog.showCustomModalBottomSheet(
      ctx: context,
      title: 'Sharing duration',
      titleSize: ImFontSize.normal,
      titleColor: ImColor.black48,
      items: [
        CustomBottomSheetItem(
          name: 'For 15 minutes',
          onTap: () {
            shareLiveLocation(context, const Duration(minutes: 15));
          },
        ),
        CustomBottomSheetItem(
          name: 'For 1 hour',
          onTap: () {
            shareLiveLocation(context, const Duration(hours: 1));
          },
        ),
        CustomBottomSheetItem(
          name: 'For 8 hours',
          onTap: () {
            shareLiveLocation(context, const Duration(hours: 8));
          },
        ),
        CustomBottomSheetItem(
          name: 'Until I turn it off',
          onTap: () {
            shareLiveLocation(context, const Duration(days: 7));
          },
        ),
      ],
    );
  }

  void shareLiveLocation(BuildContext context, Duration duration) {
    setState(() {
      _isSharing = !_isSharing;
    });
    liveLocationManager.enableLiveLocation(
      friendId: widget.chat.friend_id,
      duration: duration,
    );
    LiveLocationManager.enable = true;
    widget.onChanged(_isSharing);
    Navigator.of(context).pop();
  }
}
