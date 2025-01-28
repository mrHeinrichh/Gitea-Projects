import 'package:cross_file/cross_file.dart';
import 'package:flutter/painting.dart';

abstract class DropEvent {
  Offset location;

  DropEvent(this.location);

  @override
  String toString() {
    return '$runtimeType($location)';
  }
}

class DropEnterEvent extends DropEvent {
  final List<XFile> files;

  DropEnterEvent({required this.files, required Offset location})
      : super(location);
}

class DropExitEvent extends DropEvent {
  final List<XFile> files;

  DropExitEvent({required this.files, required Offset location})
      : super(location);
}

class DropUpdateEvent extends DropEvent {
  final List<XFile> files;

  DropUpdateEvent({required this.files, required Offset location})
      : super(location);
}

class DropDoneEvent extends DropEvent {
  final List<XFile> files;

  DropDoneEvent({
    required Offset location,
    required this.files,
  }) : super(location);

  @override
  String toString() {
    return '$runtimeType($location, $files)';
  }
}
