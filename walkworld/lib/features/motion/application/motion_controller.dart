import 'dart:async';
import 'dart:math' as math;

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
      final locationServiceStatus = await _motionService
          .getLocationServiceStatus();

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

      state = state.copyWith(permissionStatus: result.status, error: null);
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
      realtime: const MotionRealtime(
        status: MotionStatus.preparing,
        durationSeconds: 0,
        distanceMeters: 0,
        pointCount: 0,
      ),
      finishedSession: null,
      error: null,
    );

    try {
      final result = await _motionService.startWorkout(sessionId: sessionId);

      if (!result.accepted) {
        _setError(code: 'start_workout_rejected', message: '原生未接受开始运动命令。');
        return;
      }

      state = state.copyWith(
        status: result.status,
        currentSessionId: sessionId,
        sessionStartTime: result.startTime,
        realtime:
            (state.realtime ??
                    const MotionRealtime(
                      status: MotionStatus.running,
                      durationSeconds: 0,
                      distanceMeters: 0,
                      pointCount: 0,
                    ))
                .copyWith(status: result.status),
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

      if (!result.accepted) {
        _setError(code: 'pause_workout_rejected', message: '原生未接受暂停运动命令。');
        return;
      }

      state = state.copyWith(
        status: result.status,
        realtime: state.realtime?.copyWith(status: result.status),
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

      if (!result.accepted) {
        _setError(code: 'resume_workout_rejected', message: '原生未接受继续运动命令。');
        return;
      }

      state = state.copyWith(
        status: result.status,
        realtime: state.realtime?.copyWith(status: result.status),
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

      if (!result.accepted) {
        _setError(code: 'stop_workout_rejected', message: '原生未接受结束运动命令。');
        return;
      }

      final normalizedSession = _normalizeFinishedSession(result.summary);

      state = state.copyWith(
        status: result.status,
        finishedSession: normalizedSession,
        recordedPoints: normalizedSession.points,
        currentSessionId: null,
        realtime: MotionRealtime(
          status: result.status,
          durationSeconds: normalizedSession.durationSeconds,
          distanceMeters: normalizedSession.totalDistanceMeters,
          averageSpeedMps: normalizedSession.averageSpeedMps,
          pointCount: normalizedSession.points.length,
          latestPoint: normalizedSession.points.isEmpty
              ? null
              : normalizedSession.points.last,
        ),
        sessionStartTime: normalizedSession.startTime,
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
        final permissionStatus = MotionPermissionStatus.fromValue(
          event.payload['status'] as String?,
        );
        state = state.copyWith(permissionStatus: permissionStatus, error: null);
        break;
      case MotionChannelEventType.statusChanged:
        final status = MotionStatusX.fromValue(
          event.payload['status'] as String? ?? '',
        );
        state = state.copyWith(
          status: status,
          currentSessionId: status == MotionStatus.finished
              ? null
              : state.currentSessionId,
          error: null,
        );
        break;
      case MotionChannelEventType.locationUpdated:
        final point = MotionPoint.fromMap(event.payload);
        _handleLocationUpdated(point);
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
        state = state.copyWith(status: MotionStatus.error, error: error);
        break;
    }
  }

  /// 原生若先推送定位点、后推送统计事件，正式页也要先具备可见的实时增长。
  ///
  /// 这里基于已采纳点位做一层 Flutter 侧兜底统计，等 `motionUpdated`
  /// 到来后再由原生统计结果覆盖，避免 UI 依赖单一路径。
  void _handleLocationUpdated(MotionPoint point) {
    final previousPoints = state.recordedPoints;
    final previousPoint = previousPoints.isEmpty ? null : previousPoints.last;

    final appended = _appendRecordedPoint(point);
    if (!appended) {
      return;
    }

    final previousRealtime = state.realtime;
    final distanceIncrement = previousPoint == null
        ? 0
        : _estimateDistanceMeters(previousPoint, point);
    final nextDistanceMeters =
        (previousRealtime?.distanceMeters ?? 0) + distanceIncrement;
    final derivedDurationSeconds = _deriveDurationSeconds(point.timestamp);
    final nextDurationSeconds = math.max(
      previousRealtime?.durationSeconds ?? 0,
      derivedDurationSeconds,
    );
    final currentSpeedMps =
        point.speedMps ?? _deriveSpeedBetweenPoints(previousPoint, point);
    final averageSpeedMps = nextDurationSeconds > 0
        ? nextDistanceMeters / nextDurationSeconds
        : null;

    state = state.copyWith(
      realtime:
          (previousRealtime ??
                  const MotionRealtime(
                    status: MotionStatus.running,
                    durationSeconds: 0,
                    distanceMeters: 0,
                    pointCount: 0,
                  ))
              .copyWith(
                status: state.status,
                durationSeconds: nextDurationSeconds,
                distanceMeters: nextDistanceMeters,
                currentSpeedMps: currentSpeedMps,
                averageSpeedMps: averageSpeedMps,
                pointCount: state.recordedPoints.length,
                latestPoint: point,
              ),
      error: null,
    );
  }

  /// 追加轨迹点时做一次轻量去重，避免 `locationUpdated` 和
  /// `motionUpdated.latestPoint` 同时到来时重复入列。
  bool _appendRecordedPoint(MotionPoint point) {
    final points = state.recordedPoints;

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final isSamePoint =
          lastPoint.timestamp == point.timestamp &&
          lastPoint.latitude == point.latitude &&
          lastPoint.longitude == point.longitude;

      if (isSamePoint) {
        return false;
      }
    }

    state = state.copyWith(recordedPoints: [...points, point], error: null);

    return true;
  }

  /// 用 session 起点与最新点时间戳估算实时时长，避免只有点位事件时 UI 不更新。
  int _deriveDurationSeconds(int latestTimestampMillis) {
    final sessionStartTime = state.sessionStartTime;
    if (sessionStartTime == null) {
      return state.realtime?.durationSeconds ?? 0;
    }

    final elapsedMillis = latestTimestampMillis - sessionStartTime;
    if (elapsedMillis <= 0) {
      return state.realtime?.durationSeconds ?? 0;
    }

    return elapsedMillis ~/ 1000;
  }

  /// 基于前后两个点位估算直线距离，作为正式页实时统计的兜底值。
  double _estimateDistanceMeters(MotionPoint from, MotionPoint to) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(to.latitude - from.latitude);
    final longitudeDelta = _toRadians(to.longitude - from.longitude);
    final fromLatitudeRadians = _toRadians(from.latitude);
    final toLatitudeRadians = _toRadians(to.latitude);
    final haversine =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(fromLatitudeRadians) *
            math.cos(toLatitudeRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusMeters * arc;
  }

  /// 当原生速度字段缺失时，退化成相邻点位间的平均速度。
  double? _deriveSpeedBetweenPoints(
    MotionPoint? previous,
    MotionPoint current,
  ) {
    if (previous == null) {
      return null;
    }

    final durationMillis = current.timestamp - previous.timestamp;
    if (durationMillis <= 0) {
      return null;
    }

    final distanceMeters = _estimateDistanceMeters(previous, current);
    return distanceMeters / (durationMillis / 1000);
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  /// 将原生返回的最终结果整理为 Flutter 侧可直接使用的最终记录。
  ///
  /// 主要处理两个问题：
  /// 1. 原生返回的 `sessionId` 可能为空，需要补齐
  /// 2. 原生返回的轨迹点可能为空，需要兜底使用 Flutter 已缓存的数据
  MotionSession _normalizeFinishedSession(MotionSession session) {
    final fallbackSessionId = state.currentSessionId ?? session.sessionId;
    final fallbackStartTime = state.sessionStartTime ?? session.startTime;
    final fallbackPoints = session.points.isEmpty
        ? state.recordedPoints
        : session.points;
    final fallbackEndTime = session.endTime == 0
        ? DateTime.now().millisecondsSinceEpoch
        : session.endTime;
    final fallbackDurationSeconds = session.durationSeconds > 0
        ? session.durationSeconds
        : state.realtime?.durationSeconds ?? 0;
    final fallbackDistanceMeters = session.totalDistanceMeters > 0
        ? session.totalDistanceMeters
        : state.realtime?.distanceMeters ?? 0;
    final fallbackAverageSpeed =
        session.averageSpeedMps ??
        state.realtime?.averageSpeedMps ??
        state.realtime?.currentSpeedMps;

    return session.copyWith(
      sessionId: fallbackSessionId,
      startTime: fallbackStartTime,
      endTime: fallbackEndTime,
      durationSeconds: fallbackDurationSeconds,
      totalDistanceMeters: fallbackDistanceMeters,
      averageSpeedMps: fallbackAverageSpeed,
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
      error: MotionError(code: code, message: message, detail: detail),
    );
  }
}
