import 'package:flutter/material.dart';


class VideoOverlay {
  VideoOverlay();

  OverlayEntry? _entry;

  OverlayEntry createAlignOverlay({Widget? child}) {
    return OverlayEntry(
      builder: (_) {
        return child ??
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.red,
              ),
              child: const Text('Align Overlay'),
            );
      },
    );
  }

  void insert(BuildContext context, {Widget? child}) {
    _entry = createAlignOverlay(child: child);
    Overlay.of(context).insert(_entry!);
  }

  void close() {
    _entry?.remove();
    _entry = null;
  }
}
