import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fconsole/core/fconsole.dart';
import 'package:flutter_fconsole/delegate/custom_card_delegate.dart';
import 'package:flutter_fconsole/model/log.dart';
import 'package:flutter_fconsole/style/color.dart';
import 'package:flutter_fconsole/style/text.dart';
import 'package:flutter_fconsole/widget/messages.dart';
import 'package:flutter_fconsole/widget/show_fps.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tapped/tapped.dart';

part 'console_panel.dart';

part 'console_container.dart';

LinkedHashMap<Object, BuildContext> _contextMap = LinkedHashMap();

OverlayEntry? consoleEntry;

///show console btn
void showConsole({BuildContext? context}) {
  if (FConsole.instance.status.value == FConsoleStatus.hide) {
    FConsole.instance.status.value = FConsoleStatus.consoleBtn;
    context ??= _contextMap.values.first;
    _ConsoleTheme _consoleTheme = _ConsoleTheme.of(context)!;
    Widget consoleBtn = _consoleTheme.consoleBtn ?? _consoleBtn();

    Alignment consolePosition =
        _consoleTheme.consolePosition ?? Alignment(-0.8, 0.7);

    consoleEntry = OverlayEntry(builder: (ctx) {
      return ConsoleContainer(
        consoleBtn: consoleBtn,
        consolePosition: consolePosition,
      );
    });
    Overlay.of(context).insert(consoleEntry!);
  }
}

///hide console btn
void hideConsole({BuildContext? context}) {
  if (consoleEntry != null) {
    FConsole.instance.status.value = FConsoleStatus.hide;
    consoleEntry!.remove();
    consoleEntry = null;
  }
}

OverlayEntry? consolePanelEntry;

///show console panel
showConsolePanel(Function onHideTap, {BuildContext? context}) {
  context ??= _contextMap.values.first;
  consolePanelEntry = OverlayEntry(builder: (ctx) {
    return ConsolePanel(() {
      onHideTap();
      hideConsolePanel();
    });
  });
  Overlay.of(context).insert(consolePanelEntry!);
}

hideConsolePanel() {
  if (consolePanelEntry != null) {
    FConsole.instance.status.value = FConsoleStatus.consoleBtn;
    consolePanelEntry!.remove();
    consolePanelEntry = null;
  }
}

class ConsoleWidget extends StatefulWidget {
  /// 子组件，通常为App层
  final Widget child;

  /// 悬浮按钮组件
  final Widget? consoleBtn;

  /// 悬浮按钮配置
  final ConsoleOptions? options;

  /// 默认初始化位置
  final Alignment? consolePosition;

  ConsoleWidget({
    Key? key,
    required this.child,
    this.consolePosition,
    this.consoleBtn,
    this.options,
  }) : super(key: key);

  @override
  _ConsoleWidgetState createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  dispose() {
    _contextMap.remove(this);
    super.dispose();
  }

  initState() {
    super.initState();
    FConsole.instance.options = widget.options ?? ConsoleOptions();
    WidgetsBinding.instance.addPostFrameCallback((d) {
      if (FConsole.instance.options.displayMode == ConsoleDisplayMode.Always) {
        showConsole();
      }
    });
  }

  Widget build(BuildContext context) {
    return Material(
      child: _ConsoleTheme(
        consoleBtn: widget.consoleBtn,
        consolePosition: widget.consolePosition,
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Stack(
            textDirection: ui.TextDirection.ltr,
            children: [
              widget.child,
              Localizations(
                locale: const Locale("zh"),
                delegates: const [
                  GlobalCupertinoLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (ctx) {
                        _contextMap[this] = ctx;
                        return Container();
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsoleTheme extends InheritedWidget {
  final Widget? consoleBtn;
  final Widget child;
  final Alignment? consolePosition;

  const _ConsoleTheme({required this.child, this.consoleBtn, this.consolePosition})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  static _ConsoleTheme? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ConsoleTheme>();
}
