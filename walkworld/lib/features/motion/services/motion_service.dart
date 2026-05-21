import 'dart:async';

import 'package:flutter/services.dart';

import '../presentation/widgets/motion_type_sheet.dart';
import 'motion_channel_models.dart';
import 'motion_channel_protocol.dart';

/// 定义运动模块与原生通信所需的能力边界。
abstract class MotionService {
  /// 原生侧持续推送的运动事件流。
  Stream<MotionChannelEvent> get events;

  /// 请求定位权限。
  Future<MotionPermissionResult> requestLocationPermission();

  /// 查询系统定位服务开关状态。
  Future<MotionLocationServiceStatus> getLocationServiceStatus();

  /// 开始一次新的运动会话。
  Future<MotionCommandResult> startWorkout({
    required String sessionId,
    required MotionType motionType,
  });

  /// 暂停当前运动会话。
  Future<MotionCommandResult> pauseWorkout();

  /// 继续当前运动会话。
  Future<MotionCommandResult> resumeWorkout();

  /// 结束当前运动会话，并拿到最终汇总。
  Future<MotionStopResult> stopWorkout();
}

/// 基于 MethodChannel / EventChannel 的默认实现。
class MethodChannelMotionService implements MotionService {
  MethodChannelMotionService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel(MotionChannelNames.method),
        _eventChannel =
            eventChannel ?? const EventChannel(MotionChannelNames.event);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<MotionChannelEvent>? _events;

  @override
  Stream<MotionChannelEvent> get events {
    return _events ??=
        _eventChannel.receiveBroadcastStream().map<MotionChannelEvent>((event) {
      final eventMap = event as Map<Object?, Object?>? ?? const {};
      return MotionChannelEvent.fromMap(eventMap);
    });
  }

  @override
  Future<MotionPermissionResult> requestLocationPermission() async {
    final response = await _invokeMapMethod(
      MotionChannelMethods.requestLocationPermission,
    );
    return MotionPermissionResult.fromMap(response);
  }

  @override
  Future<MotionLocationServiceStatus> getLocationServiceStatus() async {
    final response = await _invokeMapMethod(
      MotionChannelMethods.getLocationServiceStatus,
    );
    return MotionLocationServiceStatus.fromMap(response);
  }

  @override
  Future<MotionCommandResult> startWorkout({
    required String sessionId,
    required MotionType motionType,
  }) async {
    final response = await _invokeMapMethod(
      MotionChannelMethods.startWorkout,
      arguments: {
        'sessionId': sessionId,
        // 将 MotionType 转为原生能识别的字符串。
        'motionType': motionType.channelValue,
      },
    );
    return MotionCommandResult.fromMap(response);
  }

  @override
  Future<MotionCommandResult> pauseWorkout() async {
    final response = await _invokeMapMethod(MotionChannelMethods.pauseWorkout);
    return MotionCommandResult.fromMap(response);
  }

  @override
  Future<MotionCommandResult> resumeWorkout() async {
    final response = await _invokeMapMethod(MotionChannelMethods.resumeWorkout);
    return MotionCommandResult.fromMap(response);
  }

  @override
  Future<MotionStopResult> stopWorkout() async {
    final response = await _invokeMapMethod(MotionChannelMethods.stopWorkout);
    return MotionStopResult.fromMap(response);
  }

  Future<Map<Object?, Object?>> _invokeMapMethod(
    String method, {
    Map<String, Object?>? arguments,
  }) async {
    final response = await _methodChannel.invokeMethod<Object?>(
      method,
      arguments,
    );

    if (response is Map<Object?, Object?>) {
      return response;
    }

    if (response is Map) {
      return Map<Object?, Object?>.from(response);
    }

    return const {};
  }
}
