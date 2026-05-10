---
name: theme-color-tokens
description: 当任务涉及 Flutter 项目的白天/黑夜主题色、新增或调整亮暗模式颜色、AppThemeTokens、AppColorTokens、主题 token 收口、页面颜色取值规范时使用。适用于新增色值、替换硬编码颜色、补充中文注释、检查页面是否绕开主题体系等场景。
---

# Theme Color Tokens

本 skill 仅用于当前仓库。

适用场景：

- 用户提到“白天/黑夜模式色值”“亮色/暗色主题色”
- 用户要求新增主题颜色、调整主题颜色
- 用户指出页面里直接写了 `Color(...)`，希望改回主题体系
- 用户提到 `AppThemeTokens`、`AppColorTokens`、`ThemeExtension`
- 用户要求给主题颜色字段补中文注释
- 需要检查某个页面是否绕开了现有主题逻辑

## 当前仓库主题约定

- 主题基础说明以 `docs/app-theme-foundation.md` 为准。
- 动态颜色源头定义在 `walkworld/lib/app/theme/app_color_tokens.dart`。
- 主题聚合出口定义在 `walkworld/lib/app/theme/app_theme_tokens.dart`。
- 页面和组件优先通过 `Theme.of(context)` 与 `ThemeExtension<AppThemeTokens>` 取值。
- 页面层不直接持有“明暗两套色值”的硬编码逻辑，除非是资源切换而不是颜色定义。

## 工作流程

1. 先检查目标代码是否直接写了亮暗分支或原始 `Color(...)`：

```bash
rg -n "Brightness\\.dark|Color\\(" walkworld/lib
```

2. 如果是新增主题颜色，先判断是否属于全局可复用语义；若是，就先加到 `AppColorTokens`，再映射到 `AppThemeTokens`。

3. 新增 `AppThemeTokens` 字段时，必须补中文注释，说明这个颜色的语义和常见使用场景。

4. 页面层接入时，优先使用：

```dart
final tokens = Theme.of(context).extension<AppThemeTokens>()!;
```

5. 如果页面当前通过 `isDark ? ... : ...` 直接分叉颜色，优先改为从 `tokens` 读取；如果只是选择不同资源文件，例如 `*_day.svg` / `*_night.svg`，可保留资源切换。

6. 改完后至少执行相关格式化；如果本次改动涉及 Flutter 主题逻辑，优先补一次：

```bash
fvm flutter analyze
```

## 处理原则

- 新增色值时，先定义语义，再填写数值；不要按十六进制值命名。
- 不要在页面、组件、业务模块里重复保存同一套明暗色值。
- 能复用已有 token 时不要新增重复字段。
- 只有确认是业务局部语义且不适合全局复用时，才考虑在模块层做映射 token。
- 注释使用中文，尽量直接解释“这个颜色给谁用、为什么存在”。
- 不删除现有注释；如果原注释不准确，可以在保留意图的前提下修改得更清楚。

## 新增主题色的推荐顺序

1. 在 `AppColorTokens` 定义动态颜色的 `light` / `dark`
2. 在 `AppThemeTokens` 增加解析字段与中文注释
3. 如有需要，确认 `copyWith` 与 `lerp` 同步补齐
4. 页面或组件通过 `AppThemeTokens` 读取，不直接写明暗色值

## 快速自检

- 是否把新增明暗色值收口进 `AppColorTokens` 与 `AppThemeTokens`
- 是否仍有页面直接写 `isDark ? Color(...) : Color(...)`
- 是否给新增主题字段补了中文注释
- 是否误把资源切换问题和主题颜色问题混在一起
- 是否执行了 `fvm` 前缀的 Flutter 命令
