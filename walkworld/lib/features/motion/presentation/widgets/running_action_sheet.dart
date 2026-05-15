import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/application.dart';
import '../../models/motion_status.dart';
import 'motion_page_support.dart';
import 'motion_type_sheet.dart';
import 'motion_finish_sheet.dart';

/// 弹出运动中面板。
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
    builder: (context) => RunningActionSheet(motionType: motionType),
  );
}

/// 运动中面板：以 BottomSheet 形式展示，盖住底部 tab。
class RunningActionSheet extends ConsumerWidget {
  const RunningActionSheet({super.key, required this.motionType});

  /// 记录用户开始运动前选择的运动类型，供面板头部直接展示。
  final MotionType motionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motionState = ref.watch(motionControllerProvider);
    final controller = ref.read(motionControllerProvider.notifier);
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final isDark = theme.brightness == Brightness.dark;
    final pageTokens = MotionPageTokens.fromTheme(appTokens, theme.brightness);

    final realtime = motionState.realtime;
    final durationFormat = formatMotionDuration(realtime?.durationSeconds ?? 0);
    final distanceKm = ((realtime?.distanceMeters ?? 0) / 1000).toStringAsFixed(
      2,
    );
    final currentPace = formatMotionPace(realtime?.currentSpeedMps);

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
                                  painter: PlayTrianglePainter(
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
                          showMotionFinishSheet(context);
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

/// 正在记录的红点指示器。
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
  final MotionPageTokens pageTokens;

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
