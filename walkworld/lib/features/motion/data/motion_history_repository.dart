import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// 运动历史记录本地仓储。
///
/// 存储拆成两张表：
/// 1. `motion_records` 保存每次运动的汇总信息
/// 2. `motion_points` 保存每次运动的完整有效轨迹点
/// 3. `motion_stats` 保存首页和我的页高频读取的汇总统计
class MotionHistoryRepository {
  Database? _database;

  Future<void> saveSession(MotionSession session) async {
    final database = await _openDatabase();
    final routeBounds =
        session.routeBounds ?? MotionRouteBounds.fromPoints(session.points);
    final motionType = session.motionType ?? MotionType.hiking;
    final now = DateTime.now().millisecondsSinceEpoch;

    await database.transaction((transaction) async {
      final existingRows = await transaction.query(
        _recordsTable,
        columns: const ['session_id'],
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
        limit: 1,
      );

      await transaction.delete(
        _pointsTable,
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
      );
      await transaction.delete(
        _recordsTable,
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
      );

      await transaction.insert(_recordsTable, {
        'session_id': session.sessionId,
        'schema_version': session.schemaVersion,
        'motion_type': motionType.channelValue,
        'start_time': session.startTime,
        'end_time': session.endTime,
        'duration_seconds': session.durationSeconds,
        'total_distance_meters': session.totalDistanceMeters,
        'average_speed_mps': session.averageSpeedMps,
        'min_latitude': routeBounds?.minLatitude,
        'max_latitude': routeBounds?.maxLatitude,
        'min_longitude': routeBounds?.minLongitude,
        'max_longitude': routeBounds?.maxLongitude,
        'created_at': now,
      });

      final batch = transaction.batch();
      for (var index = 0; index < session.points.length; index++) {
        final point = session.points[index];
        batch.insert(_pointsTable, {
          'session_id': session.sessionId,
          'point_index': index,
          'latitude': point.latitude,
          'longitude': point.longitude,
          'timestamp': point.timestamp,
          'speed_mps': point.speedMps,
          'accuracy_meters': point.accuracyMeters,
          'altitude_meters': point.altitudeMeters,
        });
      }
      await batch.commit(noResult: true);

      // 理论上 sessionId 不会重复；若出现重复保存，回填能避免汇总表重复累加。
      if (existingRows.isEmpty) {
        await _increaseStats(transaction, session, now);
      } else {
        await _rebuildStats(transaction, now);
      }
    });
  }

  Future<List<MotionSession>> fetchLatestSessions({int limit = 3}) async {
    final database = await _openDatabase();
    final rows = await database.query(
      _recordsTable,
      orderBy: 'end_time DESC',
      limit: limit,
    );

    return rows.map(_sessionFromRecordRow).toList(growable: false);
  }

