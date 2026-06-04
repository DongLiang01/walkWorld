import 'package:flutter_test/flutter_test.dart';
import 'package:walkworld/features/motion/models/models.dart';

void main() {
  group('MotionSession', () {
    test('可以序列化并反序列化运动类型、路线边界和轨迹点', () {
      const session = MotionSession(
        schemaVersion: 1,
        sessionId: 'motion_1',
        motionType: MotionType.running,
        startTime: 1000,
        endTime: 7000,
        durationSeconds: 6,
        totalDistanceMeters: 32.5,
        averageSpeedMps: 5.4,
        routeBounds: MotionRouteBounds(
          minLatitude: 31.1,
          maxLatitude: 31.2,
          minLongitude: 121.4,
          maxLongitude: 121.5,
        ),
        points: [
          MotionPoint(
            latitude: 31.1,
            longitude: 121.4,
            timestamp: 1000,
            speedMps: 4.8,
            accuracyMeters: 6,
            altitudeMeters: 5,
          ),
          MotionPoint(latitude: 31.2, longitude: 121.5, timestamp: 7000),
        ],
      );

      final restored = MotionSession.fromMap(session.toMap());

      expect(restored.schemaVersion, 1);
      expect(restored.sessionId, 'motion_1');
      expect(restored.motionType, MotionType.running);
      expect(restored.routeBounds?.minLatitude, 31.1);
      expect(restored.routeBounds?.maxLongitude, 121.5);
      expect(restored.points, hasLength(2));
      expect(restored.points.first.speedMps, 4.8);
      expect(restored.points.last.latitude, 31.2);
    });
  });
}
