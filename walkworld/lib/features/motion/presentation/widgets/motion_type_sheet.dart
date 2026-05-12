import 'package:flutter/material.dart';
import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';

/// 运动类型枚举，对应设计稿三种类型选项。
enum MotionType {
  /// 徒步 — 轻松步行，低强度有氧，适合休闲
  hiking,

  /// 跑步 — 有氧运动，提升心肺，消耗热量
  running,

  /// 骑行 — 低冲击骑行，高效燃脂减脂
  cycling,
}

extension MotionTypeExt on MotionType {
  String get label => switch (this) {
        MotionType.hiking => '徒步',
        MotionType.running => '跑步',
        MotionType.cycling => '骑行',
      };

  String get description => switch (this) {
        MotionType.hiking => '轻松步行，低强度有氧，适合休闲',
        MotionType.running => '有氧运动，提升心肺，消耗热量',
        MotionType.cycling => '低冲击骑行，高效燃脂减脂',
      };

  /// SVG 资源路径
  String get iconAssetPath => switch (this) {
        MotionType.hiking  => 'assets/icons/motion/motion_type_hiking.svg',
        MotionType.running => 'assets/icons/motion/motion_type_running.svg',
        MotionType.cycling => 'assets/icons/motion/motion_type_cycling.svg',
      };

  Color getIconBg(AppThemeTokens tokens) => switch (this) {
        MotionType.hiking => tokens.motionTypeHikingBg,
        MotionType.running => tokens.motionModalOptionSelectedBackground, // 跑步非选中态为半透明主题色
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
    barrierColor: Theme.of(context)
        .extension<AppThemeTokens>()!
        .motionModalScrim,
    builder: (_) => const _MotionTypeSheet(),
  );
}

class _MotionTypeSheet extends StatefulWidget {
  const _MotionTypeSheet();

  @override
  State<_MotionTypeSheet> createState() => _MotionTypeSheetState();
}

class _MotionTypeSheetState extends State<_MotionTypeSheet> {
  /// 当前选中的运动类型，默认选徒步
  MotionType _selected = MotionType.hiking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
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
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 拖拽手柄 ──
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appTokens.motionModalHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 标题区 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择运动类型',
                      style: TextStyle(
                        color: appTokens.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '开始前先选择本次运动方式',
                      style: TextStyle(
                        color: appTokens.motionModalDescription,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 运动类型选项列表 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: MotionType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MotionTypeOption(
                        type: type,
                        isSelected: _selected == type,
                        appTokens: appTokens,
                        isDark: isDark,
                        onTap: () => setState(() => _selected = type),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

            // 底部按钮行，用 MediaQuery 处理安全区
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  // 底部安全区 + 固定边距
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Row(
                  children: [
                    // 取消按钮
                    SizedBox(
                      width: 90,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: appTokens.motionModalMutedActionBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: appTokens.motionModalMutedActionBorder,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(null),
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                '取消',
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
                    ),
                    const SizedBox(width: 10),

                    // 确认开始按钮（渐变，与开始运动主按钮视觉一致）
                    Expanded(
                      child: SizedBox(
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
                                color: appTokens.motionPrimaryActionEnd
                                    .withValues(
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
                              onTap: () =>
                                  Navigator.of(context).pop(_selected),
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 小播放图标
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(alpha: 0.20),
                                    ),
                                    child: Center(
                                      child: CustomPaint(
                                        size: const Size(6, 7),
                                        painter: _PlayTrianglePainter(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
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
                child: AppSvgIcon(
                  type.iconAssetPath,
                  size: 20,
                ),
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

            // 右侧勾选指示器
            const SizedBox(width: 10),
            AnimatedContainer(
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
                      : appTokens.motionModalOptionBorder
                          .withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放三角形图标画笔（复用 motion_page.dart 的同款）
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
  bool shouldRepaint(covariant _PlayTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
