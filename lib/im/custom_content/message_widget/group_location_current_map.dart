import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:jxim_client/im/custom_input/component/compass_btn.dart';

class GroupLocationCurrentMap extends StatefulWidget {
  final String latitude;
  final String longitude;

  const GroupLocationCurrentMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<GroupLocationCurrentMap> createState() =>
      _GroupLocationCurrentMapState();
}

class _GroupLocationCurrentMapState extends State<GroupLocationCurrentMap> {
  final Completer<GoogleMapController> googleMapController =
      Completer<GoogleMapController>();
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  void getUserLocation() async {
    // 获取用户位置
    userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // 用户位置获取后，构建地图
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // if (Platform.isIOS)
    //   return AppleMap(
    //     controller: widget.appleMapController,
    //     la: double.parse(widget.messageLocation.latitude),
    //     lo: double.parse(widget.messageLocation.longitude),
    //   );
    return Stack(children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            double.parse(widget.latitude),
            double.parse(widget.longitude),
          ),
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onMapCreated: (GoogleMapController controller) async {
          if (!googleMapController.isCompleted) {
            googleMapController.complete(controller);
          }
        },
        markers: {
          Marker(
            markerId: const MarkerId('My'),
            position: LatLng(
              double.parse(widget.latitude),
              double.parse(widget.longitude),
            ),
          )
        },
      ),
      Positioned(
        child: CompassBtn(onPressed: () async {
          final mapController = await googleMapController.future;
          if(userPosition != null) {
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(userPosition!.latitude, userPosition!.longitude),
                  zoom: 16,
                ),
              ),
            );
          }
        }),
      ),
    ]);
  }
}
