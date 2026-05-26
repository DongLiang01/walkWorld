import 'motion_status.dart';

/// 表示原生侧持续推送的最新运动汇总数据。
class MotionRealtime {
  const MotionRealtime({
    required this.status,
    required this.durationSeconds,
    required this.distanceMeters,
    this.currentSpeedMps,
    this.averageSpeedMps,
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

  MotionRealtime copyWith({
    MotionStatus? status,
    int? durationSeconds,
    double? distanceMeters,
    double? currentSpeedMps,
    double? averageSpeedMps,
  }) {
    return MotionRealtime(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedMps: currentSpeedMps ?? this.currentSpeedMps,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'status': status.value,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'currentSpeedMps': currentSpeedMps,
      'averageSpeedMps': averageSpeedMps,
    };
  }

  factory MotionRealtime.fromMap(Map<Object?, Object?> map) {
    return MotionRealtime(
      status: MotionStatusX.fromValue(map['status'] as String? ?? 'error'),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      currentSpeedMps: (map['currentSpeedMps'] as num?)?.toDouble(),
      averageSpeedMps: (map['averageSpeedMps'] as num?)?.toDouble(),
    );
  }
}
