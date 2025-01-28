part of 'maps_flutter.dart';

class AppleMapController {
  late final MethodChannel channel;

  AppleMapController({this.getPermission, this.pinEvent});

  Function(bool)? getPermission;
  Function(Map)? pinEvent;

  init(int id) {
    channel = MethodChannel('map_view_flutter/$id');
    channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'pinCurrentLocation':
        final result = call.arguments;
        pinEvent?.call(call.arguments);
        Future.delayed(const Duration(seconds: 400), () {
          focus(la: result['latitude'], lo: result['longitude']);
        });
        break;
      case 'getPermission':
        getPermission?.call(call.arguments);
        break;
      default:
        throw MissingPluginException();
    }
  }

  Future<Map> getUserCoordinate() async {
    final data = await channel.invokeMethod('getCurrentUserCoordinate', {});
    if (data != null) {
      return data;
    }
    return {};
  }

  Future<Map> getAnnotationCoordinate() async {
    final data = await channel.invokeMethod('annotationLocation', {});
    if (data != null) {
      return data;
    }
    return {};
  }

  Future<Map> getAddress([Map? coordinate]) async {
    final data = await channel.invokeMethod('getAddress', coordinate ?? {});
    if (data != null) {
      return data;
    }
    return {};
  }

  Future<List> getNearbyLocation() async {
    final data = await channel.invokeMethod('getNearbyLocation', {});
    if (data != null) {
      return data;
    }
    return [];
  }

  void pinLocation({required double la, required double lo}) async {
    channel.invokeMethod('pinLocation', {"la": la, "lo": lo});
  }

  Future<Uint8List?> takeSnapshot([Uint8List? dataList]) async {
    final data =
        await channel.invokeMethod<Uint8List>('snapshot', {"data": dataList});
    return data;
  }

  void focus({required double la, required double lo}) async {
    channel.invokeMethod('focus', {"la": la, "lo": lo});
  }
}
