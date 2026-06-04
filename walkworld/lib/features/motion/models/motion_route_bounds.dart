import 'motion_point.dart';

/// 表示一条运动路径的经纬度边界。
///
/// 详情页地图可以使用这个边界直接把相机缩放到完整路线范围。
class MotionRouteBounds {
  const MotionRouteBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  Map<String, Object?> toMap() {
    return {
      'minLatitude': minLatitude,
      'maxLatitude': maxLatitude,
      'minLongitude': minLongitude,
      'maxLongitude': maxLongitude,
    };
  }

  factory MotionRouteBounds.fromMap(Map<Object?, Object?> map) {
    return MotionRouteBounds(
      minLatitude: (map['minLatitude'] as num).toDouble(),
      maxLatitude: (map['maxLatitude'] as num).toDouble(),
      minLongitude: (map['minLongitude'] as num).toDouble(),
      maxLongitude: (map['maxLongitude'] as num).toDouble(),
    );
  }

  static MotionRouteBounds? fromPoints(List<MotionPoint> points) {
    if (points.isEmpty) {
      return null;
    }

    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLatitude) minLatitude = point.latitude;
      if (point.latitude > maxLatitude) maxLatitude = point.latitude;
      if (point.longitude < minLongitude) minLongitude = point.longitude;
      if (point.longitude > maxLongitude) maxLongitude = point.longitude;
    }

    return MotionRouteBounds(
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
    );
  }
}
