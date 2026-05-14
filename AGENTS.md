# 仓库协作约定，工作时会优先遵守这些指令

## 1. 基础工作规范
1. **纯中文交流**：回答、思考尽可能使用中文。
2. **注释留存**：注释必须使用中文；尽量不要删除现有注释，可以修改但不能擅自删除。
3. **修改安全检查**：修改或删除代码时，必须先排查是否被其他地方调用，确认不影响外部链路后再操作。
4. **环境命令**：所有 Flutter 相关命令必须使用 `fvm` 前缀（如 `fvm flutter ...`）。

## 2. Figma 还原与 SVG 图标规范
1. **像素级还原**：用户提供 Figma 链接要求还原 UI 时，最终效果必须保持和设计稿完全一致。
2. **禁止自带 Icons**：还原设计稿时，**严格禁止图省事使用 Flutter 自带的 `Icons.*`**（如 `Icons.pause` 等）。所有出现的设计稿图标，必须从 Figma 导出为 SVG。
3. **SVG 清洗拦截**：从 Figma 新增或替换 SVG 资源到本地后，**第一步必须执行预处理脚本**：`python3 .codex/skills/figma-svg-normalizer/scripts/normalize_svg_vars.py <路径>`。确认剔除了 `var(...)` 等 `flutter_svg` 不兼容的写法后，才能接入页面。
4. **统一渲染组件**：所有涉及 SVG 图片渲染的地方，必须统一使用项目自带的 `AppSvgIcon` 组件（如 `import 'package:walkworld/app/svg/app_svg_icon.dart';`），**绝对禁止直接使用 `SvgPicture.asset`**。

## 3. 主题色与暗黑模式规范（Color Tokens）
1. **强制读取规范**：凡是涉及白天/黑夜主题色变更、新增 `AppColorTokens` 或 `AppThemeTokens`、页面手写 `Color(...)`、颜色收口等修改，必须先读取并使用 `theme-color-tokens` skill。未读取时不准写代码。
2. **收口到主题池**：除非用户明确要求做“临时原型”，否则在页面 UI 层禁止直接写亮暗判断的两套 `Color(...)` 或硬编码颜色值。所有颜色必须上浮提取并收口到主题体系。
3. **改前全局排查**：凡涉及老代码主题色替换或重构，开始写代码前必须先执行范围检查：`rg -n "Brightness\.dark|Color\(" walkworld/lib`，摸清影响范围后，再按 `theme-color-tokens` 规范落地。