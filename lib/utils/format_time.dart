import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

enum DateStyle {
  MonDD, // October 19
  MMDDYYYY, // 10/19/2023
  YYYYMMDD, // 2023/10/19
}

enum MuteDuration {
  forever,
  hour,
  eighthHours,
  day,
  sevenDays,
  week,
  month,
  custom,
}

class FormatTime {
  static String formatTimeFun(int? createTime, {bool useOnline = true}) {
    if (createTime == null || (createTime != null && createTime == 0)) {
      return '';
    }
    String time = '';
    //时间戳转时间
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    DateTime now = DateTime.now();
    //获取当前时间戳
    int nowYear = DateTime.now().year;
    int differenceSecond = now.difference(cdate).inSeconds;
    int differenceMinute = now.difference(cdate).inMinutes;
    int differenceHours = now.difference(cdate).inHours;
    if (differenceSecond < 70) {
      if (useOnline) {
        time = localized(chatOnline);
      } else {
        time = localized(myChatJustNow);
      }
    } else if (differenceSecond >= 70 && differenceSecond < 3600) {
      time = '$differenceMinute${localized(myChatMinutes)}';
    } else if (differenceSecond >= 3600 && differenceSecond < 24 * 3600) {
      time = '$differenceHours${localized(myChatHours)}';
    } else if (differenceHours >= 24) {
      if (nowYear == cdate.year) {
        time =
            "${cdate.month.toString().padLeft(2, '0')}/${cdate.day.toString().padLeft(2, '0')}";
      } else {
        time =
            "${cdate.month.toString().padLeft(2, '0')}/${cdate.day.toString().padLeft(2, '0')}/${cdate.year.toString()}";
      }
    }
    return time;
  }

  static String chartTime(
    int createTime,
    bool showDay, {
    bool todayShowTime = false,
    DateStyle dateStyle = DateStyle.MonDD,
  }) {
    // Constants
    const int millisecondsPerSecond = 1000;
    const int daysInAWeek = 7;

    // Helper function to get formatted time
    String getFormattedTime(DateTime dateTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    DateTime cdate =
        DateTime.fromMillisecondsSinceEpoch(createTime * millisecondsPerSecond);
    DateTime now = DateTime.now();

    DateTime cDateCopied = cdate.subtract(
      Duration(
        hours: cdate.hour,
        minutes: cdate.minute,
        seconds: cdate.second,
        milliseconds: cdate.millisecond,
        microseconds: cdate.microsecond,
      ),
    );
    DateTime nowDateCopied = now.subtract(
      Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond,
      ),
    );

    if (!showDay) {
      return getFormattedTime(cdate);
    }

    if (cdate.year == now.year &&
        cdate.month == now.month &&
        now.day >= cdate.day) {
      int dayDifference = (nowDateCopied.day - cDateCopied.day).abs();

      if (dayDifference == 0) {
        return todayShowTime ? getFormattedTime(cdate) : localized(myChatToday);
      } else if (dayDifference >= 1 && dayDifference < daysInAWeek) {
        int weekDay = (nowDateCopied.weekday - dayDifference <= 0)
            ? nowDateCopied.weekday + daysInAWeek - dayDifference
            : nowDateCopied.weekday - dayDifference;
        return getWeek(weekDay);
      }
    } else if (nowDateCopied.month - cDateCopied.month == 1 &&
        nowDateCopied.difference(cDateCopied).inDays < 8) {
      int dayDifference = nowDateCopied.difference(cDateCopied).inDays;
      if (dayDifference >= 2 && dayDifference <= daysInAWeek) {
        int weekDay = (nowDateCopied.weekday - dayDifference <= 0)
            ? nowDateCopied.weekday + daysInAWeek - dayDifference
            : nowDateCopied.weekday - dayDifference;
        return getWeek(weekDay);
      }

      return localized(myChatYesterday);
    }

    if (dateStyle == DateStyle.YYYYMMDD) {
      int year = cdate.year;
      int currentYear = now.year;

      if (year != currentYear) {
        // String locale = Intl.getCurrentLocale();
        Locale locale = objectMgr.langMgr.currLocale;
        String localeStr = locale.toString();
        //en_US zh_CN
        if (localeStr == 'zh_CN') {
          return '$year年 ${getMonth(createTime)}${getDay(createTime)}${localized(chatCellDay)}';
        } else {
          return '${getMonth(createTime)} ${getDay(createTime)}${localized(chatCellDay)}, $year';
        }
      } else {
        return '${getMonth(createTime)} ${getDay(createTime)}${localized(chatCellDay)}';
      }
    }

    return dateStyle == DateStyle.MonDD
        ? '${getMonth(createTime)} ${getDay(createTime)}${localized(chatCellDay)}'
        : getMMDDYYYY(createTime);
  }

  static String getTime(int endtime) {
    String time = '';
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(endtime * 1000);
    time =
        '${cdate.year.toString()}-${cdate.month.toString().padLeft(2, '0')}-${cdate.day.toString().padLeft(2, '0')} ${cdate.hour.toString().padLeft(2, '0')}:${cdate.minute.toString().padLeft(2, '0')}';
    return time;
  }

