# 应用主题色基础设计

## 文档目的

这份文档只负责应用级主题色设计，不承载业务模块页面方案，也不承载图标、导航、资源目录等其他基础规范。

本文件当前只聚焦：

- 主题 token 组织方案
- 明暗模式颜色管理方案

## 适用范围

本文件覆盖所有跨模块复用的主题色基础能力，例如：

- 全局主题色
- 明暗模式颜色切换
- 跨模块颜色 token 复用

说明：

- 运动模块、首页模块、“我的”模块等业务模块，只引用本文件定义的主题色基础能力。
- 业务模块自己的文档只记录“如何使用”，不重复定义这些主题色基础能力。

## 主题颜色设计原则

### 原则 1：不按页面建颜色

颜色不按页面维度创建，不存在“首页一套、运动页一套、我的一套”这种重复定义。

如果多个页面本质上使用的是同一个设计 token，就只定义一次，全局复用。

### 原则 2：不按色值命名业务变量

不建议使用类似：

- `dlt_356578_DF7F55`

这样的变量名作为长期业务命名。

原因：

- 名称无法表达用途
- 设计改色后变量名会失真
- 后续维护时无法快速判断这个颜色属于按钮、文字还是背景

### 原则 3：按语义定义 token

颜色 token 应该表达“用途”，而不是表达“它现在长什么样”。

例如：

- `brandPrimary`
- `surfacePrimary`
- `surfaceSecondary`
- `textPrimary`
- `textSecondary`
- `danger`

### 原则 4：一份 token，内含明暗两套值

每个动态颜色 token 自己持有：

- `light`
- `dark`

最终取值时，根据当前主题模式返回对应颜色。

## 推荐代码组织

建议目录：

- `lib/app/theme/app_dynamic_color.dart`
- `lib/app/theme/app_color_tokens.dart`
- `lib/app/theme/app_theme_tokens.dart`
- `lib/app/theme/app_theme.dart`

职责建议：

- `app_dynamic_color.dart`
  - 定义单个动态颜色模型
- `app_color_tokens.dart`
  - 定义全局基础颜色 token
- `app_theme_tokens.dart`
  - 定义主题级聚合入口
- `app_theme.dart`
  - 输出亮色/暗色 `ThemeData`

## 推荐的数据模型

建议使用一个轻量动态颜色模型：

```dart
class DltDynamicColor {
  const DltDynamicColor({
    required this.light,
    required this.dark,
  });

  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
```

说明：

- 这里的重点不是类名本身，而是“一个 token 对应明暗两套值”的组织方式。
- 后续如果改成 `ThemeExtension` 持有这些 token，也不影响这个思路。

## 颜色 token 分层方案

建议分成两层。

### 第一层：全局基础 token

这层只定义全局可复用的动态颜色，不绑定具体页面。

示例：

```dart
class AppColorTokens {
  static const brandPrimary = DltDynamicColor(
    light: Color(0xFF356578),
    dark: Color(0xFFDF7F55),
  );

  static const surfacePrimary = DltDynamicColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF111111),
  );

  static const textPrimary = DltDynamicColor(
    light: Color(0xFF111111),
    dark: Color(0xFFF5F5F5),
  );
}
```

特点：

- 一次定义
- 多模块复用
- 后续改色只改一处

### 第二层：业务映射 token

这层不一定重新定义色值，而是从全局基础 token 做语义映射。

例如运动模块里：

```dart
class MotionThemeTokens {
  static const actionPrimary = AppColorTokens.brandPrimary;
  static const panelBackground = AppColorTokens.surfacePrimary;
  static const primaryText = AppColorTokens.textPrimary;
}
```

特点：

- 业务代码可读性更好
- 如果后续运动模块要和全局品牌色脱钩，可以只改映射关系
- 不会造成页面级重复建色

## 当前推荐的基础 token 命名方向

第一批建议优先准备这些全局 token：

- `brandPrimary`
- `brandAccent`
- `surfacePrimary`
- `surfaceSecondary`
- `surfaceOverlay`
- `textPrimary`
- `textSecondary`
- `textInverse`
- `borderPrimary`
- `dividerPrimary`
- `danger`
- `warning`
- `success`

说明：

- 这里只定命名方向，不在本轮直接拍死所有最终色值。
- 具体数值应以 Figma 设计稿实际整理后填入。

## 当前推荐的使用规则

### 页面层规则

- 页面组件不直接写设计稿原始色值
- 页面组件优先通过 `Theme.of(context)` 或主题扩展取值
- 页面层不创建新的“页面专属基础色”

### 模块层规则

- 模块层可以定义自己的语义映射 token
- 模块层如果只是复用全局色，不重复创建色值
- 模块层如果确实需要新增业务色，先判断是否能抽象成全局 token

### 改色规则

- 如果只是全局品牌色调整，只改基础 token
- 如果只是单模块视觉偏移，优先改模块映射 token
- 不允许在多个页面手动同步改相同色值

## 当前确认结论

### 结论 1：采用两层 token 结构

已确认采用：

- 全局基础 token
- 业务映射 token

后续实现要求：

- 全局基础 token 负责持有动态色值
- 业务模块只做语义映射，不重复定义同一套色值

### 结论 2：保留 `DltDynamicColor` 模型

已确认保留 `DltDynamicColor` 作为当前动态颜色模型。

后续实现要求：

- 每个动态颜色 token 持有 `light` 与 `dark`
- 页面取值时根据当前主题模式解析最终颜色

### 结论 3：token 命名由实现侧统一收敛

已确认第一批 token 命名由实现阶段统一收敛，不要求用户先逐个命名确认。

后续实现要求：

- 命名优先表达语义
- 命名避免绑定具体页面
- 命名避免绑定具体色值
