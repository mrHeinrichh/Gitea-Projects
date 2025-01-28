


import 'package:flutter/material.dart';

enum EncryptionStyle{
  period,
  asterisk,
}

extension EncryptionString on Text {

  Text encryptString({
        int? start,
        int? end,
        EncryptionStyle style = EncryptionStyle.asterisk
    }){
    String first = this.data!.substring(0,start ?? 2);
    String last = this.data!.substring(this.data!.length - (end ?? 2), this.data!.length);

    String encryptStyle;
    switch(style){
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
      overflow: this.overflow,
    );
  }
}
