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
class MotionHistoryRepository {
  Database? _database;

  Future<void> saveSession(MotionSession session) async {
    final database = await _openDatabase();
    final routeBounds =
        session.routeBounds ?? MotionRouteBounds.fromPoints(session.points);
    final motionType = session.motionType ?? MotionType.hiking;
    final now = DateTime.now().millisecondsSinceEpoch;

    await database.transaction((transaction) async {
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
      version: 1,
      onCreate: (database, version) async {
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
      },
    );

    _database = database;
    return database;
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
}
