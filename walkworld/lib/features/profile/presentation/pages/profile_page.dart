import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../../motion/application/motion_history_provider.dart';
import '../../application/goal_route_provider.dart';
import '../../application/identity_provider.dart';
import 'city_select_page.dart';
import 'identity_select_page.dart';
import 'motion_history_page.dart';

// ─── 页面级常量 ───────────────────────────────────────────────
/// 卡片通用圆角
const double _kCardRadius = 16;

/// 区块间距
const double _kSectionGap = 12;

// ─── 辅助方法 ─────────────────────────────────────────────────
/// 生成统一卡片 BoxDecoration（防止四处重复手写）
BoxDecoration _profileCardDecoration(AppThemeTokens tokens) {
  return BoxDecoration(
    color: tokens.profileCardBackground,
    borderRadius: BorderRadius.circular(_kCardRadius),
    border: Border.all(color: tokens.profileCardBorder),
    boxShadow: [
      BoxShadow(
        color: tokens.profileCardBorder,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// 格式化距离展示文案（适配太空大距离）
String _formatDistKm(double distKm) {
  if (distKm >= 100000000) {
    // 亿级：如 1.5 亿 km
    return '${(distKm / 100000000).toStringAsFixed(2)} 亿 km';
  } else if (distKm >= 10000) {
    // 万级：如 38.4 万 km
    return '${(distKm / 10000).toStringAsFixed(2)} 万 km';
  }
  return '${distKm.toStringAsFixed(2)} km';
}

// ─── 页面入口 ─────────────────────────────────────────────────

/// "我的"页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      backgroundColor: tokens.profilePageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _ProfileIdentitySection(),
              SizedBox(height: _kSectionGap),
              _ProfileCurrentGoalSection(),
              SizedBox(height: _kSectionGap),
              _ProfileStatsSection(),
              SizedBox(height: _kSectionGap),
              _ProfileJourneySection(),
              SizedBox(height: _kSectionGap),
              _ProfileHistorySection(),
              SizedBox(height: 24), // 底部留白
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 用户身份区块 ──────────────────────────────────────────────

/// 用户当前身份展示卡片（图标 + 身份名称 + 可点击箭头）
class _ProfileIdentitySection extends ConsumerWidget {
  const _ProfileIdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final identity = ref.watch(identityProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IdentitySelectPage()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _profileCardDecoration(tokens),
        child: Row(
          children: [
            // 身份图标
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.profileIconBgOrange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.profileIconBorderOrange),
              ),
              child: Center(
                child: AppSvgIcon(
                  AppSvgAssets.profile(identity.iconName),
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 身份名称
            Expanded(
              child: Text(
                identity.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.profileTextPrimary,
                ),
              ),
            ),
            // 右箭头
            AppSvgIcon(
              AppSvgAssets.profile('chevron_right'),
              width: 16,
              height: 16,
              color: tokens.profileTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 当前目标区块 ──────────────────────────────────────────────

/// 当前目标卡片（根据身份类型展示不同内容）
class _ProfileCurrentGoalSection extends ConsumerWidget {
  const _ProfileCurrentGoalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final identity = ref.watch(identityProvider);
    final route = ref.watch(goalRouteProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _profileCardDecoration(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前目标',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.profileTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // ── 环球旅行家：展示「环绕地球一周」文案 ──
          if (identity.isGlobal)
            _FixedRouteLabel(
              tokens: tokens,
              iconBg: tokens.profileIconBgBlue,
              iconBorder: tokens.profileIconBorderBlue,
              iconAsset: AppSvgAssets.profile('origin_dot'),
              label: '环绕地球一周',
            )
          // ── 太空固定路线（宇航训练员/登月/太阳远征者）：固定展示，无交互 ──
          else if (identity.isFullyFixed)
            _FixedRouteLabel(
              tokens: tokens,
              iconBg: tokens.profileIconBgBlue,
              iconBorder: tokens.profileIconBorderBlue,
              iconAsset: AppSvgAssets.profile('origin_dot'),
              label: '${identity.defaultOrigin} → ${identity.defaultDest}',
            )
          // ── 星际殖民者：出发地固定 + 目的地可选 + 无交换按钮 ──
          else if (identity.fixedOrigin && !identity.fixedDest) ...[
            // 出发地行（固定，不可点击，无箭头）
            _LocationRow(
              iconBg: tokens.profileIconBgBlue,
              iconBorder: tokens.profileIconBorderBlue,
              iconAsset: AppSvgAssets.profile('origin_dot'),
              label: '出发地',
              location: route.originCity.name,
              showArrow: false,
            ),
            // 中间连接线（无交换按钮）
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: _DottedLine(color: tokens.profileTextSecondary),
            ),
            // 目的地行（可点击）
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CitySelectPage(isOrigin: false),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: _LocationRow(
                iconBg: tokens.profileIconBgOrange,
                iconBorder: tokens.profileIconBorderOrange,
                iconAsset: AppSvgAssets.profile('dest_flag'),
                label: '目的地',
                location: route.destinationCity.name,
              ),
            ),
          ]
          // ── 普通城市选择（旅行达人/亚洲探索者/洲际探索者）──
          else ...[
            // 出发地行
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CitySelectPage(isOrigin: true),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: _LocationRow(
                iconBg: tokens.profileIconBgBlue,
                iconBorder: tokens.profileIconBorderBlue,
                iconAsset: AppSvgAssets.profile('origin_dot'),
                label: '出发地',
                location: route.originCity.name,
              ),
            ),
            // 中间连接线 + 交换按钮
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: Row(
                children: [
                  _DottedLine(color: tokens.profileTextSecondary),
                  const SizedBox(width: 16),
                  if (identity.isDomestic)
                    GestureDetector(
                      onTap: () =>
                          ref.read(goalRouteProvider.notifier).swapRoute(),
                      child: _SwapButton(tokens: tokens),
                    ),
                ],
              ),
            ),
            // 目的地行
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CitySelectPage(isOrigin: false),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: _LocationRow(
                iconBg: tokens.profileIconBgOrange,
                iconBorder: tokens.profileIconBorderOrange,
                iconAsset: AppSvgAssets.profile('dest_flag'),
                label: '目的地',
                location: route.destinationCity.name,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 固定路线展示行（单行图标 + 文案，无交互）
class _FixedRouteLabel extends StatelessWidget {
  const _FixedRouteLabel({
    required this.tokens,
    required this.iconBg,
    required this.iconBorder,
    required this.iconAsset,
    required this.label,
  });

  final AppThemeTokens tokens;
  final Color iconBg;
  final Color iconBorder;
  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: iconBorder),
          ),
          child: Center(child: AppSvgIcon(iconAsset, width: 12, height: 12)),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tokens.profileTextPrimary,
          ),
        ),
      ],
    );
  }
}

/// 出发地 / 目的地展示行
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.iconBg,
    required this.iconBorder,
    required this.iconAsset,
    required this.label,
    required this.location,
    this.showArrow = true,
  });

  final Color iconBg;
  final Color iconBorder;
  final String iconAsset;
  final String label;
  final String location;

  /// 是否显示右箭头（固定出发地行不需要箭头）
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Row(
      children: [
        // 图标容器
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: iconBorder),
          ),
          child: Center(child: AppSvgIcon(iconAsset, width: 12, height: 12)),
        ),
        const SizedBox(width: 12),
        // 标签 + 地名
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.profileTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.profileTextPrimary,
                ),
              ),
            ],
          ),
        ),
        // 右箭头（可选）
        if (showArrow)
          AppSvgIcon(
            AppSvgAssets.profile('chevron_right'),
            width: 16,
            height: 16,
            color: tokens.profileTextSecondary,
          ),
      ],
    );
  }
}

