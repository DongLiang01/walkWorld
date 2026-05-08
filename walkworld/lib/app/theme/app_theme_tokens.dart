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
      danger: AppColorTokens.danger.resolve(brightness),
      warning: AppColorTokens.warning.resolve(brightness),
      success: AppColorTokens.success.resolve(brightness),
    );
  }

  final Color brandPrimary;
  final Color brandAccent;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceOverlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInverse;
  final Color borderPrimary;
  final Color dividerPrimary;
  final Color danger;
  final Color warning;
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
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t) ?? brandPrimary,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t) ?? brandAccent,
      surfacePrimary:
          Color.lerp(surfacePrimary, other.surfacePrimary, t) ?? surfacePrimary,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ?? surfaceSecondary,
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
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}
