import 'package:flutter/material.dart';

/// 首页默认占位页。
///
/// 当前仅用于搭建底部导航架构，后续会按正式设计稿替换。
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScaffold(
      title: '首页',
      subtitle: 'Home Placeholder',
      backgroundColor: Color(0xFFE9F5FF),
      accentColor: Color(0xFF2E7D9A),
      description: '这里先作为首页占位页，后续再接入 Figma 正式内容。',
      icon: Icons.explore_outlined,
    );
  }
}

class _PlaceholderScaffold extends StatelessWidget {
  const _PlaceholderScaffold({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
    required this.description,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(title), backgroundColor: backgroundColor),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: accentColor.withValues(alpha: 0.14),
                  child: Icon(icon, size: 36, color: accentColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: accentColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: const Color(0xFF35515D),
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
