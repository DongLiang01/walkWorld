import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lpinyin/lpinyin.dart';

import '../domain/city_model.dart';
import 'identity_provider.dart';

const String _citySeedAssetPath = 'assets/datas/city_seed_data.json';

/// 城市选择页所需的完整数据
class CitySelectData {
  const CitySelectData({required this.cities, required this.groupedCities});

  /// 所有城市列表
  final List<City> cities;

  /// 按首字母分组后的城市列表
  final Map<String, List<City>> groupedCities;
}

/// 所有解析完成的城市列表 Provider
final citiesProvider = FutureProvider<List<City>>((ref) async {
  return _loadCitySeedData();
});

/// 统一读取并解析本地城市 JSON
Future<List<City>> _loadCitySeedData() async {
  final seedJson = await rootBundle.loadString(_citySeedAssetPath);
  final list = jsonDecode(seedJson) as List;
  return list
      .map((item) => City.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// 按拼音首字母分组并排序后的城市 Map Provider
final groupedCitiesProvider = FutureProvider<Map<String, List<City>>>((
  ref,
) async {
  final cities = await ref.watch(citiesProvider.future);
  final groups = <String, List<City>>{};

  for (final city in cities) {
    groups.putIfAbsent(getCityPinyinGroup(city), () => []).add(city);
  }

  // 对分组的 Key (首字母) 进行字母序排列
  final sortedKeys = groups.keys.toList()..sort();
  final sortedGroups = <String, List<City>>{};

  for (final key in sortedKeys) {
    // 组内城市按名称拼音/英文进行排序
    final list = groups[key]!..sort((a, b) => a.name.compareTo(b.name));
    sortedGroups[key] = list;
  }

  return sortedGroups;
});

/// 城市选择页聚合数据 Provider，避免页面重复处理多个异步 Provider
final citySelectDataProvider = FutureProvider<CitySelectData>((ref) async {
  final cities = await ref.watch(citiesProvider.future);
  final groupedCities = await ref.watch(groupedCitiesProvider.future);
  return CitySelectData(cities: cities, groupedCities: groupedCities);
});

/// 根据身份和选择类型（出发/目的）筛选可选城市并分组的聚合 Provider。
///
/// [isOrigin] 为 true 时按 `identity.originZones` 筛选，否则按 `identity.destZones`。
final filteredCitySelectDataProvider =
    FutureProvider.family<CitySelectData, bool>((ref, isOrigin) async {
  final allCities = await ref.watch(citiesProvider.future);
  final identity = ref.watch(identityProvider);
  final allowedZones = isOrigin ? identity.originZones : identity.destZones;

  // 按 zone 筛选
  final filtered =
      allCities.where((c) => allowedZones.contains(c.zone)).toList();

  // 按拼音首字母分组
  final groups = <String, List<City>>{};
  for (final city in filtered) {
    groups.putIfAbsent(getCityPinyinGroup(city), () => []).add(city);
  }
  final sortedKeys = groups.keys.toList()..sort();
  final sortedGroups = <String, List<City>>{};
  for (final key in sortedKeys) {
    sortedGroups[key] = groups[key]!
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  return CitySelectData(cities: filtered, groupedCities: sortedGroups);
});

/// 获取城市用于列表分组的首字母
String getCityPinyinGroup(City city) {
  final name = city.name.trim();
  if (name.isEmpty) return '#';

  final shortPinyin = PinyinHelper.getShortPinyin(name).trim();
  if (shortPinyin.isEmpty) return '#';

  final firstChar = shortPinyin[0].toUpperCase();
  final codeUnit = firstChar.codeUnitAt(0);
  if ((codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122)) {
    return firstChar;
  }

  return '#';
}

/// 从已解析城市列表中按名称查找城市
City findCityByName(List<City> cities, String name) {
  return cities.firstWhere((city) => city.name == name);
}

