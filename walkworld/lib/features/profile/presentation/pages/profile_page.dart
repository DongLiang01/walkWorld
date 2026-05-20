import 'package:flutter/material.dart';

import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';

/// “我的”页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      backgroundColor: tokens.profilePageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileCurrentGoalSection(),
              const SizedBox(height: 12),
              const _ProfileStatsSection(),
              const SizedBox(height: 12),
              const _ProfileJourneySection(),
              const SizedBox(height: 12),
              const _ProfileHistorySection(),
              const SizedBox(height: 24), // 底部留白
            ],
          ),
        ),
      ),
    );
  }
}

/// 当前目标区块
class _ProfileCurrentGoalSection extends StatelessWidget {
  const _ProfileCurrentGoalSection();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.profileCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.profileCardBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.profileCardBorder,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          _buildLocationRow(
            context: context,
            iconBg: tokens.profileIconBgBlue,
            iconBorder: tokens.profileIconBorderBlue,
            iconAsset: AppSvgAssets.profile('origin_dot'),
            label: '出发地',
            location: '北京',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Row(
              children: [
                _buildDottedLine(tokens.profileTextSecondary),
                const SizedBox(width: 16),
                Container(
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
                ),
              ],
            ),
          ),
          _buildLocationRow(
            context: context,
            iconBg: tokens.profileIconBgOrange,
            iconBorder: tokens.profileIconBorderOrange,
            iconAsset: AppSvgAssets.profile('dest_flag'),
            label: '目的地',
            location: '上海',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required BuildContext context,
    required Color iconBg,
    required Color iconBorder,
    required String iconAsset,
    required String label,
    required String location,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

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
        AppSvgIcon(
          AppSvgAssets.profile('chevron_right'),
          width: 16,
          height: 16,
          color: tokens.profileTextSecondary,
        ),
      ],
    );
  }

  Widget _buildDottedLine(Color color) {
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

/// 统计数据卡片组
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
      decoration: BoxDecoration(
        color: tokens.profileCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.profileCardBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.profileCardBorder,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: tokens.profileTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
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

/// 我的旅程进度卡片
class _ProfileJourneySection extends StatelessWidget {
  const _ProfileJourneySection();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.profileCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.profileCardBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.profileCardBorder,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的旅程',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.profileTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.profileAccentBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '北京 → 上海',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.profileTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '共 1318 km',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: tokens.profileTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '12',
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
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: tokens.profileProgressBg,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      tokens.profileProgressStart,
                      tokens.profileProgressEnd,
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已完成',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.profileTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '156.3',
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
                ),
              ),
              Container(width: 1, height: 24, color: tokens.profileCardBorder),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '剩余',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.profileTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '1161.7',
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 历史记录区块
class _ProfileHistorySection extends StatelessWidget {
  const _ProfileHistorySection();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Column(
      children: [
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
        _HistoryCard(
          iconAsset: AppSvgAssets.profile('history_running'),
          iconBg: tokens.profileIconBgBlue,
          iconBorder: tokens.profileIconBorderBlue,
          type: '跑步',
          date: '今天 14:30',
          duration: '32 分钟',
          distance: '5.2',
        ),
        const SizedBox(height: 8),
        _HistoryCard(
          iconAsset: AppSvgAssets.profile('history_hiking'),
          iconBg: tokens.profileIconBgGreen,
          iconBorder: tokens.profileIconBorderGreen,
          type: '徒步',
          date: '昨天 09:15',
          duration: '108 分钟',
          distance: '8.4',
        ),
        const SizedBox(height: 8),
        _HistoryCard(
          iconAsset: AppSvgAssets.profile('history_cycling'),
          iconBg: tokens.profileIconBgPurple,
          iconBorder: tokens.profileIconBorderPurple,
          type: '骑行',
          date: '12月3日 07:50',
          duration: '58 分钟',
          distance: '18.6',
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.iconAsset,
    required this.iconBg,
    required this.iconBorder,
    required this.type,
    required this.date,
    required this.duration,
    required this.distance,
  });

  final String iconAsset;
  final Color iconBg;
  final Color iconBorder;
  final String type;
  final String date;
  final String duration;
  final String distance;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.profileCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.profileCardBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.profileCardBorder,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconBorder),
            ),
            child: Center(child: AppSvgIcon(iconAsset, width: 20, height: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.profileTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: tokens.profileTextSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: tokens.profileTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: tokens.profileTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
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
