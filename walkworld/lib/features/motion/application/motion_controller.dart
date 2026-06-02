import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../presentation/widgets/motion_type_sheet.dart';
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
    return MotionState.initial();
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
  /// [motionType] 会一并下传到原生侧，用于切换对应运动类型的过滤参数组。
  Future<void> startWorkout({required MotionType motionType}) async {
    if (state.status == MotionStatus.running ||
        state.status == MotionStatus.preparing) {
      return;
    }

    final sessionId = _buildSessionId();

    state = state.copyWith(
      status: MotionStatus.preparing,
      currentSessionId: sessionId,
      sessionStartTime: null,
      realtime: const MotionRealtime(
        status: MotionStatus.preparing,
        durationSeconds: 0,
        distanceMeters: 0,
      ),
      finishedSession: null,
      error: null,
      motionType: motionType,
    );

    try {
      final result = await _motionService.startWorkout(
        sessionId: sessionId,
        motionType: motionType,
      );

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

    // 立即标记正在结束，UI 层据此展示 loading 遮罩。
    state = state.copyWith(isFinishing: true);

    try {
      final result = await _motionService.stopWorkout();

      if (!result.accepted) {
        _setError(code: 'stop_workout_rejected', message: '原生未接受结束运动命令。');
        state = state.copyWith(isFinishing: false);
        return;
      }

      final normalizedSession = _normalizeFinishedSession(result.summary);

      state = state.copyWith(
        status: result.status,
        finishedSession: normalizedSession,
        currentSessionId: null,
        realtime: MotionRealtime(
          status: result.status,
          durationSeconds: normalizedSession.durationSeconds,
          distanceMeters: normalizedSession.totalDistanceMeters,
          averageSpeedMps: normalizedSession.averageSpeedMps,
        ),
        sessionStartTime: normalizedSession.startTime,
        error: null,
        isFinishing: false,
      );
    } catch (error) {
      _setError(
        code: 'stop_workout_failed',
        message: '结束运动失败。',
        detail: error.toString(),
      );
      state = state.copyWith(isFinishing: false);
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
      case MotionChannelEventType.motionUpdated:
        final realtime = MotionRealtime.fromMap(event.payload);
        state = state.copyWith(
          status: realtime.status,
          realtime: realtime,
          error: null,
        );
        break;
      case MotionChannelEventType.error:
        final error = MotionError.fromMap(event.payload);
        state = state.copyWith(status: MotionStatus.error, error: error);
        break;
    }
  }

  /// 将原生返回的最终结果整理为 Flutter 侧可直接使用的最终记录。
  ///
  /// 主要处理两个问题：
  /// 1. 原生返回的 `sessionId` 可能为空，需要补齐
  /// 2. 原生返回的统计字段若缺失，退化使用 Flutter 当前展示中的实时数据
  MotionSession _normalizeFinishedSession(MotionSession session) {
    final fallbackSessionId = state.currentSessionId ?? session.sessionId;
    final fallbackStartTime = state.sessionStartTime ?? session.startTime;
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
      points: session.points,
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
