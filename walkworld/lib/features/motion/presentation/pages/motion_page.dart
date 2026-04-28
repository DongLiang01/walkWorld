import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/application.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';

/// 运动模块的最小页面入口。
///
/// 第 4 步阶段只验证一件事：
/// Flutter 页面是否能够成功承载 iOS 原生地图视图。
/// 因此这里先不放运动控制按钮和实时统计面板。
class MotionPage extends ConsumerStatefulWidget {
  const MotionPage({super.key});

  @override
  ConsumerState<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends ConsumerState<MotionPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(
      () => ref.read(motionControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motionState = ref.watch(motionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MotionMapView(
              creationParams: {
                'showUserLocation': true,
                'sessionStatus': motionState.status.value,
              },
              currentPoint:
                  motionState.realtime?.latestPoint ??
                  (motionState.recordedPoints.isNotEmpty
                      ? motionState.recordedPoints.last
                      : null),
              trackPoints: motionState.recordedPoints,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF7F7F7),
            child: Text('地图容器已接入，当前状态：${motionState.status.value}'),
          ),
        ],
      ),
    );
  }
}
