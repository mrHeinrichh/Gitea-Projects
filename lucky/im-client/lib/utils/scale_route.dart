import 'package:flutter/material.dart';

class ScaleRoute extends PageRouteBuilder{
  final double? x;
  final double? y;
  final double? begin;
  final Widget page;
  ScaleRoute({
    required this.page,
    this.x = 0,
    this.y = 0,
    this.begin = 0 
  }):super(
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) => page,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
    ) => ScaleTransition(
      alignment: Alignment(x??0,y??0),
      scale: Tween<double>(
        begin: begin??0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)),
    child: child,
    ),
  );
}
