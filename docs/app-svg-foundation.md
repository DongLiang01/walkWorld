# 应用 SVG 基础设计

## 文档目的

这份文档只负责应用级 SVG 资源规范，不承载主题色、页面布局或业务模块交互设计。

## 目录规划

建议目录：

- `walkworld/assets/icons/common/`
- `walkworld/assets/icons/tabbar/`
- `walkworld/assets/icons/motion/`

含义：

- `common/`：通用图标
- `tabbar/`：底部导航图标
- `motion/`：运动模块专用图标

## 命名规则

统一规则：

- 全部小写
- 使用下划线分词
- 按语义命名
- 不按颜色命名

示例：

- `arrow_left.svg`
- `close.svg`
- `tab_home.svg`
- `tab_motion.svg`
- `motion_start.svg`
- `motion_pause.svg`
- `motion_distance.svg`

## 接入方式

建议方案：

- 在 `pubspec.yaml` 中统一声明 `assets/icons/`
- 使用 `flutter_svg`
- 封装统一组件，例如 `AppSvgIcon`

`AppSvgIcon` 统一负责：

- 资源路径
- 尺寸
- 颜色覆写
- 语义标签

## 使用规则

### 单色图标

- 优先保留单份 SVG
- 通过代码根据主题色或状态色着色

适用场景：

- `TabBar` 图标
- 通用线性图标
- 可跟随状态变化的操作图标

### 多色图标

- 保留原始 SVG
- 不强行代码染色

适用场景：

- 插画型图标
- 装饰型图标
- 结果页视觉型图标

### 选中态规则

- 如果只是颜色变化，优先一份 SVG + 代码着色
- 如果连图形本身都不同，再保留两份资源

## 当前推荐结论

1. `TabBar` 图标放 `assets/icons/tabbar/`
2. 运动模块图标放 `assets/icons/motion/`
3. 优先单份 SVG + 状态着色
4. 统一通过 `AppSvgIcon` 使用
