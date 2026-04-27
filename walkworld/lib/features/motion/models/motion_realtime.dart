import 'motion_point.dart';
import 'motion_status.dart';

/// 表示原生侧持续推送的最新运动汇总数据。
class MotionRealtime {
  const MotionRealtime({
    required this.status,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.pointCount,
    this.currentSpeedMps,
    this.averageSpeedMps,
    this.latestPoint,
  });

  /// 当前运动状态。
  final MotionStatus status;

  /// 有效运动时长，单位秒。
  final int durationSeconds;

  /// 当前累计有效距离，单位米。
  final double distanceMeters;

  /// 当前速度，单位米每秒。
  final double? currentSpeedMps;

  /// 当前平均速度，单位米每秒。
  final double? averageSpeedMps;

  /// 当前已采纳的有效轨迹点数量。
  final int pointCount;

  /// 最近一个被采纳的轨迹点，没有时为空。
  final MotionPoint? latestPoint;

  MotionRealtime copyWith({
    MotionStatus? status,
    int? durationSeconds,
    double? distanceMeters,
    double? currentSpeedMps,
    double? averageSpeedMps,
    int? pointCount,
    MotionPoint? latestPoint,
  }) {
    return MotionRealtime(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedMps: currentSpeedMps ?? this.currentSpeedMps,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
      pointCount: pointCount ?? this.pointCount,
      latestPoint: latestPoint ?? this.latestPoint,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'status': status.value,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'currentSpeedMps': currentSpeedMps,
      'averageSpeedMps': averageSpeedMps,
      'pointCount': pointCount,
      'latestPoint': latestPoint?.toMap(),
    };
  }

  factory MotionRealtime.fromMap(Map<Object?, Object?> map) {
    final latestPointMap = map['latestPoint'] as Map<Object?, Object?>?;

    return MotionRealtime(
      status: MotionStatusX.fromValue(map['status'] as String? ?? 'error'),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      currentSpeedMps: (map['currentSpeedMps'] as num?)?.toDouble(),
      averageSpeedMps: (map['averageSpeedMps'] as num?)?.toDouble(),
      pointCount: (map['pointCount'] as num?)?.toInt() ?? 0,
      latestPoint: latestPointMap == null
          ? null
          : MotionPoint.fromMap(latestPointMap),
    );
  }
}
