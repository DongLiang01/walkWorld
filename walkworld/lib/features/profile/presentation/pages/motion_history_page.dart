import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../../motion/application/motion_history_provider.dart';
import '../../../motion/models/models.dart';

/// 历史列表条目间距
const double motionHistoryItemGap = 8;

/// 运动历史记录数据模型（仅个人中心页面组内使用）
class MotionHistoryItem {
  const MotionHistoryItem({
    required this.sessionId,
    required this.iconAsset,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.type,
    required this.date,
    required this.duration,
    required this.distance,
  });

  final String sessionId;
  final String iconAsset;
  final Color iconBgColor;
  final Color iconBorderColor;
  final String type;
  final String date;
  final String duration;
  final String distance;
}

/// 将运动记录转换为历史列表展示项。
MotionHistoryItem motionHistoryItemFromSession(
  MotionSession session,
  AppThemeTokens tokens,
) {
  final motionType = session.motionType ?? MotionType.hiking;

  return MotionHistoryItem(
    sessionId: session.sessionId,
    iconAsset: _historyIconAsset(motionType),
    iconBgColor: _historyIconBackground(motionType, tokens),
    iconBorderColor: _historyIconBorder(motionType, tokens),
    type: motionType.label,
    date: _formatHistoryDate(session.endTime),
    duration: _formatHistoryDuration(session.durationSeconds),
    distance: (session.totalDistanceMeters / 1000).toStringAsFixed(2),
  );
}

String _historyIconAsset(MotionType motionType) {
  return switch (motionType) {
    MotionType.hiking => AppSvgAssets.profile('history_hiking'),
    MotionType.running => AppSvgAssets.profile('history_running'),
    MotionType.cycling => AppSvgAssets.profile('history_cycling'),
  };
}

Color _historyIconBackground(MotionType motionType, AppThemeTokens tokens) {
  return switch (motionType) {
    MotionType.hiking => tokens.profileIconBgGreen,
    MotionType.running => tokens.profileIconBgBlue,
    MotionType.cycling => tokens.profileIconBgPurple,
  };
}

Color _historyIconBorder(MotionType motionType, AppThemeTokens tokens) {
  return switch (motionType) {
    MotionType.hiking => tokens.profileIconBorderGreen,
    MotionType.running => tokens.profileIconBorderBlue,
    MotionType.cycling => tokens.profileIconBorderPurple,
  };
}

String _formatHistoryDuration(int durationSeconds) {
  final totalMinutes = (durationSeconds / 60).round();
  if (totalMinutes < 60) {
    return '$totalMinutes 分钟';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours 小时';
  }
  return '$hours 小时 $minutes 分钟';
}

String _formatHistoryDate(int timestamp) {
  if (timestamp <= 0) {
    return '--';
  }

  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final recordDay = DateTime(date.year, date.month, date.day);
  final timeText =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  if (recordDay == today) {
    return '今天 $timeText';
  }
  if (recordDay == today.subtract(const Duration(days: 1))) {
    return '昨天 $timeText';
  }
  return '${date.month}月${date.day}日 $timeText';
}

BoxDecoration _motionHistoryCardDecoration(AppThemeTokens tokens) {
  return BoxDecoration(
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
  );
}

/// 全部运动历史记录页
class MotionHistoryPage extends ConsumerWidget {
  const MotionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final historyAsync = ref.watch(allMotionSessionsProvider);

    return Scaffold(
      backgroundColor: tokens.profilePageBackground,
      appBar: AppBar(
        backgroundColor: tokens.surfacePrimary,
        foregroundColor: tokens.profileTextPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '运动历史',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tokens.profileTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: MotionHistoryEmptyCard(tokens: tokens),
              );
            }

            final items = sessions
                .map((session) => motionHistoryItemFromSession(session, tokens))
                .toList(growable: false);

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemBuilder: (context, index) {
                return MotionHistoryCard(item: items[index]);
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: motionHistoryItemGap);
              },
              itemCount: items.length,
            );
          },
          loading: () {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: MotionHistoryStatusCard(tokens: tokens, text: '历史记录加载中…'),
            );
          },
          error: (_, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: MotionHistoryStatusCard(tokens: tokens, text: '历史记录加载失败'),
            );
          },
        ),
      ),
    );
  }
}

class MotionHistoryEmptyCard extends StatelessWidget {
  const MotionHistoryEmptyCard({super.key, required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return MotionHistoryStatusCard(tokens: tokens, text: '暂无运动记录');
  }
}

class MotionHistoryStatusCard extends StatelessWidget {
  const MotionHistoryStatusCard({
    super.key,
    required this.tokens,
    required this.text,
  });

  final AppThemeTokens tokens;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: _motionHistoryCardDecoration(tokens),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: tokens.profileTextSecondary,
        ),
      ),
    );
  }
}

/// 单条历史记录卡片
class MotionHistoryCard extends StatelessWidget {
  const MotionHistoryCard({super.key, required this.item});

  final MotionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _motionHistoryCardDecoration(tokens),
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
