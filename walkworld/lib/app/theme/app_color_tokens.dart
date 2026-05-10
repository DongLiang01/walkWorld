import 'package:flutter/material.dart';

import 'app_dynamic_color.dart';

/// 应用级基础颜色 token，只负责定义全局可复用的色值。
class AppColorTokens {
  const AppColorTokens._();

  static const brandPrimary = DltDynamicColor(
    light: Color(0xFF356578),
    dark: Color(0xFFDF7F55),
  );

  static const brandAccent = DltDynamicColor(
    light: Color(0xFF4E8FA6),
    dark: Color(0xFFF3A17F),
  );

  static const surfacePrimary = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF121212),
  );

  static const surfaceSecondary = DltDynamicColor(
    light: Color(0xFFF5F7FA),
    dark: Color(0xFF1D1F24),
  );

  static const surfaceOverlay = DltDynamicColor(
    light: Color(0xCCFFFFFF),
    dark: Color(0xCC17191D),
  );

  static const textPrimary = DltDynamicColor(
    light: Color(0xFF111111),
    dark: Color(0xFFF5F5F5),
  );

  static const textSecondary = DltDynamicColor(
    light: Color(0xFF5F6B76),
    dark: Color(0xFFB5BDC5),
  );

  static const textInverse = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF111111),
  );

  static const borderPrimary = DltDynamicColor(
    light: Color(0xFFDCE3EA),
    dark: Color(0xFF2F333A),
  );

  static const dividerPrimary = DltDynamicColor(
    light: Color(0xFFE7EDF3),
    dark: Color(0xFF2A2E35),
  );

  static const tabBarBackground = DltDynamicColor(
    light: Color(0xF7FFFFFF),
    dark: Color(0xF7070B17),
  );

  static const tabBarBorder = DltDynamicColor(
    light: Color(0x14000000),
    dark: Color(0x14FFFFFF),
  );

  static const tabBarActive = DltDynamicColor(
    light: Color(0xFF1A6FDB),
    dark: Color(0xFF00D4FF),
  );

  static const tabBarInactive = DltDynamicColor(
    light: Color(0xFF9CA3AF),
    dark: Color(0xFF3D5070),
  );

  static const danger = DltDynamicColor(
    light: Color(0xFFD84F4F),
    dark: Color(0xFFFF7D7D),
  );

  static const warning = DltDynamicColor(
    light: Color(0xFFE8A33A),
    dark: Color(0xFFFFC46B),
  );

  static const success = DltDynamicColor(
    light: Color(0xFF34A56F),
    dark: Color(0xFF5DCC95),
  );
}
