import 'package:flutter/material.dart';

enum EncryptionStyle {
  period,
  asterisk,
}

extension EncryptionString on Text {
  Text encryptString({
    int? start,
    int? end,
    EncryptionStyle style = EncryptionStyle.asterisk,
  }) {
    //如果总长度少于7位 就是靓号 不需要脱敏处理
    if (data!.length < 7) {
      return Text(
        data!,
        style: this.style,
        overflow: overflow,
      );
    }

    String first = data!.substring(0, start ?? 2);
    String last = data!.substring(data!.length - (end ?? 2), data!.length);

    String encryptStyle;
    switch (style) {
      case EncryptionStyle.period:
        encryptStyle = '$first...$last';
        break;
      default:
        encryptStyle = '($first****$last)';
        break;
    }

    return Text(
      encryptStyle,
      style: this.style,
      overflow: overflow,
    );
  }
}
