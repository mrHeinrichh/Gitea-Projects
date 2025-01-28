import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/component/compass_btn.dart';
import 'package:jxim_client/im/custom_input/component/location_item.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/live_location_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';

import '../../../../utils/color.dart';
import '../../../../utils/lang_util.dart';
import '../../../../utils/localization/app_localizations.dart';
import '../../../../utils/theme/text_styles.dart';

import '../../../../views/component/no_permission_view.dart';
import '../../custom_bottom_sheet_dialog.dart';
import '../../custom_input_controller.dart';
import '../../sheet_title_bar.dart';

class LocationSelector extends StatefulWidget {
  final CustomInputController inputController;

  const LocationSelector({super.key, required this.inputController});

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: LocationController(),
        builder: (LocationController controller) {
          return Container(
            decoration: BoxDecoration(
              color: sheetTitleBarColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.w),
                topRight: Radius.circular(12.w),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 0.0.w,
                  offset: const Offset(0.0, -1.0),
                ),
              ],
            ),
            child: Obx(
              () {
                if (controller.granted.value == GRANTED.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.granted.value == GRANTED.denied) {
                  return NoPermissionView(
                    title: localized(registerLocation),
                    imageUrl: 'assets/svgs/no_location_permission.svg',
                    mainContent: localized(accessYourLocation),
                    subContent: localized(toSendLocation),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTitleBar(context),
                    _buildMap(context, controller),
                    _buildCurrentLocation(controller),
                    // buildShareLiveLocation(context, controller),
                    _buildNearbyTitle(),
                    _buildNearByLocation(controller),
                  ],
                );
              },
            ),
          );
        });
  }

  Widget _buildMap(BuildContext context, LocationController controller) {
    return Stack(
      children: [
        Positioned(
          left: 10000,
          child: RepaintBoundary(
            key: controller.globalKey,
            child: controller.avatar.value,
          ),
        ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.zero,
          height: 195,
          width: 1.sw,
          child: Obx(
            () => GoogleMap(
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              initialCameraPosition: CameraPosition(
                target: controller.currentLocation.value,
                zoom: 14.47,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              markers: controller.marker.value,
              zoomControlsEnabled: false,
              onMapCreated: controller.onMapCreated,
            ),
          ),
        ),
        Positioned(child: CompassBtn(
          onPressed: () async {
            final mapController = await controller.gooController.future;
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: controller.currentLocation.value,
                  zoom: 14.47,
                ),
              ),
            );
          },
        )),
      ],
    );
  }

  Container _buildNearbyTitle() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: dividerColor,
            blurRadius: 0.0.w,
            offset: const Offset(0.0, -1.0),
          ),
        ],
      ),
      height: 30,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        localized(nearLoc),
        style: jxTextStyle.textStyle12(color: JXColors.secondaryTextBlack),
      ),
    );
  }

  Obx _buildNearByLocation(LocationController controller) {
    return Obx(
      () {
        final dataNull = controller.nearbyLocations.isEmpty;
        final itemCount = controller.nearbyLocations.length;
        final dataList = controller.nearbyLocations.value;
        if (dataNull) {
          return const Center(child: CircularProgressIndicator());
        }
        return Expanded(
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return LocationItem(
                pngPath: 'assets/icons/icon_currentLocation.png',
                title: dataList[index]['name'],
                subTitle: dataList[index]['address'],
                onClick: () {
                  onNearbyItemTap(controller, index);
                },
                showDivider: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return SheetTitleBar(
      title: localized(registerLocation),
      divider: false,
    );
  }

  Widget buildShareLiveLocation(
      BuildContext ctx, LocationController controller) {
    return LocationItem(
      showDivider: false,
      title: localized(shareLiveLoc),
      subTitle: localized(shareYourLiveLoc),
      svgPath: 'assets/svgs/liveLocation.svg',
      onClick: () {
        CustomBottomSheetDialog.showCustomModalBottomSheet(
          ctx: ctx,
          title: 'Sharing duration',
          titleSize: ImFontSize.normal,
          titleColor: ImColor.black48,
          items: [
            CustomBottomSheetItem(
              name: 'For 15 minutes',
              onTap: () {
                shareLiveLocation(const Duration(minutes: 15), controller);
              },
            ),
            CustomBottomSheetItem(
              name: 'For 1 hour',
              onTap: () {
                shareLiveLocation(const Duration(hours: 1), controller);
              },
            ),
            CustomBottomSheetItem(
              name: 'For 8 hours',
              onTap: () {
                shareLiveLocation(const Duration(hours: 8), controller);
              },
            ),
            CustomBottomSheetItem(
              name: 'Until I turn it off',
              onTap: () {
                shareLiveLocation(const Duration(days: 7), controller);
              },
            ),
          ],
        );
      },
    );
  }

  // 共享位置消息
  void shareLiveLocation(Duration duration, LocationController controller) {
    final inputController = widget.inputController;
    Get.back();
    sendCurrentLocation(1, controller, duration: duration);
    liveLocationManager.enableLiveLocation(
      friendId: inputController.chatController.chat.friend_id,
      duration: duration,
    );
    LiveLocationManager.enable = true;
  }

  Widget _buildCurrentLocation(LocationController controller) {
    return LocationItem(
      pngPath: 'assets/icons/icon_currentLocation.png',
      title: localized(curLoc),
      subTitle: localized(accurateMeter),
      onClick: () {
        sendCurrentLocation(0, controller);
      },
      showDivider: false,
    );
  }

  // 发送位置消息到聊天室
  Future<void> sendCurrentLocation(int type, LocationController controller,
      {Duration? duration}) async {
    if (!connectivityMgr.hasNetwork()) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return;
    }
    final inputController = widget.inputController;
    if (controller.isSending.value) return;
    try {
      showLoading();
      controller.isSending.value = true;
      final position = await controller.getCurrentPosition();
      final place = await controller.getAddressFromLalo(position);
      final mapController = await controller.gooController.future;
      await controller.moveCameraToTargetPosition(
        controller.currentPosition.latitude,
        controller.currentPosition.longitude,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final imageData = await mapController.takeSnapshot();
      String path =
          "${downloadMgr.appDocumentRootPath}/Location${DateTime.now().millisecondsSinceEpoch}.jpg";
      if (imageData != null) {
        File(path).writeAsBytes(imageData).then((File file) {
          dismissLoading();
          if (type == 0) {
            objectMgr.chatMgr.sendLocation(
              file,
              inputController.chatId,
              place.street!,
              place.name!,
              position.longitude.toString(),
              position.latitude.toString(),
              type,
            );
          }
          if (type == 1) {
            objectMgr.chatMgr.sendLocation(
              file,
              inputController.chatId,
              'Live Location',
              '',
              position.longitude.toString(),
              position.latitude.toString(),
              type,
              startTime: DateTime.now().millisecondsSinceEpoch,
              duration: duration?.inMilliseconds,
            );
          }
          Get.back();
          pdebug('File saved successfully: ${file.path}');
          controller.isSending.value = false;
          playSendMessageSound();
        });
      }
    } catch (e) {
      dismissLoading();
      pdebug(e);
    }
  }

  void onNearbyItemTap(LocationController controller, int index) {
    if (!connectivityMgr.hasNetwork()) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return;
    }
    controller.selectedIndex.value = index;
    final dataList = controller.nearbyLocations.value;
    controller.marker.add(Marker(
      markerId: MarkerId(dataList[index]['name']),
      position:
          LatLng(dataList[index]['latitude'], dataList[index]['longitude']),
    ));
    sendNearbyLocation(controller);
  }

  Future<void> sendNearbyLocation(LocationController controller) async {
    final inputController = widget.inputController;
    controller.isSending.value = true;
    try {
      showLoading();
      final mapController = await controller.gooController.future;
      final selectedPosition =
          controller.nearbyLocations[controller.selectedIndex.value];
      await controller.moveCameraToTargetPosition(
        selectedPosition['latitude'],
        selectedPosition['longitude'],
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final imageData = await mapController.takeSnapshot();
      String path =
          "${downloadMgr.appDocumentRootPath}/Location${DateTime.now().millisecondsSinceEpoch}.jpg";
      if (imageData != null) {
        final dataList = controller.nearbyLocations;
        File(path).writeAsBytes(imageData).then((File file) {
          dismissLoading();
          objectMgr.chatMgr.sendLocation(
            file,
            inputController.chatId,
            dataList[controller.selectedIndex.value]['name'],
            dataList[controller.selectedIndex.value]['address'],
            dataList[controller.selectedIndex.value]['longitude'].toString(),
            dataList[controller.selectedIndex.value]['latitude'].toString(),
            0,
          );
          Get.back();
          pdebug('File saved successfully: ${file.path}');
          controller.isSending.value = false;
          playSendMessageSound();
        });
      }
    } catch (e) {
      dismissLoading();
      pdebug(e);
    }
  }

  void playSendMessageSound() {
    if (Get.isRegistered<CustomInputController>()) {
      final controller = Get.find<CustomInputController>();
      controller.playSendMessageSound();
    }
  }
}
