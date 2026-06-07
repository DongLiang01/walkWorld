import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/motion_history_repository.dart';
import '../models/models.dart';

/// 运动历史记录仓储 Provider。
final motionHistoryRepositoryProvider = Provider<MotionHistoryRepository>((
  ref,
) {
  return MotionHistoryRepository();
});

/// “我的”页历史记录区使用的最新三条运动记录。
final latestMotionSessionsProvider = FutureProvider<List<MotionSession>>((
  ref,
) async {
  final repository = ref.watch(motionHistoryRepositoryProvider);
  return repository.fetchLatestSessions(limit: 3);
});

/// 运动历史列表页使用的全部运动记录。
final allMotionSessionsProvider = FutureProvider<List<MotionSession>>((
  ref,
) async {
  final repository = ref.watch(motionHistoryRepositoryProvider);
  return repository.fetchLatestSessions(limit: null);
});

/// 最近一次运动距离，单位米。
final latestMotionDistanceMetersProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(motionHistoryRepositoryProvider);
  return repository.fetchLatestSessionDistanceMeters();
});

/// 首页和我的页使用的运动汇总统计。
final motionHistoryStatsProvider = FutureProvider<MotionHistoryStats>((
  ref,
) async {
  final repository = ref.watch(motionHistoryRepositoryProvider);
  return repository.fetchStats();
});
