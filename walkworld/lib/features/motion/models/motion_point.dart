/// 表示运动轨迹中的一个定位点。
class MotionPoint {
  const MotionPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speedMps,
    this.accuracyMeters,
    this.altitudeMeters,
  });

  /// 纬度，单位为度。
  final double latitude;

  /// 经度，单位为度。
  final double longitude;

  /// 该定位点产生时的 Unix 毫秒时间戳。
  final int timestamp;

  /// 当前瞬时速度，单位米每秒，原生有返回时才有值。
  final double? speedMps;

  /// 水平定位精度，单位米。
  final double? accuracyMeters;

  /// 海拔高度，单位米。
  final double? altitudeMeters;

  MotionPoint copyWith({
    double? latitude,
    double? longitude,
    int? timestamp,
    double? speedMps,
    double? accuracyMeters,
    double? altitudeMeters,
  }) {
    return MotionPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speedMps: speedMps ?? this.speedMps,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'speedMps': speedMps,
      'accuracyMeters': accuracyMeters,
      'altitudeMeters': altitudeMeters,
    };
  }

  factory MotionPoint.fromMap(Map<Object?, Object?> map) {
    return MotionPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: (map['timestamp'] as num).toInt(),
      speedMps: (map['speedMps'] as num?)?.toDouble(),
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      altitudeMeters: (map['altitudeMeters'] as num?)?.toDouble(),
    );
  }
}
