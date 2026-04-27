import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// 运动模块默认使用的原生通信 service。
final motionServiceProvider = Provider<MotionService>((ref) {
  return MethodChannelMotionService();
});
