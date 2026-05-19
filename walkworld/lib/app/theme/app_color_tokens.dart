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

  static const motionPageBackground = DltDynamicColor(
    light: Color(0xFFF5F9FD),
    dark: Color(0xFF0A1020),
  );

  static const motionPanelBackground = DltDynamicColor(
    light: Color(0xF7FFFFFF),
    dark: Color(0xE3070B17),
  );

  static const motionPanelBorder = DltDynamicColor(
    light: Color(0x121A6FDB),
    dark: Color(0x14FFFFFF),
  );

  static const motionMetricCardBackground = DltDynamicColor(
    light: Color(0xFFF8FBFF),
    dark: Color(0xFF141D30),
  );

  static const motionMetricLabel = DltDynamicColor(
    light: Color(0xFF5C7087),
    dark: Color(0xFF8EA2BF),
  );

  static const motionMetricValue = DltDynamicColor(
    light: Color(0xFF142335),
    dark: Color(0xFFFFFFFF),
  );

  static const motionPrimaryActionStart = DltDynamicColor(
    light: Color(0xFF1A6FDB),
    dark: Color(0xFF0A7AFF),
  );

  static const motionPrimaryActionEnd = DltDynamicColor(
    light: Color(0xFF29B8F6),
    dark: Color(0xFF00D4FF),
  );

  static const motionDisabledActionBackground = DltDynamicColor(
    light: Color(0xFFAAC3DA),
    dark: Color(0xFF40536E),
  );

  static const motionStopActionBackground = DltDynamicColor(
    light: Color(0xFFFF6B35),
    dark: Color(0xFFFF6B35),
  );

  static const motionModalScrim = DltDynamicColor(
    light: Color(0x85000000),
    dark: Color(0xAD000000),
  );

  static const motionModalBackground = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF0C1828),
  );

  static const motionModalHandle = DltDynamicColor(
    light: Color(0x1A000000),
    dark: Color(0x24FFFFFF),
  );

  static const motionModalDescription = DltDynamicColor(
    light: Color(0xFF64748B),
    dark: Color(0xFF6A84A4),
  );

  static const motionModalOptionBackground = DltDynamicColor(
    light: Color(0xFFF3F6FB),
    dark: Color(0x0DFFFFFF),
  );

  static const motionModalOptionBorder = DltDynamicColor(
    light: Color(0x0D000000),
    dark: Color(0x12FFFFFF),
  );

  static const motionModalOptionSelectedBackground = DltDynamicColor(
    light: Color(0x121A6FDB),
    dark: Color(0x1700D4FF),
  );

  static const motionModalOptionSelectedBorder = DltDynamicColor(
    light: Color(0xFF1A6FDB),
    dark: Color(0xFF00D4FF),
  );

  static const motionModalMutedActionBackground = DltDynamicColor(
    light: Color(0xFFF3F6FB),
    dark: Color(0x12FFFFFF),
  );

  static const motionModalMutedActionBorder = DltDynamicColor(
    light: Color(0x14000000),
    dark: Color(0x1AFFFFFF),
  );

  static const motionModalMutedActionText = DltDynamicColor(
    light: Color(0xFF374151),
    dark: Color(0xA6FFFFFF),
  );

  static const motionModalOptionActiveAccent = DltDynamicColor(
    light: Color(0xFF1A6FDB),
    dark: Color(0xFF00D4FF),
  );

  static const motionTypeHikingBg = DltDynamicColor(
    light: Color(0x2128A745),
    dark: Color(0x2128A745),
  );

  static const motionTypeCyclingBg = DltDynamicColor(
    light: Color(0x21FF6B35),
    dark: Color(0x21FF6B35),
  );

  static const homePageBackground = DltDynamicColor(
    light: Color(0xFFF0F4F9),
    dark: Color(0xFF070B17),
  );

  static const homeCardBackground = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0x0DFFFFFF),
  );

  static const homeCardBorder = DltDynamicColor(
    light: Color(0x00FFFFFF),
    dark: Color(0x1AFFFFFF),
  );

  static const homeMapCardBackground = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xEB060B18),
  );

  static const homeMapCardBorder = DltDynamicColor(
    light: Color(0x00FFFFFF),
    dark: Color(0x2400D4FF),
  );

  static const homeProgressBackground = DltDynamicColor(
    light: Color(0xFFE5EBF5),
    dark: Color(0x14FFFFFF),
  );

  static const homeIconBgBlue = DltDynamicColor(
    light: Color(0xFFEBF3FF),
    dark: Color(0x1F00D4FF),
  );

  static const homeIconBorderBlue = DltDynamicColor(
    light: Color(0x00FFFFFF),
    dark: Color(0x3300D4FF),
  );

  static const homeIconBgPurple = DltDynamicColor(
    light: Color(0xFFFFF3E5),
    dark: Color(0x267B5CF5),
  );

  static const homeIconBorderPurple = DltDynamicColor(
    light: Color(0x00FFFFFF),
    dark: Color(0x407B5CF5),
  );
}
