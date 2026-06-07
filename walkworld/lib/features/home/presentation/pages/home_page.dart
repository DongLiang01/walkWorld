import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walkworld/app/svg/app_svg_assets.dart';

import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../../../main.dart';
import '../../../profile/application/goal_route_provider.dart';
import '../../../profile/application/identity_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 首页
// ─────────────────────────────────────────────────────────────────────────────

/// 首页默认占位页。
///
/// 后续会按正式设计稿替换。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final identity = ref.watch(identityProvider);

    return Scaffold(
      backgroundColor: tokens.homePageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 30,
                bottom: 20,
              ),
              child: _HomeHeaderSection(
                onToggleTheme: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .toggleForTest(Theme.of(context).brightness);
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _CurrentTargetCard(),
                    const SizedBox(height: 12),
                    if (!identity.isGlobal)
                      _DestinationLookButton(),
                    if (!identity.isGlobal)
                      const SizedBox(height: 12),
                    const _MapCard(),
                    const SizedBox(height: 12),
                    const _ProgressCard(),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: _TotalTravelCard()),
                        SizedBox(width: 12),
                        Expanded(child: _WeeklyExerciseCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 页面头部
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeaderSection extends ConsumerWidget {
  const _HomeHeaderSection({required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final identity = ref.watch(identityProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '您好，',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: tokens.textPrimary,
            letterSpacing: -0.14,
          ),
        ),
        Text(
          identity.name,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: tokens.tabBarActive,
            letterSpacing: -0.14,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(Icons.brightness_6_outlined, color: tokens.textSecondary),
          tooltip: '测试切换主题',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 当前目标卡片
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentTargetCard extends ConsumerWidget {
  const _CurrentTargetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final identity = ref.watch(identityProvider);
    final route = ref.watch(goalRouteProvider);
    //获取出发地和目的地
    final distanceRoute = ref.watch(routeDistanceInfoProvider).asData?.value;
    final percent = ((distanceRoute?.ratio ?? 0) * 100).toStringAsFixed(1);

    // 根据身份类型决定目标展示文案
    final String targetLabel;
    if (identity.isGlobal) {
      targetLabel = '环绕地球一周';
    } else if (identity.isFullyFixed) {
      targetLabel = '${identity.defaultOrigin} → ${identity.defaultDest}';
    } else {
      targetLabel = '${route.originCity.name} → ${route.destinationCity.name}';
    }

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前目标',
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  letterSpacing: 0.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                targetLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                  fontSize: 15,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent%',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tokens.tabBarActive,
                  fontSize: 26,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                '已完成',
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 目的地一览卡片
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationLookButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: GestureDetector(
        onTap: () => {},
        child: Row(
          children: [
            Text(
              '去目的地看看',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.tabBarActive,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 路线地图卡片
// ─────────────────────────────────────────────────────────────────────────────

class _MapCard extends ConsumerWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    //获取出发地和目的地
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;
    final distKmStr = route?.distKmStr ?? '0.0';

    return _HomeCard(
      // 地图卡片使用专属背景色 token
      overrideBackground: tokens.homeMapCardBackground,
      overrideBorder: tokens.homeMapCardBorder,
      // 暗色模式地图卡片有更明显的阴影强调
      overrideShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 12, right: 14),
            child: _CardIconTitle(
              svgPath: isDark
                  ? AppSvgAssets.home('map_night')
                  : AppSvgAssets.home('map_day'),
              iconBg: tokens.homeIconBgBlue,
              iconBorder: tokens.homeIconBorderBlue,
              title: '路线地图',
              titleStyle: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          // 地图占位区域（后续替换为真实地图组件）
          // 颜色为占位专用色，暂未收口到 token（待地图功能接入后统一处理）
          Container(
            height: 140,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C1425) : const Color(0xFFEBF3FF),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                '$distKmStr km',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.tabBarActive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 旅途进度卡片
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final identity = ref.watch(identityProvider);
    //获取出发地和目的地
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;
    final goalRoute = ref.watch(goalRouteProvider);
    final originCityName = route?.originCityName ?? goalRoute.originCity.name;
    final destinationCityName =
        route?.destinationCityName ?? goalRoute.destinationCity.name;
    final distKmStr = route?.distKmStr ?? '0.0';
    final completedDistStr = route?.completedDistStr ?? '0.0';
    final ratio = route?.ratio ?? 0.0;

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 进度标题行：左标签 + 右数值
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '旅途进度',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '$completedDistStr / $distKmStr km',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.tabBarActive,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 进度条
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: tokens.homeProgressBackground,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tokens.tabBarActive,
                      tokens.tabBarActive.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 固定路线身份：进度条下方展示统一文案
          if (identity.isGlobal)
            Center(
              child: Text(
                '环绕地球一周',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontSize: 11,
                ),
              ),
            )
          else if (identity.isFullyFixed)
            Center(
              child: Text(
                '${identity.defaultOrigin} → ${identity.defaultDest}',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontSize: 11,
                ),
              ),
            )
          // 可选城市身份（含星际殖民者）：起终点标签行
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 起点
                Row(
                  children: [
                    _ProgressDot(color: tokens.tabBarActive),
                    const SizedBox(width: 4),
                    Text(
                      '$originCityName 起点',
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                // 终点
                Row(
                  children: [
                    Text(
                      '$destinationCityName 终点',
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _ProgressDot(color: tokens.warning),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 本周运动卡片
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyExerciseCard extends ConsumerWidget {
  const _WeeklyExerciseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardIconTitle(
            svgPath: isDark
                ? AppSvgAssets.home('total_travel_night')
                : AppSvgAssets.home('total_travel_day'),
            iconBg: tokens.homeIconBgBlue,
            iconBorder: tokens.homeIconBorderBlue,
            title: '旅途时长',
            titleStyle: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          // 数值行：数字 + 单位基线对齐
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                route?.totalDurationHoursStr ?? '0.0',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'h',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '本月 ${route?.monthlyDurationHoursStr ?? '0.0'} h',
            style: textTheme.labelSmall?.copyWith(
              color: tokens.success,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 累计旅途卡片
// ─────────────────────────────────────────────────────────────────────────────

class _TotalTravelCard extends ConsumerWidget {
  const _TotalTravelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardIconTitle(
            svgPath: isDark
                ? AppSvgAssets.home('week_exercise_night')
                : AppSvgAssets.home('week_exercise_day'),
            iconBg: tokens.homeIconBgPurple,
            iconBorder: tokens.homeIconBorderPurple,
            title: '累计旅途',
            titleStyle: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          // 数值行：数字 + 单位基线对齐
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                route?.completedDistStr ?? '0.0',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'km',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '本月 ${route?.monthlyDistanceKmStr ?? '0.0'} km',
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 局部私有组件
// ─────────────────────────────────────────────────────────────────────────────

/// 首页通用卡片容器。
///
/// 统一管理卡片圆角、边框、背景色和亮/暗模式阴影，
/// 避免各卡片重复写相同的 BoxDecoration 逻辑。
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.padding,
    this.overrideBackground,
    this.overrideBorder,
    this.overrideShadow,
  });

  final Widget child;

  /// 卡片内边距，不传则不添加（由 child 自行控制）。
  final EdgeInsetsGeometry? padding;

  /// 覆盖默认背景色（如地图卡片使用专属 token）。
  final Color? overrideBackground;

  /// 覆盖默认边框色。
  final Color? overrideBorder;

  /// 覆盖默认阴影；传 null 则走内置亮/暗逻辑。
  final List<BoxShadow>? overrideShadow;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 亮色模式统一使用细微投影，暗色模式不加阴影
    final defaultShadow = isDark
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: overrideBackground ?? tokens.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: overrideBorder ?? tokens.homeCardBorder),
        boxShadow: overrideShadow ?? defaultShadow,
      ),
      child: child,
    );
  }
}

/// 卡片图标 + 标题行。
///
/// 统一图标徽章（圆角小方块包裹 SVG）与右侧文字标题的排列方式。
class _CardIconTitle extends StatelessWidget {
  const _CardIconTitle({
    required this.svgPath,
    required this.iconBg,
    required this.iconBorder,
    required this.title,
    this.titleStyle,
  });

  final String svgPath;
  final Color iconBg;
  final Color iconBorder;
  final String title;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 图标徽章：圆角小方块 + SVG 图标
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconBg,
            border: Border.all(color: iconBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: AppSvgIcon(svgPath, size: 14),
        ),
        const SizedBox(width: 8),
        Text(title, style: titleStyle),
      ],
    );
  }
}

/// 进度条起终点指示圆点。
class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
