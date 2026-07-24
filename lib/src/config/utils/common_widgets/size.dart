import 'package:flutter/material.dart';
import 'package:wonder_souls/main.dart';

extension IntExtensions on double? {
  double validate({double value = 0}) {
    return this ?? value;
  }

  Widget get height => SizedBox(height: this?.toDouble());
  Widget get width => SizedBox(width: this?.toDouble());
}

Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
double sHeight = screenSize.height;
double swidth = screenSize.width;
