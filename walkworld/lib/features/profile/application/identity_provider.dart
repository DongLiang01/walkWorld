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
    this.isDomestic = false,
    this.originZones = const ['domestic'],
    this.destZones = const ['domestic'],
    this.defaultOrigin = '北京',
    this.defaultDest = '上海',
    this.fixedOrigin = false,
    this.fixedDest = false,
  });

  /// 身份名称（如 "旅行达人"）
  final String name;

  /// 对应的 SVG 图标文件名（不含路径和扩展名）
  final String iconName;

  /// 是否为环球旅行家身份（环绕地球一周模式）
  final bool isGlobal;

  /// 是否为旅行达人身份
  final bool isDomestic;

  /// 出发地可选 zone 列表
  final List<String> originZones;

  /// 目的地可选 zone 列表
  final List<String> destZones;

  /// 默认出发地城市名
  final String defaultOrigin;

  /// 默认目的地城市名
  final String defaultDest;

  /// 出发地是否固定不可选
  final bool fixedOrigin;

  /// 目的地是否固定不可选
  final bool fixedDest;

  /// 该身份是否完全不需要城市选择（出发地和目的地都固定）
  bool get isFullyFixed => fixedOrigin && fixedDest;
}

/// 所有可选身份列表（顺序即展示顺序）
const List<IdentityItem> allIdentities = [
  // ── 地球旅行身份 ──
  IdentityItem(
    name: '旅行达人',
    iconName: 'rank_traveler',
    originZones: ['domestic'],
    destZones: ['domestic'],
    defaultOrigin: '北京',
    defaultDest: '上海',
    isDomestic: true,
  ),
  IdentityItem(
    name: '亚洲探索者',
    iconName: 'rank_asia',
    originZones: ['domestic'],
    destZones: ['asia'],
    defaultOrigin: '北京',
    defaultDest: '东京',
  ),
  IdentityItem(
    name: '洲际探索者',
    iconName: 'rank_intercontinental',
    originZones: ['domestic'],
    destZones: ['intercontinental'],
    defaultOrigin: '北京',
    defaultDest: '纽约',
  ),
  // ── 环球旅行家 ──
  IdentityItem(
    name: '环球旅行家',
    iconName: 'rank_global',
    isGlobal: true,
    fixedOrigin: true,
    fixedDest: true,
  ),
  // ── 太空身份 ──
  IdentityItem(
    name: '宇航训练员',
    iconName: 'rank_trainee',
    fixedOrigin: true,
    fixedDest: true,
    defaultOrigin: '地球',
    defaultDest: '国际空间站',
  ),
  IdentityItem(
    name: '登月1号宇航员',
    iconName: 'rank_moon_mission',
    fixedOrigin: true,
    fixedDest: true,
    defaultOrigin: '地球',
    defaultDest: '月球',
  ),
  IdentityItem(
    name: '星际殖民者',
    iconName: 'rank_colonial',
    fixedOrigin: true,
    fixedDest: false,
    originZones: ['space'],
    destZones: ['planet'],
    defaultOrigin: '地球',
    defaultDest: '火星',
  ),
  IdentityItem(
    name: '太阳远征者',
    iconName: 'rank_solar',
    fixedOrigin: true,
    fixedDest: true,
    defaultOrigin: '地球',
    defaultDest: '太阳',
  ),
];

/// 默认身份
const IdentityItem defaultIdentity = IdentityItem(
  name: '旅行达人',
  iconName: 'rank_traveler',
  originZones: ['domestic'],
  destZones: ['domestic'],
  defaultOrigin: '北京',
  defaultDest: '上海',
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
