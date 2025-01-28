//单位转换
import 'dart:math';

import 'package:flutter/cupertino.dart';

String numerical(int num) {
  if (num > 1000 && num < 10000) {
    return (num / 1000).toStringAsFixed(1) + 'k';
  } else if (num > 10000 && num < 1000000) {
    return (num / 10000).toStringAsFixed(1) + 'w';
  } else if (num > 1000000) {
    return '100w';
  } else {
    return num.toString();
  }
}

String exchange(int num) {
  if (num >= 100000 && num < 100000000) {
    return (num / 10000).toStringAsFixed(1) + '万';
  } else if (num >= 100000000) {
    return (num / 100000000).toStringAsFixed(1) + '亿';
  } else {
    return num.toString();
  }
}

String exchange1(double num) {
  if (num >= 10000 && num < 100000000) {
    return (num / 10000).toStringAsFixed(1) + 'W';
  } else if (num >= 100000000) {
    return (num / 100000000).toStringAsFixed(1) + 'Y';
  } else {
    return num.toStringAsFixed(1);
  }
}

String exchange2(double num) {
  if (num >= 10000 && num < 100000000) {
    return (num / 10000).floorToDouble().toStringAsFixed(0) + 'W';
  } else if (num >= 100000000) {
    return (num / 100000000).floorToDouble().toStringAsFixed(0) + 'Y';
  } else {
    return num.floorToDouble().toStringAsFixed(0);
  }
}

String rankValue(int num) {
  if (num > 9999 && num < 1000000) {
    return (num / 10000).toStringAsFixed(1) + '万';
  } else if (num >= 1000000 && num < 10000000) {
    return (num ~/ 10000).toStringAsFixed(0) + '万';
  } else if (num >= 10000000 && num < 100000000) {
    return (num ~/ 10000).toStringAsFixed(0) + '万';
  } else if (num >= 100000000 && num < 1000000000) {
    return (num ~/ 100000000).toStringAsFixed(0) + '亿';
  } else {
    return num.toString();
  }
}

//经纬度距离计算
double caculateDistance(
    double latitude, double longitude, double latitude1, double longitude1) {
  double lon1 = (pi / 180) * latitude; //开始经度
  double lon2 = (pi / 180) * latitude1; //结束经度
  double lat1 = (pi / 180) * longitude; //开始纬度
  double lat2 = (pi / 180) * longitude1; //结束纬度
  // 地球半径
  double R = 6371;
  // 两点间距离 km，如果想要米的话，结果*1000就可以了
  var _data =
      acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)) *
          R;
  return _data.isNaN ? 0.0 : _data;
}

TextBox calcLastLineEnd(
  BuildContext context,
  BoxConstraints constraints,
  TextSpan textSpan,
) {
  final richTextWidget = Text.rich(textSpan).build(context) as RichText;
  final renderObject = richTextWidget.createRenderObject(context);
  renderObject.layout(constraints);
  final lastBox = renderObject
      .getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: textSpan.toPlainText().length,
        ),
      ).last;
  return lastBox;
}

Size calcTextSize(TextSpan textSpan, BuildContext? context) {
  final double textScaleFactor = context != null
      ? MediaQuery.of(context).textScaleFactor
      : WidgetsBinding.instance.window.textScaleFactor;

  final TextDirection textDirection =
      context != null ? Directionality.of(context) : TextDirection.ltr;

  final TextPainter textPainter = TextPainter(
    text: textSpan,
    textDirection: textDirection,
    textScaleFactor: textScaleFactor,
    textWidthBasis: TextWidthBasis.longestLine,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  return textPainter.size;
}
