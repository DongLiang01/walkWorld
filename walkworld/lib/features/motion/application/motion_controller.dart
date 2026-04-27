import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'motion_service_provider.dart';
import 'motion_state.dart';

/// 负责驱动运动模块状态流转的控制器。
///
/// 它承担三类职责：
/// 1. 调用原生 service 执行业务命令
/// 2. 监听原生事件流并更新 Flutter 状态
/// 3. 对外暴露统一的开始、暂停、继续、结束入口
class MotionController extends Notifier<MotionState> {
  StreamSubscription<MotionChannelEvent>? _eventSubscription;

  MotionService get _motionService => ref.read(motionServiceProvider);

  @override
  MotionState build() {
    _bindNativeEvents();
    ref.onDispose(() => _eventSubscription?.cancel());
    return MotionState.initial().copyWith(isEventListening: true);
  }

  /// 初始化页面依赖的基础信息。
  ///
  /// 当前主要做两件事：
  /// 1. 查询系统定位服务是否开启
  /// 2. 保证原生事件监听已经建立
  Future<void> initialize() async {
    try {
      final locationServiceStatus =
          await _motionService.getLocationServiceStatus();

      state = state.copyWith(
        locationServiceEnabled: locationServiceStatus.enabled,
        error: null,
      );
    } catch (error) {
      _setError(
        code: 'location_service_status_failed',
        message: '查询定位服务状态失败。',
        detail: error.toString(),
      );
    }
  }

  /// 主动请求定位权限，并同步更新 Flutter 侧状态。
  Future<void> requestLocationPermission() async {
    try {
      final result = await _motionService.requestLocationPermission();

      state = state.copyWith(
        permissionStatus: result.status,
        error: null,
      );
    } catch (error) {
      _setError(
        code: 'permission_request_failed',
        message: '请求定位权限失败。',
        detail: error.toString(),
      );
    }
  }

  /// 开始一次新的运动。
  ///
  /// 开始前会先把状态切到 `preparing`，等原生接受命令后再进入 `running`。
  Future<void> startWorkout() async {
    if (state.status == MotionStatus.running ||
        state.status == MotionStatus.preparing) {
      return;
    }

    final sessionId = _buildSessionId();

    state = state.copyWith(
      status: MotionStatus.preparing,
      currentSessionId: sessionId,
      sessionStartTime: null,
      recordedPoints: const [],
      realtime: null,
      finishedSession: null,
      error: null,
    );

    try {
      final result = await _motionService.startWorkout(sessionId: sessionId);

      state = state.copyWith(
        status: result.status,
        currentSessionId: sessionId,
        sessionStartTime: result.startTime,
      );
    } catch (error) {
      _setError(
        code: 'start_workout_failed',
        message: '开始运动失败。',
        detail: error.toString(),
      );
    }
  }

  /// 暂停当前运动。
  Future<void> pauseWorkout() async {
    if (state.status != MotionStatus.running) {
      return;
    }

    try {
      final result = await _motionService.pauseWorkout();
      state = state.copyWith(
        status: result.status,
        error: null,
      );
    } catch (error) {
      _setError(
        code: 'pause_workout_failed',
        message: '暂停运动失败。',
        detail: error.toString(),
      );
    }
  }

  /// 继续当前已暂停的运动。
  Future<void> resumeWorkout() async {
    if (state.status != MotionStatus.paused) {
      return;
    }

    try {
      final result = await _motionService.resumeWorkout();
      state = state.copyWith(
        status: result.status,
        error: null,
      );
    } catch (error) {
      _setError(
        code: 'resume_workout_failed',
        message: '继续运动失败。',
        detail: error.toString(),
      );
    }
  }

