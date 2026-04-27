import 'motion_point.dart';

/// 表示一次运动结束后得到的最终记录。
class MotionSession {
  const MotionSession({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.totalDistanceMeters,
    required this.points,
    this.averageSpeedMps,
  });

  /// 当前运动会话的唯一标识。
  final String sessionId;

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

  /// 本次运动的完整轨迹点集合。
  final List<MotionPoint> points;

  MotionSession copyWith({
    String? sessionId,
    int? startTime,
    int? endTime,
    int? durationSeconds,
    double? totalDistanceMeters,
    double? averageSpeedMps,
    List<MotionPoint>? points,
  }) {
    return MotionSession(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
      points: points ?? this.points,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'sessionId': sessionId,
      'startTime': startTime,
      'endTime': endTime,
      'durationSeconds': durationSeconds,
      'totalDistanceMeters': totalDistanceMeters,
      'averageSpeedMps': averageSpeedMps,
      'points': points.map((point) => point.toMap()).toList(),
    };
  }

  factory MotionSession.fromMap(Map<Object?, Object?> map) {
    final rawPoints = map['points'] as List<Object?>? ?? const [];

    return MotionSession(
      sessionId: map['sessionId'] as String? ?? '',
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      endTime: (map['endTime'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      totalDistanceMeters:
          (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      averageSpeedMps: (map['averageSpeedMps'] as num?)?.toDouble(),
      points: rawPoints
          .whereType<Map<Object?, Object?>>()
          .map(MotionPoint.fromMap)
          .toList(growable: false),
    );
  }
}
