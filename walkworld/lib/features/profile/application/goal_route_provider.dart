import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../motion/application/motion_history_provider.dart';
import '../data/goal_route_preferences_repository.dart';
import 'city_data_provider.dart';
import '../domain/city_model.dart';
import '../../../../app/utils/geo_utils.dart';

/// 目标路径状态载体
class GoalRouteState {
  const GoalRouteState({
    required this.originCity, //出发地
    required this.destinationCity, //目的地
  });

  final City originCity;
  final City destinationCity;

  GoalRouteState copyWith({City? originCity, City? destinationCity}) {
    return GoalRouteState(
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
    );
  }
}

/// 目标路径状态管理 Notifier
class GoalRouteNotifier extends Notifier<GoalRouteState> {
  @override
  GoalRouteState build() {
    final cities = ref.read(citiesProvider).requireValue;
    final savedOriginName = GoalRoutePreferencesRepository.originCityName;
    final savedDestinationName =
        GoalRoutePreferencesRepository.destinationCityName;

    // 优先恢复本地保存的路线；首次运行或缓存失效时再使用北京到上海兜底。
    return GoalRouteState(
      originCity:
          _findCityByNameOrNull(cities, savedOriginName) ??
          findCityByName(cities, '北京'),
      destinationCity:
          _findCityByNameOrNull(cities, savedDestinationName) ??
          findCityByName(cities, '上海'),
    );
  }

  /// 更新出发城市
  void updateOrigin(City city) {
    state = state.copyWith(originCity: city);
    // 同时把选择成功的城市追加到搜索历史中
    ref.read(searchHistoryProvider.notifier).addCity(city.name);
    _saveRoute();
  }

  /// 更新目的城市
  void updateDestination(City city) {
    state = state.copyWith(destinationCity: city);
    // 同时把选择成功的城市追加到搜索历史中
    ref.read(searchHistoryProvider.notifier).addCity(city.name);
    _saveRoute();
  }

  /// 互换出发地与目的地
  void swapRoute() {
    state = GoalRouteState(
      originCity: state.destinationCity,
      destinationCity: state.originCity,
    );
    _saveRoute();
  }

  void _saveRoute() {
    unawaited(
      GoalRoutePreferencesRepository.saveRoute(
        originCityName: state.originCity.name,
        destinationCityName: state.destinationCity.name,
      ),
    );
  }
}

/// 目标路径 Provider
final goalRouteProvider = NotifierProvider<GoalRouteNotifier, GoalRouteState>(
  GoalRouteNotifier.new,
);

/// 搜索记录/最近城市选择历史管理 Notifier
class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return GoalRoutePreferencesRepository.searchHistory;
  }

  /// 添加城市到最近记录（若已存在则移到最前，最多保留 5 个）
  void addCity(String name) {
    final current = List<String>.from(state);
    current.remove(name); // 去重
    current.insert(0, name); // 插到最前
    if (current.length > 5) {
      current.removeLast(); // 保持最多 5 个
    }
    state = current;
    _saveHistory();
  }

  /// 清除历史记录
  void clearHistory() {
    state = const [];
    _saveHistory();
  }

  void _saveHistory() {
    unawaited(GoalRoutePreferencesRepository.saveSearchHistory(state));
  }
}

/// 搜索历史 Provider
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

City? _findCityByNameOrNull(List<City> cities, String? name) {
  if (name == null) return null;
  for (final city in cities) {
    if (city.name == name) return city;
  }
  return null;
}

/// 出发地和目的地之间的距离、进度信息载体
class RouteDistanceInfo {
  const RouteDistanceInfo({
    required this.originCityName,
    required this.destinationCityName,
    required this.distKm,
    required this.distKmStr,
    required this.completedDist,
    required this.completedDistStr,
    required this.ratio,
    required this.totalDistanceMeters,
    required this.monthlyDistanceKm,
    required this.monthlyDistanceKmStr,
    required this.monthlySessionCount,
    required this.weeklyDistanceKm,
    required this.weeklyDistanceKmStr,
    required this.weeklyDurationSeconds,
    required this.weeklyDurationHoursStr,
    required this.weeklySessionCount,
    required this.currentStreakDays,
    required this.longestStreakDays,
  });
  //出发地城市名
  final String originCityName;
  //目的地城市名
  final String destinationCityName;
  //两地之间的直线距离
  final double distKm;
  final String distKmStr;
  //历史累计运动距离，单位公里
  final double completedDist;
  final String completedDistStr;
  //已经完成的比例
  final double ratio;
  //历史累计运动距离，单位米
  final double totalDistanceMeters;
  //本月累计运动距离，单位公里
  final double monthlyDistanceKm;
  //本月累计运动距离展示文案，保留1位小数
  final String monthlyDistanceKmStr;
  //本月运动次数
  final int monthlySessionCount;
  //本周累计运动距离，单位公里
  final double weeklyDistanceKm;
  //本周累计运动距离展示文案，保留1位小数
  final String weeklyDistanceKmStr;
  //本周累计运动时长，单位秒
  final int weeklyDurationSeconds;
  //本周累计运动时长展示文案，单位小时，保留1位小数
  final String weeklyDurationHoursStr;
  //本周运动次数
  final int weeklySessionCount;
  //当前连续运动天数
  final int currentStreakDays;
  //历史最大连续运动天数
  final int longestStreakDays;
}

//出发地、目的地间距provider
final routeDistanceInfoProvider = FutureProvider<RouteDistanceInfo>((
  ref,
) async {
  final route = ref.watch(goalRouteProvider);
  final motionStats = await ref.watch(motionHistoryStatsProvider.future);
  final distMeters = calcGeoDistance(
    route.originCity.lat,
    route.originCity.lng,
    route.destinationCity.lat,
    route.destinationCity.lng,
  );
  final distKm = distMeters / 1000.0;
  final completedDist = motionStats.totalDistanceMeters / 1000.0;
  final ratio = distKm == 0
      ? 1.0
      : (completedDist / distKm).clamp(0.0, 1.0).toDouble(); //clamp是把值限定在0和1之间
  final monthlyDistanceKm = motionStats.monthlyDistanceMeters / 1000.0;
  final weeklyDistanceKm = motionStats.weeklyDistanceMeters / 1000.0;
  final weeklyDurationHours = motionStats.weeklyDurationSeconds / 3600.0;
  return RouteDistanceInfo(
    originCityName: route.originCity.name,
    destinationCityName: route.destinationCity.name,
    distKm: distKm,
    distKmStr: distKm.toStringAsFixed(1), //留1位小数
    completedDist: completedDist,
    completedDistStr: completedDist.toStringAsFixed(1),
    ratio: ratio,
    totalDistanceMeters: motionStats.totalDistanceMeters,
    monthlyDistanceKm: monthlyDistanceKm,
    monthlyDistanceKmStr: monthlyDistanceKm.toStringAsFixed(1),
    monthlySessionCount: motionStats.monthlySessionCount,
    weeklyDistanceKm: weeklyDistanceKm,
    weeklyDistanceKmStr: weeklyDistanceKm.toStringAsFixed(1),
    weeklyDurationSeconds: motionStats.weeklyDurationSeconds,
    weeklyDurationHoursStr: weeklyDurationHours.toStringAsFixed(1),
    weeklySessionCount: motionStats.weeklySessionCount,
    currentStreakDays: motionStats.currentStreakDays,
    longestStreakDays: motionStats.longestStreakDays,
  );
});
