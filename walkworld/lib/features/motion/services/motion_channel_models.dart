import '../models/models.dart';
import 'motion_channel_protocol.dart';

/// 表示原生推送给 Flutter 的统一事件结构。
class MotionChannelEvent {
  const MotionChannelEvent({required this.type, required this.payload});

  /// 事件类型。
  final MotionChannelEventType type;

  /// 事件负载。
  final Map<Object?, Object?> payload;

  factory MotionChannelEvent.fromMap(Map<Object?, Object?> map) {
    final type = MotionChannelEventType.fromValue(map['event'] as String?);
    final payload = map['payload'] as Map<Object?, Object?>? ?? const {};

    if (type == null) {
      return MotionChannelEvent(
        type: MotionChannelEventType.error,
        payload: {
          'code': 'unknown_event',
          'message': '收到未知的原生事件类型。',
          'detail': map['event']?.toString(),
        },
      );
    }

    return MotionChannelEvent(type: type, payload: payload);
  }
}

/// 定位权限请求结果。
class MotionPermissionResult {
  const MotionPermissionResult({required this.granted, required this.status});

  /// 当前是否已获得可用定位权限。
  final bool granted;

  /// 当前权限状态。
  final MotionPermissionStatus status;

  factory MotionPermissionResult.fromMap(Map<Object?, Object?> map) {
    return MotionPermissionResult(
      granted: map['granted'] as bool? ?? false,
      status: MotionPermissionStatus.fromValue(map['status'] as String?),
    );
  }
}

/// 系统定位服务开关状态。
class MotionLocationServiceStatus {
  const MotionLocationServiceStatus({required this.enabled});

  /// 系统级定位服务是否开启。
  final bool enabled;

  factory MotionLocationServiceStatus.fromMap(Map<Object?, Object?> map) {
    return MotionLocationServiceStatus(
      enabled: map['enabled'] as bool? ?? false,
    );
  }
}

/// 开始、暂停、继续等普通命令的标准返回结果。
class MotionCommandResult {
  const MotionCommandResult({
    required this.accepted,
    required this.status,
    this.startTime,
  });

  /// 原生侧是否接受本次命令。
  final bool accepted;

  /// 命令执行后的运动状态。
  final MotionStatus status;

  /// 仅在开始运动时返回的开始时间。
  final int? startTime;

  factory MotionCommandResult.fromMap(Map<Object?, Object?> map) {
    return MotionCommandResult(
      accepted: map['accepted'] as bool? ?? false,
      status: MotionStatusX.fromValue(map['status'] as String? ?? 'error'),
      startTime: (map['startTime'] as num?)?.toInt(),
    );
  }
}

/// 结束运动后返回的最终结果。
class MotionStopResult {
  const MotionStopResult({
    required this.accepted,
    required this.status,
    required this.summary,
  });

  /// 原生侧是否接受结束命令。
  final bool accepted;

  /// 结束命令执行后的状态。
  final MotionStatus status;

  /// 本次运动的最终汇总结果。
  final MotionSession summary;

  factory MotionStopResult.fromMap(Map<Object?, Object?> map) {
    final summary = map['summary'] as Map<Object?, Object?>? ?? const {};

    return MotionStopResult(
      accepted: map['accepted'] as bool? ?? false,
      status: MotionStatusX.fromValue(map['status'] as String? ?? 'error'),
      summary: MotionSession.fromMap(summary),
    );
  }
}
