# Codex Skill 与 Plugin 学习笔记

本文档结合当前仓库的实际例子，说明：

- 什么是项目 skill
- 什么是全局 skill
- 什么是全局 plugin
- 它们分别放在哪里
- 应该怎么创建
- 它们之间有什么区别

## 1. 先说结论

如果你的需求是“我个人在很多项目里都想复用同一套工作流”，优先做成全局 skill。

如果你的需求是“这个仓库自己有一套专属流程，只想跟着仓库走”，适合做成项目内 plugin，再由 plugin 暴露 skill。

如果你的需求不仅仅是提示词或工作流，还需要成体系的插件入口、市场配置、多个 skill、脚本、资源、MCP、App 等，适合做成 plugin。

## 2. 这几个东西的区别

### Skill 是什么

skill 本质上是一套“让 Codex 在某类任务里遵循固定工作流”的说明书。

一个 skill 最少需要：

- 一个目录
- 目录里有 `SKILL.md`
- `SKILL.md` 顶部必须有 YAML frontmatter
- frontmatter 里至少要有：
  - `name`
  - `description`

可选内容：

- `agents/openai.yaml`
- `scripts/`
- `references/`
- `assets/`

### Plugin 是什么

plugin 是更完整的一层封装。

plugin 可以包含：

- 一个或多个 skill
- 脚本
- 资源
- hooks
- MCP 配置
- App 配置
- UI 元数据
- marketplace 配置

也就是说：

- `skill` 更像“能力说明 + 流程约定”
- `plugin` 更像“能力包”

## 3. 全局 skill 和项目 skill 的区别

### 全局 skill

全局 skill 是装在你个人环境里的，所有项目都可以触发。

典型目录：

```text
~/.codex/skills/<skill-name>/
```

例如这次我为你创建的全局 skill：

```text
/Users/dongliang/.codex/skills/module-progress-sync/
```

它里面现在有：

```text
/Users/dongliang/.codex/skills/module-progress-sync/SKILL.md
/Users/dongliang/.codex/skills/module-progress-sync/agents/openai.yaml
/Users/dongliang/.codex/skills/module-progress-sync/scripts/create_module_docs.py
/Users/dongliang/.codex/skills/module-progress-sync/scripts/mark_module_step_done.py
```

特点：

- 所有项目可复用
- 更适合个人通用工作流
- 不依赖某个仓库存在
- 改一次，所有项目都受影响

### 项目 skill

项目 skill 一般跟着仓库走，只在某个项目内生效。

最稳妥的做法通常是“项目内 plugin 暴露 skill”，目录类似：

```text
<repo>/plugins/<plugin-name>/skills/<skill-name>/SKILL.md
```

特点：

- 只在这个仓库里可用
- 非常适合项目专属约定
- 可以跟代码一起提交、评审、版本化
- 不会影响其他项目

## 4. 全局 plugin 和项目 plugin 的区别

### 项目 plugin

项目 plugin 通常放在仓库内：

```text
<repo>/plugins/<plugin-name>/
<repo>/.agents/plugins/marketplace.json
```

目录通常类似：

```text
<repo>/plugins/<plugin-name>/
<repo>/.agents/plugins/marketplace.json
```

### 全局 plugin

全局 plugin 通常放在家目录：

```text
~/plugins/<plugin-name>/
~/.agents/plugins/marketplace.json
```

特点：

- 所有项目都能用
- 比全局 skill 更重
- 更适合长期复用的一整套插件能力
- 适合多个 skill、脚本、资源打包在一起

## 5. 什么时候该选哪一个

推荐优先级：

1. 只是想复用提示词、步骤、工作流：
   选全局 skill
2. 只想给某个仓库加专属流程：
   选项目 skill 或项目 plugin
3. 想把多个能力打包成一个完整体系，带 marketplace 和更多扩展能力：
   选 plugin

对你这次这个需求来说：

- “任何项目里新增模块时，都先给我 plan 和 implementation spec”
- “每完成一步，就自动检查并标记删除线”

这是典型的个人通用工作流，所以最适合全局 skill。

## 6. Skill 最小结构

一个最小可用的 skill 目录如下：

```text
my-skill/
└── SKILL.md
```

`SKILL.md` 最少应写成这样：

```md
---
name: my-skill
description: 说明这个 skill 做什么，以及什么情况下应该触发它。
---

# My Skill

这里写工作流说明。
```

