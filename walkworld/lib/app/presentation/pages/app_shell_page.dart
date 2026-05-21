import 'package:flutter/material.dart';

import '../../svg/svg.dart';
import '../../theme/app_theme_tokens.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/motion/presentation/presentation.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';

/// 应用根壳页面。
///
/// 当前正式页与调试页职责已经拆开：
/// 1. 提供接近设计稿语义的底部三栏导航
/// 2. “运动”模块挂正式 `MotionPage`
/// 3. 首页、运动页、“我的”页都走当前正式入口
/// 4. 底部导航只负责页面切换，不再承载调试或占位页面分流
class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    HomePage(),
    MotionPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _FigmaTabBar(
        currentIndex: _currentIndex,
        isDark: isDark,
        tokens: tokens,
        onTap: _onTabChanged,
      ),
    );
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.label,
    required this.assetName,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String label;
  final String assetName;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetName,
                width: 24,
                height: 24,
                color: labelColor,
                semanticLabel: label,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  letterSpacing: 0.017,
                  fontWeight: FontWeight.w400,
                ).copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 按 Figma 节点参数还原的底部导航栏。
class _FigmaTabBar extends StatelessWidget {
  const _FigmaTabBar({
    required this.currentIndex,
    required this.isDark,
    required this.tokens,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final AppThemeTokens tokens;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: '首页',
        asset: AppSvgAssets.tabbar(isDark ? 'home_night' : 'home_day'),
      ),
      (
        label: '运动',
        asset: AppSvgAssets.tabbar(isDark ? 'motion_night' : 'motion_day'),
      ),
      (
        label: '我的',
        asset: AppSvgAssets.tabbar(isDark ? 'profile_night' : 'profile_day'),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.tabBarBackground,
        border: Border(top: BorderSide(color: tokens.tabBarBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 83,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];

              return Expanded(
                child: _TabBarItem(
                  label: item.label,
                  assetName: item.asset,
                  isSelected: currentIndex == index,
                  onTap: () => onTap(index),
                  activeColor: tokens.tabBarActive,
                  inactiveColor: tokens.tabBarInactive,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
