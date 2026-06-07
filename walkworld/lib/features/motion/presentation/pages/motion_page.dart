import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/application.dart';
import '../../models/models.dart';
import '../widgets/motion_finish_sheet.dart';
import '../widgets/motion_map_view.dart';
import '../widgets/motion_page_support.dart';
import '../widgets/pre_start_action_area.dart';
import '../widgets/running_action_sheet.dart';
import '../widgets/motion_type_sheet.dart';

/// 运动模块正式页面入口。
///
/// 当前按 Figma 落地“开始运动前/运动中/运动结束”的正式页骨架：
/// 1. 保持地图层、底部主操作区和底部导航的空间关系稳定
/// 2. 地图相关职责全部留在原生侧，Flutter 只消费正式页展示所需状态
/// 3. 为后续接入运动记录保存能力保留结束态数据边界
class MotionPage extends ConsumerStatefulWidget {
  const MotionPage({super.key});

  @override
  ConsumerState<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends ConsumerState<MotionPage> {
  MotionType? _selectedMotionType;
  MotionMapNativeController? _mapController;
  bool _isFinishSheetVisible = false;
  bool _isErrorDialogVisible = false;
  bool _isShortWorkoutDialogVisible = false;
  String? _lastPresentedErrorKey;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(
      () => ref.read(motionControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MotionState>(
      motionControllerProvider,
      _handleMotionStateChanged,
    );

    final motionState = ref.watch(motionControllerProvider);
    final controller = ref.read(motionControllerProvider.notifier);
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final pageTokens = MotionPageTokens.fromTheme(appTokens, theme.brightness);
    final mediaQuery = MediaQuery.of(context);
    final canStart =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;
    final showPreStartLayout =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.preparing ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;
    final showRunningOverlay =
        motionState.status == MotionStatus.running ||
        motionState.status == MotionStatus.paused;

    return Scaffold(
      backgroundColor: pageTokens.pageBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: pageTokens.pageBackground),
              child: MotionMapView(
                creationParams: {
                  'showUserLocation': true,
                  'sessionStatus': motionState.status.value,
                },
                onControllerCreated: (controller) {
                  _mapController = controller;
                },
                workoutStartResetToken: motionState.currentSessionId,
                sessionStatus: motionState.status,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      pageTokens.mapTopMask,
                      Colors.transparent,
                      pageTokens.mapBottomMask,
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: showPreStartLayout
                  ? PreStartActionArea(
                      key: const ValueKey('prestart'),
                      motionState: motionState,
                      pageTokens: pageTokens,
                      canStart: canStart,
                      // 点击开始运动先弹出类型选择弹窗，确认后再触发开始
                      onStart: canStart ? () => _handleStart(controller) : null,
                    )
                  : const SizedBox.shrink(key: ValueKey('running')),
            ),
          ),
          Positioned(
            right: 16,
            bottom: mediaQuery.padding.bottom + 214,
            child: IgnorePointer(
              ignoring: !showRunningOverlay,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showRunningOverlay ? 1 : 0,
                child: _MapRecenterButton(
                  pageTokens: pageTokens,
                  onTap: () {
                    final controller = _mapController;
                    if (controller == null) {
                      return;
                    }
                    unawaited(controller.focusCurrentLocation());
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !showRunningOverlay,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: showRunningOverlay ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showRunningOverlay ? 1 : 0,
                  child: RunningActionSheet(
                    motionType: _selectedMotionType ?? MotionType.hiking,
                  ),
                ),
              ),
            ),
          ),

          // 结束运动 loading 遮罩：截图 + 数据汇总期间展示
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !motionState.isFinishing,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: motionState.isFinishing ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '数据处理中…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStart(MotionController controller) async {
    final selectedType = await showMotionTypeSheet(context);
    // 用户取消时 selectedType 为 null，直接返回
    if (selectedType == null) return;

    _selectedMotionType = selectedType;
    _lastPresentedErrorKey = null;
    await controller.startWorkout(motionType: selectedType);
  }

  void _handleMotionStateChanged(MotionState? previous, MotionState next) {
    if (!mounted) {
      return;
    }

    final previousStatus = previous?.status;
    final nextStatus = next.status;
    final didReceiveFinishedSummary =
        nextStatus == MotionStatus.finished &&
        (previousStatus != MotionStatus.finished ||
            previous?.isFinishing == true ||
            previous?.finishedSession != next.finishedSession ||
            previous?.isShortWorkoutDiscarded != next.isShortWorkoutDiscarded);

    if (previousStatus == nextStatus && !didReceiveFinishedSummary) {
      return;
    }

    if (nextStatus == MotionStatus.running ||
        nextStatus == MotionStatus.paused) {
      _lastPresentedErrorKey = null;
      _dismissFinishSheetIfNeeded();
      _dismissShortWorkoutDialogIfNeeded();
      return;
    }

    if (nextStatus == MotionStatus.finished) {
      if (next.isFinishing) {
        return;
      }

      _lastPresentedErrorKey = null;
      _dismissErrorDialogIfNeeded();
      if (next.isShortWorkoutDiscarded) {
        _dismissFinishSheetIfNeeded();
        _showShortWorkoutDialogIfNeeded();
      } else {
        _dismissShortWorkoutDialogIfNeeded();
        _showFinishSheetIfNeeded();
      }
      return;
    }

    if (nextStatus == MotionStatus.error) {
      _dismissFinishSheetIfNeeded();
      _dismissShortWorkoutDialogIfNeeded();
      _showErrorDialogIfNeeded(next);
      return;
    }

    if (nextStatus == MotionStatus.idle) {
      _lastPresentedErrorKey = null;
      _dismissErrorDialogIfNeeded();
      _dismissShortWorkoutDialogIfNeeded();
    }
  }

  void _showFinishSheetIfNeeded() {
    if (_isFinishSheetVisible) {
      return;
    }

    _isFinishSheetVisible = true;
    Future<void>.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 120));

