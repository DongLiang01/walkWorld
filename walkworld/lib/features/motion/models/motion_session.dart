import 'motion_point.dart';
import 'motion_route_bounds.dart';
import 'motion_type.dart';

/// 表示一次运动结束后得到的最终记录。
class MotionSession {
  const MotionSession({
    this.schemaVersion = 1,
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.totalDistanceMeters,
    required this.points,
    this.motionType,
    this.averageSpeedMps,
    this.routeBounds,
    this.routeSnapshotBase64,
  });

  /// 数据结构版本，用于后续数据库或字段升级时兼容旧记录。
  final int schemaVersion;

  /// 当前运动会话的唯一标识。
  final String sessionId;

  /// 本次运动类型。
  final MotionType? motionType;

  /// 运动开始时间，Unix 毫秒时间戳。
  final int startTime;

  /// 运动结束时间，Unix 毫秒时间戳。
  final int endTime;

  /// 有效运动总时长，单位秒。
  final int durationSeconds;

  /// 最终累计距离，单位米。
  final double totalDistanceMeters;

  /// 最终平均速度，单位米每秒。
  final double? averageSpeedMps;

  /// 本次运动路径的经纬度边界，供详情页地图初始化视野。
  final MotionRouteBounds? routeBounds;

  /// 本次运动的完整轨迹点集合。
  final List<MotionPoint> points;

  /// 运动结束时生成的路线截图，使用 Base64 编码，仅供结束弹窗展示，不入库保存。
  final String? routeSnapshotBase64;

  MotionSession copyWith({
    int? schemaVersion,
    String? sessionId,
    MotionType? motionType,
    int? startTime,
    int? endTime,
    int? durationSeconds,
    double? totalDistanceMeters,
    double? averageSpeedMps,
    MotionRouteBounds? routeBounds,
    List<MotionPoint>? points,
    String? routeSnapshotBase64,
  }) {
    return MotionSession(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sessionId: sessionId ?? this.sessionId,
      motionType: motionType ?? this.motionType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
      routeBounds: routeBounds ?? this.routeBounds,
      points: points ?? this.points,
      routeSnapshotBase64: routeSnapshotBase64 ?? this.routeSnapshotBase64,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'sessionId': sessionId,
      'motionType': motionType?.channelValue,
      'startTime': startTime,
      'endTime': endTime,
      'durationSeconds': durationSeconds,
      'totalDistanceMeters': totalDistanceMeters,
      'averageSpeedMps': averageSpeedMps,
      'routeBounds': routeBounds?.toMap(),
      'points': points.map((point) => point.toMap()).toList(),
      'routeSnapshotBase64': routeSnapshotBase64,
    };
  }

  factory MotionSession.fromMap(Map<Object?, Object?> map) {
    final rawPoints = map['points'] as List<Object?>? ?? const [];
    final rawRouteBounds = map['routeBounds'] as Map<Object?, Object?>?;

    return MotionSession(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      sessionId: map['sessionId'] as String? ?? '',
      motionType: map['motionType'] == null
          ? null
          : motionTypeFromValue(map['motionType'] as String?),
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      endTime: (map['endTime'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      totalDistanceMeters:
          (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      averageSpeedMps: (map['averageSpeedMps'] as num?)?.toDouble(),
      routeBounds: rawRouteBounds == null
          ? null
          : MotionRouteBounds.fromMap(rawRouteBounds),
      points: rawPoints
          .whereType<Map<Object?, Object?>>()
          .map(MotionPoint.fromMap)
          .toList(growable: false),
      routeSnapshotBase64: map['routeSnapshotBase64'] as String?,
    );
  }
}
