import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/app_svg_icon.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../../profile/application/goal_route_provider.dart';
import '../../../profile/application/identity_provider.dart';
import '../../../profile/presentation/pages/motion_history_page.dart';
import '../../application/application.dart';
import 'motion_page_support.dart';

/// 弹出运动结束面板。
Future<void> showMotionFinishSheet(BuildContext context) {
  final appTokens = Theme.of(context).extension<AppThemeTokens>()!;
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    barrierColor: appTokens.motionModalScrim,
    builder: (context) => const MotionFinishSheet(),
  );
}

/// 运动结束面板：以 BottomSheet 形式展示，展示本次运动的总结。
class MotionFinishSheet extends ConsumerWidget {
  const MotionFinishSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motionState = ref.watch(motionControllerProvider);
    final theme = Theme.of(context);
    final appTokens = theme.extension<AppThemeTokens>()!;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final finishedSession = motionState.finishedSession;
    final realtime = motionState.realtime;

    final durationFormat = formatMotionDuration(
      finishedSession?.durationSeconds ?? realtime?.durationSeconds ?? 0,
    );
    final distanceKm =
        (((finishedSession?.totalDistanceMeters ?? realtime?.distanceMeters) ??
                    0) /
                1000)
            .toStringAsFixed(2);
    final currentSpeed = formatMotionSpeed(
      finishedSession?.averageSpeedMps ??
          realtime?.averageSpeedMps ??
          realtime?.currentSpeedMps,
    );
    final routeSnapshotBase64 = finishedSession?.routeSnapshotBase64;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.88),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTokens.motionModalBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18.2)),
          border: isDark
              ? Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 0.65,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.18),
              blurRadius: isDark ? 39 : 15.6,
              offset: Offset(0, isDark ? -13 : -7.8),
            ),
            if (isDark)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 0,
                offset: const Offset(0, -0.65),
              ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 6.5,
            bottom: mediaQuery.padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部小横条（把手）
              Container(
                width: 23.4,
                height: 2.6,
                decoration: BoxDecoration(
                  color: appTokens.motionModalHandle,
                  borderRadius: BorderRadius.circular(1.3),
                ),
              ),
              const SizedBox(height: 10.4),

              // 头部徽章与文本
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Column(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 59.8,
                            height: 59.8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha: 0.18),
                                  const Color(
                                    0xFF11632F,
                                  ).withValues(alpha: 0.09),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.35, 0.7],
                              ),
                            ),
                          ),
                          const AppSvgIcon(
                            'assets/icons/motion/motion_completion_badge.svg',
                            size: 45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '完成本次旅途',
                      style: TextStyle(
                        color: appTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.617,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '您的旅途距离已同步推进当前旅程',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appTokens.motionModalDescription,
                        fontSize: 8.45,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1145,
                      ),
                    ),
                    if (routeSnapshotBase64 != null &&
                        routeSnapshotBase64.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _RouteSnapshotCard(
                        routeSnapshotBase64: routeSnapshotBase64,
                        appTokens: appTokens,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),
              _SectionDivider(appTokens: appTokens),
              const SizedBox(height: 11),

              // 数据统计区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _MetricCell(
                          value: durationFormat,
                          unit: '',
                          label: '时长',
                          appTokens: appTokens,
                        ),
                      ),
                      _MetricDivider(color: appTokens.dividerPrimary),
                      Expanded(
                        child: _MetricCell(
                          value: distanceKm,
                          unit: 'km',
                          label: '距离',
                          appTokens: appTokens,
                        ),
                      ),
                      _MetricDivider(color: appTokens.dividerPrimary),
                      Expanded(
                        child: _MetricCell(
                          value: currentSpeed,
                          unit: 'km/h',
                          label: '均速',
                          appTokens: appTokens,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _SectionDivider(appTokens: appTokens),
              const SizedBox(height: 10),

              // 虚拟旅程进度区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: _JourneyProgressCard(
                  appTokens: appTokens,
                  isDark: isDark,
                  distanceKm: distanceKm,
                ),
              ),
              const SizedBox(height: 10.4),

              // 底部操作按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: _SecondaryActionButton(
                        label: '查看记录',
                        iconPath: 'assets/icons/motion/motion_view_history.svg',
                        backgroundColor:
                            appTokens.motionModalMutedActionBackground,
                        borderColor: appTokens.motionModalMutedActionBorder,
                        textColor: appTokens.motionModalMutedActionText,
                        onTap: () {
                          Navigator.of(context).pop(); // 关闭弹窗
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => const MotionHistoryPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PrimaryActionButton(
                        label: '完成',
                        iconPath: 'assets/icons/motion/motion_finish_flag.svg',
                        startColor: appTokens.motionPrimaryActionStart,
                        endColor: appTokens.motionPrimaryActionEnd,
                        shadowColor: appTokens.motionPrimaryActionStart
                            .withValues(alpha: 0.38),
                        onTap: () {
                          Navigator.of(context).pop(); // 关闭弹窗
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSnapshotCard extends StatelessWidget {
  const _RouteSnapshotCard({
    required this.routeSnapshotBase64,
    required this.appTokens,
    required this.isDark,
  });

  final String routeSnapshotBase64;
  final AppThemeTokens appTokens;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(routeSnapshotBase64);
    } catch (_) {
      imageBytes = null;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTokens.motionModalMutedActionBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.78,
        child: imageBytes == null
            ? ColoredBox(
                color: appTokens.motionModalMutedActionBackground,
                child: Center(
                  child: Text(
                    '路线截图生成失败',
                    style: TextStyle(
                      color: appTokens.motionModalDescription,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: appTokens.motionModalMutedActionBackground,
                    child: Center(
                      child: Text(
                        '路线截图生成失败',
                        style: TextStyle(
                          color: appTokens.motionModalDescription,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.appTokens});

  final AppThemeTokens appTokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.65,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10.4),
      color: appTokens.dividerPrimary,
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(width: 0.65, thickness: 0.65, color: color);
  }
}

class _JourneyProgressCard extends ConsumerWidget {
  const _JourneyProgressCard({
    required this.appTokens,
    required this.isDark,
    required this.distanceKm,
  });

  final AppThemeTokens appTokens;
  final bool isDark;
  final String distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeDistanceInfoProvider).asData?.value;
    final goalRoute = ref.watch(goalRouteProvider);
    final distKm = route?.distKm ?? 0.0;
    final completedDist = route?.completedDist ?? 0.0;
    final progress = route?.ratio ?? 0.0;
    final remainingDist = distKm > completedDist ? distKm - completedDist : 0.0;
    final identity = ref.watch(identityProvider);

    return Container(
      //设置背景色圆角等
      decoration: BoxDecoration(
        color: appTokens.motionPrimaryActionStart.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11.7),
        border: Border.all(
          color: appTokens.motionPrimaryActionStart.withValues(alpha: 0.18),
          width: 0.65,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.4),
        child: Column(
          //决定整体高度 = 内容高度
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                //占用左边剩余空间
                Expanded(
                  child: Row(
                    children: [
                      AppSvgIcon(
                        'assets/icons/motion/motion_journey_route.svg',
                        color: appTokens.textPrimary,
                        size: 11.7,
                      ),
                      const SizedBox(width: 5.2),
                      Expanded(
                        child: Text(
                          identity.isGlobal
                              ? '环绕地球一周'
                              : '${route?.originCityName ?? goalRoute.originCity.name} → ${route?.destinationCityName ?? goalRoute.destinationCity.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appTokens.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: appTokens.motionPrimaryActionStart.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6.5),
                  ),
                  child: Text(
                    '+$distanceKm km',
                    style: TextStyle(
                      color: appTokens.motionPrimaryActionStart,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress, // 占位比例
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.95),
                      gradient: LinearGradient(
                        colors: [
                          appTokens.motionPrimaryActionStart,
                          appTokens.motionPrimaryActionEnd,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: appTokens.motionPrimaryActionStart.withValues(
                            alpha: 0.33,
                          ),
                          blurRadius: 5.2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                //左右各占一半，中间间距是8
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: appTokens.motionModalDescription,
                      ),
                      children: [
                        const TextSpan(text: '已走 '),
                        TextSpan(
                          text: '${completedDist.toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: appTokens.motionPrimaryActionStart,
                          ),
                        ),
                        TextSpan(text: ' / ${distKm.toStringAsFixed(2)} km'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: appTokens.motionModalDescription,
                      ),
                      children: [
                        const TextSpan(text: '还剩 '),
                        TextSpan(
                          text: '${remainingDist.toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: appTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.iconPath,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11.7),
        border: Border.all(color: borderColor, width: 0.65),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.7),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(iconPath, color: textColor, size: 11.7),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.iconPath,
    required this.startColor,
    required this.endColor,
    required this.shadowColor,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final Color startColor;
  final Color endColor;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11.7),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 7.8,
            offset: const Offset(0, 3.9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.7),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSvgIcon(
                  'assets/icons/motion/motion_finish_flag.svg',
                  color: Colors.white,
                  size: 11.7,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.appTokens,
  });

  final String label;
  final String value;
  final String unit;
  final AppThemeTokens appTokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: appTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.38,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: appTokens.textSecondary,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: appTokens.motionModalDescription,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
