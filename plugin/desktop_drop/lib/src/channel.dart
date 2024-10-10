import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'drop_item.dart';
import 'events.dart';
import 'utils/platform.dart' if (dart.library.html) 'utils/platform_web.dart';

typedef RawDropListener = void Function(DropEvent);

class DesktopDrop {
  static const MethodChannel _channel = MethodChannel('desktop_drop');

  DesktopDrop._();

  static final instance = DesktopDrop._();

  final _listeners = <RawDropListener>{};

  var _inited = false;

  Offset? _offset;

  List<XFile> fileList = [];

  void init() {
    if (_inited) {
      return;
    }
    _inited = true;
    _channel.setMethodCallHandler((call) async {
      try {
        return await _handleMethodChannel(call);
      } catch (e, s) {
        debugPrint('_handleMethodChannel: $e $s');
      }
    });
  }

  Future<void> _handleMethodChannel(MethodCall call) async {
    switch (call.method) {
      case "entered":
        final List parameter = call.arguments;
        _offset = Offset(parameter[0], parameter[1]);
        fileList = (parameter[2] as List).map((e) => XFile(e)).toList();
        _notifyEvent(
          DropEnterEvent(
            location: _offset!,
            files: fileList,
          ),
        );
        break;
      case "updated":
        if (_offset == null && Platform.isLinux) {
          final List parameter = call.arguments;
          _offset = Offset(parameter[0], parameter[1]);
          fileList = (parameter[2] as List).map((e) => XFile(e)).toList();
          _notifyEvent(
            DropEnterEvent(
              location: _offset!,
              files: fileList,
            ),
          );
          return;
        }
        final List parameter = call.arguments;
        _offset = Offset(parameter[0], parameter[1]);
        fileList = (parameter[2] as List).map((e) => XFile(e)).toList();
        _notifyEvent(
          DropUpdateEvent(
            location: _offset!,
            files: fileList,
          ),
        );
        break;
      case "exited":
        assert(_offset != null);
        _notifyEvent(
          DropExitEvent(
            location: _offset ?? Offset.zero,
            files: [],
          ),
        );
        _offset = null;
        break;
      case "performOperation":
        assert(_offset != null);
        final paths = (call.arguments as List).cast<String>();
        _notifyEvent(
          DropDoneEvent(
            location: _offset ?? Offset.zero,
            files: paths.map((e) => XFile(e)).toList(),
          ),
        );
        _offset = null;
        break;
      case "performOperation_linux":
        // gtk notify 'exit' before 'performOperation'.
        assert(_offset == null);
        final text = (call.arguments as List<dynamic>)[0] as String;
        final offset = ((call.arguments as List<dynamic>)[1] as List<dynamic>)
            .cast<double>();
        final paths = const LineSplitter().convert(text).map((e) {
          try {
            return Uri.tryParse(e)?.toFilePath() ?? '';
          } catch (error, stacktrace) {
            debugPrint('failed to parse linux path: $error $stacktrace');
          }
          return '';
        }).where((e) => e.isNotEmpty);
        _notifyEvent(DropDoneEvent(
          location: Offset(offset[0], offset[1]),
          files: paths.map((e) => XFile(e)).toList(),
        ));
        break;
      case "performOperation_web":
        assert(_offset != null);
        final results = (call.arguments as List)
            .cast<Map>()
            .map((e) => WebDropItem.fromJson(e.cast<String, dynamic>()))
            .map((e) => XFile(
                  e.uri,
                  name: e.name,
                  length: e.size,
                  lastModified: e.lastModified,
                  mimeType: e.type,
                ))
            .toList();
        _notifyEvent(
          DropDoneEvent(location: _offset ?? Offset.zero, files: results),
        );
        _offset = null;
        break;
      default:
        throw UnimplementedError('${call.method} not implement.');
    }
  }

  void _notifyEvent(DropEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  void addRawDropEventListener(RawDropListener listener) {
    assert(!_listeners.contains(listener));
    _listeners.add(listener);
  }

  void removeRawDropEventListener(RawDropListener listener) {
    assert(_listeners.contains(listener));
    _listeners.remove(listener);
  }
}
