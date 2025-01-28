import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/special_container/special_container_util.dart';

var posOriY = 0.0;
var posStartY = 0.0;
var posDiffY = 0.0;
var posOriAbsY = 0.0;

class SpecialContainerFix extends StatelessWidget {
  const SpecialContainerFix({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showFixView();
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
          _showFixView();
        } else if (diff <= -20) {
          sheetHeight.value = kSheetHeightMin;
        }

        // if (posDiffY >= 5) {
        //   sheetHeight.value = kSheetHeightMax;
        // } else if (posDiffY <= -5) {
        //   sheetHeight.value = kSheetHeightMin;
        // }

        // print('onVerticalDragEnd---yy--->${detail.localPosition.dy}');
      },
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(
            maxHeight: 300,
            minHeight: 78.0,
          ),
          height: sheetHeight.value,
          color: Colors.green,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              child: Container(
                color: Colors.pink,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'data1',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    Text(
                      'data1',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFixView() {
    sheetHeight.value = kSheetHeightMax;

    // showCupertinoModalBottomSheet(
    //   isDismissible: true,
    //   expand: false,
    //   // barrierColor: Colors.transparent,
    //   isNeedBarrier: true,
    //   barrierColor: Colors.yellow.withOpacity(0.3),
    //   context: navigatorKey.currentState!.context,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => Container(height:kSheetHeightMax,color: Colors.red,),
    // );
    // sheetHeight.value = MediaQuery.of(navigatorKey.currentState!.context).padding.bottom;
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // use Scaffold also in order to provide material app widgets
      body: Center(child: Text("Something")),
    );
  }
}
