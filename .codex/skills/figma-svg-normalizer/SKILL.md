---
name: figma-svg-normalizer
description: 当任务涉及从 Figma 下载、导出、新增、替换 SVG 资源到当前 Flutter 项目时优先使用。导入后立即自动检查并规范化 SVG，重点处理 flutter_svg 不兼容的 CSS 变量写法，例如把 stroke/fill 中的 var(--token, #color) 替换为 Flutter 可解析的字面量颜色；也适用于已出现图标不显示、加载失败时的排查与批量修复。
---

# Figma SVG Normalizer

本 skill 仅用于当前仓库。

适用场景：

- 用户说“从 Figma 下载了新的 SVG / 刚导出了新的 SVG”
- 用户说“把这批 Figma 图标接入项目”
- 用户新增、替换了 `assets/` 下的 SVG 资源
- 用户说“Figma 导出的 svg 加载不出来”
- 用户说“flutter_svg 不显示图标 / tabbar 图标丢失”
- SVG 中出现 `var(--token, #color)`、`style="..."` 这类 Flutter 兼容性问题
- 需要批量修复 `assets/` 下新导入的 SVG

## 工作流程

1. 只要本次任务包含“从 Figma 导入新的 SVG”，就先执行检查，不要等页面加载失败后再处理。

2. 先检查目标 SVG 是否包含 `var(`：

```bash
rg -n "var\\(" 路径
```

3. 如果存在，优先使用脚本批量规范化：

```bash
python3 .codex/skills/figma-svg-normalizer/scripts/normalize_svg_vars.py 路径
```

4. 规范化后再次检查，确认没有残留：

```bash
rg -n "var\\(" 路径
```

5. 如果这次任务已经要把 SVG 接入 Flutter 页面，再检查对应调用方是否仍通过 `AppSvgIcon` 或 `SvgPicture.asset` 正常加载。

## 处理原则

- 只替换 Flutter 不兼容的 CSS 变量写法，不擅自修改路径、尺寸、viewBox。
- 优先保留 `var(--token, fallback)` 中的 fallback 颜色值，例如 `#9CA3AF`。
- 如果 `var(...)` 没有 fallback 颜色，不自动猜测颜色，先提示用户或结合上下文确认。
- 修改前注意检索调用方，避免误删其他资源或命名。
- 若是批量导入的 Figma 资源，优先对整个目录执行脚本，而不是逐文件手改。
- 这是导入阶段的默认步骤，不是故障后的补救步骤。

## 当前仓库约定

- Flutter 资源主要位于 `walkworld/assets/`
- Flutter SVG 统一组件位于 `walkworld/lib/app/svg/`
- 从 Figma 新增或替换 SVG 后，默认先执行一次规范化脚本，再接入页面或提交代码
- 如果只是资源文件不兼容，优先修 SVG 本身，不要先改页面逻辑

## 脚本说明

脚本路径：

`./scripts/normalize_svg_vars.py`

能力：

- 支持单个 `.svg` 文件
- 支持目录递归处理
- 将 `stroke="var(--x, #xxxxxx)"`、`fill="var(--x, #xxxxxx)"` 等属性值替换为对应 fallback 颜色
- 输出修改统计，便于复核