  static String getYYMMDDhhmm(int vtime) {
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(vtime * 1000);
    DateTime now = DateTime.now();

    // Check if the date is today
    if (cdate.year == now.year &&
        cdate.month == now.month &&
        cdate.day == now.day) {
      String timePart =
          '${cdate.hour.toString().padLeft(2, '0')}:${cdate.minute.toString().padLeft(2, '0')}';
      return timePart;
    } else {
      String datePart =
          '${cdate.month.toString().padLeft(2, '0')}/${cdate.day.toString().padLeft(2, '0')}/${cdate.year.toString().substring(2)}';
      String timePart =
          '${cdate.hour.toString().padLeft(2, '0')}:${cdate.minute.toString().padLeft(2, '0')}';
      return '$datePart, $timePart';
    }
  }

  static String getShowTime(int startTamp) {
    int minute = startTamp ~/ 60;
    return '$minute';
  }

  //01-01
  static String getDateFormat(int startime) {
    String time = '';
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(startime * 1000);
    time =
        '${cdate.day.toString().padLeft(2, '0')}/${cdate.month.toString().padLeft(2, '0')}/${cdate.year.toString()}';
    return time;
  }

  //2021年1月1日
  static String getChinaDayTime(int startime) {
    String time = '';
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(startime * 1000);
    time =
        '${cdate.year.toString()}${localized(myChatYear1)}${cdate.month.toString()}${localized(myChatMonth1)}${cdate.day.toString()}${localized(myChatDay1)}';
    return time;
  }

  // 获取倒数时间
  static String getCountTime(int time) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(time);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    String timeAgo;
    if (difference.inSeconds < 60) {
      timeAgo = localized(myChatJustNow);
    } else if (difference.inMinutes < 60) {
      timeAgo =
          '${difference.inMinutes < 0 ? 0 : difference.inMinutes}${localized(myChatMinutes)}';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}${localized(myChatHours)}';
    } else {
      timeAgo = '${difference.inDays} 天前';
    }
    return timeAgo;
  }

  static bool iSameDay(int starTime, int endTime) {
    DateTime start = DateTime.fromMillisecondsSinceEpoch(starTime * 1000);
    DateTime end = DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
    return start.day == end.day &&
        start.month == end.month &&
        start.year == end.year;
  }

  //20日
  static String getDay(int startTime) {
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
    return cdate.day < 10
        ? cdate.day.toString()
        : cdate.day.toString().padLeft(2, '0');
  }

  static String getWeek(int index) {
    List<String> daydata = [
      localized(monday),
      localized(tuesday),
      localized(wednesday),
      localized(thursday),
      localized(friday),
      localized(saturday),
      localized(sunday),
    ];
    return daydata[index - 1];
  }

  static String getMonth(int ctime) {
    List<String> monthData = [
      localized(january),
      localized(february),
      localized(march),
      localized(april),
      localized(may),
      localized(june),
      localized(july),
      localized(august),
      localized(september),
      localized(october),
      localized(november),
      localized(december),
    ];
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(ctime * 1000);
    int month = dateTime.month;
    if (month - 1 < monthData.length) {
      return monthData[month - 1];
    }
    return '';
  }

  //23:59:59
  static String getAllTime(int timeTamp) {
    String time = '';
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(timeTamp * 1000);
    time =
        '${cdate.hour.toString().padLeft(2, '0')}:${cdate.minute.toString().padLeft(2, '0')}:${cdate.second.toString().padLeft(2, '0')}';
    return time;
  }

  static String get12hourTime(int time) {
    bool isAm = true;
    StringBuffer timeStr = StringBuffer();
    DateTime cdate = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    if (cdate.hour > 12) {
      timeStr.write('${cdate.hour - 12}');
      isAm = false;
    } else {
      timeStr.write('${cdate.hour}');
    }
    timeStr.write(':');
    timeStr.write(cdate.minute.toString().padLeft(2, '0'));
    timeStr.write(isAm ? ' AM' : ' PM');
    return timeStr.toString();
  }

  static String getMMDDYYYY(int time, {bool isShowYear = false}) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    int year = date.year;
    int currentYear = DateTime.now().year;

    if (isShowYear || year != currentYear) {
      return DateFormat('MM/dd/yyyy').format(date);
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  static String getDDMMYYYY(int time, {bool isShowYear = false}) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    int year = date.year;
    int currentYear = DateTime.now().year;

    if (isShowYear || year != currentYear) {
      return DateFormat('dd-MM-yyyy').format(date);
    } else {
      return DateFormat('dd-MM').format(date);
    }
  }

  static bool isOnline(int seconds) {
    final now = DateTime.now();
    final online = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final differenceSecond = now.difference(online).inSeconds;
    return differenceSecond < 70;
  }

  static String getMMDDHHMM(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    DateTime now = DateTime.now();

    if (dateTime.year == now.year) {
      // Same year, format as MM/DD HH:MM
      return DateFormat('MM/dd HH:mm').format(dateTime);
    } else {
      // Different year, format as YYYY/MM/DD HH:MM
      return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
    }
  }
}
