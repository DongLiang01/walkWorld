# 仓库协作约定，工作时会优先遵守这些指令

1. 回答、思考尽可能使用中文。
2. 注释使用中文，尽量不要删除注释，可以修改但是不能删除。
3. 修改代码时，请注意是否其他地方在调用，确认不影响其他地方时，再删除。
4. Flutter 相关命令使用 `fvm` 前缀。
5. 从 Figma 新增或替换 SVG 资源到 Flutter 项目后，先检查并规范化 SVG；优先执行 `python3 .codex/skills/figma-svg-normalizer/scripts/normalize_svg_vars.py 路径`，确认没有 `var(...)` 这类 `flutter_svg` 不兼容写法后，再接入页面。
6. 凡是涉及白天/黑夜主题色、新增或调整亮暗模式颜色、`AppColorTokens`、`AppThemeTokens`、页面新增 `Color(...)`、颜色收口等修改，必须先使用 `theme-color-tokens` skill，再开始改代码。
7. 命中上一条场景但未先读取并遵循 `theme-color-tokens` skill 时，不得继续实现。
8. 除非用户明确要求做临时原型，否则页面层禁止直接新增亮暗两套 `Color(...)`；必须优先收口到主题体系。
9. 凡涉及主题色相关改动，开始实现前必须先执行范围检查：`rg -n "Brightness\\.dark|Color\\(" walkworld/lib`，确认影响范围后，再按 `theme-color-tokens` skill 修改。
10. 在所有涉及 SVG 图片加载的开发中，必须统一使用项目中封装好的 `AppSvgIcon` 组件（例如通过 `import 'package:walkworld/app/svg/app_svg_icon.dart';`），禁止直接使用 `SvgPicture.asset`。
