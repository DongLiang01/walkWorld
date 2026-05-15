import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/application.dart';
import '../../models/models.dart';
import '../../models/motion_status.dart';
import '../widgets/motion_map_view.dart';
import '../widgets/motion_page_support.dart';
import '../widgets/pre_start_action_area.dart';
import '../widgets/running_action_sheet.dart';
import '../widgets/motion_type_sheet.dart';

/// 运动模块正式页面入口。
///
/// 当前先按 Figma 落地“开始运动前”日间/夜间正式页面骨架：
/// 1. 保持地图层、底部主操作区和底部导航的空间关系稳定
/// 2. 将调试页职责从正式页中拆出，避免视觉实现继续被联调字段污染
/// 3. 为后续接入“运动类型选择、运动中、运动结束”设计稿保留结构边界
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
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final pageTokens = MotionPageTokens.fromTheme(appTokens, theme.brightness);
    final latestPoint =
        motionState.realtime?.latestPoint ??
        (motionState.recordedPoints.isNotEmpty
            ? motionState.recordedPoints.last
            : null);
    final canStart =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;
    final showPreStartLayout =
        motionState.status == MotionStatus.idle ||
        motionState.status == MotionStatus.preparing ||
        motionState.status == MotionStatus.finished ||
        motionState.status == MotionStatus.error;

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
                currentPoint: latestPoint,
                trackPoints: motionState.recordedPoints,
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
                      onStart: canStart
                          ? () => _showTypeSheetAndStart(
                              context,
                              controller.startWorkout,
                            )
                          : null,
                    )
                  : const SizedBox.shrink(key: ValueKey('running')),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹出运动类型选择底部弹窗，用户确认后再触发 [onConfirm] 开始运动。
///
/// 若用户取消弹窗，则不做任何操作。
Future<void> _showTypeSheetAndStart(
  BuildContext context,
  Future<void> Function() onConfirm,
) async {
  final selectedType = await showMotionTypeSheet(context);
  // 用户取消时 selectedType 为 null，直接返回
  if (selectedType == null) return;
  // 当前 startWorkout 暂不接受类型参数，后续可扩展
  await onConfirm();

  if (context.mounted) {
    showRunningActionSheet(context, motionType: selectedType);
  }
}
