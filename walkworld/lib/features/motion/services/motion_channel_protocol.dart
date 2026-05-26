/// 统一定义运动模块在 Flutter 与 iOS 原生之间使用的通道名。
final class MotionChannelNames {
  MotionChannelNames._();

  /// MethodChannel 名称，用于 Flutter 主动调用原生方法。
  static const method = 'walkworld/motion_method';

  /// EventChannel 名称，用于原生持续向 Flutter 推送事件。
  static const event = 'walkworld/motion_event';
}

/// 统一定义 Flutter 调用原生时使用的方法名。
final class MotionChannelMethods {
  MotionChannelMethods._();

  static const requestLocationPermission = 'requestLocationPermission';
  static const getLocationServiceStatus = 'getLocationServiceStatus';
  static const startWorkout = 'startWorkout';
  static const pauseWorkout = 'pauseWorkout';
  static const resumeWorkout = 'resumeWorkout';
  static const stopWorkout = 'stopWorkout';
}

/// 统一定义原生推送给 Flutter 的事件名。
enum MotionChannelEventType {
  permissionChanged('permissionChanged'),
  statusChanged('statusChanged'),
  motionUpdated('motionUpdated'),
  error('error');

  const MotionChannelEventType(this.value);

  /// 通道中传输的事件字符串。
  final String value;

  /// 将原生侧事件字符串映射为 Flutter 枚举。
  static MotionChannelEventType? fromValue(String? value) {
    for (final eventType in MotionChannelEventType.values) {
      if (eventType.value == value) {
        return eventType;
      }
    }

    return null;
  }
}

/// 统一定义权限状态字符串，避免 Flutter 与原生两端各写一套魔法值。
enum MotionPermissionStatus {
  notDetermined('not_determined'),
  denied('denied'),
  deniedForever('denied_forever'),
  grantedWhenInUse('granted_when_in_use'),
  grantedAlways('granted_always');

  const MotionPermissionStatus(this.value);

  /// 通道中传输的权限状态字符串。
  final String value;

  /// 将原生侧权限状态字符串映射为 Flutter 枚举。
  static MotionPermissionStatus fromValue(String? value) {
    for (final status in MotionPermissionStatus.values) {
      if (status.value == value) {
        return status;
      }
    }

    return MotionPermissionStatus.notDetermined;
  }
}
