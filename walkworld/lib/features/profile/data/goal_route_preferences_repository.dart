import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 目标路线与搜索记录的本地偏好仓储。
///
/// Provider 仍保持同步读取，启动时先调用 [initialize] 预热缓存；
/// 用户后续选择城市时再异步写回本地文件。
class GoalRoutePreferencesRepository {
  static const _fileName = 'goal_route_preferences.json';
  static const _originCityKey = 'originCityName';
  static const _destinationCityKey = 'destinationCityName';
  static const _searchHistoryKey = 'searchHistory';
  static const _identityKey = 'identity';

  static String? _originCityName;
  static String? _destinationCityName;
  static List<String> _searchHistory = const [];
  static String? _identity;
  static bool _initialized = false;

  /// 启动时读取本地缓存，失败时保持空缓存并使用业务默认值兜底。
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final file = await _preferencesFile();
      if (!await file.exists()) {
        _initialized = true;
        return;
      }

      final rawContent = await file.readAsString();
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        _initialized = true;
        return;
      }

      _originCityName = _stringValue(decoded[_originCityKey]);
      _destinationCityName = _stringValue(decoded[_destinationCityKey]);
      _searchHistory = _stringListValue(decoded[_searchHistoryKey]);
      _identity = _stringValue(decoded[_identityKey]);
    } catch (_) {
      _originCityName = null;
      _destinationCityName = null;
      _searchHistory = const [];
      _identity = null;
    } finally {
      _initialized = true;
    }
  }

  /// 已缓存的出发城市名。
  static String? get originCityName => _originCityName;

  /// 已缓存的目的城市名。
  static String? get destinationCityName => _destinationCityName;

  /// 已缓存的搜索记录。
  static List<String> get searchHistory => List.unmodifiable(_searchHistory);

  /// 已缓存的用户身份。
  static String? get identity => _identity;

  /// 保存出发地和目的地。
  static Future<void> saveRoute({
    required String originCityName,
    required String destinationCityName,
  }) async {
    _originCityName = originCityName;
    _destinationCityName = destinationCityName;
    await _writePreferences();
  }

  /// 保存搜索记录。
  static Future<void> saveSearchHistory(List<String> history) async {
    _searchHistory = List.unmodifiable(history);
    await _writePreferences();
  }

  /// 保存用户身份。
  static Future<void> saveIdentity(String identity) async {
    _identity = identity;
    await _writePreferences();
  }

  static Future<void> _writePreferences() async {
    try {
      final file = await _preferencesFile();
      await file.writeAsString(
        jsonEncode({
          _originCityKey: _originCityName,
          _destinationCityKey: _destinationCityName,
          _searchHistoryKey: _searchHistory,
          _identityKey: _identity,
        }),
        flush: true,
      );
    } catch (_) {
      // 本地偏好写入失败不应阻断用户选择城市，下一次仍使用内存状态。
    }
  }

  static Future<File> _preferencesFile() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return File(
      '${documentsDirectory.path}${Platform.pathSeparator}$_fileName',
    );
  }

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _stringListValue(Object? value) {
    if (value is! List) return const [];

    final result = <String>[];
    for (final item in value) {
      final cityName = _stringValue(item);
      if (cityName == null || result.contains(cityName)) continue;
      result.add(cityName);
      if (result.length >= 5) break;
    }
    return List.unmodifiable(result);
  }
}
