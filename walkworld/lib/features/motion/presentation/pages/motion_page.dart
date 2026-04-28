import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/application.dart';
import '../../models/models.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';

/// 运动模块的调试页面入口。
///
/// 当前阶段除了展示 iOS 原生地图，还额外承担 Step 5 的验收职责：
/// 1. 可直接触发权限申请与运动控制命令
/// 2. 可直接看到 Flutter 是否持续收到原生定位事件
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
    final controller = ref.read(motionControllerProvider.notifier);
    final latestPoint =
        motionState.realtime?.latestPoint ??
        (motionState.recordedPoints.isNotEmpty
            ? motionState.recordedPoints.last
            : null);

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
              currentPoint: latestPoint,
              trackPoints: motionState.recordedPoints,
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: const Color(0xFFF7F7F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: controller.requestLocationPermission,
                        child: const Text('请求权限'),
                      ),
                      FilledButton(
                        onPressed: controller.startWorkout,
                        child: const Text('开始'),
                      ),
                      OutlinedButton(
                        onPressed: controller.pauseWorkout,
                        child: const Text('暂停'),
                      ),
                      OutlinedButton(
                        onPressed: controller.resumeWorkout,
                        child: const Text('继续'),
                      ),
                      OutlinedButton(
                        onPressed: controller.stopWorkout,
                        child: const Text('结束'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Step 5 调试面板',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _DebugField(
                    label: '运动状态',
                    value: motionState.status.value,
                  ),
                  _DebugField(
                    label: '权限状态',
                    value: motionState.permissionStatus.value,
                  ),
                  _DebugField(
                    label: '定位服务',
                    value: motionState.locationServiceEnabled == null
                        ? '未知'
                        : (motionState.locationServiceEnabled! ? '已开启' : '未开启'),
                  ),
                  _DebugField(
                    label: '已收点数',
                    value: '${motionState.recordedPoints.length}',
                  ),
                  _DebugField(
                    label: '实时距离',
                    value: motionState.realtime == null
                        ? '--'
                        : '${motionState.realtime!.distanceMeters.toStringAsFixed(1)} m',
                  ),
                  _DebugField(
                    label: '当前速度',
                    value: motionState.realtime?.currentSpeedMps == null
                        ? '--'
                        : '${motionState.realtime!.currentSpeedMps!.toStringAsFixed(2)} m/s',
                  ),
                  _DebugField(
                    label: '最新时间',
                    value: latestPoint == null
                        ? '--'
                        : _formatTimestamp(latestPoint.timestamp),
                  ),
                  _DebugField(
                    label: '最新坐标',
                    value: latestPoint == null
                        ? '--'
                        : '${latestPoint.latitude.toStringAsFixed(6)}, ${latestPoint.longitude.toStringAsFixed(6)}',
                  ),
                  _DebugField(
                    label: '最新精度',
                    value: latestPoint?.accuracyMeters == null
                        ? '--'
                        : '${latestPoint!.accuracyMeters!.toStringAsFixed(1)} m',
                  ),
                  if (motionState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '错误：${motionState.error!.code} ${motionState.error!.message}'
                      '${motionState.error!.detail == null ? '' : '\n${motionState.error!.detail}'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 将毫秒时间戳格式化为本地时间，便于观察点位是否持续更新。
  String _formatTimestamp(int timestampMillis) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// 调试面板中的单行字段展示。
class _DebugField extends StatelessWidget {
  const _DebugField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label：$value'),
    );
  }
}
