import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 统一封装 SVG 图标的使用方式，避免页面层重复处理尺寸、颜色和语义标签。
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.assetName, {
    super.key,
    this.size = 24,
    this.width,
    this.height,
    this.color,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  /// SVG 资源完整路径。
  final String assetName;

  /// 默认正方形尺寸。
  final double size;

  /// 可选单独宽度，未传时回退到 [size]。
  final double? width;

  /// 可选单独高度，未传时回退到 [size]。
  final double? height;

  /// 单色 SVG 的覆写颜色。
  final Color? color;

  /// 提供给无障碍系统的语义标签。
  final String? semanticLabel;

  /// SVG 的缩放方式。
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? size;
    final resolvedHeight = height ?? size;

    return SvgPicture.asset(
      assetName,
      width: resolvedWidth,
      height: resolvedHeight,
      fit: fit,
      semanticsLabel: semanticLabel,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
