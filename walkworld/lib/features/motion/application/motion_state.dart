import '../models/models.dart';
import '../services/motion_channel_protocol.dart';

/// 用于标记 `copyWith` 中“调用方没有传这个字段”的哨兵值。
const _unset = Object();

/// 表示 Flutter 侧当前这次运动流程的完整状态快照。
///
/// 这个类只负责承载状态，不直接处理业务逻辑。
/// 真正的状态流转由 `MotionController` 驱动。
class MotionState {
  const MotionState({
    required this.status,
    required this.permissionStatus,
    required this.recordedPoints,
    this.realtime,
    this.finishedSession,
    this.error,
    this.currentSessionId,
    this.sessionStartTime,
    this.locationServiceEnabled,
    this.isEventListening = false,
  });

  /// 当前运动状态，是页面渲染和交互的核心依据。
  final MotionStatus status;

  /// 当前定位权限状态。
  final MotionPermissionStatus permissionStatus;

  /// 当前这次运动已经采集并保留的轨迹点。
  ///
  /// 这里保存的是 Flutter 侧认可的点集，后续页面画线和结束生成记录
  /// 都可以直接依赖这份数据。
  final List<MotionPoint> recordedPoints;

  /// 原生侧推送的实时统计结果。
  final MotionRealtime? realtime;

  /// 当前运动结束后得到的最终记录。
  final MotionSession? finishedSession;

  /// 最近一次错误信息。
  final MotionError? error;

  /// 当前这次运动会话的唯一标识。
  final String? currentSessionId;

  /// 当前这次运动的开始时间，单位为 Unix 毫秒时间戳。
  final int? sessionStartTime;

  /// 系统级定位服务是否开启。
  final bool? locationServiceEnabled;

  /// 是否已经建立对原生事件流的监听。
  ///
  /// 这个字段主要用于调试和排查初始化问题。
  final bool isEventListening;

  /// 默认初始状态。
  factory MotionState.initial() {
    return const MotionState(
      status: MotionStatus.idle,
      permissionStatus: MotionPermissionStatus.notDetermined,
      recordedPoints: [],
    );
  }

  /// 基于当前状态构造下一份状态快照。
  ///
  /// 对于可空字段，使用内部哨兵值区分：
  /// - 不传：保持原值
  /// - 传 `null`：显式清空
  MotionState copyWith({
    MotionStatus? status,
    MotionPermissionStatus? permissionStatus,
    List<MotionPoint>? recordedPoints,
    Object? realtime = _unset,
    Object? finishedSession = _unset,
    Object? error = _unset,
    Object? currentSessionId = _unset,
    Object? sessionStartTime = _unset,
    Object? locationServiceEnabled = _unset,
    bool? isEventListening,
  }) {
    return MotionState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      recordedPoints: recordedPoints ?? this.recordedPoints,
      realtime: identical(realtime, _unset)
          ? this.realtime
          : realtime as MotionRealtime?,
      finishedSession: identical(finishedSession, _unset)
          ? this.finishedSession
          : finishedSession as MotionSession?,
      error:
          identical(error, _unset) ? this.error : error as MotionError?,
      currentSessionId: identical(currentSessionId, _unset)
          ? this.currentSessionId
          : currentSessionId as String?,
      sessionStartTime: identical(sessionStartTime, _unset)
          ? this.sessionStartTime
          : sessionStartTime as int?,
      locationServiceEnabled: identical(locationServiceEnabled, _unset)
          ? this.locationServiceEnabled
          : locationServiceEnabled as bool?,
      isEventListening: isEventListening ?? this.isEventListening,
    );
  }
}
