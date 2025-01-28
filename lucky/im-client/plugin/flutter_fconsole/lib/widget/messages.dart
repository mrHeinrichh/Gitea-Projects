import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fconsole/style/color.dart';
import 'package:flutter_fconsole/style/text.dart';

void Function(String) showFconsoleMessage = (str) {};

class FconsoleMessageView extends StatefulWidget {
  const FconsoleMessageView({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<FconsoleMessageView> createState() => _FconsoleMessageViewState();
}

class _FconsoleMessageViewState extends State<FconsoleMessageView> {
  @override
  void initState() {
    super.initState();
    showFconsoleMessage = _showMessage;
  }

  _showMessage(String msg) {
    setState(() {
      msgs.add(_Msg(msg));
    });
  }

  Set<_Msg> msgs = {};

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        widget.child,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var msg in msgs)
                _MsgTag(
                  key: Key(msg.key),
                  title: msg.content,
                  onRemove: () {
                    setState(() {
                      msgs.remove(msg);
                    });
                  },
                ),
            ],
          ),
        )
      ],
    );
  }
}

class _Msg {
  final String content;
  final String key;

  _Msg(this.content)
      : key = '$content${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';
}

class _MsgTag extends StatefulWidget {
  const _MsgTag({
    Key? key,
    required this.title,
    required this.onRemove,
  }) : super(key: key);

  final String title;
  final Function onRemove;

  @override
  State<_MsgTag> createState() => _MsgTagState();
}

class _MsgTagState extends State<_MsgTag> {
  bool isShow = false;
  bool dismiss = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((s) {
      setState(() {
        isShow = true;
      });
    });
     _timer = Timer(const Duration(milliseconds: 1600), () {
      setState(() {
        dismiss = true;
      });
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeInOutCubic,
      opacity: (isShow && !dismiss) ? 1 : 0,
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 330),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.bottomCenter,
        heightFactor: dismiss ? 0 : 1,
        onEnd: () {
          widget.onRemove();
        },
        child: Container(
          decoration: ShapeDecoration(
            color: ColorPlate.black.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          constraints: const BoxConstraints(
            maxWidth: 280,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 6,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: StText.normal(
            widget.title,
            style: const TextStyle(color: ColorPlate.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }
  
}
