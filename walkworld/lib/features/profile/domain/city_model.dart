import 'package:flutter/foundation.dart';

/// 城市实体领域模型
@immutable
class City {
  const City({
    required this.name,
    required this.country,
    required this.zone,
    required this.lat,
    required this.lng,
    this.distKm,
  });

  /// 城市名称
  final String name;

  /// 国家/地区
  final String country;

  /// 所属区域：domestic / asia / intercontinental / space / planet
  final String zone;

  /// 纬度
  final double lat;

  /// 经度
  final double lng;

  /// 太空目的地固定距离（km），地球城市为 null
  final double? distKm;

  factory City.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String).trim();
    final country = (json['country'] as String).trim();
    final zone = (json['zone'] as String).trim();
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final distKm =
        json.containsKey('distKm') ? (json['distKm'] as num).toDouble() : null;

    return City(
      name: name,
      country: country,
      zone: zone,
      lat: lat,
      lng: lng,
      distKm: distKm,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'country': country,
      'zone': zone,
      'lat': lat,
      'lng': lng,
    };
    if (distKm != null) {
      map['distKm'] = distKm;
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          country == other.country &&
          zone == other.zone &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(name, country, zone, lat, lng);
}
