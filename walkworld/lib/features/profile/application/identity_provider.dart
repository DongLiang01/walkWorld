import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_route_preferences_repository.dart';

// ─── 身份数据模型 ──────────────────────────────────────────────

/// 单个身份条目
class IdentityItem {
  const IdentityItem({
    required this.name,
    required this.iconName,
    this.isGlobal = false,
  });

  /// 身份名称（如 "旅行达人"）
  final String name;

  /// 对应的 SVG 图标文件名（不含路径和扩展名）
  final String iconName;

  /// 是否为环球旅行家身份（环绕地球一周模式）
  final bool isGlobal;
}

/// 所有可选身份列表（顺序即展示顺序）
const List<IdentityItem> allIdentities = [
  IdentityItem(name: '旅行达人', iconName: 'rank_traveler'),
  IdentityItem(name: '亚洲探索者', iconName: 'rank_asia'),
  IdentityItem(name: '洲际探索者', iconName: 'rank_intercontinental'),
  IdentityItem(name: '环球旅行家', iconName: 'rank_global', isGlobal: true),
  IdentityItem(name: '宇航训练员', iconName: 'rank_trainee'),
  IdentityItem(name: '登月1号宇航员', iconName: 'rank_moon_mission'),
  IdentityItem(name: '星际殖民者', iconName: 'rank_colonial'),
  IdentityItem(name: '太阳远征者', iconName: 'rank_solar'),
];

/// 默认身份
const IdentityItem defaultIdentity = IdentityItem(
  name: '旅行达人',
  iconName: 'rank_traveler',
);

// ─── 身份状态管理 ──────────────────────────────────────────────

/// 当前身份 Notifier
class IdentityNotifier extends Notifier<IdentityItem> {
  @override
  IdentityItem build() {
    // 从本地缓存恢复上次选择的身份，找不到则使用默认身份
    final savedName = GoalRoutePreferencesRepository.identity;
    if (savedName != null) {
      for (final item in allIdentities) {
        if (item.name == savedName) return item;
      }
    }
    return defaultIdentity;
  }

  /// 切换身份
  void selectIdentity(IdentityItem identity) {
    state = identity;
    unawaited(GoalRoutePreferencesRepository.saveIdentity(identity.name));
  }
}

/// 当前身份 Provider
final identityProvider = NotifierProvider<IdentityNotifier, IdentityItem>(
  IdentityNotifier.new,
);
