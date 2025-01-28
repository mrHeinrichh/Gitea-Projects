import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/component/compass_btn.dart';
import 'package:jxim_client/im/custom_input/component/location_item.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/sheet_title_bar.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart' as jx;
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/no_permission_view.dart';

class LocationPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;

  const LocationPicker({super.key, required this.onLocationSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  @override
  void dispose() {
    Get.findAndDelete<LocationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LocationController(),
      builder: (LocationController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: colorBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.transparent,
                blurRadius: 0.0,
                offset: Offset(0.0, -1.0),
              ),
            ],
          ),
          child: Obx(() {
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
                _buildNearbyTitle(),
                _buildNearByLocation(controller),
              ],
            );
          }),
        );
      },
    );
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
              markers: controller.marker,
              zoomControlsEnabled: false,
              onMapCreated: controller.onMapCreated,
            ),
          ),
        ),
        Positioned(
          child: CompassBtn(
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
          ),
        ),
      ],
    );
  }

  Container _buildNearbyTitle() {
    return Container(
      decoration: const BoxDecoration(
        color: colorBackground,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorBorder,
            blurRadius: 0.0,
            offset: Offset(0.0, -1.0),
          ),
        ],
      ),
      height: 30,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        localized(nearLoc),
        style: jx.jxTextStyle.textStyle12(color: colorTextSecondary),
      ),
    );
  }

  Obx _buildNearByLocation(LocationController controller) {
    return Obx(
      () {
        final dataNull = controller.nearbyLocations.isEmpty;
        final itemCount = controller.nearbyLocations.length;
        final dataList = controller.nearbyLocations;
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

  Future<void> sendCurrentLocation(
    int type,
    LocationController controller, {
    Duration? duration,
  }) async {
    if (!connectivityMgr.hasNetwork()) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return;
    }
    if (controller.isSending.value) return;
    try {
      Toast.showLoadingPopup(
          context, DialogType.loading, localized(isLoadingText));
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
          dismissAllToast();
          if (type == 0) {
            Map<String, dynamic> data = {
              'name': place.name!,
              'address': place.street!,
              'longitude': position.longitude.toString(),
              'latitude': position.latitude.toString(),
              'city': '',
              'filePath': file.path,
              'url': '',
            };
            widget.onLocationSelected(data);
          }
          Get.back();
          pdebug('File saved successfully: ${file.path}');
          controller.isSending.value = false;
        });
      }
    } catch (e) {
      dismissAllToast();
      pdebug(e);
    }
  }

  void onNearbyItemTap(LocationController controller, int index) {
    if (!connectivityMgr.hasNetwork()) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return;
    }
    controller.selectedIndex.value = index;
    final dataList = controller.nearbyLocations;
    controller.marker.add(Marker(
      markerId: MarkerId(dataList[index]['name']),
      position:
          LatLng(dataList[index]['latitude'], dataList[index]['longitude']),
    ));
    sendNearbyLocation(controller);
  }

  Future<void> sendNearbyLocation(LocationController controller) async {
    controller.isSending.value = true;
    try {
      Toast.showLoadingPopup(
          context, DialogType.loading, localized(isLoadingText));
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
          dismissAllToast();
          Map<String, dynamic> data = {
            'name': dataList[controller.selectedIndex.value]['name'],
            'address': dataList[controller.selectedIndex.value]['address'],
            'longitude': dataList[controller.selectedIndex.value]['longitude']
                .toString(),
            'latitude':
                dataList[controller.selectedIndex.value]['latitude'].toString(),
            'city': '',
            'filePath': file.path,
            'url': '',
          };
          widget.onLocationSelected(data);
          Get.back();
          controller.isSending.value = false;
        });
      }
    } catch (e) {
      dismissAllToast();
      pdebug(e);
    }
  }
}
