import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';

/// Flutter 侧运动地图容器。
///
/// 这个组件负责两件事：
/// 1. 承载 iOS 原生 `PlatformView`
/// 2. 把 Flutter 当前持有的位置点和轨迹点同步给原生地图
///
/// 原生地图一旦创建成功，后续的当前位置刷新和轨迹绘制都通过
/// 当前 viewId 对应的专属 MethodChannel 完成。
class MotionMapView extends StatefulWidget {
  const MotionMapView({
    super.key,
    this.creationParams,
    this.currentPoint,
    this.trackPoints = const [],
  });

  /// 创建原生地图视图时传给 iOS 侧的初始化参数。
  final Map<String, Object?>? creationParams;

  /// 当前最新位置点。
  final MotionPoint? currentPoint;

  /// 当前完整轨迹点集合。
  final List<MotionPoint> trackPoints;

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

    final pointChanged =
        oldWidget.currentPoint?.timestamp != widget.currentPoint?.timestamp;
    final trackChanged =
        oldWidget.trackPoints.length != widget.trackPoints.length ||
        (oldWidget.trackPoints.isNotEmpty &&
            widget.trackPoints.isNotEmpty &&
            oldWidget.trackPoints.last.timestamp !=
                widget.trackPoints.last.timestamp);

    if (pointChanged && widget.currentPoint != null) {
      _nativeController!.updateUserLocation(widget.currentPoint!);
    }

    if (trackChanged) {
      if (widget.trackPoints.isEmpty) {
        _nativeController!.clearTrack();
      } else {
        _nativeController!.updateTrack(widget.trackPoints);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const ColoredBox(
        color: Color(0xFFF4F6F8),
        child: Center(
          child: Text('当前地图容器仅实现了 iOS 原生视图接入。'),
        ),
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

    if (widget.currentPoint != null) {
      await controller.updateUserLocation(widget.currentPoint!);
    }

    if (widget.trackPoints.isNotEmpty) {
      await controller.updateTrack(widget.trackPoints);
    }
  }
}

/// 对单个原生地图视图的 Flutter 侧控制器。
///
/// 每个 `PlatformView` 都会分配一个唯一的 viewId。
/// 这里用 viewId 拼出专属 MethodChannel，避免多个地图实例之间串消息。
class MotionMapNativeController {
  MotionMapNativeController({
    required int viewId,
  }) : _channel = MethodChannel('walkworld/motion_map_control_$viewId');

  final MethodChannel _channel;

  /// 刷新原生地图中的当前位置展示。
  Future<void> updateUserLocation(MotionPoint point) {
    return _channel.invokeMethod<void>('updateUserLocation', point.toMap());
  }

  /// 刷新原生地图中的轨迹折线。
  Future<void> updateTrack(List<MotionPoint> points) {
    return _channel.invokeMethod<void>(
      'updateTrack',
      {
        'points': points.map((point) => point.toMap()).toList(),
      },
    );
  }

  /// 清空原生地图中的轨迹折线和当前位置标记。
  Future<void> clearTrack() {
    return _channel.invokeMethod<void>('clearTrack');
  }
}
