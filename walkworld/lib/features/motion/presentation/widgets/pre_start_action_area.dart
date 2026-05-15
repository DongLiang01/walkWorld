import 'package:flutter/material.dart';

import '../../application/motion_state.dart';
import '../../models/motion_status.dart';
import 'motion_page_support.dart';

/// 开始前状态的底部操作区，按设计稿只保留单一主操作。
class PreStartActionArea extends StatelessWidget {
  const PreStartActionArea({
    super.key,
    required this.motionState,
    required this.pageTokens,
    required this.canStart,
    required this.onStart,
  });

  final MotionState motionState;
  final MotionPageTokens pageTokens;
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
            GlassCapsule(
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
    final duration = formatMotionDuration(session.durationSeconds);
    return '本次完成 $distanceKm km · 用时 $duration';
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
  final MotionPageTokens pageTokens;
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
                        painter: PlayTrianglePainter(
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