/// 出发地与目的地之间的虚线装饰
class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          width: 2,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// 出发地与目的地之间的交换按钮
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tokens.profileIconBgBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.profileIconBorderBlue),
      ),
      child: Center(
        child: AppSvgIcon(
          AppSvgAssets.profile('swap'),
          width: 16,
          height: 16,
          color: tokens.profileAccentBlue,
        ),
      ),
    );
  }
}

// ─── 统计数据卡片组 ────────────────────────────────────────────

/// 三格统计数据卡片行
class _ProfileStatsSection extends ConsumerWidget {
  const _ProfileStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('streak_days'),
            iconBg: tokens.profileIconBgOrange,
            iconBorder: tokens.profileIconBorderOrange,
            title: '连续运动',
            value: '${route?.currentStreakDays ?? 0}',
            unit: '天',
            subtitle: '最佳 ${route?.longestStreakDays ?? 0} 天',
            subtitleColor: tokens.profileTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('total_dist'),
            iconBg: tokens.profileIconBgBlue,
            iconBorder: tokens.profileIconBorderBlue,
            title: '本月累计',
            value: route?.monthlyDistanceKmStr ?? '0.0',
            unit: 'km',
            subtitle:
                '最新 ${route?.latestMotionDistanceKm.toStringAsFixed(2) ?? 0} km',
            subtitleColor: tokens.profileTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('calendar'),
            iconBg: tokens.profileIconBgPurple,
            iconBorder: tokens.profileIconBorderPurple,
            title: '本月次数',
            value: '${route?.monthlySessionCount ?? 0}',
            unit: '次',
            subtitle: '目标 20 次',
            subtitleColor: tokens.profileAccentPurple,
          ),
        ),
      ],
    );
  }
}

