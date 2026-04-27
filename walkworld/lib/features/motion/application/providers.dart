import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'motion_controller.dart';
import 'motion_state.dart';

/// 运动模块的主控制器 provider。
///
/// 页面层通常直接读取它来触发动作，例如：
/// - 开始运动
/// - 暂停运动
/// - 继续运动
/// - 结束运动
final motionControllerProvider =
    NotifierProvider<MotionController, MotionState>(MotionController.new);

/// 当前运动状态的派生 provider。
final motionStatusProvider = Provider<MotionStatus>((ref) {
  return ref.watch(motionControllerProvider).status;
});

/// 当前实时运动数据的派生 provider。
final motionRealtimeProvider = Provider<MotionRealtime?>((ref) {
  return ref.watch(motionControllerProvider).realtime;
});

/// 当前已记录轨迹点的派生 provider。
final motionRecordedPointsProvider = Provider<List<MotionPoint>>((ref) {
  return ref.watch(motionControllerProvider).recordedPoints;
});

/// 当前最终运动结果的派生 provider。
final motionFinishedSessionProvider = Provider<MotionSession?>((ref) {
  return ref.watch(motionControllerProvider).finishedSession;
});

/// 当前错误信息的派生 provider。
final motionErrorProvider = Provider<MotionError?>((ref) {
  return ref.watch(motionControllerProvider).error;
});
