import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiver/core.dart';

typedef OnLatestImageAvailable = Function(CameraImage image);

Future<List<CameraDescription>> availableCameras() async {
  return CameraPlatform.instance.availableCameras();
}

void _unawaited(Future<void>? future) {}

class CameraValue {
  const CameraValue({
    required this.isInitialized,
    this.errorDescription,
    this.previewSize,
    required this.isRecordingVideo,
    required this.isTakingPicture,
    required this.isStreamingImages,
    required bool isRecordingPaused,
    required this.flashMode,
    required this.exposureMode,
    required this.focusMode,
    required this.exposurePointSupported,
    required this.focusPointSupported,
    required this.deviceOrientation,
    this.lockedCaptureOrientation,
    this.recordingOrientation,
    this.isPreviewPaused = false,
    this.previewPauseOrientation,
  }) : _isRecordingPaused = isRecordingPaused;

  const CameraValue.uninitialized()
      : this(
          isInitialized: false,
          isRecordingVideo: false,
          isTakingPicture: false,
          isStreamingImages: false,
          isRecordingPaused: false,
          flashMode: FlashMode.auto,
          exposureMode: ExposureMode.auto,
          exposurePointSupported: false,
          focusMode: FocusMode.auto,
          focusPointSupported: false,
          deviceOrientation: DeviceOrientation.portraitUp,
          isPreviewPaused: false,
        );

  final bool isInitialized;

  final bool isTakingPicture;

  final bool isRecordingVideo;

  final bool isStreamingImages;

  final bool _isRecordingPaused;

  final bool isPreviewPaused;

  final DeviceOrientation? previewPauseOrientation;

  bool get isRecordingPaused => isRecordingVideo && _isRecordingPaused;

  final String? errorDescription;

  final Size? previewSize;

  double get aspectRatio => previewSize!.width / previewSize!.height;

  bool get hasError => errorDescription != null;

  final FlashMode flashMode;

  final ExposureMode exposureMode;

  final FocusMode focusMode;

  final bool exposurePointSupported;

  final bool focusPointSupported;

  final DeviceOrientation deviceOrientation;

  final DeviceOrientation? lockedCaptureOrientation;

  bool get isCaptureOrientationLocked => lockedCaptureOrientation != null;

  final DeviceOrientation? recordingOrientation;

  CameraValue copyWith({
    bool? isInitialized,
    bool? isRecordingVideo,
    bool? isTakingPicture,
    bool? isStreamingImages,
    String? errorDescription,
    Size? previewSize,
    bool? isRecordingPaused,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    bool? exposurePointSupported,
    bool? focusPointSupported,
    DeviceOrientation? deviceOrientation,
    Optional<DeviceOrientation>? lockedCaptureOrientation,
    Optional<DeviceOrientation>? recordingOrientation,
    bool? isPreviewPaused,
    Optional<DeviceOrientation>? previewPauseOrientation,
  }) {
    return CameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription,
      previewSize: previewSize ?? this.previewSize,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      isStreamingImages: isStreamingImages ?? this.isStreamingImages,
      isRecordingPaused: isRecordingPaused ?? _isRecordingPaused,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      exposurePointSupported:
          exposurePointSupported ?? this.exposurePointSupported,
      focusPointSupported: focusPointSupported ?? this.focusPointSupported,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      lockedCaptureOrientation: lockedCaptureOrientation == null
          ? this.lockedCaptureOrientation
          : lockedCaptureOrientation.orNull,
      recordingOrientation: recordingOrientation == null
          ? this.recordingOrientation
          : recordingOrientation.orNull,
      isPreviewPaused: isPreviewPaused ?? this.isPreviewPaused,
      previewPauseOrientation: previewPauseOrientation == null
          ? this.previewPauseOrientation
          : previewPauseOrientation.orNull,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CameraValue')}('
        'isRecordingVideo: $isRecordingVideo, '
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize, '
        'isStreamingImages: $isStreamingImages, '
        'flashMode: $flashMode, '
        'exposureMode: $exposureMode, '
        'focusMode: $focusMode, '
        'exposurePointSupported: $exposurePointSupported, '
        'focusPointSupported: $focusPointSupported, '
        'deviceOrientation: $deviceOrientation, '
        'lockedCaptureOrientation: $lockedCaptureOrientation, '
        'recordingOrientation: $recordingOrientation, '
        'isPreviewPaused: $isPreviewPaused, '
        'previewPausedOrientation: $previewPauseOrientation)';
  }
}

