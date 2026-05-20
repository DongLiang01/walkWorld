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
    required this.motionPageBackground,
    required this.motionPanelBackground,
    required this.motionPanelBorder,
    required this.motionMetricCardBackground,
    required this.motionMetricLabel,
    required this.motionMetricValue,
    required this.motionPrimaryActionStart,
    required this.motionPrimaryActionEnd,
    required this.motionDisabledActionBackground,
    required this.motionStopActionBackground,
    required this.motionModalScrim,
    required this.motionModalBackground,
    required this.motionModalHandle,
    required this.motionModalDescription,
    required this.motionModalOptionBackground,
    required this.motionModalOptionBorder,
    required this.motionModalOptionSelectedBackground,
    required this.motionModalOptionSelectedBorder,
    required this.motionModalMutedActionBackground,
    required this.motionModalMutedActionBorder,
    required this.motionModalMutedActionText,
    required this.motionModalOptionActiveAccent,
    required this.motionTypeHikingBg,
    required this.motionTypeCyclingBg,
    required this.homePageBackground,
    required this.homeCardBackground,
    required this.homeCardBorder,
    required this.homeMapCardBackground,
    required this.homeMapCardBorder,
    required this.homeProgressBackground,
    required this.homeIconBgBlue,
    required this.homeIconBorderBlue,
    required this.homeIconBgPurple,
    required this.homeIconBorderPurple,
    required this.profilePageBackground,
    required this.profileCardBackground,
    required this.profileCardBorder,
    required this.profileTextPrimary,
    required this.profileTextSecondary,
    required this.profileAccentBlue,
    required this.profileAccentOrange,
    required this.profileAccentPurple,
    required this.profileIconBgBlue,
    required this.profileIconBorderBlue,
    required this.profileIconBgOrange,
    required this.profileIconBorderOrange,
    required this.profileIconBgPurple,
    required this.profileIconBorderPurple,
    required this.profileIconBgGreen,
    required this.profileIconBorderGreen,
    required this.profileProgressStart,
    required this.profileProgressEnd,
    required this.profileProgressBg,
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
      motionPageBackground: AppColorTokens.motionPageBackground.resolve(
        brightness,
      ),
      motionPanelBackground: AppColorTokens.motionPanelBackground.resolve(
        brightness,
      ),
      motionPanelBorder: AppColorTokens.motionPanelBorder.resolve(brightness),
      motionMetricCardBackground: AppColorTokens.motionMetricCardBackground
          .resolve(brightness),
      motionMetricLabel: AppColorTokens.motionMetricLabel.resolve(brightness),
      motionMetricValue: AppColorTokens.motionMetricValue.resolve(brightness),
      motionPrimaryActionStart: AppColorTokens.motionPrimaryActionStart.resolve(
        brightness,
      ),
      motionPrimaryActionEnd: AppColorTokens.motionPrimaryActionEnd.resolve(
        brightness,
      ),
      motionDisabledActionBackground: AppColorTokens
          .motionDisabledActionBackground
          .resolve(brightness),
      motionStopActionBackground: AppColorTokens.motionStopActionBackground
          .resolve(brightness),
      motionModalScrim: AppColorTokens.motionModalScrim.resolve(brightness),
      motionModalBackground: AppColorTokens.motionModalBackground.resolve(
        brightness,
      ),
      motionModalHandle: AppColorTokens.motionModalHandle.resolve(brightness),
      motionModalDescription: AppColorTokens.motionModalDescription.resolve(
        brightness,
      ),
      motionModalOptionBackground: AppColorTokens.motionModalOptionBackground
          .resolve(brightness),
      motionModalOptionBorder: AppColorTokens.motionModalOptionBorder.resolve(
        brightness,
      ),
      motionModalOptionSelectedBackground: AppColorTokens
          .motionModalOptionSelectedBackground
          .resolve(brightness),
      motionModalOptionSelectedBorder: AppColorTokens
          .motionModalOptionSelectedBorder
          .resolve(brightness),
      motionModalMutedActionBackground: AppColorTokens
          .motionModalMutedActionBackground
          .resolve(brightness),
      motionModalMutedActionBorder: AppColorTokens.motionModalMutedActionBorder
          .resolve(brightness),
      motionModalMutedActionText: AppColorTokens.motionModalMutedActionText
          .resolve(brightness),
      motionModalOptionActiveAccent: AppColorTokens
          .motionModalOptionActiveAccent
          .resolve(brightness),
      motionTypeHikingBg: AppColorTokens.motionTypeHikingBg.resolve(brightness),
      motionTypeCyclingBg: AppColorTokens.motionTypeCyclingBg.resolve(
        brightness,
      ),
      homePageBackground: AppColorTokens.homePageBackground.resolve(brightness),
      homeCardBackground: AppColorTokens.homeCardBackground.resolve(brightness),
      homeCardBorder: AppColorTokens.homeCardBorder.resolve(brightness),
      homeMapCardBackground: AppColorTokens.homeMapCardBackground.resolve(
        brightness,
      ),
      homeMapCardBorder: AppColorTokens.homeMapCardBorder.resolve(brightness),
      homeProgressBackground: AppColorTokens.homeProgressBackground.resolve(
        brightness,
      ),
      homeIconBgBlue: AppColorTokens.homeIconBgBlue.resolve(brightness),
      homeIconBorderBlue: AppColorTokens.homeIconBorderBlue.resolve(brightness),
      homeIconBgPurple: AppColorTokens.homeIconBgPurple.resolve(brightness),
      homeIconBorderPurple: AppColorTokens.homeIconBorderPurple.resolve(
        brightness,
      ),
      profilePageBackground: AppColorTokens.profilePageBackground.resolve(
        brightness,
      ),
      profileCardBackground: AppColorTokens.profileCardBackground.resolve(
        brightness,
      ),
      profileCardBorder: AppColorTokens.profileCardBorder.resolve(brightness),
      profileTextPrimary: AppColorTokens.profileTextPrimary.resolve(brightness),
      profileTextSecondary: AppColorTokens.profileTextSecondary.resolve(
        brightness,
      ),
      profileAccentBlue: AppColorTokens.profileAccentBlue.resolve(brightness),
      profileAccentOrange: AppColorTokens.profileAccentOrange.resolve(
        brightness,
      ),
      profileAccentPurple: AppColorTokens.profileAccentPurple.resolve(
        brightness,
      ),
      profileIconBgBlue: AppColorTokens.profileIconBgBlue.resolve(brightness),
      profileIconBorderBlue: AppColorTokens.profileIconBorderBlue.resolve(
        brightness,
      ),
      profileIconBgOrange: AppColorTokens.profileIconBgOrange.resolve(
        brightness,
      ),
      profileIconBorderOrange: AppColorTokens.profileIconBorderOrange.resolve(
        brightness,
      ),
      profileIconBgPurple: AppColorTokens.profileIconBgPurple.resolve(
        brightness,
      ),
      profileIconBorderPurple: AppColorTokens.profileIconBorderPurple.resolve(
        brightness,
      ),
      profileIconBgGreen: AppColorTokens.profileIconBgGreen.resolve(brightness),
      profileIconBorderGreen: AppColorTokens.profileIconBorderGreen.resolve(
        brightness,
      ),
      profileProgressStart: AppColorTokens.profileProgressStart.resolve(
        brightness,
      ),
      profileProgressEnd: AppColorTokens.profileProgressEnd.resolve(brightness),
      profileProgressBg: AppColorTokens.profileProgressBg.resolve(brightness),
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

  /// 运动模块正式页主背景色，通常用于地图页外层底色和明暗基调。
  final Color motionPageBackground;

  /// 运动模块底部面板背景色，通常用于正式运动页底部浮层容器。
  final Color motionPanelBackground;

  /// 运动模块底部面板边框色，通常用于面板描边与卡片边界。
  final Color motionPanelBorder;

  /// 运动模块指标卡片背景色，通常用于距离、时长、速度等数据卡片。
  final Color motionMetricCardBackground;

  /// 运动模块指标标签文字色，通常用于指标名称和单位等弱化信息。
  final Color motionMetricLabel;

  /// 运动模块指标主数值颜色，通常用于距离、时长、速度等主信息。
  final Color motionMetricValue;

  /// 运动模块主操作渐变起始色，通常用于“开始运动”等核心 CTA。
  final Color motionPrimaryActionStart;

  /// 运动模块主操作渐变结束色，通常用于“开始运动”等核心 CTA。
  final Color motionPrimaryActionEnd;

  /// 运动模块禁用操作底色，通常用于不可点击的主操作按钮。
  final Color motionDisabledActionBackground;

  /// 运动模块结束操作底色，通常用于“结束运动”等强提醒操作。
  final Color motionStopActionBackground;

  /// 运动模块弹窗遮罩色，通常用于类型选择弹窗打开后的地图遮罩。
  final Color motionModalScrim;

  /// 运动模块弹窗背景色，通常用于底部弹窗主体容器。
  final Color motionModalBackground;

  /// 运动模块弹窗拖拽条颜色，通常用于弹窗顶部手柄。
  final Color motionModalHandle;

  /// 运动模块弹窗说明文字色，通常用于副标题和弱说明。
  final Color motionModalDescription;

  /// 运动模块弹窗选项默认背景色，通常用于未选中的运动类型卡片。
  final Color motionModalOptionBackground;

  /// 运动模块弹窗选项默认边框色，通常用于未选中的运动类型卡片描边。
  final Color motionModalOptionBorder;

  /// 运动模块弹窗选项选中背景色，通常用于当前选中的运动类型卡片。
  final Color motionModalOptionSelectedBackground;

  /// 运动模块弹窗选项选中边框色，通常用于当前选中的运动类型卡片描边。
  final Color motionModalOptionSelectedBorder;

  /// 运动模块弹窗弱化操作底色，通常用于“取消”类次级按钮。
  final Color motionModalMutedActionBackground;

  /// 运动模块弹窗弱化操作边框色，通常用于“取消”类次级按钮描边。
  final Color motionModalMutedActionBorder;

  /// 运动模块弹窗弱化操作文字色，通常用于“取消”类次级按钮文字。
  final Color motionModalMutedActionText;

  /// 运动模块弹窗选项中，代表选中状态的品牌高亮色（如跑步选中时的背景和文字）。
  final Color motionModalOptionActiveAccent;

  /// 运动模块弹窗选项中，徒步的图标默认背景色。
  final Color motionTypeHikingBg;

  /// 运动模块弹窗选项中，骑行的图标默认背景色。
  final Color motionTypeCyclingBg;

  /// 首页背景底色
  final Color homePageBackground;

  /// 首页通用卡片背景色
  final Color homeCardBackground;

  /// 首页通用卡片边框色
  final Color homeCardBorder;

  /// 首页地图卡片背景色
  final Color homeMapCardBackground;

  /// 首页地图卡片边框色
  final Color homeMapCardBorder;

  /// 首页进度条底色
  final Color homeProgressBackground;

  /// 首页蓝色图标背景色（如路线地图、本周运动）
  final Color homeIconBgBlue;

  /// 首页蓝色图标边框色
  final Color homeIconBorderBlue;

  /// 首页紫色图标背景色（如累计旅途）
  final Color homeIconBgPurple;

  /// 首页紫色图标边框色
  final Color homeIconBorderPurple;

  /// profilePageBackground
  final Color profilePageBackground;

  /// profileCardBackground
  final Color profileCardBackground;

  /// profileCardBorder
  final Color profileCardBorder;

  /// profileTextPrimary
  final Color profileTextPrimary;

  /// profileTextSecondary
  final Color profileTextSecondary;

  /// profileAccentBlue
  final Color profileAccentBlue;

  /// profileAccentOrange
  final Color profileAccentOrange;

  /// profileAccentPurple
  final Color profileAccentPurple;

  /// profileIconBgBlue
  final Color profileIconBgBlue;

  /// profileIconBorderBlue
  final Color profileIconBorderBlue;

  /// profileIconBgOrange
  final Color profileIconBgOrange;

  /// profileIconBorderOrange
  final Color profileIconBorderOrange;

  /// profileIconBgPurple
  final Color profileIconBgPurple;

  /// profileIconBorderPurple
  final Color profileIconBorderPurple;

  /// profileIconBgGreen
  final Color profileIconBgGreen;

  /// profileIconBorderGreen
  final Color profileIconBorderGreen;

  /// profileProgressStart
  final Color profileProgressStart;

  /// profileProgressEnd
  final Color profileProgressEnd;

  /// profileProgressBg
  final Color profileProgressBg;

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
    Color? motionPageBackground,
    Color? motionPanelBackground,
    Color? motionPanelBorder,
    Color? motionMetricCardBackground,
    Color? motionMetricLabel,
    Color? motionMetricValue,
    Color? motionPrimaryActionStart,
    Color? motionPrimaryActionEnd,
    Color? motionDisabledActionBackground,
    Color? motionStopActionBackground,
    Color? motionModalScrim,
    Color? motionModalBackground,
    Color? motionModalHandle,
    Color? motionModalDescription,
    Color? motionModalOptionBackground,
    Color? motionModalOptionBorder,
    Color? motionModalOptionSelectedBackground,
    Color? motionModalOptionSelectedBorder,
    Color? motionModalMutedActionBackground,
    Color? motionModalMutedActionBorder,
    Color? motionModalMutedActionText,
    Color? motionModalOptionActiveAccent,
    Color? motionTypeHikingBg,
    Color? motionTypeCyclingBg,
    Color? homePageBackground,
    Color? homeCardBackground,
    Color? homeCardBorder,
    Color? homeMapCardBackground,
    Color? homeMapCardBorder,
    Color? homeProgressBackground,
    Color? homeIconBgBlue,
    Color? homeIconBorderBlue,
    Color? homeIconBgPurple,
    Color? homeIconBorderPurple,
    Color? profilePageBackground,
    Color? profileCardBackground,
    Color? profileCardBorder,
    Color? profileTextPrimary,
    Color? profileTextSecondary,
    Color? profileAccentBlue,
    Color? profileAccentOrange,
    Color? profileAccentPurple,
    Color? profileIconBgBlue,
    Color? profileIconBorderBlue,
    Color? profileIconBgOrange,
    Color? profileIconBorderOrange,
    Color? profileIconBgPurple,
    Color? profileIconBorderPurple,
    Color? profileIconBgGreen,
    Color? profileIconBorderGreen,
    Color? profileProgressStart,
    Color? profileProgressEnd,
    Color? profileProgressBg,
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
      motionPageBackground: motionPageBackground ?? this.motionPageBackground,
      motionPanelBackground:
          motionPanelBackground ?? this.motionPanelBackground,
      motionPanelBorder: motionPanelBorder ?? this.motionPanelBorder,
      motionMetricCardBackground:
          motionMetricCardBackground ?? this.motionMetricCardBackground,
      motionMetricLabel: motionMetricLabel ?? this.motionMetricLabel,
      motionMetricValue: motionMetricValue ?? this.motionMetricValue,
      motionPrimaryActionStart:
          motionPrimaryActionStart ?? this.motionPrimaryActionStart,
      motionPrimaryActionEnd:
          motionPrimaryActionEnd ?? this.motionPrimaryActionEnd,
      motionDisabledActionBackground:
          motionDisabledActionBackground ?? this.motionDisabledActionBackground,
      motionStopActionBackground:
          motionStopActionBackground ?? this.motionStopActionBackground,
      motionModalScrim: motionModalScrim ?? this.motionModalScrim,
      motionModalBackground:
          motionModalBackground ?? this.motionModalBackground,
      motionModalHandle: motionModalHandle ?? this.motionModalHandle,
      motionModalDescription:
          motionModalDescription ?? this.motionModalDescription,
      motionModalOptionBackground:
          motionModalOptionBackground ?? this.motionModalOptionBackground,
      motionModalOptionBorder:
          motionModalOptionBorder ?? this.motionModalOptionBorder,
      motionModalOptionSelectedBackground:
          motionModalOptionSelectedBackground ??
          this.motionModalOptionSelectedBackground,
      motionModalOptionSelectedBorder:
          motionModalOptionSelectedBorder ??
          this.motionModalOptionSelectedBorder,
      motionModalMutedActionBackground:
          motionModalMutedActionBackground ??
          this.motionModalMutedActionBackground,
      motionModalMutedActionBorder:
          motionModalMutedActionBorder ?? this.motionModalMutedActionBorder,
      motionModalMutedActionText:
          motionModalMutedActionText ?? this.motionModalMutedActionText,
      motionModalOptionActiveAccent:
          motionModalOptionActiveAccent ?? this.motionModalOptionActiveAccent,
      motionTypeHikingBg: motionTypeHikingBg ?? this.motionTypeHikingBg,
      motionTypeCyclingBg: motionTypeCyclingBg ?? this.motionTypeCyclingBg,
      homePageBackground: homePageBackground ?? this.homePageBackground,
      homeCardBackground: homeCardBackground ?? this.homeCardBackground,
      homeCardBorder: homeCardBorder ?? this.homeCardBorder,
      homeMapCardBackground:
          homeMapCardBackground ?? this.homeMapCardBackground,
      homeMapCardBorder: homeMapCardBorder ?? this.homeMapCardBorder,
      homeProgressBackground:
          homeProgressBackground ?? this.homeProgressBackground,
      homeIconBgBlue: homeIconBgBlue ?? this.homeIconBgBlue,
      homeIconBorderBlue: homeIconBorderBlue ?? this.homeIconBorderBlue,
      homeIconBgPurple: homeIconBgPurple ?? this.homeIconBgPurple,
      homeIconBorderPurple: homeIconBorderPurple ?? this.homeIconBorderPurple,
      profilePageBackground:
          profilePageBackground ?? this.profilePageBackground,
      profileCardBackground:
          profileCardBackground ?? this.profileCardBackground,
      profileCardBorder: profileCardBorder ?? this.profileCardBorder,
      profileTextPrimary: profileTextPrimary ?? this.profileTextPrimary,
      profileTextSecondary: profileTextSecondary ?? this.profileTextSecondary,
      profileAccentBlue: profileAccentBlue ?? this.profileAccentBlue,
      profileAccentOrange: profileAccentOrange ?? this.profileAccentOrange,
      profileAccentPurple: profileAccentPurple ?? this.profileAccentPurple,
      profileIconBgBlue: profileIconBgBlue ?? this.profileIconBgBlue,
      profileIconBorderBlue:
          profileIconBorderBlue ?? this.profileIconBorderBlue,
      profileIconBgOrange: profileIconBgOrange ?? this.profileIconBgOrange,
      profileIconBorderOrange:
          profileIconBorderOrange ?? this.profileIconBorderOrange,
      profileIconBgPurple: profileIconBgPurple ?? this.profileIconBgPurple,
      profileIconBorderPurple:
          profileIconBorderPurple ?? this.profileIconBorderPurple,
      profileIconBgGreen: profileIconBgGreen ?? this.profileIconBgGreen,
      profileIconBorderGreen:
          profileIconBorderGreen ?? this.profileIconBorderGreen,
      profileProgressStart: profileProgressStart ?? this.profileProgressStart,
      profileProgressEnd: profileProgressEnd ?? this.profileProgressEnd,
      profileProgressBg: profileProgressBg ?? this.profileProgressBg,
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
      motionPageBackground:
          Color.lerp(motionPageBackground, other.motionPageBackground, t) ??
          motionPageBackground,
      motionPanelBackground:
          Color.lerp(motionPanelBackground, other.motionPanelBackground, t) ??
          motionPanelBackground,
      motionPanelBorder:
          Color.lerp(motionPanelBorder, other.motionPanelBorder, t) ??
          motionPanelBorder,
      motionMetricCardBackground:
          Color.lerp(
            motionMetricCardBackground,
            other.motionMetricCardBackground,
            t,
          ) ??
          motionMetricCardBackground,
      motionMetricLabel:
          Color.lerp(motionMetricLabel, other.motionMetricLabel, t) ??
          motionMetricLabel,
      motionMetricValue:
          Color.lerp(motionMetricValue, other.motionMetricValue, t) ??
          motionMetricValue,
      motionPrimaryActionStart:
          Color.lerp(
            motionPrimaryActionStart,
            other.motionPrimaryActionStart,
            t,
          ) ??
          motionPrimaryActionStart,
      motionPrimaryActionEnd:
          Color.lerp(motionPrimaryActionEnd, other.motionPrimaryActionEnd, t) ??
          motionPrimaryActionEnd,
      motionDisabledActionBackground:
          Color.lerp(
            motionDisabledActionBackground,
            other.motionDisabledActionBackground,
            t,
          ) ??
          motionDisabledActionBackground,
      motionStopActionBackground:
          Color.lerp(
            motionStopActionBackground,
            other.motionStopActionBackground,
            t,
          ) ??
          motionStopActionBackground,
      motionModalScrim:
          Color.lerp(motionModalScrim, other.motionModalScrim, t) ??
          motionModalScrim,
      motionModalBackground:
          Color.lerp(motionModalBackground, other.motionModalBackground, t) ??
          motionModalBackground,
      motionModalHandle:
          Color.lerp(motionModalHandle, other.motionModalHandle, t) ??
          motionModalHandle,
      motionModalDescription:
          Color.lerp(motionModalDescription, other.motionModalDescription, t) ??
          motionModalDescription,
      motionModalOptionBackground:
          Color.lerp(
            motionModalOptionBackground,
            other.motionModalOptionBackground,
            t,
          ) ??
          motionModalOptionBackground,
      motionModalOptionBorder:
          Color.lerp(
            motionModalOptionBorder,
            other.motionModalOptionBorder,
            t,
          ) ??
          motionModalOptionBorder,
      motionModalOptionSelectedBackground:
          Color.lerp(
            motionModalOptionSelectedBackground,
            other.motionModalOptionSelectedBackground,
            t,
          ) ??
          motionModalOptionSelectedBackground,
      motionModalOptionSelectedBorder:
          Color.lerp(
            motionModalOptionSelectedBorder,
            other.motionModalOptionSelectedBorder,
            t,
          ) ??
          motionModalOptionSelectedBorder,
      motionModalMutedActionBackground:
          Color.lerp(
            motionModalMutedActionBackground,
            other.motionModalMutedActionBackground,
            t,
          ) ??
          motionModalMutedActionBackground,
      motionModalMutedActionBorder:
          Color.lerp(
            motionModalMutedActionBorder,
            other.motionModalMutedActionBorder,
            t,
          ) ??
          motionModalMutedActionBorder,
      motionModalMutedActionText:
          Color.lerp(
            motionModalMutedActionText,
            other.motionModalMutedActionText,
            t,
          ) ??
          motionModalMutedActionText,
      motionModalOptionActiveAccent:
          Color.lerp(
            motionModalOptionActiveAccent,
            other.motionModalOptionActiveAccent,
            t,
          ) ??
          motionModalOptionActiveAccent,
      motionTypeHikingBg:
          Color.lerp(motionTypeHikingBg, other.motionTypeHikingBg, t) ??
          motionTypeHikingBg,
      motionTypeCyclingBg:
          Color.lerp(motionTypeCyclingBg, other.motionTypeCyclingBg, t) ??
          motionTypeCyclingBg,
      homePageBackground:
          Color.lerp(homePageBackground, other.homePageBackground, t) ??
          homePageBackground,
      homeCardBackground:
          Color.lerp(homeCardBackground, other.homeCardBackground, t) ??
          homeCardBackground,
      homeCardBorder:
          Color.lerp(homeCardBorder, other.homeCardBorder, t) ?? homeCardBorder,
      homeMapCardBackground:
          Color.lerp(homeMapCardBackground, other.homeMapCardBackground, t) ??
          homeMapCardBackground,
      homeMapCardBorder:
          Color.lerp(homeMapCardBorder, other.homeMapCardBorder, t) ??
          homeMapCardBorder,
      homeProgressBackground:
          Color.lerp(homeProgressBackground, other.homeProgressBackground, t) ??
          homeProgressBackground,
      homeIconBgBlue:
          Color.lerp(homeIconBgBlue, other.homeIconBgBlue, t) ?? homeIconBgBlue,
      homeIconBorderBlue:
          Color.lerp(homeIconBorderBlue, other.homeIconBorderBlue, t) ??
          homeIconBorderBlue,
      homeIconBgPurple:
          Color.lerp(homeIconBgPurple, other.homeIconBgPurple, t) ??
          homeIconBgPurple,
      homeIconBorderPurple:
          Color.lerp(homeIconBorderPurple, other.homeIconBorderPurple, t) ??
          homeIconBorderPurple,
      profilePageBackground:
          Color.lerp(profilePageBackground, other.profilePageBackground, t) ??
          profilePageBackground,
      profileCardBackground:
          Color.lerp(profileCardBackground, other.profileCardBackground, t) ??
          profileCardBackground,
      profileCardBorder:
          Color.lerp(profileCardBorder, other.profileCardBorder, t) ??
          profileCardBorder,
      profileTextPrimary:
          Color.lerp(profileTextPrimary, other.profileTextPrimary, t) ??
          profileTextPrimary,
      profileTextSecondary:
          Color.lerp(profileTextSecondary, other.profileTextSecondary, t) ??
          profileTextSecondary,
      profileAccentBlue:
          Color.lerp(profileAccentBlue, other.profileAccentBlue, t) ??
          profileAccentBlue,
      profileAccentOrange:
          Color.lerp(profileAccentOrange, other.profileAccentOrange, t) ??
          profileAccentOrange,
      profileAccentPurple:
          Color.lerp(profileAccentPurple, other.profileAccentPurple, t) ??
          profileAccentPurple,
      profileIconBgBlue:
          Color.lerp(profileIconBgBlue, other.profileIconBgBlue, t) ??
          profileIconBgBlue,
      profileIconBorderBlue:
          Color.lerp(profileIconBorderBlue, other.profileIconBorderBlue, t) ??
          profileIconBorderBlue,
      profileIconBgOrange:
          Color.lerp(profileIconBgOrange, other.profileIconBgOrange, t) ??
          profileIconBgOrange,
      profileIconBorderOrange:
          Color.lerp(
            profileIconBorderOrange,
            other.profileIconBorderOrange,
            t,
          ) ??
          profileIconBorderOrange,
      profileIconBgPurple:
          Color.lerp(profileIconBgPurple, other.profileIconBgPurple, t) ??
          profileIconBgPurple,
      profileIconBorderPurple:
          Color.lerp(
            profileIconBorderPurple,
            other.profileIconBorderPurple,
            t,
          ) ??
          profileIconBorderPurple,
      profileIconBgGreen:
          Color.lerp(profileIconBgGreen, other.profileIconBgGreen, t) ??
          profileIconBgGreen,
      profileIconBorderGreen:
          Color.lerp(
            profileIconBorderGreen,
            other.profileIconBorderGreen,
            t,
          ) ??
          profileIconBorderGreen,
      profileProgressStart:
          Color.lerp(profileProgressStart, other.profileProgressStart, t) ??
          profileProgressStart,
      profileProgressEnd:
          Color.lerp(profileProgressEnd, other.profileProgressEnd, t) ??
          profileProgressEnd,
      profileProgressBg:
          Color.lerp(profileProgressBg, other.profileProgressBg, t) ??
          profileProgressBg,
    );
  }
}
