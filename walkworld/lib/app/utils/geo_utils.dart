import 'dart:math';

/// 地球平均半径，单位：米。
///
/// 用于计算两点之间的大圆距离，适合出发地到目的地的直线距离展示。
const double _earthRadiusMeters = 6371000.0;

/// 使用 Haversine 公式计算两个经纬度坐标之间的地表直线距离，单位：米。
///
/// 参数均为度数：
/// - [lat1]、[lng1]：第一个点的纬度和经度
/// - [lat2]、[lng2]：第二个点的纬度和经度
double calcGeoDistance(double lat1, double lng1, double lat2, double lng2) {
  _validateLatitude(lat1, 'lat1');
  _validateLongitude(lng1, 'lng1');
  _validateLatitude(lat2, 'lat2');
  _validateLongitude(lng2, 'lng2');

  if (lat1 == lat2 && lng1 == lng2) {
    return 0;
  }

  final rLat1 = _degToRad(lat1);
  final rLat2 = _degToRad(lat2);
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);

  final haversineA =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rLat1) * cos(rLat2) * sin(dLng / 2) * sin(dLng / 2);
  final safeA = haversineA.clamp(0.0, 1.0);
  final centralAngle = 2 * atan2(sqrt(safeA), sqrt(1 - safeA));

  return _earthRadiusMeters * centralAngle;
}

/// 角度转弧度
double _degToRad(double deg) => deg * pi / 180.0;

void _validateLatitude(double latitude, String name) {
  if (!latitude.isFinite || latitude < -90 || latitude > 90) {
    throw ArgumentError.value(latitude, name, '纬度必须在 [-90, 90] 范围内');
  }
}

void _validateLongitude(double longitude, String name) {
  if (!longitude.isFinite || longitude < -180 || longitude > 180) {
    throw ArgumentError.value(longitude, name, '经度必须在 [-180, 180] 范围内');
  }
}
