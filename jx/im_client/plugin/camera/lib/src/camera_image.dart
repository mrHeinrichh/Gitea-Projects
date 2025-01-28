import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';

class Plane {
  Plane._fromPlatformInterface(CameraImagePlane plane)
      : bytes = plane.bytes,
        bytesPerPixel = plane.bytesPerPixel,
        bytesPerRow = plane.bytesPerRow,
        height = plane.height,
        width = plane.width;

  Plane._fromPlatformData(Map<dynamic, dynamic> data)
      : bytes = data['bytes'] as Uint8List,
        bytesPerPixel = data['bytesPerPixel'] as int?,
        bytesPerRow = data['bytesPerRow'] as int,
        height = data['height'] as int?,
        width = data['width'] as int?;

  final Uint8List bytes;

  final int? bytesPerPixel;

  final int bytesPerRow;

  final int? height;

  final int? width;
}

class ImageFormat {
  ImageFormat._fromPlatformInterface(CameraImageFormat format)
      : group = format.group,
        raw = format.raw;

  ImageFormat._fromPlatformData(this.raw) : group = _asImageFormatGroup(raw);

  final ImageFormatGroup group;

  final dynamic raw;
}

ImageFormatGroup _asImageFormatGroup(dynamic rawFormat) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    switch (rawFormat) {
      case 35:
        return ImageFormatGroup.yuv420;

      case 256:
        return ImageFormatGroup.jpeg;
    }
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    switch (rawFormat) {
      case 875704438:
        return ImageFormatGroup.yuv420;

      case 1111970369:
        return ImageFormatGroup.bgra8888;
    }
  }

  return ImageFormatGroup.unknown;
}

class CameraImage {
  CameraImage.fromPlatformInterface(CameraImageData data)
      : format = ImageFormat._fromPlatformInterface(data.format),
        height = data.height,
        width = data.width,
        planes = List<Plane>.unmodifiable(data.planes.map<Plane>(
            (CameraImagePlane plane) => Plane._fromPlatformInterface(plane))),
        lensAperture = data.lensAperture,
        sensorExposureTime = data.sensorExposureTime,
        sensorSensitivity = data.sensorSensitivity;

  @Deprecated('Use fromPlatformInterface instead')
  CameraImage.fromPlatformData(Map<dynamic, dynamic> data)
      : format = ImageFormat._fromPlatformData(data['format']),
        height = data['height'] as int,
        width = data['width'] as int,
        lensAperture = data['lensAperture'] as double?,
        sensorExposureTime = data['sensorExposureTime'] as int?,
        sensorSensitivity = data['sensorSensitivity'] as double?,
        planes = List<Plane>.unmodifiable((data['planes'] as List<dynamic>)
            .map<Plane>((dynamic planeData) =>
                Plane._fromPlatformData(planeData as Map<dynamic, dynamic>)));

  final ImageFormat format;

  final int height;

  final int width;

  final List<Plane> planes;

  final double? lensAperture;

  final int? sensorExposureTime;

  final double? sensorSensitivity;
}
