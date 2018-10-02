import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'package:presto/constants.dart' as constants;
import 'package:presto/widgets/app_bar_menu.dart';

void showAppBarMenu(BuildContext context, AppBarMenuBuilder builder) {
  showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppBarMenu(
          builder: builder,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) => child);
}


DateTime dateToMonth(DateTime date) {
  return DateTime(date.year, date.month);
}

String dateToShortString(DateTime date) {
  return '${constants.kWeekdays[date.weekday - 1]}, ${constants.kMonthsShort[date.month - 1]} ${date.day}';
}

String dateToShortStringWithTime(DateTime date) {
  return '${constants.kWeekdays[date.weekday - 1]}, ${constants.kMonthsShort[date.month - 1]} ${date.day} at ${_twentyFourToTwelveHour(date.hour)}:${_toMinutesString(date.minute)} ${_AmOrPm(date.hour)}';
}

int _twentyFourToTwelveHour(int hour) {
  if(hour > 12) {
    return hour % 12;
  }

  return hour;
}

String _toMinutesString(int minutes) {
  if(minutes < 10) {
    return '0$minutes';
  }

  return '$minutes';
}

String _AmOrPm(int hour) {
  if(hour < 12) {
    return 'a.m.';
  }

  return 'p.m.';
}