如果缺少 `name`，就会出现你刚才看到的报错：

```text
技能必须提供名称
```

## 7. 怎么创建全局 skill

### 做法 A：手动创建

1. 新建目录：

```bash
mkdir -p ~/.codex/skills/my-skill
```

2. 新建 `SKILL.md`

```text
~/.codex/skills/my-skill/SKILL.md
```

3. 在 `SKILL.md` 里写 frontmatter：

```md
---
name: my-skill
description: 说明 skill 的作用和触发场景
---
```

4. 如果需要脚本，再加：

```text
~/.codex/skills/my-skill/scripts/
```

5. 如果需要 UI 元数据，再加：

```text
~/.codex/skills/my-skill/agents/openai.yaml
```

### 做法 B：用系统 skill-creator 脚手架

可以使用系统自带脚本：

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/init_skill.py \
  my-skill \
  --path ~/.codex/skills \
  --resources scripts
```

如果要带 UI 元数据，再补生成或手写 `agents/openai.yaml`。

## 8. 怎么创建项目 skill

这里要分两种理解。

### 方式 1：严格意义上的“项目内可发现 skill”

在当前 Codex 生态里，更稳妥的做法是通过项目 plugin 来暴露 skill。

也就是：

1. 先创建项目 plugin
2. 再把 skill 放到 plugin 的 `skills/` 目录下

目录通常是：

```text
<repo>/plugins/<plugin-name>/skills/<skill-name>/SKILL.md
```

项目里的实际路径通常会长这样：

```text
<repo>/plugins/<plugin-name>/skills/<skill-name>/SKILL.md
```

### 方式 2：只是在项目里保存一套 skill 资料

你也可以单纯在仓库里放一个 skill 目录，例如：

```text
<repo>/tools/skills/my-skill/SKILL.md
```

但这种做法是否会被 Codex 自动发现，取决于当前产品的扫描规则。

所以如果你的目标是“稳定可用、可触发”，优先推荐方式 1，也就是“项目 plugin + skill”。

## 9. 怎么创建项目 plugin

项目内 plugin 的典型创建方式是：

```bash
python3 /Users/dongliang/.codex/skills/.system/plugin-creator/scripts/create_basic_plugin.py \
  my-plugin \
  --path <repo>/plugins \
  --with-skills \
  --with-scripts \
  --with-marketplace \
  --marketplace-path <repo>/.agents/plugins/marketplace.json
```

创建后通常会得到：

```text
<repo>/plugins/<plugin-name>/.codex-plugin/plugin.json
<repo>/plugins/<plugin-name>/skills/
<repo>/plugins/<plugin-name>/scripts/
<repo>/.agents/plugins/marketplace.json
```

## 10. 怎么创建全局 plugin

如果你以后要做一个全局 plugin，目录一般是：

```text
~/plugins/<plugin-name>/
~/.agents/plugins/marketplace.json
```

可以参考 `plugin-creator` 的 home-local 用法：

```bash
python3 /Users/dongliang/.codex/skills/.system/plugin-creator/scripts/create_basic_plugin.py \
  my-plugin \
  --path ~/plugins \
  --marketplace-path ~/.agents/plugins/marketplace.json \
  --with-marketplace
```

## 11. 这次你项目里的实际落地

### 全局 skill

```text
/Users/dongliang/.codex/skills/module-progress-sync/
```

作用：

- 任意项目里都可以复用“模块计划 + 实施步骤 + 自动标记完成”的工作流

### 项目 plugin

如果某个仓库确实需要项目专属版本，可以按下面形式保存在仓库里：

```text
<repo>/plugins/<plugin-name>/
```

作用：

- 仓库专属实现版本
- 可以跟着仓库一起提交和维护

### 仓库级规则

```text
/Users/dongliang/Desktop/DLLT.git/walkWord/AGENTS.md
```

作用：

- 在这个仓库里进一步强化“新功能先建文档、按 Step 执行、完成后自动标记”的约定

## 12. 一句经验建议

如果一套能力是“我个人在很多仓库都要用”，优先做成全局 skill。  
如果一套能力是“这个仓库自己特有”，优先做成项目 plugin。  
如果两者都需要，就像这次一样：全局 skill 负责通用工作流，项目 plugin 负责仓库内落地和版本化。
