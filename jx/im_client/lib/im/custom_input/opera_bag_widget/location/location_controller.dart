import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jxim_client/firebase_options.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/utils/live_location_utils.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';

// import 'package:location/location.dart' show Location;
// import 'package:location/location.dart' show LocationData;

enum GRANTED {
  loading,
  denied,
  grant,
}

class LocationController extends GetxController {
  static LatLng cachedLocation = const LatLng(0, 0);
  static List<Map<String, dynamic>> cachedNearbyLocations = [];

  final nearbyLocations = <Map<String, dynamic>>[].obs;

  final Completer<GoogleMapController> gooController =
      Completer<GoogleMapController>();
  final selectedIndex = (-1).obs;
  final granted = GRANTED.loading.obs;
  final marker = <Marker>{}.obs;
  final isSending = false.obs;
  final currentLocation = const LatLng(1.28000, 103.85000).obs;
  final avatar = Rxn<Widget>();
  final globalKey = GlobalKey();
  late Position currentPosition;

  bool get isSameLocation {
    return (cachedLocation.latitude == currentLocation.value.latitude) &&
        (cachedLocation.longitude == currentLocation.value.longitude);
  }

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init() async {
    currentLocation.value = cachedLocation;
    nearbyLocations.value = cachedNearbyLocations;
    await getPermissionAndLocation();
    avatar.value = await liveLocationUtils.getAvatar();
    await Future.delayed(const Duration(milliseconds: 500));
    addMarkerAndAnimateCamera();
  }

  Future<void> getPermissionAndLocation() async {
    try {
      final serviceEnabled = await checkService();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        // showErrorToast(
        //     'Location services are disabled, Please try again later!');
      }
      final hasPermission = await checkPermission();
      if (hasPermission) {
        granted.value = hasPermission ? GRANTED.grant : GRANTED.denied;
      } else {
        final isGranted = await requestPermission();
        granted.value = isGranted ? GRANTED.grant : GRANTED.denied;
        if (!isGranted) {
          debugPrint('Location services denied.');
          // showErrorToast(
          // 'Location services is denied, please enable permission!');
        }
      }
      final position = await getCurrentPosition();
      currentPosition = position;
      currentLocation.value = LatLng(position.latitude, position.longitude);
      if (!isSameLocation || cachedNearbyLocations.isEmpty) {
        cachedLocation = LatLng(position.latitude, position.longitude);
        getNearbyLocations();
      }
    } catch (e) {
      debugPrint('Location services error: $e');
      // showErrorToast('Location services has error:  $e');
      return;
    }
  }

  Future<void> addMarkerAndAnimateCamera() async {
    final icon = await getMarkerIconByAvatar();
    final position = currentPosition;
    marker.add(
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(position.latitude, position.longitude),
        icon: icon,
      ),
    );
    moveCameraToTargetPosition(
      currentPosition.latitude,
      currentPosition.longitude,
    );
  }

  Future<void> moveCameraToTargetPosition(
    double latitude,
    double longitude,
  ) async {
    final mapController = await gooController.future;
    return mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
      ),
    );
  }

  Future<bool> checkService() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return [LocationPermission.whileInUse, LocationPermission.always]
        .contains(permission);
  }

  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return [LocationPermission.whileInUse, LocationPermission.always]
        .contains(permission);
  }

  Future<Position> getCurrentPosition() async {
    final currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return currentPosition;
  }

  void onMapCreated(GoogleMapController mapController) {
    gooController.complete(mapController);
  }

  Future<BitmapDescriptor> getMarkerIconByAvatar() async {
    final byte = await liveLocationUtils.widgetToImage(globalKey);
    final icon = BitmapDescriptor.fromBytes(
      byte ?? Uint8List(0),
      size: const Size(54, 54),
    );
    return icon;
  }

  Future<Placemark> getAddressFromLalo(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    return placemarks.first;
  }

  Future<List<Map<String, dynamic>>> searchNearbyPlaces(
    double la,
    double lo,
  ) async {
    const String apiUrl =
        'https://places.googleapis.com/v1/places:searchNearby';
    final String apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;

    final Map<String, dynamic> requestBody = {
      "maxResultCount": 10,
      "locationRestriction": {
        "circle": {
          "center": {"latitude": la, "longitude": lo},
          "radius": 500.0,
        },
      },
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'places.displayName,places.formattedAddress,places.location,places.primaryType',
    };

    http.Client client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Request successful, you can handle the response here
        pdebug("Location service response: ${response.body}");
        final result = jsonDecode(response.body);
        return (result['places'] as List).map((e) {
          final data = {
            "name": e['displayName']['text'],
            "address": e['formattedAddress'],
            "category": e['primaryType'],
            "latitude": e['location']['latitude'],
            "longitude": e['location']['longitude'],
          };
          return data;
        }).toList();
      } else {
        // Request failed
        pdebug("Error: ${response.statusCode} - ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      debugPrint('Location: searchNearbyPlaces Error $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<void> getNearbyLocations() async {
    try {
      nearbyLocations.value = await searchNearbyPlaces(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      pdebug('Location: $nearbyLocations');
      if (nearbyLocations.isNotEmpty) {
        cachedNearbyLocations = nearbyLocations;
      } else {
        if (!connectivityMgr.hasNetwork()) {
          nearbyLocations.value = cachedNearbyLocations;
        }
      }
    } catch (e) {
      debugPrint('Location: getNearbyLocations Error $e');
    }
  }
}
