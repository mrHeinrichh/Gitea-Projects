import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/live_location_utils.dart';

class GroupLocationLiveMap extends StatefulWidget {
  final Chat chat;
  final MessageMyLocation messageLocation;
  final String role;

  const GroupLocationLiveMap({
    super.key,
    required this.chat,
    required this.messageLocation,
    required this.role,
  });

  static Completer<GoogleMapController> googleMapController =
      Completer<GoogleMapController>();

  @override
  State<GroupLocationLiveMap> createState() => _GroupLocationLiveMapState();
}

class _GroupLocationLiveMapState extends State<GroupLocationLiveMap> {
  final userId = objectMgr.localStorageMgr.userID.toString();
  BitmapDescriptor iconMe = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconFriend = BitmapDescriptor.defaultMarker;
  String nicknameMe = '';
  String nicknameFriend = '';
  final globalKey1 = GlobalKey();
  final globalKey2 = GlobalKey();

  bool added = false;

  @override
  void initState() {
    _getAvatarByNickname();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 10000,
          child: RepaintBoundary(
            key: globalKey1,
            child: liveLocationUtils.getAvatarByNickname(nicknameMe),
          ),
        ),
        Positioned(
          left: 10000,
          child: RepaintBoundary(
            key: globalKey2,
            child: liveLocationUtils.getAvatarByNickname(nicknameMe),
          ),
        ),
        StreamBuilder(
          stream: FirebaseFirestore.instance.collection('location').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            /// snapshot.connectionState
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                debugPrint('[Live Location]: no data');
                return const Center(child: CircularProgressIndicator());
              case ConnectionState.waiting:
                debugPrint('[Live Location]: waiting data');
                return const Center(child: CircularProgressIndicator());
              case ConnectionState.active:
                if (snapshot.hasError) {
                  debugPrint('[Live Location]: has error');
                  return const Center(child: CircularProgressIndicator());
                } else {
                  // pdebug('---------Stream---------${snapshot}');
                  if (added) {
                    _animateMap(snapshot);
                  }
                  return _buildMap(snapshot);
                }
              case ConnectionState.done:
                debugPrint('[Live Location]: has error');
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ],
    );
  }

  GoogleMap _buildMap(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    final friendId = widget.chat.friend_id.toString();
    final friendEl =
        snapshot.data!.docs.where((element) => element.id == friendId);

    return GoogleMap(
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        Marker(
          markerId: MarkerId(userId),
          position: LatLng(
            snapshot.data!.docs
                .singleWhere((element) => element.id == userId)['latitude'],
            snapshot.data!.docs
                .singleWhere((element) => element.id == userId)['longitude'],
          ),
          icon: widget.role == 'me' ? iconMe : iconFriend,
          infoWindow: const InfoWindow(title: 'Go'),
        ),
        if (friendEl.isNotEmpty)
          Marker(
            markerId: MarkerId(friendId),
            position: LatLng(
              snapshot.data!.docs
                  .singleWhere((element) => element.id == friendId)['latitude'],
              snapshot.data!.docs.singleWhere(
                  (element) => element.id == friendId)['longitude'],
            ),
            icon: widget.role == 'me' ? iconFriend : iconMe,
            infoWindow: const InfoWindow(title: 'Go'),
          ),
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          snapshot.data!.docs
              .singleWhere((element) => element.id == userId)['latitude'],
          snapshot.data!.docs
              .singleWhere((element) => element.id == userId)['longitude'],
        ),
        zoom: 14.47,
      ),
      onMapCreated: (GoogleMapController controller) async {
        if (!GroupLocationLiveMap.googleMapController.isCompleted) {
          GroupLocationLiveMap.googleMapController.complete(controller);
        }
        added = true;
      },
    );
  }

  Future<void> _animateMap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    final userId = objectMgr.localStorageMgr.userID.toString();
    final controller = await GroupLocationLiveMap.googleMapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            snapshot.data!.docs
                .singleWhere((element) => element.id == userId)['latitude'],
            snapshot.data!.docs
                .singleWhere((element) => element.id == userId)['longitude'],
          ),
          zoom: 14.47,
        ),
      ),
    );
  }

  Future<void> _getAvatarByNickname() async {
    final name1 = await liveLocationUtils.getShortNameById(widget.chat.userId);
    final name2 =
        await liveLocationUtils.getShortNameById(widget.chat.friend_id);

    setState(() {
      nicknameMe = name1 ?? '';
      nicknameFriend = name2 ?? '';
    });

    await Future.delayed(
        const Duration(milliseconds: 200)); // 延迟一下，不然拿不到paint数据

    final byte1 = await liveLocationUtils.widgetToImage(globalKey1);
    final byte2 = await liveLocationUtils.widgetToImage(globalKey2);

    final icon1 = await BitmapDescriptor.fromBytes(
      byte1 ?? Uint8List(0),
      size: const Size(54, 54),
    );
    final icon2 = await BitmapDescriptor.fromBytes(
      byte2 ?? Uint8List(0),
      size: const Size(54, 54),
    );

    setState(() {
      iconMe = icon1;
      iconFriend = icon2;
    });
  }
}
