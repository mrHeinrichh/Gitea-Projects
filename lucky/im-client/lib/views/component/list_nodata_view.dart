import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/localization/app_localizations.dart';

///列表空状态组件
class ListNodataView extends StatefulWidget {
  ///默认列表:群、好友、聚会、我的收藏
  static const listTypeDefault = 0;

  ///收益列表:我的收益
  static const listTypeProfit = 2;

  ///列表类型数量
  static const maxListType = 5;

  ///列表空状态组件
  ListNodataView(
      {Key? key,
      required this.type,
      //this.tips = '暂无数据',
      this.tips = '',
      this.bottom,
      this.requestCallback,
      this.showBtn = true})
      : super(key: key);
  final int type;
  String tips;
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
    if (widget.tips == '') {
      widget.tips = localized(myGroupEmpty);
    }
    return _loading
        ? const SizedBox()
        : Center(
            child: EventsWidget(
              data: objectMgr.socketMgr,
              eventTypes: [
                SocketMgr.eventSocketClose,
                SocketMgr.eventSocketError
              ],
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 244.w,
                      height: 128.w,
                      child: Image.asset(_checkState() ? img : _noConnectImg),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                          top: 32.w,
                          bottom:
                              _checkState() ? (widget.bottom ?? 96.w) : 28.w),
                      child: Text(
                        // _checkState() ? widget.tips : '网络信号差,请重试',
                        _checkState()
                            ? widget.tips
                            : localized(myGroupConnection),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.normal,
                          color: colorCCCCCC,
                          height: 1,
                        ),
                      ),
                    ),
                    // _checkState() || !widget.showBtn!
                    //     ?
                    const SizedBox()
                    // : CommonButton.button(localized(toastReloadAgain), () {
                    //     if (widget.requestCallback != null) {
                    //       widget.requestCallback!();
                    //     }
                    //   }, width: 187, height: 40, font: 14)
                  ],
                );
              },
            ),
          );
  }
}
