import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

/// 统一输出应用的亮色与暗色主题。
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return _buildTheme(Brightness.light);
  }

  static ThemeData dark() {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final tokens = AppThemeTokens.resolve(brightness);
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.brandPrimary,
      onPrimary: tokens.textInverse,
      secondary: tokens.brandAccent,
      onSecondary: tokens.textInverse,
      error: tokens.danger,
      onError: tokens.textInverse,
      surface: tokens.surfacePrimary,
      onSurface: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surfacePrimary,
      dividerColor: tokens.dividerPrimary,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surfacePrimary,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.borderPrimary),
        ),
      ),
      textTheme: ThemeData(
        brightness: brightness,
        colorScheme: colorScheme,
      ).textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.brandPrimary,
          foregroundColor: tokens.textInverse,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.borderPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brandPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSecondary,
        selectedColor: tokens.brandPrimary,
        secondarySelectedColor: tokens.brandPrimary,
        side: BorderSide(color: tokens.borderPrimary),
        labelStyle: TextStyle(color: tokens.textPrimary),
        secondaryLabelStyle: TextStyle(color: tokens.textInverse),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        brightness: brightness,
      ),
      iconTheme: IconThemeData(
        color: tokens.textPrimary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textPrimary,
        textColor: tokens.textPrimary,
      ),
      splashColor: tokens.brandPrimary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      disabledColor: isDark ? tokens.textSecondary : tokens.borderPrimary,
    );
  }
}
