// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;

import 'package:events_widget/events_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/flutter_pasteboard.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sys_oprate_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/material_magnifer.dart';

// import 'localizations.dart';
// import 'text_selection_toolbar.dart';
// import 'text_selection_toolbar_button.dart';
// import 'theme.dart';

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleOverlap = 1.5;
// Extracted from https://developer.apple.com/design/resources/.
const double _kSelectionHandleRadius = 9;

// Minimal padding from tip of the selection toolbar arrow to horizontal edges of the
// screen. Eyeballed value.
const double _kArrowScreenPadding = 26.0;

const double _kHandleSize = 22.0;
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

// Generates the child that's passed into CupertinoTextSelectionToolbar.
class _ExtentMyTextSelectionControlsToolbar extends StatefulWidget {
  const _ExtentMyTextSelectionControlsToolbar({
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.handleNewline,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.translateY,
  });

  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final VoidCallback? handleNewline;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final double translateY;

  @override
  _ExtentMyTextSelectionControlsToolbarState createState() =>
      _ExtentMyTextSelectionControlsToolbarState();
}

class _ExtentMyTextSelectionControlsToolbarState
    extends State<_ExtentMyTextSelectionControlsToolbar> {
  ValueListenable<ClipboardStatus>? _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.handlePaste != null) {
      _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      getImgCopyData();
    }
  }

  bool isPermission = false;
  bool _haveImgPasteData = false;
  dynamic _imgPasteData;

  Future<void> getImgCopyData() async {
    //如果剪切板有获取到图片的数据

    var rep = await FlutterPasteboard.image;
    if (rep is Uint8List) {
      // File ff = File("/storage/emulated/0/sogou/.expression/");
      _imgPasteData = rep;
    } else if (rep is Uri) {
      await _getImgPasteDataByFile(rep.path);
    } else if (rep is String) {
      await _getImgPasteDataByFile(rep);
    }
    _haveImgPasteData =
        _imgPasteData != null && _imgPasteData!.length > 0 ? true : false;
    ExtentMyTextSelectionControls.imgPasteData = _imgPasteData;
    setState(() {});
  }

  Future<void> _getImgPasteDataByFile(String path) async {
    // android暂时不支持图片粘贴，这个权限询问暂时注释掉
    // if (Platform.isAndroid && !isPermission) {
    //   if (await Permission.storage.request().isGranted) {
    //     isPermission = true;
    //   }
    // }

    if (isPermission) {
      File f = File(path);
      if (f.existsSync()) {
        _imgPasteData = f.readAsBytesSync();
      }
    } else {
      _imgPasteData = path;
      copyToClipboard(path);
    }
  }

  @override
  void didUpdateWidget(_ExtentMyTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus != widget.clipboardStatus) {
      if (_clipboardStatus != null) {
        _clipboardStatus!.removeListener(_onChangedClipboardStatus);
      }
      _clipboardStatus = widget.clipboardStatus;
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      if (widget.handlePaste != null) {
        getImgCopyData();
      }
    }
  }

  @override
  void dispose() {
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (_clipboardStatus != null) {
      _clipboardStatus!.removeListener(_onChangedClipboardStatus);
      _haveImgPasteData = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EventsWidget(
      data: objectMgr.sysOprateMgr,
      eventTypes: const [SysOprateMgr.eventShowBigGlass],
      builder: (context) {
        if (objectMgr.sysOprateMgr.showBigGlass) {
          return _buildMagnifer();
        }
        return _buildToolBar();
      },
    );
  }

  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;

  Widget _buildMagnifer() {
    TextSelectionPoint point = widget.endpoints[0];
    if (widget.endpoints.length > 1) {
      if (offset1 != widget.endpoints[0].point) {
        point = widget.endpoints[0];
        offset1 = point.point;
      }
      if (offset2 != widget.endpoints[1].point) {
        point = widget.endpoints[1];
        offset2 = point.point;
      }
    }

    final TextSelectionPoint startTextSelectionPoint = point;

    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + startTextSelectionPoint.point.dx,
      widget.globalEditableRegion.top +
          startTextSelectionPoint.point.dy -
          widget.textLineHeight -
          _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + startTextSelectionPoint.point.dx,
      widget.globalEditableRegion.top +
          startTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    return MaterialMagnifier(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      textLineHeight: widget.textLineHeight,
      translateY: widget.translateY,
    );
  }

  Widget _buildToolBar() {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null &&
        _clipboardStatus!.value == ClipboardStatus.unknown &&
        !_haveImgPasteData) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it, assuming there's always enough
    // space at the bottom in this case.
    final double anchorX =
        (widget.selectionMidpoint.dx + widget.globalEditableRegion.left).clamp(
      _kArrowScreenPadding + mediaQuery.padding.left,
      mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
    );

    // The y-coordinate has to be calculated instead of directly quoting
    // selectionMidpoint.dy, since the caller
    // (TextSelectionOverlay._buildToolbar) does not know whether the toolbar is
    // going to be facing up or down.
    final Offset anchorAbove = Offset(
      anchorX,
      widget.endpoints.first.point.dy -
          widget.textLineHeight +
          widget.globalEditableRegion.top,
    );
    final Offset anchorBelow = Offset(
      anchorX,
      widget.endpoints.last.point.dy + widget.globalEditableRegion.top,
    );

    final List<Widget> items = <Widget>[];
    final CupertinoLocalizations localizations =
        CupertinoLocalizations.of(context);
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      items.add(
        CupertinoTextSelectionToolbarButton.text(
          onPressed: onPressed,
          text: text,
        ),
      );
    }

    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
    }
    if (widget.handlePaste != null &&
        (_clipboardStatus!.value == ClipboardStatus.pasteable ||
            _haveImgPasteData)) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(
        localizations.selectAllButtonLabel,
        widget.handleSelectAll!,
      );
    }

    // 移除长按输入框出现 change line 功能
    // if (widget.handleNewline != null) {
    //   addToolbarButton(localized(chatTextChangeLine), widget.handleNewline!);
    // }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return CupertinoTextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: items,
    );
  }
}

