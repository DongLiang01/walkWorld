import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'city_data_provider.dart';
import '../domain/city_model.dart';
import '../../../../app/utils/geo_utils.dart';

/// 目标路径状态载体
class GoalRouteState {
  const GoalRouteState({
    required this.originCity,   //出发地
    required this.destinationCity,  //目的地
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

    // 默认出发地为北京，目的地为上海，具体经纬度从已解析城市列表中获取
    return GoalRouteState(
      originCity: findCityByName(cities, '北京'),
      destinationCity: findCityByName(cities, '上海'),
    );
  }

  /// 更新出发城市
  void updateOrigin(City city) {
    state = state.copyWith(originCity: city);
    // 同时把选择成功的城市追加到搜索历史中
    ref.read(searchHistoryProvider.notifier).addCity(city.name);
  }

  /// 更新目的城市
  void updateDestination(City city) {
    state = state.copyWith(destinationCity: city);
    // 同时把选择成功的城市追加到搜索历史中
    ref.read(searchHistoryProvider.notifier).addCity(city.name);
  }

  /// 互换出发地与目的地
  void swapRoute() {
    state = GoalRouteState(
      originCity: state.destinationCity,
      destinationCity: state.originCity,
    );
  }
}

/// 目标路径 Provider
final goalRouteProvider = NotifierProvider<GoalRouteNotifier, GoalRouteState>(
  GoalRouteNotifier.new,
);

/// 搜索记录/最近城市选择历史管理 Notifier
class SearchHistoryNotifier extends Notifier<List<String>> {
  // 默认包含 Figma 原型上展示的城市
  static const _defaultHistory = ['上海', '广州', '成都', '杭州'];

  @override
  List<String> build() {
    return _defaultHistory;
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
  }

  /// 清除历史记录
  void clearHistory() {
    state = const [];
  }
}

/// 搜索历史 Provider
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

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
  });
  //出发地城市名
  final String originCityName; 
  //目的地城市名
  final String destinationCityName;  
  //两地之间的直线距离
  final double distKm;   
  final String distKmStr; 
  //已经完成的距离 
  final double completedDist;
  final String completedDistStr;
  //已经完成的比例
  final double ratio;
}

//出发地、目的地间距provider
final routeDistanceInfoProvider = Provider<RouteDistanceInfo>((ref) {
  final route = ref.watch(goalRouteProvider);
  final distMeters = calcGeoDistance(
    route.originCity.lat, route.originCity.lng,
    route.destinationCity.lat, route.destinationCity.lng,
  );
  final distKm = distMeters / 1000.0;
  final completedDist = 168.0;
  final ratio = distKm == 0 ? 1.0 : completedDist / distKm;
  return RouteDistanceInfo(
    originCityName: route.originCity.name,
    destinationCityName: route.destinationCity.name,
    distKm: distKm,
    distKmStr: distKm.toStringAsFixed(1),  //留1位小数
    completedDist: completedDist,
    completedDistStr: completedDist.toStringAsFixed(1),
    ratio: ratio,
  );
});
