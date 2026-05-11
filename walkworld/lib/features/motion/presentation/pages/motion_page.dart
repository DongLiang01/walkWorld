import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/application.dart';
import '../../models/models.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';

/// 运动模块正式页面入口。
///
/// 当前先按 Figma 落地“开始运动前”日间/夜间正式页面骨架：
/// 1. 保持地图层、底部主操作区和底部导航的空间关系稳定
/// 2. 将调试页职责从正式页中拆出，避免视觉实现继续被联调字段污染
/// 3. 为后续接入“运动类型选择、运动中、运动结束”设计稿保留结构边界
class MotionPage extends ConsumerStatefulWidget {
  const MotionPage({super.key});

  @override
  ConsumerState<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends ConsumerState<MotionPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(
      () => ref.read(motionControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motionState = ref.watch(motionControllerProvider);
    final controller = ref.read(motionControllerProvider.notifier);
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final pageTokens = _MotionPageTokens.resolve(theme.brightness);
    final latestPoint =
        motionState.realtime?.latestPoint ??
        (motionState.recordedPoints.isNotEmpty
            ? motionState.recordedPoints.last
            : null);
    final canStart =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;
    final showPreStartLayout =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.preparing ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;

    return Scaffold(
      backgroundColor: pageTokens.pageBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: pageTokens.pageBackground),
              child: MotionMapView(
                creationParams: {
                  'showUserLocation': true,
                  'sessionStatus': motionState.status.value,
                },
                currentPoint: latestPoint,
                trackPoints: motionState.recordedPoints,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      pageTokens.mapTopMask,
                      Colors.transparent,
                      pageTokens.mapBottomMask,
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: showPreStartLayout
                  ? _PreStartActionArea(
                      key: const ValueKey('prestart'),
                      motionState: motionState,
                      pageTokens: pageTokens,
                      canStart: canStart,
                      onStart: canStart ? controller.startWorkout : null,
                    )
                  : _RunningActionPanel(
                      key: const ValueKey('running'),
                      motionState: motionState,
                      pageTokens: pageTokens,
                      appTokens: appTokens,
                      onPause: motionState.status == MotionStatus.running
                          ? controller.pauseWorkout
                          : null,
                      onResume: motionState.status == MotionStatus.paused
                          ? controller.resumeWorkout
                          : null,
                      onStop: controller.stopWorkout,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 开始前状态的底部操作区，按设计稿只保留单一主操作。
class _PreStartActionArea extends StatelessWidget {
  const _PreStartActionArea({
    super.key,
    required this.motionState,
    required this.pageTokens,
    required this.canStart,
    required this.onStart,
  });

  final MotionState motionState;
  final _MotionPageTokens pageTokens;
  final bool canStart;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final summary = switch (motionState.status) {
      MotionStatus.finished => _buildFinishedSummary(motionState),
      MotionStatus.error => '请先恢复定位或重新授权，再继续开始运动。',
      MotionStatus.preparing => '正在和原生地图建立连接，请稍等片刻。',
      _ => null,
    };
    final buttonLabel = switch (motionState.status) {
      MotionStatus.finished => '再来一次',
      MotionStatus.error => '重新开始',
      MotionStatus.preparing => '正在准备',
      _ => '开始运动',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (summary != null) ...[
            _GlassCapsule(
              pageTokens: pageTokens,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                summary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pageTokens.overlaySecondaryText,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _PrimaryMotionButton(
            label: buttonLabel,
            pageTokens: pageTokens,
            enabled: canStart,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }

  String _buildFinishedSummary(MotionState motionState) {
    final session = motionState.finishedSession;
    if (session == null) {
      return '本次运动已完成。';
    }

    final distanceKm = (session.totalDistanceMeters / 1000).toStringAsFixed(
      session.totalDistanceMeters >= 1000 ? 2 : 1,
    );
    final duration = _formatDuration(session.durationSeconds);
    return '本次完成 $distanceKm km · 用时 $duration';
  }
}

/// 在未拿到“运动中 / 暂停中”正式设计稿前，先用同一套视觉基线承接真实控制链路。
class _RunningActionPanel extends StatelessWidget {
  const _RunningActionPanel({
    super.key,
    required this.motionState,
    required this.pageTokens,
    required this.appTokens,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final MotionState motionState;
  final _MotionPageTokens pageTokens;
  final AppThemeTokens appTokens;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final realtime = motionState.realtime;
    final duration = _formatDuration(realtime?.durationSeconds ?? 0);
    final distanceKm = ((realtime?.distanceMeters ?? 0) / 1000).toStringAsFixed(
      2,
    );
    final currentSpeed = _formatSpeed(realtime?.currentSpeedMps);
    final averageSpeed = _formatSpeed(realtime?.averageSpeedMps);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pageTokens.panelBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: pageTokens.panelBorder),
          boxShadow: [
            BoxShadow(
              color: pageTokens.panelShadow,
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    motionState.status == MotionStatus.running ? '运动中' : '已暂停',
                    style: TextStyle(
                      color: pageTokens.overlayPrimaryText,
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: pageTokens.softBadgeBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pageTokens.softBadgeBorder),
                    ),
                    child: Text(
                      motionState.status == MotionStatus.running
                          ? '实时记录中'
                          : '暂停中',
                      style: TextStyle(
                        color: pageTokens.softBadgeText,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: '距离',
                      value: distanceKm,
                      unit: 'km',
                      pageTokens: pageTokens,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: '时长',
                      value: duration,
                      unit: '',
                      pageTokens: pageTokens,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: '当前速度',
                      value: currentSpeed,
                      unit: 'km/h',
                      pageTokens: pageTokens,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: '平均速度',
                      value: averageSpeed,
                      unit: 'km/h',
                      pageTokens: pageTokens,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: motionState.status == MotionStatus.running
                          ? onPause
                          : onResume,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appTokens.textPrimary,
                        side: BorderSide(color: pageTokens.panelActionBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        motionState.status == MotionStatus.running
                            ? '暂停'
                            : '继续',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onStop,
                      style: FilledButton.styleFrom(
                        backgroundColor: pageTokens.stopActionBackground,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('结束运动'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryMotionButton extends StatelessWidget {
  const _PrimaryMotionButton({
    required this.label,
    required this.pageTokens,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final _MotionPageTokens pageTokens;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gradientColors = enabled
        ? [pageTokens.primaryActionStart, pageTokens.primaryActionEnd]
        : [
            pageTokens.disabledActionBackground,
            pageTokens.disabledActionBackground,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: const Alignment(-0.96, -0.45),
          end: const Alignment(1, 0.55),
          colors: gradientColors,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: pageTokens.primaryActionGlow,
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 58,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pageTokens.primaryActionIconBackground,
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(6, 7),
                        painter: _PlayTrianglePainter(
                          color: pageTokens.primaryActionIconForeground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: pageTokens.primaryActionText,
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.pageTokens,
  });

  final String label;
  final String value;
  final String unit;
  final _MotionPageTokens pageTokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pageTokens.metricCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pageTokens.metricCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: pageTokens.metricLabelText,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pageTokens.metricValueText,
                      fontSize: 22,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: pageTokens.metricUnitText,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({
    required this.pageTokens,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final _MotionPageTokens pageTokens;
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

class _PlayTrianglePainter extends CustomPainter {
  const _PlayTrianglePainter({required this.color});

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
  bool shouldRepaint(covariant _PlayTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 正式页面当前使用的运动模块视觉 token。
///
/// 这层 token 只服务运动模块正式 UI，不扩散到全局主题。
class _MotionPageTokens {
  const _MotionPageTokens({
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
    required this.softBadgeBackground,
    required this.softBadgeBorder,
    required this.softBadgeText,
  });

  factory _MotionPageTokens.resolve(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _MotionPageTokens(
        pageBackground: Color(0xFF0A1020),
        mapTopMask: Color(0x240A1020),
        mapBottomMask: Color(0xCC070B17),
        overlayBackground: Color(0x8A0D1528),
        overlayBorder: Color(0x1FFFFFFF),
        overlayShadow: Color(0x52000000),
        overlayPrimaryText: Color(0xFFF4FAFF),
        overlaySecondaryText: Color(0xFFB3C3D8),
        overlayActionBackground: Color(0x2200D4FF),
        panelBackground: Color(0xE3070B17),
        panelBorder: Color(0x14FFFFFF),
        panelShadow: Color(0x8A000000),
        panelActionBorder: Color(0x1FFFFFFF),
        metricCardBackground: Color(0xFF141D30),
        metricCardBorder: Color(0x14FFFFFF),
        metricLabelText: Color(0xFF8EA2BF),
        metricValueText: Color(0xFFFFFFFF),
        metricUnitText: Color(0xFF8EA2BF),
        primaryActionStart: Color(0xFF0A7AFF),
        primaryActionEnd: Color(0xFF00D4FF),
        primaryActionGlow: Color(0x7300B4FF),
        primaryActionText: Color(0xFFFFFFFF),
        primaryActionIconBackground: Color(0x33FFFFFF),
        primaryActionIconForeground: Color(0xFFFFFFFF),
        disabledActionBackground: Color(0xFF40536E),
        stopActionBackground: Color(0xFFFF6B35),
        softBadgeBackground: Color(0x1A00D4FF),
        softBadgeBorder: Color(0x2600D4FF),
        softBadgeText: Color(0xFF00D4FF),
      );
    }

    return const _MotionPageTokens(
      pageBackground: Color(0xFFF5F9FD),
      mapTopMask: Color(0x12FFFFFF),
      mapBottomMask: Color(0xCCF5F9FD),
      overlayBackground: Color(0xE8FFFFFF),
      overlayBorder: Color(0x141A6FDB),
      overlayShadow: Color(0x1A1A6FDB),
      overlayPrimaryText: Color(0xFF162334),
      overlaySecondaryText: Color(0xFF51667D),
      overlayActionBackground: Color(0x121A6FDB),
      panelBackground: Color(0xF7FFFFFF),
      panelBorder: Color(0x121A6FDB),
      panelShadow: Color(0x141A6FDB),
      panelActionBorder: Color(0x1A254E7A),
      metricCardBackground: Color(0xFFF8FBFF),
      metricCardBorder: Color(0x141A6FDB),
      metricLabelText: Color(0xFF5C7087),
      metricValueText: Color(0xFF142335),
      metricUnitText: Color(0xFF5C7087),
      primaryActionStart: Color(0xFF1A6FDB),
      primaryActionEnd: Color(0xFF29B8F6),
      primaryActionGlow: Color(0x331A6FDB),
      primaryActionText: Color(0xFFFFFFFF),
      primaryActionIconBackground: Color(0x26FFFFFF),
      primaryActionIconForeground: Color(0xFFFFFFFF),
      disabledActionBackground: Color(0xFFAAC3DA),
      stopActionBackground: Color(0xFFFF6B35),
      softBadgeBackground: Color(0x121A6FDB),
      softBadgeBorder: Color(0x141A6FDB),
      softBadgeText: Color(0xFF1A6FDB),
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
  final Color softBadgeBackground;
  final Color softBadgeBorder;
  final Color softBadgeText;
}

String _formatDuration(int seconds) {
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

String _formatSpeed(double? metersPerSecond) {
  if (metersPerSecond == null) {
    return '--';
  }

  final speedKmPerHour = math.max(0, metersPerSecond * 3.6);
  return speedKmPerHour.toStringAsFixed(1);
}