/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double halfStrokeWidth = 1.0;
    final Paint paint = Paint()..color = color;
    final Rect circle = Rect.fromCircle(
      center: const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      radius: _kSelectionHandleRadius,
    );
    final Rect line = Rect.fromPoints(
      const Offset(
        _kSelectionHandleRadius - halfStrokeWidth,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(_kSelectionHandleRadius + halfStrokeWidth, size.height),
    );
    final Path path = Path()
      ..addOval(circle)
      // Draw line so it slightly overlaps the circle.
      ..addRect(line);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) =>
      color != oldPainter.color;
}

/// iOS Cupertino styled text selection controls.
class ExtentMyTextSelectionControls extends TextSelectionControls {
  ExtentMyTextSelectionControls({this.translateY = -75.0});

  final double translateY;

  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _ExtentMyTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      handleNewline: handleNewline,
      selectionMidpoint: position,
      textLineHeight: textLineHeight,
      translateY: translateY,
    );
  }

  static dynamic imgPasteData;
  static int pasteImgIndex = -1;

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    super.handlePaste(delegate);
    var imgData = ExtentMyTextSelectionControls.imgPasteData;
    if (imgData != null) {
      if (imgData is Uint8List && imgData.isNotEmpty) {
        if (pasteImgIndex == -1) {
          String? idxStr =
              objectMgr.localStorageMgr.read(LocalStorageMgr.PASTE_IMD_IDX);
          pasteImgIndex =
              idxStr != null && idxStr.isNotEmpty ? int.parse(idxStr) : 0;
        }
        //删除旧的
        int oldIdx = pasteImgIndex - 1;
        if (oldIdx >= 0) {
          File vFileOld = File(
            "${downloadMgr.appDocumentRootPath}/cache_pasted$oldIdx.jpg",
          );
          if (vFileOld.existsSync()) {
            vFileOld.deleteSync(recursive: true);
          }
        }
        String path =
            "${downloadMgr.appDocumentRootPath}/cache_pasted$pasteImgIndex.jpg";
        pasteImgIndex++;
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.PASTE_IMD_IDX, pasteImgIndex.toString());
        // objectMgr.localStorageMgr.remove(LocalStorageMgr.PASTE_IMD_IDX);
        File vFileSave = File(path);
        if (!vFileSave.existsSync()) {
          vFileSave.createSync(recursive: true);
        }
        var ff = await vFileSave.writeAsBytes(imgData, flush: true);
        if (ff.existsSync()) {
          if (handlerPasteSend != null) {
            handlerPasteSend!(ff);
          }
        }
        return;
      } else if (imgData is String) {}
    }
  }

  Function? handlerPasteSend;
  VoidCallback? handleNewline;

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
    double? startGlyphHeight,
    double? endGlyphHeight,
  ]) {
    // iOS selection handles do not respond to taps.

    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    startGlyphHeight = startGlyphHeight ?? textLineHeight;
    endGlyphHeight = endGlyphHeight ?? textLineHeight;

    final Size desiredSize;
    final Widget handle;

    const Widget customPaint = CustomPaint(
      painter: _TextSelectionHandlePainter(Colors.red),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        desiredSize = getHandleSize(startGlyphHeight);
        handle = SizedBox.fromSize(
          size: desiredSize,
          child: customPaint,
        );
        return handle;
      case TextSelectionHandleType.right:
        desiredSize = getHandleSize(endGlyphHeight);
        handle = SizedBox.fromSize(
          size: desiredSize,
          child: customPaint,
        );
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(
    TextSelectionHandleType type,
    double textLineHeight, [
    double? startGlyphHeight,
    double? endGlyphHeight,
  ]) {
    startGlyphHeight = startGlyphHeight ?? textLineHeight;
    endGlyphHeight = endGlyphHeight ?? textLineHeight;

    final Size handleSize;

    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        handleSize = getHandleSize(startGlyphHeight);
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        handleSize = getHandleSize(endGlyphHeight);
        return Offset(
          handleSize.width / 2,
          handleSize.height -
              2 * _kSelectionHandleRadius +
              _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      case TextSelectionHandleType.collapsed:
        handleSize = getHandleSize(textLineHeight);
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

// /// Text selection controls that follows iOS design conventions.
// final TextSelectionControls extentMyTextSelectionControls = ExtentMyTextSelectionControls();
