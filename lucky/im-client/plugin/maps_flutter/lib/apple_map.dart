part of maps_flutter;

class AppleMap extends StatelessWidget {
  const AppleMap({
    super.key,
    required this.controller,
    this.onInitFinish,
    this.la,
    this.lo,
    this.isUserInteractionEnabled = true,
    this.isZoomEnabled = true,
  });

  final AppleMapController controller;

  final double? la;
  final double? lo;
  final Function? onInitFinish;
  final bool isUserInteractionEnabled;
  final bool isZoomEnabled;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      if (la != null && lo != null) ...{
        "coordinate": <String, double>{
          "latitude": la!,
          "longitude": lo!,
        }
      },
      "isUserInteractionEnabled": isUserInteractionEnabled,
      "isZoomEnabled": isZoomEnabled
    };
    return UiKitView(
      viewType: 'appleNativeMapView',
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      onPlatformViewCreated: (id) {
        controller.init(id);
        onInitFinish?.call();
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class AppleMapPreview extends StatelessWidget {
  const AppleMapPreview({super.key, required this.la, required this.lo});

  final double la;
  final double lo;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "coordinate": <String, double>{"latitude": la, "longitude": lo}
    };
    return UiKitView(
      viewType: 'appleNativePreviewMapView',
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