/// 单项统计卡片
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconAsset,
    required this.iconBg,
    required this.iconBorder,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.subtitleColor,
  });

  final String iconAsset;
  final Color iconBg;
  final Color iconBorder;
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _profileCardDecoration(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: iconBorder),
            ),
            child: Center(child: AppSvgIcon(iconAsset, width: 14, height: 14)),
          ),
          const SizedBox(height: 12),
          // 标题
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: tokens.profileTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // 数值 + 单位（基线对齐）
          FittedBox(
            //只准缩小，不准放大
            fit: BoxFit.scaleDown,
            //缩小后左对齐
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tokens.profileTextPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: tokens.profileTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 副标题
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 我的旅程进度卡片 ──────────────────────────────────────────

/// 旅程进度展示卡片
class _ProfileJourneySection extends ConsumerWidget {
  const _ProfileJourneySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;
    final goalRoute = ref.watch(goalRouteProvider);
    final distKm = route?.distKm ?? 0.0;
    final completedDist = route?.completedDist ?? 0.0;
    final progress = route?.ratio ?? 0.0;
    final percent = (progress * 100).toStringAsFixed(1);
    final remainingDist = distKm > completedDist ? distKm - completedDist : 0.0;

    final identity = ref.watch(identityProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _profileCardDecoration(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '我的旅程',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.profileTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 路线标题行（蓝点 + 路线 + 总里程）
          _JourneyRouteHeader(
            tokens: tokens,
            // 环球旅行家显示特殊文案，其他身份使用 provider 提供的城市名
            routeLabel: identity.isGlobal
                ? '环绕地球一周'
                : '${route?.originCityName ?? goalRoute.originCity.name} → ${route?.destinationCityName ?? goalRoute.destinationCity.name}',
            totalDistText: '共 ${_formatDistKm(distKm)}',
          ),
          const SizedBox(height: 16),
          // 完成百分比
          _JourneyPercentLabel(tokens: tokens, percent: percent),
          const SizedBox(height: 8),
          // 进度条
          _JourneyProgressBar(tokens: tokens, progress: progress),
          const SizedBox(height: 12),
          // 已完成 / 剩余里程
          _JourneyDistRow(
            tokens: tokens,
            completedDistText: completedDist.toStringAsFixed(2),
            remainingDistText: remainingDist.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

/// 旅程路线标题行（蓝点 + 路线名 + 总里程）
class _JourneyRouteHeader extends StatelessWidget {
  const _JourneyRouteHeader({
    required this.tokens,
    required this.routeLabel,
    required this.totalDistText,
  });

  final AppThemeTokens tokens;

  /// 路线展示文案（如 "北京 → 上海" 或 "环绕地球一周"）
  final String routeLabel;
  final String totalDistText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 蓝色方点
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: tokens.profileAccentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // 路线名
        Text(
          routeLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.profileTextPrimary,
          ),
        ),
        const Spacer(),
        // 总里程
        Text(
          totalDistText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: tokens.profileTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// 旅程完成百分比标签
class _JourneyPercentLabel extends StatelessWidget {
  const _JourneyPercentLabel({required this.tokens, required this.percent});

  final AppThemeTokens tokens;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          percent,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: tokens.profileAccentBlue,
          ),
        ),
        Text(
          '%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: tokens.profileAccentBlue,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '旅程完成',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: tokens.profileTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// 旅程进度条（带渐变填充）
class _JourneyProgressBar extends StatelessWidget {
  const _JourneyProgressBar({required this.tokens, required this.progress});

  final AppThemeTokens tokens;

  /// 0.0 ~ 1.0
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: tokens.profileProgressBg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [tokens.profileProgressStart, tokens.profileProgressEnd],
            ),
          ),
        ),
      ),
    );
  }
}

