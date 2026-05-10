import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_tokens.dart';
import '../../../../main.dart';

/// 首页默认占位页。
///
/// 当前仅用于搭建底部导航架构，后续会按正式设计稿替换。
class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PlaceholderScaffold(
      title: '首页',
      subtitle: 'Home Placeholder',
      description: '这里先作为首页占位页，后续再接入 Figma 正式内容。',
      icon: Icons.explore_outlined,
      onToggleTheme: () {
        final brightness = Theme.of(context).brightness;

        // 测试按钮仅在白天与黑夜之间切换，便于直接验证主题资源与配色。
        ref.read(themeModeProvider.notifier).toggleForTest(brightness);
      },
    );
  }
}

class _PlaceholderScaffold extends StatelessWidget {
  const _PlaceholderScaffold({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.onToggleTheme,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final scaffoldColor = tokens.surfacePrimary;
    final panelColor = tokens.surfaceSecondary.withValues(alpha: 0.88);
    final accentColor = tokens.brandPrimary;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(title: Text(title), backgroundColor: scaffoldColor),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.borderPrimary),
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
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onToggleTheme,
                  icon: const Icon(Icons.brightness_6_outlined),
                  label: const Text('测试切换主题'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
