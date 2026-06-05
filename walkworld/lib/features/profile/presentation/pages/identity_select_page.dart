import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../application/identity_provider.dart';

// ============================================================
// 身份选择页面 — 展示所有可选身份，当前身份显示对勾
// ============================================================

/// 身份选择页面入口
class IdentitySelectPage extends ConsumerWidget {
  const IdentitySelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final currentIdentity = ref.watch(identityProvider);

    return Scaffold(
      backgroundColor: tokens.profilePageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 顶部导航栏 ──
            _IdentityAppBar(tokens: tokens),
            // ── 身份列表 ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: allIdentities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final identity = allIdentities[index];
                  final isSelected = identity.name == currentIdentity.name;

                  return _IdentityCard(
                    identity: identity,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(identityProvider.notifier)
                          .selectIdentity(identity);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 顶部导航栏 ──────────────────────────────────────────────

/// 页面顶部自定义导航栏
class _IdentityAppBar extends StatelessWidget {
  const _IdentityAppBar({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧返回箭头按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AppSvgIcon(
                  AppSvgAssets.common('back_arrow'),
                  width: 20,
                  height: 20,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 页面标题
          Text(
            '选择身份',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.profileTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 身份列表卡片 ────────────────────────────────────────────

/// 单个身份卡片（样式与 profile 页面身份卡片一致，但右侧为对勾或空）
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.identity,
    required this.isSelected,
    required this.onTap,
  });

  final IdentityItem identity;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.profileCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? tokens.profileAccentBlue
                : tokens.profileCardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.profileCardBorder,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 身份图标
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.profileIconBgOrange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.profileIconBorderOrange),
              ),
              child: Center(
                child: AppSvgIcon(
                  AppSvgAssets.profile(identity.iconName),
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 身份名称
            Expanded(
              child: Text(
                identity.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? tokens.profileAccentBlue
                      : tokens.profileTextPrimary,
                ),
              ),
            ),
            // 选中状态：对勾图标
            if (isSelected)
              AppSvgIcon(
                AppSvgAssets.common('checkmark'),
                width: 16,
                height: 16,
                color: tokens.profileAccentBlue,
              ),
          ],
        ),
      ),
    );
  }
}
