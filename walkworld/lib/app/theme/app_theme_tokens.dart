import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

/// 主题层对外暴露的已解析颜色集合。
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.brandPrimary,
    required this.brandAccent,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInverse,
    required this.borderPrimary,
    required this.dividerPrimary,
    required this.tabBarBackground,
    required this.tabBarBorder,
    required this.tabBarActive,
    required this.tabBarInactive,
    required this.danger,
    required this.warning,
    required this.success,
  });

  factory AppThemeTokens.resolve(Brightness brightness) {
    return AppThemeTokens(
      brandPrimary: AppColorTokens.brandPrimary.resolve(brightness),
      brandAccent: AppColorTokens.brandAccent.resolve(brightness),
      surfacePrimary: AppColorTokens.surfacePrimary.resolve(brightness),
      surfaceSecondary: AppColorTokens.surfaceSecondary.resolve(brightness),
      surfaceOverlay: AppColorTokens.surfaceOverlay.resolve(brightness),
      textPrimary: AppColorTokens.textPrimary.resolve(brightness),
      textSecondary: AppColorTokens.textSecondary.resolve(brightness),
      textInverse: AppColorTokens.textInverse.resolve(brightness),
      borderPrimary: AppColorTokens.borderPrimary.resolve(brightness),
      dividerPrimary: AppColorTokens.dividerPrimary.resolve(brightness),
      tabBarBackground: AppColorTokens.tabBarBackground.resolve(brightness),
      tabBarBorder: AppColorTokens.tabBarBorder.resolve(brightness),
      tabBarActive: AppColorTokens.tabBarActive.resolve(brightness),
      tabBarInactive: AppColorTokens.tabBarInactive.resolve(brightness),
      danger: AppColorTokens.danger.resolve(brightness),
      warning: AppColorTokens.warning.resolve(brightness),
      success: AppColorTokens.success.resolve(brightness),
    );
  }

  /// 品牌主色，通常用于主按钮、强调操作等核心视觉元素。
  final Color brandPrimary;

  /// 品牌辅助色，通常用于次级强调、补充视觉高亮等场景。
  final Color brandAccent;

  /// 页面主背景色，通常用于 Scaffold 等大面积底色。
  final Color surfacePrimary;

  /// 次级容器背景色，通常用于卡片、分组面板等承载区域。
  final Color surfaceSecondary;

  /// 浮层背景色，通常用于弹层、遮罩容器等半透明表面。
  final Color surfaceOverlay;

  /// 主要文字颜色，通常用于标题、正文等核心文本内容。
  final Color textPrimary;

  /// 次要文字颜色，通常用于说明、辅助信息、弱化文本等内容。
  final Color textSecondary;

  /// 反色文字颜色，通常用于深色按钮或高强调底色上的文字。
  final Color textInverse;

  /// 主边框颜色，通常用于输入框、卡片描边等常规边界。
  final Color borderPrimary;

  /// 分割线颜色，通常用于列表分隔、区域分隔等细线元素。
  final Color dividerPrimary;

  /// 底部导航栏背景色。
  final Color tabBarBackground;

  /// 底部导航栏顶部边框色。
  final Color tabBarBorder;

  /// 底部导航栏选中态颜色。
  final Color tabBarActive;

  /// 底部导航栏未选中态颜色。
  final Color tabBarInactive;

  /// 危险语义色，通常用于错误、删除、严重警告等场景。
  final Color danger;

  /// 警告语义色，通常用于风险提示、注意事项等场景。
  final Color warning;

  /// 成功语义色，通常用于完成状态、成功反馈等场景。
  final Color success;

  @override
  AppThemeTokens copyWith({
    Color? brandPrimary,
    Color? brandAccent,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceOverlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? textInverse,
    Color? borderPrimary,
    Color? dividerPrimary,
    Color? tabBarBackground,
    Color? tabBarBorder,
    Color? tabBarActive,
    Color? tabBarInactive,
    Color? danger,
    Color? warning,
    Color? success,
  }) {
    return AppThemeTokens(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandAccent: brandAccent ?? this.brandAccent,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textInverse: textInverse ?? this.textInverse,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      dividerPrimary: dividerPrimary ?? this.dividerPrimary,
      tabBarBackground: tabBarBackground ?? this.tabBarBackground,
      tabBarBorder: tabBarBorder ?? this.tabBarBorder,
      tabBarActive: tabBarActive ?? this.tabBarActive,
      tabBarInactive: tabBarInactive ?? this.tabBarInactive,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  //想支持亮暗主题的动画渐变切换而不是瞬间跳变，就需要正确实现 lerp
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      brandPrimary:
          Color.lerp(brandPrimary, other.brandPrimary, t) ?? brandPrimary,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t) ?? brandAccent,
      surfacePrimary:
          Color.lerp(surfacePrimary, other.surfacePrimary, t) ?? surfacePrimary,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ??
          surfaceSecondary,
      surfaceOverlay:
          Color.lerp(surfaceOverlay, other.surfaceOverlay, t) ?? surfaceOverlay,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textInverse: Color.lerp(textInverse, other.textInverse, t) ?? textInverse,
      borderPrimary:
          Color.lerp(borderPrimary, other.borderPrimary, t) ?? borderPrimary,
      dividerPrimary:
          Color.lerp(dividerPrimary, other.dividerPrimary, t) ?? dividerPrimary,
      tabBarBackground:
          Color.lerp(tabBarBackground, other.tabBarBackground, t) ??
          tabBarBackground,
      tabBarBorder:
          Color.lerp(tabBarBorder, other.tabBarBorder, t) ?? tabBarBorder,
      tabBarActive:
          Color.lerp(tabBarActive, other.tabBarActive, t) ?? tabBarActive,
      tabBarInactive:
          Color.lerp(tabBarInactive, other.tabBarInactive, t) ?? tabBarInactive,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}