  Future<MotionSession?> fetchSession(String sessionId) async {
    final database = await _openDatabase();
    final recordRows = await database.query(
      _recordsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (recordRows.isEmpty) {
      return null;
    }

    final pointRows = await database.query(
      _pointsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'point_index ASC',
    );

    return _sessionFromRecordRow(
      recordRows.first,
      points: pointRows.map(_pointFromRow).toList(growable: false),
    );
  }

  /// 获取高频展示使用的运动汇总统计。
  ///
  /// 首次运行、旧库升级后没有汇总记录，或跨周跨月导致周期统计过期时，
  /// 从 `motion_records` 回填一次；正常情况下直接读取 `motion_stats`。
  Future<MotionHistoryStats> fetchStats() async {
    final database = await _openDatabase();
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;
    final monthKey = _monthKey(now);
    final weekKey = _weekKey(now);

    return database.transaction((transaction) async {
      final stats = await _fetchStats(transaction);
      if (stats == null ||
          stats.monthlyKey != monthKey ||
          stats.weeklyKey != weekKey) {
        return _rebuildStats(transaction, nowMillis);
      }
      return stats;
    });
  }

  Future<Database> _openDatabase() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath =
        '${documentsDirectory.path}${Platform.pathSeparator}motion_history.db';
    final database = await openDatabase(
      databasePath,
      version: 2,
      onCreate: (database, version) async {
        await _createSchema(database);
      },
      onUpgrade: (database, oldVersion, version) async {
        if (oldVersion < 2) {
          await _createStatsTable(database);
        }
      },
    );

    _database = database;
    return database;
  }

  Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE $_recordsTable (
        session_id TEXT PRIMARY KEY,
        schema_version INTEGER NOT NULL,
        motion_type TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        total_distance_meters REAL NOT NULL,
        average_speed_mps REAL,
        min_latitude REAL,
        max_latitude REAL,
        min_longitude REAL,
        max_longitude REAL,
        created_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE $_pointsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        point_index INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        speed_mps REAL,
        accuracy_meters REAL,
        altitude_meters REAL,
        FOREIGN KEY(session_id) REFERENCES $_recordsTable(session_id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_motion_records_end_time ON $_recordsTable(end_time DESC)',
    );
    await database.execute(
      'CREATE INDEX idx_motion_points_session_order ON $_pointsTable(session_id, point_index)',
    );
    await _createStatsTable(database);
  }

