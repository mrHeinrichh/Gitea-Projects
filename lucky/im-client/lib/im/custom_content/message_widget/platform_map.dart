import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_flutter/maps_flutter.dart';

class PlatformMapBottomSheet extends StatelessWidget {
  const PlatformMapBottomSheet({super.key, required this.la, required this.lo});

  final double la;
  final double lo;

  @override
  Widget build(BuildContext context) {
    AppleMapController appleMapController = AppleMapController();
    final Completer<GoogleMapController> _controller =
        Completer<GoogleMapController>();
    return Expanded(
      child: Platform.isIOS
          ? AppleMap(
              controller: appleMapController,
              la: la,
              lo: lo,
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(la, lo),
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) async {
                _controller.complete(controller);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('My'),
                  position: LatLng(la, lo),
                )
              },
            ),
    );
  }
}
