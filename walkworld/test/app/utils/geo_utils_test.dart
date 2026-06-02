import 'package:flutter_test/flutter_test.dart';
import 'package:walkworld/app/utils/geo_utils.dart';

void main() {
  group('calcGeoDistance', () {
    test('相同坐标返回 0', () {
      expect(calcGeoDistance(31.2304, 121.4737, 31.2304, 121.4737), 0);
    });

    test('计算上海到北京的大圆直线距离', () {
      final distanceMeters = calcGeoDistance(
        31.2304,
        121.4737,
        39.9042,
        116.4074,
      );

      expect(distanceMeters, closeTo(1067500, 1000));
    });

    test('非法经纬度会抛出参数错误', () {
      expect(
        () => calcGeoDistance(91, 121.4737, 39.9042, 116.4074),
        throwsArgumentError,
      );
      expect(
        () => calcGeoDistance(31.2304, double.nan, 39.9042, 116.4074),
        throwsArgumentError,
      );
    });
  });
}
