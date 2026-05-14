import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/application.dart';
import '../../models/models.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';
import '../widgets/motion_type_sheet.dart';

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
    final pageTokens = _MotionPageTokens.fromTheme(appTokens, theme.brightness);
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
                      // 点击开始运动先弹出类型选择弹窗，确认后再触发开始
                      onStart: canStart
                          ? () => _showTypeSheetAndStart(
                              context,
                              controller.startWorkout,
                            )
                          : null,
                    )
                  : const SizedBox.shrink(key: ValueKey('running')),
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

/// 弹出运动中面板
Future<void> showRunningActionSheet(
  BuildContext context, {
  required MotionType motionType,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false, // 运动期间不让弹窗消失
    enableDrag: false, // 去掉拖拽收回
    barrierColor: Colors.transparent, // 保持底部的地图可见
    builder: (context) => _RunningActionSheet(motionType: motionType),
  );
}

/// 运动中面板：以 BottomSheet 形式展示，盖住底部 tab
class _RunningActionSheet extends ConsumerWidget {
  const _RunningActionSheet({required this.motionType});

  /// 记录用户开始运动前选择的运动类型，供面板头部直接展示。
  final MotionType motionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motionState = ref.watch(motionControllerProvider);
    final controller = ref.read(motionControllerProvider.notifier);
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final isDark = theme.brightness == Brightness.dark;
    final pageTokens = _MotionPageTokens.fromTheme(appTokens, theme.brightness);

    final realtime = motionState.realtime;
    final durationFormat = _formatDuration(realtime?.durationSeconds ?? 0);
    final distanceKm = ((realtime?.distanceMeters ?? 0) / 1000).toStringAsFixed(
      2,
    );
    final currentPace = _formatPace(realtime?.currentSpeedMps);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: pageTokens.panelBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.14),
            blurRadius: isDark ? 26 : 11.7,
            offset: Offset(0, isDark ? -7.8 : -5.2),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 0,
            offset: const Offset(0, -0.65),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16, // 去掉了手柄，留出一定顶部边距
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部状态指示区
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  // 闪烁的红点
                  const _RecordingIndicator(),
                  const SizedBox(width: 6),
                  Text(
                    motionState.status == MotionStatus.running ? '正在记录' : '已暂停',
                    style: TextStyle(
                      color: pageTokens.overlayPrimaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 运动类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pageTokens.softBadgeBackground,
                      borderRadius: BorderRadius.circular(5.2),
                    ),
                    child: Text(
                      motionType.label,
                      style: TextStyle(
                        color: pageTokens.softBadgeText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // 数据统计区
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _MetricCell(
                      value: distanceKm,
                      unit: 'km',
                      label: '距离',
                      pageTokens: pageTokens,
                    ),
                  ),
                  Container(
                    width: 0.65,
                    height: 33,
                    color: pageTokens.panelBorder,
                  ),
                  Expanded(
                    child: _MetricCell(
                      value: durationFormat,
                      unit: '',
                      label: '时长',
                      pageTokens: pageTokens,
                    ),
                  ),
                  Container(
                    width: 0.65,
                    height: 33,
                    color: pageTokens.panelBorder,
                  ),
                  Expanded(
                    child: _MetricCell(
                      value: currentPace,
                      unit: '/km',
                      label: '配速',
                      pageTokens: pageTokens,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // 底部操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: pageTokens.mutedActionBackground,
                        borderRadius: BorderRadius.circular(11.7),
                        border: Border.all(
                          color: pageTokens.mutedActionBorder,
                          width: 0.65,
                        ),
                      ),
                      child: InkWell(
                        onTap: motionState.status == MotionStatus.running
                            ? controller.pauseWorkout
                            : controller.resumeWorkout,
                        borderRadius: BorderRadius.circular(11.7),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (motionState.status == MotionStatus.running)
                                AppSvgIcon(
                                  'assets/icons/motion/motion_action_pause.svg',
                                  color: pageTokens.mutedActionText,
                                  size: 11.7,
                                )
                              else
                                CustomPaint(
                                  size: const Size(10, 11.7),
                                  painter: _PlayTrianglePainter(
                                    color: pageTokens.mutedActionText,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                motionState.status == MotionStatus.running
                                    ? '暂停'
                                    : '继续',
                                style: TextStyle(
                                  color: pageTokens.mutedActionText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11.7),
                        color: pageTokens.stopActionBackground,
                        boxShadow: [
                          BoxShadow(
                            color: pageTokens.stopActionBackground.withValues(
                              alpha: 0.45,
                            ),
                            blurRadius: 7.15,
                            offset: const Offset(0, 3.9),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          controller.stopWorkout();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(11.7),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppSvgIcon(
                                'assets/icons/motion/motion_action_stop.svg',
                                color: Colors.white,
                                size: 10.4,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '结束运动',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 正在记录的红点指示器
class _RecordingIndicator extends StatefulWidget {
  const _RecordingIndicator();

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14.56,
              height: 14.56,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFF3B30,
                ).withValues(alpha: 0.15 + 0.1 * _controller.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 8.45,
              height: 8.45,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFF3B30,
                ).withValues(alpha: 0.25 + 0.15 * _controller.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 6.5,
              height: 6.5,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
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

class _MetricCell extends StatelessWidget {
  const _MetricCell({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: pageTokens.metricValueText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: pageTokens.metricUnitText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: pageTokens.metricLabelText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    required this.mutedActionBackground,
    required this.mutedActionBorder,
    required this.mutedActionText,
    required this.softBadgeBackground,
    required this.softBadgeBorder,
    required this.softBadgeText,
  });

  factory _MotionPageTokens.fromTheme(
    AppThemeTokens tokens,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return _MotionPageTokens(
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

/// 弹出运动类型选择底部弹窗，用户确认后再触发 [onConfirm] 开始运动。
///
/// 若用户取消弹窗，则不做任何操作。
Future<void> _showTypeSheetAndStart(
  BuildContext context,
  Future<void> Function() onConfirm,
) async {
  final selectedType = await showMotionTypeSheet(context);
  // 用户取消时 selectedType 为 null，直接返回
  if (selectedType == null) return;
  // 当前 startWorkout 暂不接受类型参数，后续可扩展
  await onConfirm();

  if (context.mounted) {
    showRunningActionSheet(context, motionType: selectedType);
  }
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

String _formatPace(double? metersPerSecond) {
  if (metersPerSecond == null || metersPerSecond <= 0) {
    return "--'--";
  }
  // 配速：分钟/公里 = 1000 / (米/秒 * 60)
  final double minutesPerKm = 1000 / (metersPerSecond * 60);
  final int minutes = minutesPerKm.floor();
  final int seconds = ((minutesPerKm - minutes) * 60).round();
  return '$minutes\'${seconds.toString().padLeft(2, '0')}';
}
