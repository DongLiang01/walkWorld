import 'package:flutter/material.dart';

/// “我的”默认占位页。
///
/// 当前仅用于搭建底部导航架构，后续会按正式设计稿替换。
class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E8),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFFFFF4E8),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD88C3E).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(
                    0xFFD88C3E,
                  ).withValues(alpha: 0.14),
                  child: const Icon(
                    Icons.person_outline,
                    size: 36,
                    color: Color(0xFFD88C3E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '我的',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFD88C3E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profile Placeholder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFBE7630),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '这里先作为“我的”模块占位页，后续再按设计稿接入个人信息、设置和运动记录入口。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: const Color(0xFF6A4A2B),
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
