import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:jxim_client/utils/localization/app_localizations.dart';

class ListNodataView extends StatefulWidget {
  static const listTypeDefault = 0;

  static const listTypeProfit = 2;

  static const maxListType = 5;

  const ListNodataView({
    super.key,
    required this.type,
    this.bottom,
    this.requestCallback,
    this.showBtn = true,
  });
  final int type;
  final double? bottom;
  final Function? requestCallback;
  final bool? showBtn;

  @override
  State<ListNodataView> createState() => _ListNodataViewState();
}

class _ListNodataViewState extends State<ListNodataView> {
  final String _defaultImg = 'assets/images/common/empty_state0.png';
  final String _noConnectImg =
      'assets/images/common/network_signal_difference.png';

  bool _loading = true;

  _checkState() {
    return objectMgr.socketMgr.isConnect &&
        objectMgr.socketMgr.socket != null &&
        objectMgr.socketMgr.socket!.open;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var img = widget.type < ListNodataView.maxListType
        ? 'assets/images/common/empty_state${widget.type}.png'
        : _defaultImg;

    return _loading
        ? const SizedBox()
        : Center(
            child: EventsWidget(
              data: objectMgr.socketMgr,
              eventTypes: const [
                SocketMgr.eventSocketClose,
                SocketMgr.eventSocketError,
              ],
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 244.w,
                      height: 128.w,
                      child: Image.asset(_checkState() ? img : _noConnectImg),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: 32.w,
                        bottom: _checkState() ? (widget.bottom ?? 96.w) : 28.w,
                      ),
                      child: Text(
                        _checkState()
                            ? localized(myGroupEmpty)
                            : localized(myGroupConnection),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(),
                  ],
                );
              },
            ),
          );
  }
}
