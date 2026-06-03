import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../../../app/utils/geo_utils.dart';
import '../../application/goal_route_provider.dart';
import 'city_select_page.dart';

// ─── 页面级常量 ───────────────────────────────────────────────
/// 卡片通用圆角
const double _kCardRadius = 16;

/// 区块间距
const double _kSectionGap = 12;

/// 历史列表条目间距
const double _kHistoryItemGap = 8;

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

// ─── 历史记录数据模型（仅页面内使用）────────────────────────────
class _HistoryItem {
  const _HistoryItem({
    required this.iconAsset,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.type,
    required this.date,
    required this.duration,
    required this.distance,
  });

  final String iconAsset;
  final Color iconBgColor;
  final Color iconBorderColor;
  final String type;
  final String date;
  final String duration;
  final String distance;
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

// ─── 当前目标区块 ──────────────────────────────────────────────

/// 当前目标卡片（出发地 → 目的地）
class _ProfileCurrentGoalSection extends ConsumerWidget {
  const _ProfileCurrentGoalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
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
                GestureDetector(
                  onTap: () => ref.read(goalRouteProvider.notifier).swapRoute(),
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
      ),
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
  });

  final Color iconBg;
  final Color iconBorder;
  final String iconAsset;
  final String label;
  final String location;

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
        // 右箭头
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
class _ProfileStatsSection extends StatelessWidget {
  const _ProfileStatsSection();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('streak_days'),
            iconBg: tokens.profileIconBgOrange,
            iconBorder: tokens.profileIconBorderOrange,
            title: '连续运动',
            value: '23',
            unit: '天',
            subtitle: '最佳记录',
            subtitleColor: tokens.profileTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('total_dist'),
            iconBg: tokens.profileIconBgBlue,
            iconBorder: tokens.profileIconBorderBlue,
            title: '累计距离',
            value: '156.3',
            unit: 'km',
            subtitle: '↑ +18%',
            subtitleColor: tokens.profileAccentBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            iconAsset: AppSvgAssets.profile('calendar'),
            iconBg: tokens.profileIconBgPurple,
            iconBorder: tokens.profileIconBorderPurple,
            title: '本月次数',
            value: '18',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.profileTextPrimary,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: tokens.profileTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 副标题
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
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
    final route = ref.watch(goalRouteProvider);

    // 基于 Haversine 实时计算大圆地理距离，单位：米
    final distMeters = calcGeoDistance(
      route.originCity.lat,
      route.originCity.lng,
      route.destinationCity.lat,
      route.destinationCity.lng,
    );
    final distKm = distMeters / 1000.0;

    // 已完成里程，这里我们关联了用户历史以来的“累计距离”即 156.3 km
    const completedDist = 156.3;

    // 进度比例最低为 0，最大为 1.0
    final progress = distKm > 0
        ? (completedDist / distKm).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).toInt();

    // 剩余里程
    final remainingDist = distKm > completedDist ? distKm - completedDist : 0.0;

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
            originName: route.originCity.name,
            destName: route.destinationCity.name,
            totalDistText: '共 ${distKm.toStringAsFixed(1)} km',
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
            completedDistText: completedDist.toStringAsFixed(1),
            remainingDistText: remainingDist.toStringAsFixed(1),
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
    required this.originName,
    required this.destName,
    required this.totalDistText,
  });

  final AppThemeTokens tokens;
  final String originName;
  final String destName;
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
          '$originName → $destName',
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
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$percent',
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
class _ProfileHistorySection extends StatelessWidget {
  const _ProfileHistorySection();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    // 历史数据列表（后续接入真实数据源时替换此处）
    final items = [
      _HistoryItem(
        iconAsset: AppSvgAssets.profile('history_running'),
        iconBgColor: tokens.profileIconBgBlue,
        iconBorderColor: tokens.profileIconBorderBlue,
        type: '跑步',
        date: '今天 14:30',
        duration: '32 分钟',
        distance: '5.2',
      ),
      _HistoryItem(
        iconAsset: AppSvgAssets.profile('history_hiking'),
        iconBgColor: tokens.profileIconBgGreen,
        iconBorderColor: tokens.profileIconBorderGreen,
        type: '徒步',
        date: '昨天 09:15',
        duration: '108 分钟',
        distance: '8.4',
      ),
      _HistoryItem(
        iconAsset: AppSvgAssets.profile('history_cycling'),
        iconBgColor: tokens.profileIconBgPurple,
        iconBorderColor: tokens.profileIconBorderPurple,
        type: '骑行',
        date: '12月3日 07:50',
        duration: '58 分钟',
        distance: '18.6',
      ),
    ];

    return Column(
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '历史记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.profileTextPrimary,
              ),
            ),
            Text(
              '全部 ›',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: tokens.profileAccentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 历史条目列表（数据驱动）
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: _kHistoryItemGap),
          _HistoryCard(item: items[i]),
        ],
      ],
    );
  }
}

/// 单条历史记录卡片
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _profileCardDecoration(tokens),
      child: Row(
        children: [
          // 运动类型图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.iconBorderColor),
            ),
            child: Center(
              child: AppSvgIcon(item.iconAsset, width: 20, height: 20),
            ),
          ),
          const SizedBox(width: 12),
          // 类型 + 日期 + 时长
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型 · 日期
                Row(
                  children: [
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.profileTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 分隔小圆点
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: tokens.profileTextSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: tokens.profileTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 时长
                Text(
                  item.duration,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: tokens.profileTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 右侧距离
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.distance,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tokens.profileTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
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
      ),
    );
  }
}
