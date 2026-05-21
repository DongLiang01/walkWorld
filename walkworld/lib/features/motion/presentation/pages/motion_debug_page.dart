import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/application.dart';
import '../../models/models.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';
import '../widgets/motion_type_sheet.dart';

/// 运动模块的调试页面入口。
///
/// 当前阶段除了展示 iOS 原生地图，还额外承担联调与验收职责：
/// 1. 可直接触发权限申请与运动控制命令
/// 2. 可直接看到 Flutter 是否持续收到原生实时事件
/// 3. 可直接验证开始、暂停、继续、结束这条核心交互链路
class MotionDebugPage extends ConsumerStatefulWidget {
  const MotionDebugPage({super.key});

  @override
  ConsumerState<MotionDebugPage> createState() => _MotionDebugPageState();
}

class _MotionDebugPageState extends ConsumerState<MotionDebugPage> {
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
    final theme = Theme.of(context);
    final latestPoint =
        motionState.realtime?.latestPoint ??
        (motionState.recordedPoints.isNotEmpty
            ? motionState.recordedPoints.last
            : null);
    final canRequestPermission = motionState.status != MotionStatus.preparing;
    final canStart =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;
    final canPause = motionState.status == MotionStatus.running;
    final canResume = motionState.status == MotionStatus.paused;
    final canStop =
        motionState.status == MotionStatus.running ||
        motionState.status == MotionStatus.paused;
    final panelTitle = switch (motionState.status) {
      MotionStatus.finished => '结果面板',
      MotionStatus.error => '异常面板',
      _ => '交互调试面板',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('运动调试')),
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
                        onPressed: canRequestPermission
                            ? controller.requestLocationPermission
                            : null,
                        child: const Text('请求权限'),
                      ),
                      FilledButton(
                        onPressed: canStart
                            ? () => controller.startWorkout(
                                motionType: MotionType.hiking,
                              )
                            : null,
                        child: const Text('开始'),
                      ),
                      OutlinedButton(
                        onPressed: canPause ? controller.pauseWorkout : null,
                        child: const Text('暂停'),
                      ),
                      OutlinedButton(
                        onPressed: canResume ? controller.resumeWorkout : null,
                        child: const Text('继续'),
                      ),
                      OutlinedButton(
                        onPressed: canStop ? controller.stopWorkout : null,
                        child: const Text('结束'),
                      ),
                      if (motionState.error != null)
                        TextButton(
                          onPressed: controller.clearError,
                          child: const Text('清除错误'),
                        ),
                      if (motionState.status == MotionStatus.finished)
                        TextButton(
                          onPressed: () => controller.startWorkout(
                            motionType: MotionType.hiking,
                          ),
                          child: const Text('再来一次'),
                        ),
                      if (motionState.status == MotionStatus.error && canStart)
                        TextButton(
                          onPressed: () => controller.startWorkout(
                            motionType: MotionType.hiking,
                          ),
                          child: const Text('重新开始'),
                        ),
                      if (motionState.status == MotionStatus.paused)
                        TextButton(
                          onPressed: controller.stopWorkout,
                          child: const Text('暂停后结束'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(panelTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _DebugField(label: '运动状态', value: motionState.status.value),
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
                    label: '事件监听',
                    value: motionState.isEventListening ? '已建立' : '未建立',
                  ),
                  _DebugField(
                    label: '当前会话',
                    value: motionState.currentSessionId ?? '--',
                  ),
                  _DebugField(
                    label: '已收点数',
                    value: '${motionState.recordedPoints.length}',
                  ),
                  _DebugField(
                    label: '运动时长',
                    value: motionState.realtime == null
                        ? '--'
                        : '${motionState.realtime!.durationSeconds} s',
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
                    label: '平均速度',
                    value: motionState.realtime?.averageSpeedMps == null
                        ? '--'
                        : '${motionState.realtime!.averageSpeedMps!.toStringAsFixed(2)} m/s',
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
                  if (motionState.finishedSession != null) ...[
                    const SizedBox(height: 8),
                    Text('本次结果', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    _DebugField(
                      label: '开始时间',
                      value: _formatTimestamp(
                        motionState.finishedSession!.startTime,
                      ),
                    ),
                    _DebugField(
                      label: '结束时间',
                      value: _formatTimestamp(
                        motionState.finishedSession!.endTime,
                      ),
                    ),
                    _DebugField(
                      label: '总时长',
                      value:
                          '${motionState.finishedSession!.durationSeconds} s',
                    ),
                    _DebugField(
                      label: '总距离',
                      value:
                          '${motionState.finishedSession!.totalDistanceMeters.toStringAsFixed(1)} m',
                    ),
                    _DebugField(
                      label: '轨迹点数',
                      value: '${motionState.finishedSession!.points.length}',
                    ),
                  ],
                  if (motionState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '错误：${motionState.error!.code} ${motionState.error!.message}'
                      '${motionState.error!.detail == null ? '' : '\n${motionState.error!.detail}'}',
                      style: TextStyle(color: theme.colorScheme.error),
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
  const _DebugField({required this.label, required this.value});

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
