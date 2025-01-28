import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:jxim_client/main.dart';
import 'package:jxim_client/special_container/special_container_util.dart';

var posOriY = 0.0;
var posStartY = 0.0;
var posDiffY = 0.0;
var posOriAbsY = 0.0;

class SpecialContainerFull extends StatelessWidget {
  const SpecialContainerFull({super.key});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showFullView();
      },
      onVerticalDragStart: (detail) {
        posOriY = detail.localPosition.dy;
        posStartY = posOriY;
      },
      onVerticalDragUpdate: (detail) {
        posOriAbsY = detail.localPosition.dy;
        var oriYTmp = sheetHeight.value;
        var diff = posOriY - detail.localPosition.dy;

        // print('onVerticalDragUpdate---yy--->${detail.localPosition.dy}');
        //
        // print('onVerticalDragUpdate---diff--->$diff');

        posOriY = detail.localPosition.dy;

        posDiffY = diff;

        var posResultY = oriYTmp + diff;

        sheetHeight.value = posResultY;
      },
      onVerticalDragEnd: (detail) {
        var diff = posStartY - posOriY;

        if (diff >= 20) {
          // sheetHeight.value = kSheetHeightMax;

          _showFullView();
        } else if (diff <= -20) {
          sheetHeight.value = kSheetHeightMin;
        }

      },
      child: Obx(
            () => Container(
          constraints: const BoxConstraints(
            maxHeight: kSheetHeightMin,
            minHeight: 0,
          ),
          height: sheetHeight.value,
          color: Colors.green,
        ),
      ),
    );
  }

  void _showFullView() {
    // showCupertinoModalBottomSheet(
    //   isDismissible: true,
    //   expand: true,
    //   // barrierColor: Colors.transparent,
    //   isNeedBarrier: true,
    //   barrierColor: Colors.yellow.withOpacity(0.3),
    //   context: navigatorKey.currentState!.context,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => Container(height:400,color: Colors.red,),
    // );
    // sheetHeight.value = MediaQuery.of(navigatorKey.currentState!.context).padding.bottom;
  }
}