class CameraController extends ValueNotifier<CameraValue> {
  CameraController(
    this.description,
    this.resolutionPreset, {
    this.enableAudio = true,
    this.imageFormatGroup,
  }) : super(const CameraValue.uninitialized());

  final CameraDescription description;

  final ResolutionPreset resolutionPreset;

  final bool enableAudio;

  final ImageFormatGroup? imageFormatGroup;

  @visibleForTesting
  static const int kUninitializedCameraId = -1;
  int _cameraId = kUninitializedCameraId;

  bool _isDisposed = false;
  StreamSubscription<CameraImageData>? _imageStreamSubscription;
  FutureOr<bool>? _initCalled;
  StreamSubscription<DeviceOrientationChangedEvent>?
      _deviceOrientationSubscription;

  void debugCheckIsDisposed() {
    assert(_isDisposed);
  }

  int get cameraId => _cameraId;

  Future<void> initialize() async {
    if (_isDisposed) {
      throw CameraException(
        'Disposed CameraController',
        'initialize was called on a disposed CameraController',
      );
    }
    try {
      final Completer<CameraInitializedEvent> initializeCompleter =
          Completer<CameraInitializedEvent>();

      _deviceOrientationSubscription = CameraPlatform.instance
          .onDeviceOrientationChanged()
          .listen((DeviceOrientationChangedEvent event) {
        value = value.copyWith(
          deviceOrientation: event.orientation,
        );
      });

      _cameraId = await CameraPlatform.instance.createCamera(
        description,
        resolutionPreset,
        enableAudio: enableAudio,
      );

      _unawaited(CameraPlatform.instance
          .onCameraInitialized(_cameraId)
          .first
          .then((CameraInitializedEvent event) {
        initializeCompleter.complete(event);
      }));

      await CameraPlatform.instance.initializeCamera(
        _cameraId,
        imageFormatGroup: imageFormatGroup ?? ImageFormatGroup.unknown,
      );

      value = value.copyWith(
        isInitialized: true,
        previewSize: await initializeCompleter.future
            .then((CameraInitializedEvent event) => Size(
                  event.previewWidth,
                  event.previewHeight,
                )),
        exposureMode: await initializeCompleter.future
            .then((CameraInitializedEvent event) => event.exposureMode),
        focusMode: await initializeCompleter.future
            .then((CameraInitializedEvent event) => event.focusMode),
        exposurePointSupported: await initializeCompleter.future.then(
            (CameraInitializedEvent event) => event.exposurePointSupported),
        focusPointSupported: await initializeCompleter.future
            .then((CameraInitializedEvent event) => event.focusPointSupported),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }

    _initCalled = true;
  }

  Future<void> prepareForVideoRecording() async {
    await CameraPlatform.instance.prepareForVideoRecording();
  }

  Future<void> pausePreview() async {
    if (value.isPreviewPaused) {
      return;
    }
    try {
      await CameraPlatform.instance.pausePreview(_cameraId);
      value = value.copyWith(
          isPreviewPaused: true,
          previewPauseOrientation: Optional<DeviceOrientation>.of(
              value.lockedCaptureOrientation ?? value.deviceOrientation));
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> resumePreview() async {
    if (!value.isPreviewPaused) {
      return;
    }
    try {
      await CameraPlatform.instance.resumePreview(_cameraId);
      value = value.copyWith(
          isPreviewPaused: false,
          previewPauseOrientation: const Optional<DeviceOrientation>.absent());
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<XFile> takePicture() async {
    _throwIfNotInitialized('takePicture');
    if (value.isTakingPicture) {
      throw CameraException(
        'Previous capture has not returned yet.',
        'takePicture was called before the previous capture returned.',
      );
    }
    try {
      value = value.copyWith(isTakingPicture: true);
      final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
      value = value.copyWith(isTakingPicture: false);
      return file;
    } on PlatformException catch (e) {
      value = value.copyWith(isTakingPicture: false);
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> startImageStream(OnLatestImageAvailable onAvailable) async {
    assert(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    _throwIfNotInitialized('startImageStream');
    if (value.isRecordingVideo) {
      throw CameraException(
        'A video recording is already started.',
        'startImageStream was called while a video is being recorded.',
      );
    }
    if (value.isStreamingImages) {
      throw CameraException(
        'A camera has started streaming images.',
        'startImageStream was called while a camera was streaming images.',
      );
    }

    try {
      _imageStreamSubscription = CameraPlatform.instance
          .onStreamedFrameAvailable(_cameraId)
          .listen((CameraImageData imageData) {
        onAvailable(CameraImage.fromPlatformInterface(imageData));
      });
      value = value.copyWith(isStreamingImages: true);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> stopImageStream() async {
    assert(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    _throwIfNotInitialized('stopImageStream');
    if (value.isRecordingVideo) {
      throw CameraException(
        'A video recording is already started.',
        'stopImageStream was called while a video is being recorded.',
      );
    }
    if (!value.isStreamingImages) {
      throw CameraException(
        'No camera is streaming images',
        'stopImageStream was called when no camera is streaming images.',
      );
    }

    try {
      value = value.copyWith(isStreamingImages: false);
      await _imageStreamSubscription?.cancel();
      _imageStreamSubscription = null;
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> startVideoRecording() async {
    _throwIfNotInitialized('startVideoRecording');
    if (value.isRecordingVideo) {
      throw CameraException(
        'A video recording is already started.',
        'startVideoRecording was called when a recording is already started.',
      );
    }
    if (value.isStreamingImages) {
      throw CameraException(
        'A camera has started streaming images.',
        'startVideoRecording was called while a camera was streaming images.',
      );
    }

    try {
      await CameraPlatform.instance.startVideoRecording(_cameraId);
      value = value.copyWith(
          isRecordingVideo: true,
          isRecordingPaused: false,
          recordingOrientation: Optional<DeviceOrientation>.of(
              value.lockedCaptureOrientation ?? value.deviceOrientation));
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<XFile> stopVideoRecording() async {
    _throwIfNotInitialized('stopVideoRecording');
    if (!value.isRecordingVideo) {
      throw CameraException(
        'No video is recording',
        'stopVideoRecording was called when no video is recording.',
      );
    }
    try {
      final XFile file =
          await CameraPlatform.instance.stopVideoRecording(_cameraId);
      value = value.copyWith(
        isRecordingVideo: false,
        recordingOrientation: const Optional<DeviceOrientation>.absent(),
      );
      return file;
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> pauseVideoRecording() async {
    _throwIfNotInitialized('pauseVideoRecording');
    if (!value.isRecordingVideo) {
      throw CameraException(
        'No video is recording',
        'pauseVideoRecording was called when no video is recording.',
      );
    }
    try {
      await CameraPlatform.instance.pauseVideoRecording(_cameraId);
      value = value.copyWith(isRecordingPaused: true);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> resumeVideoRecording() async {
    _throwIfNotInitialized('resumeVideoRecording');
    if (!value.isRecordingVideo) {
      throw CameraException(
        'No video is recording',
        'resumeVideoRecording was called when no video is recording.',
      );
    }
    try {
      await CameraPlatform.instance.resumeVideoRecording(_cameraId);
      value = value.copyWith(isRecordingPaused: false);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Widget buildPreview() {
    _throwIfNotInitialized('buildPreview');
    try {
      return CameraPlatform.instance.buildPreview(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> getMaxZoomLevel() {
    _throwIfNotInitialized('getMaxZoomLevel');
    try {
      return CameraPlatform.instance.getMaxZoomLevel(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> getMinZoomLevel() {
    _throwIfNotInitialized('getMinZoomLevel');
    try {
      return CameraPlatform.instance.getMinZoomLevel(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setZoomLevel(double zoom) {
    _throwIfNotInitialized('setZoomLevel');
    try {
      return CameraPlatform.instance.setZoomLevel(_cameraId, zoom);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    try {
      await CameraPlatform.instance.setFlashMode(_cameraId, mode);
      value = value.copyWith(flashMode: mode);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    try {
      await CameraPlatform.instance.setExposureMode(_cameraId, mode);
      value = value.copyWith(exposureMode: mode);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setExposurePoint(Offset? point) async {
    if (point != null &&
        (point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1)) {
      throw ArgumentError(
          'The values of point should be anywhere between (0,0) and (1,1).');
    }

    try {
      await CameraPlatform.instance.setExposurePoint(
        _cameraId,
        point == null
            ? null
            : Point<double>(
                point.dx,
                point.dy,
              ),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> getMinExposureOffset() async {
    _throwIfNotInitialized('getMinExposureOffset');
    try {
      return CameraPlatform.instance.getMinExposureOffset(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> getMaxExposureOffset() async {
    _throwIfNotInitialized('getMaxExposureOffset');
    try {
      return CameraPlatform.instance.getMaxExposureOffset(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> getExposureOffsetStepSize() async {
    _throwIfNotInitialized('getExposureOffsetStepSize');
    try {
      return CameraPlatform.instance.getExposureOffsetStepSize(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<double> setExposureOffset(double offset) async {
    _throwIfNotInitialized('setExposureOffset');

    final List<double> range = await Future.wait(
        <Future<double>>[getMinExposureOffset(), getMaxExposureOffset()]);
    if (offset < range[0] || offset > range[1]) {
      throw CameraException(
        'exposureOffsetOutOfBounds',
        'The provided exposure offset was outside the supported range for this device.',
      );
    }

    final double stepSize = await getExposureOffsetStepSize();
    if (stepSize > 0) {
      final double inv = 1.0 / stepSize;
      double roundedOffset = (offset * inv).roundToDouble() / inv;
      if (roundedOffset > range[1]) {
        roundedOffset = (offset * inv).floorToDouble() / inv;
      } else if (roundedOffset < range[0]) {
        roundedOffset = (offset * inv).ceilToDouble() / inv;
      }
      offset = roundedOffset;
    }

    try {
      return CameraPlatform.instance.setExposureOffset(_cameraId, offset);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> lockCaptureOrientation(
      {int? cameraId, DeviceOrientation? orientation}) async {
    try {
      await CameraPlatform.instance.lockCaptureOrientation(
          cameraId ?? _cameraId, orientation ?? value.deviceOrientation);
      if (!_isDisposed) {
        if (cameraId != -1) {
          value = value.copyWith(
              lockedCaptureOrientation: Optional<DeviceOrientation>.of(
                  orientation ?? value.deviceOrientation));
        }
      }
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    try {
      await CameraPlatform.instance.setFocusMode(_cameraId, mode);
      value = value.copyWith(focusMode: mode);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> unlockCaptureOrientation() async {
    try {
      await CameraPlatform.instance.unlockCaptureOrientation(_cameraId);
      value = value.copyWith(
          lockedCaptureOrientation: const Optional<DeviceOrientation>.absent());
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setFocusPoint(Offset? point) async {
    if (point != null &&
        (point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1)) {
      throw ArgumentError(
          'The values of point should be anywhere between (0,0) and (1,1).');
    }
    try {
      await CameraPlatform.instance.setFocusPoint(
        _cameraId,
        point == null
            ? null
            : Point<double>(
                point.dx,
                point.dy,
              ),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _unawaited(_deviceOrientationSubscription?.cancel());
    _isDisposed = true;
    if (_initCalled != null) {
      await _initCalled;
      await CameraPlatform.instance.dispose(_cameraId);
    }
    super.dispose();
  }

  void _throwIfNotInitialized(String functionName) {
    if (!value.isInitialized) {
      throw CameraException(
        'Uninitialized CameraController',
        '$functionName() was called on an uninitialized CameraController.',
      );
    }
    if (_isDisposed) {
      throw CameraException(
        'Disposed CameraController',
        '$functionName() was called on a disposed CameraController.',
      );
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }
}
