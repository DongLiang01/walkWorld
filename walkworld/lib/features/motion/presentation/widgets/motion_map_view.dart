import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/motion_status.dart';

/// Flutter 侧运动地图容器。
///
/// 这个组件负责两件事：
/// 1. 承载 iOS 原生 `PlatformView`
/// 2. 在开始新一轮运动时通知原生地图重置相机
///
/// 运行中的蓝点、轨迹线和轨迹恢复全部留在原生侧处理；
/// Flutter 正式页不再参与地图点位和画线同步。
class MotionMapView extends StatefulWidget {
  const MotionMapView({
    super.key,
    this.creationParams,
    this.workoutStartResetToken,
    required this.sessionStatus,
  });

  /// 创建原生地图视图时传给 iOS 侧的初始化参数。
  final Map<String, Object?>? creationParams;

  /// 每次开始一轮新运动时变化的重置信号。
  ///
  /// 当前使用 sessionId 作为 token，只要值变化，就要求原生地图重置相机。
  final String? workoutStartResetToken;

  /// 当前运动状态，用于同步原生地图展示策略。
  final MotionStatus sessionStatus;

  static const String viewType = 'walkworld/motion_map_view';

  @override
  State<MotionMapView> createState() => _MotionMapViewState();
}

class _MotionMapViewState extends State<MotionMapView> {
  MotionMapNativeController? _nativeController;

  @override
  void didUpdateWidget(covariant MotionMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_nativeController == null) {
      return;
    }

    final workoutStartResetChanged =
        oldWidget.workoutStartResetToken != widget.workoutStartResetToken &&
        widget.workoutStartResetToken != null;

    if (workoutStartResetChanged) {
      _nativeController!.resetCameraForWorkoutStart();
    }

    if (oldWidget.sessionStatus != widget.sessionStatus) {
      _nativeController!.syncSessionStatus(widget.sessionStatus.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const ColoredBox(
        color: Color(0xFFF4F6F8),
        child: Center(child: Text('当前地图容器仅实现了 iOS 原生视图接入。')),
      );
    }

    return UiKitView(
      viewType: MotionMapView.viewType,
      creationParams: widget.creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _handlePlatformViewCreated,
    );
  }

  Future<void> _handlePlatformViewCreated(int viewId) async {
    final controller = MotionMapNativeController(viewId: viewId);
    _nativeController = controller;
    await controller.syncSessionStatus(widget.sessionStatus.value);
  }
}

/// 对单个原生地图视图的 Flutter 侧控制器。
///
/// 每个 `PlatformView` 都会分配一个唯一的 viewId。
/// 这里用 viewId 拼出专属 MethodChannel，避免多个地图实例之间串消息。
class MotionMapNativeController {
  MotionMapNativeController({required int viewId})
    : _channel = MethodChannel('walkworld/motion_map_control_$viewId');

  final MethodChannel _channel;

  /// 每次开始运动都显式重置地图相机，不依赖轨迹数组是否变化。
  Future<void> resetCameraForWorkoutStart() {
    return _channel.invokeMethod<void>('resetCameraForWorkoutStart');
  }

  /// 同步当前运动状态，让原生地图切换系统蓝点显示策略。
  Future<void> syncSessionStatus(String sessionStatus) {
    return _channel.invokeMethod<void>('syncSessionStatus', {
      'sessionStatus': sessionStatus,
    });
  }
}