      if (!mounted) {
        _isFinishSheetVisible = false;
        return;
      }

      await showMotionFinishSheet(context);
      _isFinishSheetVisible = false;
    });
  }

  void _dismissFinishSheetIfNeeded() {
    if (!_isFinishSheetVisible) {
      return;
    }

    unawaited(Navigator.of(context, rootNavigator: true).maybePop());
  }

  void _showShortWorkoutDialogIfNeeded() {
    if (_isShortWorkoutDialogVisible) {
      return;
    }

    _isShortWorkoutDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text(
              '旅途距离过短',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            '由于本次旅途过短，将不会被记录',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('知道了'),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isShortWorkoutDialogVisible = false;
    });
  }

  void _dismissShortWorkoutDialogIfNeeded() {
    if (!_isShortWorkoutDialogVisible) {
      return;
    }

    unawaited(Navigator.of(context, rootNavigator: true).maybePop());
  }

  void _showErrorDialogIfNeeded(MotionState state) {
    final error = state.error;
    if (error == null) {
      return;
    }

    final errorKey = '${error.code}:${error.message}:${error.detail ?? ''}';
    if (_isErrorDialogVisible || _lastPresentedErrorKey == errorKey) {
      return;
    }

    _isErrorDialogVisible = true;
    _lastPresentedErrorKey = errorKey;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final actionLabel = _buildErrorActionLabel(error.code);

        return AlertDialog(
          title: Text(_buildErrorTitle(error.code)),
          content: Text(_buildErrorMessage(error)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('知道了'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isErrorDialogVisible = false;
      if (mounted &&
          ref.read(motionControllerProvider).status != MotionStatus.error) {
        _lastPresentedErrorKey = null;
      }
    });
  }

  void _dismissErrorDialogIfNeeded() {
    if (!_isErrorDialogVisible) {
      return;
    }

    unawaited(Navigator.of(context, rootNavigator: true).maybePop());
  }

  String _buildErrorTitle(String code) {
    return switch (code) {
      'permission_denied' || 'permission_denied_forever' => '需要定位权限',
      'location_service_disabled' => '定位服务未开启',
      'location_start_failed' || 'location_update_failed' => '定位出现异常',
      'invalid_motion_state' => '当前状态不可操作',
      _ => '运动暂时无法继续',
    };
  }

  String _buildErrorMessage(MotionError error) {
    final suffix = switch (error.code) {
      'permission_denied' => '请允许运动页访问定位后再开始。',
      'permission_denied_forever' => '请到系统设置中开启定位权限后再返回。',
      'location_service_disabled' => '请先在系统里打开定位服务，然后重新开始运动。',
      'location_start_failed' ||
      'location_update_failed' => '请稍后重试；如果问题持续存在，再检查定位权限与网络状态。',
      'invalid_motion_state' => '请返回当前页面状态后，再执行下一步操作。',
      _ => '请稍后再试。',
    };
    final detail = error.detail?.trim();

    if (detail == null || detail.isEmpty) {
      return '${error.message}\n\n$suffix';
    }

    return '${error.message}\n\n$suffix\n\n详情：$detail';
  }

  String _buildErrorActionLabel(String code) {
    return switch (code) {
      'permission_denied' || 'permission_denied_forever' => '去处理',
      'location_service_disabled' => '去开启',
      _ => '稍后重试',
    };
  }
}

/// 地图回中按钮：用于用户拖拽后快速回到当前位置并恢复跟随。
class _MapRecenterButton extends StatelessWidget {
  const _MapRecenterButton({required this.pageTokens, required this.onTap});

  final MotionPageTokens pageTokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: pageTokens.overlayBackground,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: pageTokens.overlayBorder),
            boxShadow: [
              BoxShadow(
                color: pageTokens.overlayShadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location_rounded,
            size: 20,
            color: pageTokens.overlayPrimaryText,
          ),
        ),
      ),
    );
  }
}