  /// 结束当前运动，并将原生返回的汇总结果整理为最终记录。
  Future<void> stopWorkout() async {
    if (state.status != MotionStatus.running &&
        state.status != MotionStatus.paused) {
      return;
    }

    try {
      final result = await _motionService.stopWorkout();
      final normalizedSession = _normalizeFinishedSession(result.summary);

      state = state.copyWith(
        status: result.status,
        finishedSession: normalizedSession,
        recordedPoints: normalizedSession.points,
        error: null,
      );
    } catch (error) {
      _setError(
        code: 'stop_workout_failed',
        message: '结束运动失败。',
        detail: error.toString(),
      );
    }
  }

  /// 清除当前错误信息，但不改变其他状态。
  void clearError() {
    state = state.copyWith(error: null);
  }

  void _bindNativeEvents() {
    if (_eventSubscription != null) {
      return;
    }

    _eventSubscription = _motionService.events.listen(
      _handleNativeEvent,
      onError: (Object error, StackTrace stackTrace) {
        _setError(
          code: 'event_stream_failed',
          message: '监听原生事件流失败。',
          detail: error.toString(),
        );
      },
    );
  }

  void _handleNativeEvent(MotionChannelEvent event) {
    switch (event.type) {
      case MotionChannelEventType.permissionChanged:
        final permissionStatus =
            MotionPermissionStatus.fromValue(event.payload['status'] as String?);
        state = state.copyWith(
          permissionStatus: permissionStatus,
          error: null,
        );
        break;
      case MotionChannelEventType.statusChanged:
        final status =
            MotionStatusX.fromValue(event.payload['status'] as String? ?? '');
        state = state.copyWith(
          status: status,
          error: null,
        );
        break;
      case MotionChannelEventType.locationUpdated:
        final point = MotionPoint.fromMap(event.payload);
        _appendRecordedPoint(point);
        break;
      case MotionChannelEventType.motionUpdated:
        final realtime = MotionRealtime.fromMap(event.payload);
        state = state.copyWith(
          status: realtime.status,
          realtime: realtime,
          error: null,
        );

        if (realtime.latestPoint != null) {
          _appendRecordedPoint(realtime.latestPoint!);
        }
        break;
      case MotionChannelEventType.error:
        final error = MotionError.fromMap(event.payload);
        state = state.copyWith(
          status: MotionStatus.error,
          error: error,
        );
        break;
    }
  }

  /// 追加轨迹点时做一次轻量去重，避免 `locationUpdated` 和
  /// `motionUpdated.latestPoint` 同时到来时重复入列。
  void _appendRecordedPoint(MotionPoint point) {
    final points = state.recordedPoints;

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final isSamePoint = lastPoint.timestamp == point.timestamp &&
          lastPoint.latitude == point.latitude &&
          lastPoint.longitude == point.longitude;

      if (isSamePoint) {
        return;
      }
    }

    state = state.copyWith(
      recordedPoints: [...points, point],
      error: null,
    );
  }

  /// 将原生返回的最终结果整理为 Flutter 侧可直接使用的最终记录。
  ///
  /// 主要处理两个问题：
  /// 1. 原生返回的 `sessionId` 可能为空，需要补齐
  /// 2. 原生返回的轨迹点可能为空，需要兜底使用 Flutter 已缓存的数据
  MotionSession _normalizeFinishedSession(MotionSession session) {
    final fallbackSessionId = state.currentSessionId ?? session.sessionId;
    final fallbackStartTime = state.sessionStartTime ?? session.startTime;
    final fallbackPoints =
        session.points.isEmpty ? state.recordedPoints : session.points;

    return session.copyWith(
      sessionId: fallbackSessionId,
      startTime: fallbackStartTime,
      points: fallbackPoints,
    );
  }

  /// 生成本次运动会话的本地唯一标识。
  ///
  /// 当前阶段不额外引入 uuid 依赖，先使用时间戳保证基本唯一性。
  String _buildSessionId() {
    return 'motion_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _setError({
    required String code,
    required String message,
    String? detail,
  }) {
    state = state.copyWith(
      status: MotionStatus.error,
      error: MotionError(
        code: code,
        message: message,
        detail: detail,
      ),
    );
  }
}