  Future<void> _createStatsTable(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS $_statsTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        total_distance_meters REAL NOT NULL,
        current_streak_days INTEGER NOT NULL,
        longest_streak_days INTEGER NOT NULL,
        last_active_day_key TEXT,
        monthly_key TEXT NOT NULL,
        monthly_distance_meters REAL NOT NULL,
        monthly_session_count INTEGER NOT NULL,
        weekly_key TEXT NOT NULL,
        weekly_distance_meters REAL NOT NULL,
        weekly_duration_seconds INTEGER NOT NULL,
        weekly_session_count INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _increaseStats(
    Transaction transaction,
    MotionSession session,
    int nowMillis,
  ) async {
    final stats =
        await _fetchStats(transaction) ??
        MotionHistoryStats.empty(now: DateTime.now());
    final endDate = DateTime.fromMillisecondsSinceEpoch(session.endTime);
    final sessionDayKey = _dayKey(endDate);
    final sessionMonthKey = _monthKey(endDate);
    final sessionWeekKey = _weekKey(endDate);

    final monthlyDistance = stats.monthlyKey == sessionMonthKey
        ? stats.monthlyDistanceMeters + session.totalDistanceMeters
        : session.totalDistanceMeters;
    final monthlyCount = stats.monthlyKey == sessionMonthKey
        ? stats.monthlySessionCount + 1
        : 1;
    final weeklyDistance = stats.weeklyKey == sessionWeekKey
        ? stats.weeklyDistanceMeters + session.totalDistanceMeters
        : session.totalDistanceMeters;
    final weeklyDuration = stats.weeklyKey == sessionWeekKey
        ? stats.weeklyDurationSeconds + session.durationSeconds
        : session.durationSeconds;
    final weeklyCount = stats.weeklyKey == sessionWeekKey
        ? stats.weeklySessionCount + 1
        : 1;

    final currentStreak = _nextCurrentStreakDays(
      lastActiveDayKey: stats.lastActiveDayKey,
      currentStreakDays: stats.currentStreakDays,
      sessionDayKey: sessionDayKey,
    );
    final longestStreak = currentStreak > stats.longestStreakDays
        ? currentStreak
        : stats.longestStreakDays;

    await _upsertStats(
      transaction,
      stats.copyWith(
        totalDistanceMeters:
            stats.totalDistanceMeters + session.totalDistanceMeters,
        currentStreakDays: currentStreak,
        longestStreakDays: longestStreak,
        lastActiveDayKey: sessionDayKey,
        monthlyKey: sessionMonthKey,
        monthlyDistanceMeters: monthlyDistance,
        monthlySessionCount: monthlyCount,
        weeklyKey: sessionWeekKey,
        weeklyDistanceMeters: weeklyDistance,
        weeklyDurationSeconds: weeklyDuration,
        weeklySessionCount: weeklyCount,
        updatedAt: nowMillis,
      ),
    );
  }

  Future<MotionHistoryStats> _rebuildStats(
    DatabaseExecutor executor,
    int nowMillis,
  ) async {
    final now = DateTime.fromMillisecondsSinceEpoch(nowMillis);
    final currentMonthKey = _monthKey(now);
    final currentWeekKey = _weekKey(now);
    final rows = await executor.query(
      _recordsTable,
      columns: const ['end_time', 'duration_seconds', 'total_distance_meters'],
      orderBy: 'end_time ASC',
    );

    var totalDistanceMeters = 0.0;
    var monthlyDistanceMeters = 0.0;
    var monthlySessionCount = 0;
    var weeklyDistanceMeters = 0.0;
    var weeklyDurationSeconds = 0;
    var weeklySessionCount = 0;
    var currentStreakDays = 0;
    var longestStreakDays = 0;
    String? previousDayKey;
    String? lastActiveDayKey;

    for (final row in rows) {
      final endTime = (row['end_time'] as num).toInt();
      final distance = (row['total_distance_meters'] as num).toDouble();
      final durationSeconds = (row['duration_seconds'] as num).toInt();
      final endDate = DateTime.fromMillisecondsSinceEpoch(endTime);
      final dayKey = _dayKey(endDate);

      totalDistanceMeters += distance;
      if (_monthKey(endDate) == currentMonthKey) {
        monthlyDistanceMeters += distance;
        monthlySessionCount += 1;
      }
      if (_weekKey(endDate) == currentWeekKey) {
        weeklyDistanceMeters += distance;
        weeklyDurationSeconds += durationSeconds;
        weeklySessionCount += 1;
      }

      if (dayKey == previousDayKey) {
        lastActiveDayKey = dayKey;
        continue;
      }
      currentStreakDays = _nextCurrentStreakDays(
        lastActiveDayKey: previousDayKey,
        currentStreakDays: currentStreakDays,
        sessionDayKey: dayKey,
      );
      if (currentStreakDays > longestStreakDays) {
        longestStreakDays = currentStreakDays;
      }
      previousDayKey = dayKey;
      lastActiveDayKey = dayKey;
    }

    if (!_isCurrentStreakActive(lastActiveDayKey, now)) {
      currentStreakDays = 0;
    }

    final stats = MotionHistoryStats(
      totalDistanceMeters: totalDistanceMeters,
      currentStreakDays: currentStreakDays,
      longestStreakDays: longestStreakDays,
      lastActiveDayKey: lastActiveDayKey,
      monthlyKey: currentMonthKey,
      monthlyDistanceMeters: monthlyDistanceMeters,
      monthlySessionCount: monthlySessionCount,
      weeklyKey: currentWeekKey,
      weeklyDistanceMeters: weeklyDistanceMeters,
      weeklyDurationSeconds: weeklyDurationSeconds,
      weeklySessionCount: weeklySessionCount,
      updatedAt: nowMillis,
    );
    await _upsertStats(executor, stats);
    return stats;
  }

  Future<MotionHistoryStats?> _fetchStats(DatabaseExecutor executor) async {
    final rows = await executor.query(
      _statsTable,
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return MotionHistoryStats.fromRow(rows.first);
  }

  Future<void> _upsertStats(
    DatabaseExecutor executor,
    MotionHistoryStats stats,
  ) async {
    await executor.insert(
      _statsTable,
      stats.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  int _nextCurrentStreakDays({
    required String? lastActiveDayKey,
    required int currentStreakDays,
    required String sessionDayKey,
  }) {
    if (lastActiveDayKey == sessionDayKey) {
      return currentStreakDays == 0 ? 1 : currentStreakDays;
    }
    if (lastActiveDayKey != null &&
        _dayKey(_parseDayKey(lastActiveDayKey).add(const Duration(days: 1))) ==
            sessionDayKey) {
      return currentStreakDays + 1;
    }
    return 1;
  }

  bool _isCurrentStreakActive(String? lastActiveDayKey, DateTime now) {
    if (lastActiveDayKey == null) {
      return false;
    }
    final todayKey = _dayKey(now);
    final yesterdayKey = _dayKey(now.subtract(const Duration(days: 1)));
    return lastActiveDayKey == todayKey || lastActiveDayKey == yesterdayKey;
  }

  String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  /// 固定按周一作为一周开始，避免受系统区域设置影响。
  String _weekKey(DateTime date) {
    final monday = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
    return _dayKey(monday);
  }

  DateTime _parseDayKey(String dayKey) {
    final parts = dayKey.split('-').map(int.parse).toList(growable: false);
    return DateTime(parts[0], parts[1], parts[2]);
  }

  MotionSession _sessionFromRecordRow(
    Map<String, Object?> row, {
    List<MotionPoint> points = const [],
  }) {
    return MotionSession(
      schemaVersion: row['schema_version'] as int? ?? 1,
      sessionId: row['session_id'] as String? ?? '',
      motionType: motionTypeFromValue(row['motion_type'] as String?),
      startTime: row['start_time'] as int? ?? 0,
      endTime: row['end_time'] as int? ?? 0,
      durationSeconds: row['duration_seconds'] as int? ?? 0,
      totalDistanceMeters:
          (row['total_distance_meters'] as num?)?.toDouble() ?? 0,
      averageSpeedMps: (row['average_speed_mps'] as num?)?.toDouble(),
      routeBounds: _routeBoundsFromRow(row),
      points: points,
    );
  }

  MotionPoint _pointFromRow(Map<String, Object?> row) {
    return MotionPoint(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      timestamp: (row['timestamp'] as num).toInt(),
      speedMps: (row['speed_mps'] as num?)?.toDouble(),
      accuracyMeters: (row['accuracy_meters'] as num?)?.toDouble(),
      altitudeMeters: (row['altitude_meters'] as num?)?.toDouble(),
    );
  }

  MotionRouteBounds? _routeBoundsFromRow(Map<String, Object?> row) {
    final minLatitude = (row['min_latitude'] as num?)?.toDouble();
    final maxLatitude = (row['max_latitude'] as num?)?.toDouble();
    final minLongitude = (row['min_longitude'] as num?)?.toDouble();
    final maxLongitude = (row['max_longitude'] as num?)?.toDouble();

    if (minLatitude == null ||
        maxLatitude == null ||
        minLongitude == null ||
        maxLongitude == null) {
      return null;
    }

    return MotionRouteBounds(
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
    );
  }

  static const _recordsTable = 'motion_records';
  static const _pointsTable = 'motion_points';
  static const _statsTable = 'motion_stats';
}

/// 运动历史汇总统计。
class MotionHistoryStats {
  const MotionHistoryStats({
    required this.totalDistanceMeters,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastActiveDayKey,
    required this.monthlyKey,
    required this.monthlyDistanceMeters,
    required this.monthlySessionCount,
    required this.weeklyKey,
    required this.weeklyDistanceMeters,
    required this.weeklyDurationSeconds,
    required this.weeklySessionCount,
    required this.updatedAt,
  });

  /// 历史累计运动距离，单位米。
  final double totalDistanceMeters;

  /// 当前连续运动天数，今天或昨天有运动时才保持连续。
  final int currentStreakDays;

  /// 历史最大连续运动天数。
  final int longestStreakDays;

  /// 最近一次发生运动的日期 key，格式为 yyyy-MM-dd。
  final String? lastActiveDayKey;

  /// 当前月 key，格式为 yyyy-MM。
  final String monthlyKey;

  /// 本月累计运动距离，单位米。
  final double monthlyDistanceMeters;

  /// 本月运动次数。
  final int monthlySessionCount;

  /// 当前周 key，固定取周一日期，格式为 yyyy-MM-dd。
  final String weeklyKey;

  /// 本周累计运动距离，单位米。
  final double weeklyDistanceMeters;

  /// 本周累计运动时长，单位秒。
  final int weeklyDurationSeconds;

  /// 本周运动次数。
  final int weeklySessionCount;

  /// 汇总数据更新时间，单位 Unix 毫秒。
  final int updatedAt;

  factory MotionHistoryStats.empty({required DateTime now}) {
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final weekKey =
        '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
    return MotionHistoryStats(
      totalDistanceMeters: 0,
      currentStreakDays: 0,
      longestStreakDays: 0,
      lastActiveDayKey: null,
      monthlyKey: monthKey,
      monthlyDistanceMeters: 0,
      monthlySessionCount: 0,
      weeklyKey: weekKey,
      weeklyDistanceMeters: 0,
      weeklyDurationSeconds: 0,
      weeklySessionCount: 0,
      updatedAt: DateTime.parse(dayKey).millisecondsSinceEpoch,
    );
  }

  factory MotionHistoryStats.fromRow(Map<String, Object?> row) {
    return MotionHistoryStats(
      totalDistanceMeters:
          (row['total_distance_meters'] as num?)?.toDouble() ?? 0,
      currentStreakDays: (row['current_streak_days'] as num?)?.toInt() ?? 0,
      longestStreakDays: (row['longest_streak_days'] as num?)?.toInt() ?? 0,
      lastActiveDayKey: row['last_active_day_key'] as String?,
      monthlyKey: row['monthly_key'] as String? ?? '',
      monthlyDistanceMeters:
          (row['monthly_distance_meters'] as num?)?.toDouble() ?? 0,
      monthlySessionCount: (row['monthly_session_count'] as num?)?.toInt() ?? 0,
      weeklyKey: row['weekly_key'] as String? ?? '',
      weeklyDistanceMeters:
          (row['weekly_distance_meters'] as num?)?.toDouble() ?? 0,
      weeklyDurationSeconds:
          (row['weekly_duration_seconds'] as num?)?.toInt() ?? 0,
      weeklySessionCount: (row['weekly_session_count'] as num?)?.toInt() ?? 0,
      updatedAt: (row['updated_at'] as num?)?.toInt() ?? 0,
    );
  }

  MotionHistoryStats copyWith({
    double? totalDistanceMeters,
    int? currentStreakDays,
    int? longestStreakDays,
    String? lastActiveDayKey,
    String? monthlyKey,
    double? monthlyDistanceMeters,
    int? monthlySessionCount,
    String? weeklyKey,
    double? weeklyDistanceMeters,
    int? weeklyDurationSeconds,
    int? weeklySessionCount,
    int? updatedAt,
  }) {
    return MotionHistoryStats(
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastActiveDayKey: lastActiveDayKey ?? this.lastActiveDayKey,
      monthlyKey: monthlyKey ?? this.monthlyKey,
      monthlyDistanceMeters:
          monthlyDistanceMeters ?? this.monthlyDistanceMeters,
      monthlySessionCount: monthlySessionCount ?? this.monthlySessionCount,
      weeklyKey: weeklyKey ?? this.weeklyKey,
      weeklyDistanceMeters: weeklyDistanceMeters ?? this.weeklyDistanceMeters,
      weeklyDurationSeconds:
          weeklyDurationSeconds ?? this.weeklyDurationSeconds,
      weeklySessionCount: weeklySessionCount ?? this.weeklySessionCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': 1,
      'total_distance_meters': totalDistanceMeters,
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'last_active_day_key': lastActiveDayKey,
      'monthly_key': monthlyKey,
      'monthly_distance_meters': monthlyDistanceMeters,
      'monthly_session_count': monthlySessionCount,
      'weekly_key': weeklyKey,
      'weekly_distance_meters': weeklyDistanceMeters,
      'weekly_duration_seconds': weeklyDurationSeconds,
      'weekly_session_count': weeklySessionCount,
      'updated_at': updatedAt,
    };
  }
}
