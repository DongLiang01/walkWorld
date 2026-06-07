import 'package:flutter/material.dart';

import '../../../../app/svg/app_svg_icon.dart';
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
    final buttonLabel = switch (motionState.status) {
      MotionStatus.finished => '开始旅途',
      MotionStatus.error => '重新开始',
      MotionStatus.preparing => '正在准备',
      _ => '开始旅途',
    };
    final isPreparing = motionState.status == MotionStatus.preparing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryMotionButton(
            label: buttonLabel,
            pageTokens: pageTokens,
            enabled: canStart,
            isLoading: isPreparing,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _PrimaryMotionButton extends StatelessWidget {
  static const String _startActionDayIconPath =
      'assets/icons/motion/motion_start_action_day.svg';
  static const String _startActionNightIconPath =
      'assets/icons/motion/motion_start_action_night.svg';

  const _PrimaryMotionButton({
    required this.label,
    required this.pageTokens,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final MotionPageTokens pageTokens;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  isLoading
                      ? Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pageTokens.primaryActionIconBackground,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 9,
                              height: 9,
                              //CircularProgressIndicator是系统的进度条
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pageTokens.primaryActionIconForeground,
                                ),
                              ),
                            ),
                          ),
                        )
                      : AppSvgIcon(
                          isDark
                              ? _startActionNightIconPath
                              : _startActionDayIconPath,
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
