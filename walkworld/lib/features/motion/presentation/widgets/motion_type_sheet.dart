import 'package:flutter/material.dart';

import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../models/models.dart';

extension MotionTypePresentationExt on MotionType {
  /// SVG 资源路径
  String get iconAssetPath => switch (this) {
    MotionType.hiking => 'assets/icons/motion/motion_type_hiking.svg',
    MotionType.running => 'assets/icons/motion/motion_type_running.svg',
    MotionType.cycling => 'assets/icons/motion/motion_type_cycling.svg',
  };

  Color getIconBg(AppThemeTokens tokens) => switch (this) {
    MotionType.hiking => tokens.motionTypeHikingBg,
    MotionType.running =>
      tokens.motionModalOptionSelectedBackground, // 跑步非选中态为半透明主题色
    MotionType.cycling => tokens.motionTypeCyclingBg,
  };
}

/// 展示运动类型选择底部弹窗。
///
/// 使用方式：
/// ```dart
/// final type = await showMotionTypeSheet(context);
/// if (type != null) startWorkout(type);
/// ```
Future<MotionType?> showMotionTypeSheet(BuildContext context) {
  return showModalBottomSheet<MotionType>(
    context: context,
    isScrollControlled: true,
    // 背景透明，由 sheet 内部自己绘制圆角背景
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(
      context,
    ).extension<AppThemeTokens>()!.motionModalScrim,
    builder: (_) => const _MotionTypeSheet(),
  );
}

class _MotionTypeSheet extends StatefulWidget {
  const _MotionTypeSheet();

  @override
  State<_MotionTypeSheet> createState() => _MotionTypeSheetState();
}

class _MotionTypeSheetState extends State<_MotionTypeSheet> {
  static const String _actionDayIconPath =
      'assets/icons/motion/motion_start_action_day.svg';
  static const String _actionNightIconPath =
      'assets/icons/motion/motion_start_action_night.svg';

  /// 当前选中的运动类型，默认选徒步
  MotionType _selected = MotionType.hiking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.88),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: appTokens.motionModalBackground,
            // 只保留左上右上圆角，左下右下贴边
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: mediaQuery.padding.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const _SheetHandle(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MotionTypeOptionList(
                    selected: _selected,
                    appTokens: appTokens,
                    isDark: isDark,
                    onChanged: (type) => setState(() => _selected = type),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SheetActionRow(
                    selected: _selected,
                    appTokens: appTokens,
                    isDark: isDark,
                    actionIconPath: isDark
                        ? _actionNightIconPath
                        : _actionDayIconPath,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final appTokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: appTokens.motionModalHandle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MotionTypeOptionList extends StatelessWidget {
  const _MotionTypeOptionList({
    required this.selected,
    required this.appTokens,
    required this.isDark,
    required this.onChanged,
  });

  final MotionType selected;
  final AppThemeTokens appTokens;
  final bool isDark;
  final ValueChanged<MotionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: MotionType.values.map((type) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: type == MotionType.values.last ? 0 : 10,
          ),
          child: _MotionTypeOption(
            type: type,
            isSelected: selected == type,
            appTokens: appTokens,
            isDark: isDark,
            onTap: () => onChanged(type),
          ),
        );
      }).toList(),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.selected,
    required this.appTokens,
    required this.isDark,
    required this.actionIconPath,
  });

  final MotionType selected;
  final AppThemeTokens appTokens;
  final bool isDark;
  final String actionIconPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: _SecondaryActionButton(
            label: '取消',
            appTokens: appTokens,
            onTap: () => Navigator.of(context).pop(null),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryActionButton(
            appTokens: appTokens,
            isDark: isDark,
            actionIconPath: actionIconPath,
            onTap: () => Navigator.of(context).pop(selected),
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.appTokens,
    required this.onTap,
  });

  final String label;
  final AppThemeTokens appTokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTokens.motionModalMutedActionBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTokens.motionModalMutedActionBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: appTokens.motionModalMutedActionText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.appTokens,
    required this.isDark,
    required this.actionIconPath,
    required this.onTap,
  });

  final AppThemeTokens appTokens;
  final bool isDark;
  final String actionIconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: const Alignment(-0.96, -0.45),
            end: const Alignment(1, 0.55),
            colors: [
              appTokens.motionPrimaryActionStart,
              appTokens.motionPrimaryActionEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: appTokens.motionPrimaryActionEnd.withValues(
                alpha: isDark ? 0.38 : 0.20,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppSvgIcon(actionIconPath),
                ),
                const Text(
                  '确认开始',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  const _CheckIndicator({required this.isSelected, required this.appTokens});

  final bool isSelected;
  final AppThemeTokens appTokens;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? appTokens.motionModalOptionActiveAccent
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : appTokens.motionModalOptionBorder.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Center(
              child: SizedBox(
                width: 13,
                height: 13,
                child: CustomPaint(painter: _CheckPainter()),
              ),
            )
          : null,
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.56)
      ..lineTo(size.width * 0.43, size.height * 0.78)
      ..lineTo(size.width * 0.82, size.height * 0.28);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 单个运动类型选项卡片。
class _MotionTypeOption extends StatelessWidget {
  const _MotionTypeOption({
    required this.type,
    required this.isSelected,
    required this.appTokens,
    required this.isDark,
    required this.onTap,
  });

  final MotionType type;
  final bool isSelected;
  final AppThemeTokens appTokens;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 选中/未选中的背景、边框
    final background = isSelected
        ? appTokens.motionModalOptionSelectedBackground
        : appTokens.motionModalOptionBackground;
    final borderColor = isSelected
        ? appTokens.motionModalOptionSelectedBorder
        : appTokens.motionModalOptionBorder;

    // 图标背景色：跑步选中态使用品牌色实心，其他使用语义色半透明
    final Color iconBg;
    if (isSelected && type == MotionType.running) {
      iconBg = appTokens.motionModalOptionActiveAccent;
    } else {
      iconBg = type.getIconBg(appTokens);
    }

    // 标题文字色：跑步选中时跟随品牌色
    final Color titleColor;
    if (isSelected && type == MotionType.running) {
      titleColor = appTokens.motionModalOptionActiveAccent;
    } else {
      titleColor = appTokens.textPrimary;
    }

    final overlayColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          overlayColor: WidgetStatePropertyAll(overlayColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 图标区
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: isSelected && type == MotionType.running
                        ? [
                            BoxShadow(
                              color: appTokens.motionModalOptionActiveAccent
                                  .withValues(alpha: 0.33),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : const [],
                  ),
                  child: Center(
                    child: AppSvgIcon(type.iconAssetPath, size: 20),
                  ),
                ),
                const SizedBox(width: 14),

                // 文字区
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        child: Text(type.label),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        type.description,
                        style: TextStyle(
                          color: appTokens.motionModalDescription,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                _CheckIndicator(isSelected: isSelected, appTokens: appTokens),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
