import 'package:flutter_riverpod/flutter_riverpod.dart';

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