/// 旅程"已完成 / 剩余"双列里程统计行
class _JourneyDistRow extends StatelessWidget {
  const _JourneyDistRow({
    required this.tokens,
    required this.completedDistText,
    required this.remainingDistText,
  });

  final AppThemeTokens tokens;
  final String completedDistText;
  final String remainingDistText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 已完成
        Expanded(
          child: _JourneyDistStat(
            tokens: tokens,
            label: '已完成',
            value: completedDistText,
            alignment: CrossAxisAlignment.start,
            mainAlignment: MainAxisAlignment.start,
          ),
        ),
        // 分隔线
        Container(width: 1, height: 24, color: tokens.profileCardBorder),
        // 剩余
        Expanded(
          child: _JourneyDistStat(
            tokens: tokens,
            label: '剩余',
            value: remainingDistText,
            alignment: CrossAxisAlignment.end,
            mainAlignment: MainAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

/// 旅程单侧距离统计（已完成 或 剩余）
class _JourneyDistStat extends StatelessWidget {
  const _JourneyDistStat({
    required this.tokens,
    required this.label,
    required this.value,
    required this.alignment,
    required this.mainAlignment,
  });

  final AppThemeTokens tokens;
  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final MainAxisAlignment mainAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: tokens.profileTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: mainAlignment,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.profileTextPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'km',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: tokens.profileTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 历史记录区块 ──────────────────────────────────────────────

/// 历史记录列表区块
class _ProfileHistorySection extends ConsumerWidget {
  const _ProfileHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final historyAsync = ref.watch(latestMotionSessionsProvider);

    return Column(
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '运动记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.profileTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MotionHistoryPage(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(
                  '全部 ›',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tokens.profileAccentBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return MotionHistoryEmptyCard(tokens: tokens);
            }

            final items = sessions
                .map((session) => motionHistoryItemFromSession(session, tokens))
                .toList(growable: false);

            return Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: motionHistoryItemGap),
                  MotionHistoryCard(item: items[i]),
                ],
              ],
            );
          },
          loading: () =>
              MotionHistoryStatusCard(tokens: tokens, text: '历史记录加载中…'),
          error: (_, _) =>
              MotionHistoryStatusCard(tokens: tokens, text: '历史记录加载失败'),
        ),
      ],
    );
  }
}
