import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_tokens.dart';
import '../../models/motion_realtime.dart';

/// 正式页面当前使用的运动模块视觉 token。
///
/// 这层 token 只服务运动模块正式 UI，不扩散到全局主题。
class MotionPageTokens {
  const MotionPageTokens({
    required this.pageBackground,
    required this.mapTopMask,
    required this.mapBottomMask,
    required this.overlayBackground,
    required this.overlayBorder,
    required this.overlayShadow,
    required this.overlayPrimaryText,
    required this.overlaySecondaryText,
    required this.overlayActionBackground,
    required this.panelBackground,
    required this.panelBorder,
    required this.panelShadow,
    required this.panelActionBorder,
    required this.metricCardBackground,
    required this.metricCardBorder,
    required this.metricLabelText,
    required this.metricValueText,
    required this.metricUnitText,
    required this.primaryActionStart,
    required this.primaryActionEnd,
    required this.primaryActionGlow,
    required this.primaryActionText,
    required this.primaryActionIconBackground,
    required this.primaryActionIconForeground,
    required this.disabledActionBackground,
    required this.stopActionBackground,
    required this.mutedActionBackground,
    required this.mutedActionBorder,
    required this.mutedActionText,
    required this.softBadgeBackground,
    required this.softBadgeBorder,
    required this.softBadgeText,
  });

  factory MotionPageTokens.fromTheme(
    AppThemeTokens tokens,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return MotionPageTokens(
      pageBackground: tokens.motionPageBackground,
      mapTopMask: tokens.motionPageBackground.withValues(
        alpha: isDark ? 0.14 : 0.07,
      ),
      mapBottomMask: tokens.motionPageBackground.withValues(
        alpha: isDark ? 0.80 : 0.80,
      ),
      overlayBackground: tokens.surfaceOverlay,
      overlayBorder: tokens.motionPanelBorder,
      overlayShadow: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
      overlayPrimaryText: tokens.textPrimary,
      overlaySecondaryText: tokens.textSecondary,
      overlayActionBackground: tokens.tabBarActive.withValues(alpha: 0.12),
      panelBackground: tokens.motionPanelBackground,
      panelBorder: tokens.motionPanelBorder,
      panelShadow: Colors.black.withValues(alpha: isDark ? 0.54 : 0.08),
      panelActionBorder: isDark
          ? tokens.textInverse.withValues(alpha: 0.12)
          : tokens.brandPrimary.withValues(alpha: 0.10),
      metricCardBackground: tokens.motionMetricCardBackground,
      metricCardBorder: tokens.motionPanelBorder,
      metricLabelText: tokens.motionMetricLabel,
      metricValueText: tokens.motionMetricValue,
      metricUnitText: tokens.motionMetricLabel,
      primaryActionStart: tokens.motionPrimaryActionStart,
      primaryActionEnd: tokens.motionPrimaryActionEnd,
      primaryActionGlow: tokens.motionPrimaryActionEnd.withValues(
        alpha: isDark ? 0.45 : 0.20,
      ),
      primaryActionText: tokens.textInverse,
      primaryActionIconBackground: tokens.textInverse.withValues(
        alpha: isDark ? 0.20 : 0.15,
      ),
      primaryActionIconForeground: tokens.textInverse,
      disabledActionBackground: tokens.motionDisabledActionBackground,
      stopActionBackground: tokens.motionStopActionBackground,
      mutedActionBackground: tokens.motionModalMutedActionBackground,
      mutedActionBorder: tokens.motionModalMutedActionBorder,
      mutedActionText: tokens.motionModalMutedActionText,
      softBadgeBackground: tokens.tabBarActive.withValues(alpha: 0.10),
      softBadgeBorder: tokens.tabBarActive.withValues(alpha: 0.14),
      softBadgeText: tokens.tabBarActive,
    );
  }

  final Color pageBackground;
  final Color mapTopMask;
  final Color mapBottomMask;
  final Color overlayBackground;
  final Color overlayBorder;
  final Color overlayShadow;
  final Color overlayPrimaryText;
  final Color overlaySecondaryText;
  final Color overlayActionBackground;
  final Color panelBackground;
  final Color panelBorder;
  final Color panelShadow;
  final Color panelActionBorder;
  final Color metricCardBackground;
  final Color metricCardBorder;
  final Color metricLabelText;
  final Color metricValueText;
  final Color metricUnitText;
  final Color primaryActionStart;
  final Color primaryActionEnd;
  final Color primaryActionGlow;
  final Color primaryActionText;
  final Color primaryActionIconBackground;
  final Color primaryActionIconForeground;
  final Color disabledActionBackground;
  final Color stopActionBackground;
  final Color mutedActionBackground;
  final Color mutedActionBorder;
  final Color mutedActionText;
  final Color softBadgeBackground;
  final Color softBadgeBorder;
  final Color softBadgeText;
}

/// 统一格式化运动时长。
String formatMotionDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final remainSeconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainSeconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainSeconds.toString().padLeft(2, '0')}';
}

/// 统一格式化速度显示，单位 km/h，保留两位小数。
String formatMotionSpeed(double? metersPerSecond) {
  if (metersPerSecond == null || metersPerSecond <= 0) {
    return '0.00';
  }

  // 速度：km/h = m/s * 3.6
  final speedKmh = metersPerSecond * 3.6;
  return speedKmh.toStringAsFixed(2);
}

/// 统一计算实时面板展示速度。
///
/// 运动刚开始的前几秒，定位点数量少、瞬时速度噪声大，因此这里增加
/// 最小时长与最小距离门槛；达标后再展示当前速度，避免起步阶段出现误导值。
String formatRealtimeMotionSpeed(
  MotionRealtime? realtime, {
  int minDurationSeconds = 15,
  double minDistanceMeters = 10,
}) {
  if (realtime == null) {
    return '0.00';
  }

  if (realtime.durationSeconds < minDurationSeconds ||
      realtime.distanceMeters < minDistanceMeters) {
    return '0.00';
  }

  return formatMotionSpeed(realtime.currentSpeedMps);
}

class GlassCapsule extends StatelessWidget {
  const GlassCapsule({
    super.key,
    required this.pageTokens,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final MotionPageTokens pageTokens;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pageTokens.overlayBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageTokens.overlayBorder),
        boxShadow: [
          BoxShadow(
            color: pageTokens.overlayShadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PlayTrianglePainter extends CustomPainter {
  const PlayTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PlayTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
