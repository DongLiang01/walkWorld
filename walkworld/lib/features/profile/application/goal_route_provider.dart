import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../motion/application/motion_history_provider.dart';
import '../data/goal_route_preferences_repository.dart';
import 'city_data_provider.dart';
import 'identity_provider.dart';
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
    final identity = ref.watch(identityProvider);

    // 完全固定路线的身份（环球旅行家 / 太空固定身份），直接使用默认路线
    if (identity.isFullyFixed) {
      // 环球旅行家没有实际城市，给一个兜底即可（UI 上不展示）
      if (identity.isGlobal) {
        return GoalRouteState(
          originCity: findCityByName(cities, '北京'),
          destinationCity: findCityByName(cities, '上海'),
        );
      }
      return GoalRouteState(
        originCity: findCityByName(cities, identity.defaultOrigin),
        destinationCity: findCityByName(cities, identity.defaultDest),
      );
    }

    // 非固定路线：尝试恢复本地保存的路线
    final savedOriginName = GoalRoutePreferencesRepository.originCityName;
    final savedDestinationName =
        GoalRoutePreferencesRepository.destinationCityName;

    final savedOrigin = _findCityByNameOrNull(cities, savedOriginName);
    final savedDest = _findCityByNameOrNull(cities, savedDestinationName);

    // 校验已保存的城市是否在当前身份允许的 zone 内
    final originValid =
        savedOrigin != null &&
        (identity.fixedOrigin ||
            identity.originZones.contains(savedOrigin.zone));
    final destValid =
        savedDest != null && identity.destZones.contains(savedDest.zone);

    final City originCity;
    if (identity.fixedOrigin) {
      originCity = findCityByName(cities, identity.defaultOrigin);
    } else if (savedOrigin != null && originValid) {
      originCity = savedOrigin;
    } else {
      originCity = findCityByName(cities, identity.defaultOrigin);
    }

    final City destCity;
    if (savedDest != null && destValid) {
      destCity = savedDest;
    } else {
      destCity = findCityByName(cities, identity.defaultDest);
    }

    return GoalRouteState(
      originCity: originCity,
      destinationCity: destCity,
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
  final identity = ref.watch(identityProvider);
  final motionStats = await ref.watch(motionHistoryStatsProvider.future);

  // 根据身份类型决定目标距离和展示名称
  final double distKm;
  final String originName;
  final String destName;
  if (identity.isGlobal) {
    // 环球旅行家模式：目标距离固定为地球赤道周长 40,075 km
    distKm = 40075.0;
    originName = '环绕地球一周';
    destName = '环绕地球一周';
  } else if (route.destinationCity.distKm != null) {
    // 太空目的地：使用固定距离
    distKm = route.destinationCity.distKm!;
    originName = route.originCity.name;
    destName = route.destinationCity.name;
  } else {
    // 地球城市间：计算直线距离
    final distMeters = calcGeoDistance(
      route.originCity.lat,
      route.originCity.lng,
      route.destinationCity.lat,
      route.destinationCity.lng,
    );
    distKm = distMeters / 1000.0;
    originName = route.originCity.name;
    destName = route.destinationCity.name;
  }

  final completedDist = motionStats.totalDistanceMeters / 1000.0;
  final ratio = distKm == 0
      ? 1.0
      : (completedDist / distKm).clamp(0.0, 1.0).toDouble(); //clamp是把值限定在0和1之间
  final monthlyDistanceKm = motionStats.monthlyDistanceMeters / 1000.0;
  final weeklyDistanceKm = motionStats.weeklyDistanceMeters / 1000.0;
  final weeklyDurationHours = motionStats.weeklyDurationSeconds / 3600.0;
  return RouteDistanceInfo(
    originCityName: originName,
    destinationCityName: destName,
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
