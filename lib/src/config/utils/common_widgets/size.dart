import 'package:flutter/material.dart';

extension IntExtensions on double? {
  double validate({double value = 0}) {
    return this ?? value;
  }

  Widget get height => SizedBox(height: this?.toDouble());
  Widget get width => SizedBox(width: this?.toDouble());
}
