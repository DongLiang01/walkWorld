import 'package:flutter/foundation.dart';

/// 城市实体领域模型
@immutable
class City {
  const City({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
  });

  /// 城市名称
  final String name;

  /// 国家/地区
  final String country;

  /// 纬度
  final double lat;

  /// 经度
  final double lng;

  factory City.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String).trim();
    final country = (json['country'] as String).trim();
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();

    return City(name: name, country: country, lat: lat, lng: lng);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'country': country, 'lat': lat, 'lng': lng};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          country == other.country &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(name, country, lat, lng);
}
