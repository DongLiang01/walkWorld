# 仓库协作约定，工作时会优先遵守这些指令

1. 回答、思考尽可能使用中文。
2. 注释使用中文，尽量不要删除注释，可以修改但是不能删除。
3. 修改代码时，请注意是否其他地方在调用，确认不影响其他地方时，再删除。
4. Flutter 相关命令使用 `fvm` 前缀。
5. 从 Figma 新增或替换 SVG 资源到 Flutter 项目后，先检查并规范化 SVG；优先执行 `python3 .codex/skills/figma-svg-normalizer/scripts/normalize_svg_vars.py 路径`，确认没有 `var(...)` 这类 `flutter_svg` 不兼容写法后，再接入页面。
