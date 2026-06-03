import 'package:flutter/material.dart';

/// 表示一组随明暗模式切换的动态颜色。
class DltDynamicColor {
  const DltDynamicColor({required this.light, required this.dark});

  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
