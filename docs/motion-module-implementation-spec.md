# 运动模块实施规格

## 1. 文档目的

这份文档只服务一件事：指导当前阶段的运动模块实施。

阅读方式统一为：

- 先看“目标与范围”，明确这一阶段到底做到哪里。
- 再看“协作约束”，避免误入正式 UI 开发。
- 然后严格按“实施步骤”推进。
- “步骤配套细则”只是给实施步骤提供字段、协议、状态和交互依据，不是另一套独立任务。

结论约束：

- 只要按本文件的实施步骤完成并通过验收，就可以认为当前阶段的运动模块开发完成。
- 唯一例外是正式 UI：正式 UI 不在本轮直接开工，必须先通知用户并等待设计图。
- 用户现已提供设计图后，必须先补齐正式 UI 阶段的实施步骤并与用户确认，再开始代码实现。

## 2. 目标与范围

本阶段只交付运动模块最小可用版本，目标是完成一次完整运动记录闭环。

### 本阶段包含

- 运动页基础能力
- 开始、暂停、继续、结束运动
- iOS 原生高德地图显示
- iOS 原生连续定位
- Flutter 实时展示距离、速度、时长
- 地图轨迹绘制
- 结束后生成一次完整运动记录

### 本阶段不包含

- 首页历史聚合
- “我的”页面能力
- 分享、成就、排行
- 社交能力
- 后台复杂保活策略
- HealthKit 同步
- 最终视觉定稿后的正式运动页面 UI

## 3. 架构拆分

### Flutter 负责

- 运动页 UI 容器与交互承接
- 运动状态管理
- 运动流程控制
- 实时数据展示
- 接收原生事件
- 生成和持有 `MotionSession`

### iOS 原生负责

- 高德地图 SDK 集成
- 高德定位 SDK 集成
- 地图容器实现
- 定位权限申请
- 连续定位回调
- 轨迹点采集
- 距离累计
- 实时运动数据推送

### 通信方式

- `MethodChannel`：Flutter -> iOS，发送动作命令
- `EventChannel`：iOS -> Flutter，持续推送状态和运动数据

## 4. 当前进度与协作约束

### 已完成判定

- 文档中带删除线的 Step 视为已完成，是当前唯一有效的完成标记。
- 未加删除线的 Step 视为待完成，后续实现和验收只围绕这些步骤推进。

### 当前待完成范围

- 基础能力阶段主线实施步骤已全部完成
- 待新增并推进：正式 UI 开发阶段实施步骤

### UI 开发约束

- 当前仓库里的 `MotionPage` 仅作为调试页和联调面板使用，不视为最终运动模块 UI。
- 在正式开始运动模块 UI 开发前，必须先通知用户，并等待用户提供 UI 设计图后才能继续实现。
- 在用户提供设计图前，只允许完成 UI 之前的准备工作，例如状态流、交互流程、原生事件、数据模型、控制逻辑与验收整理，不直接进入正式界面开发。

### 完成判定

- 当前阶段的“模块完成”指：实施步骤全部完成并通过验收。
- 正式 UI 单独作为后续阶段处理，不影响当前这轮除正式 UI 外的模块完成判断。

### 当前 UI 阶段输入

- 用户已提供 Figma Make 链接，作为正式 UI 开发的设计输入。
- 当前需要先完成文档确认，再开始页面实现。
- 如 Figma 细节与现有模块能力存在冲突，优先在对应 Step 中记录差异并确认，不直接跳过。

## 5. 实施步骤

按下面顺序推进，前一步验收通过后再进入下一步。

### ~~Step 1: 定义数据模型~~

~~输出内容：~~

- ~~Flutter 侧运动实体~~
- ~~Channel 传输字段~~
- ~~原生侧对应模型映射~~

~~完成标准：~~

- ~~Flutter 和 iOS 端使用同一套字段定义~~
- ~~单位和空值约定明确~~

~~对应配套细则：~~

- ~~见“6.1 Step 1 配套细则：数据模型定义”~~

### ~~Step 2: 定义 Channel 协议~~

~~输出内容：~~

- ~~`MethodChannel` 名称~~
- ~~`EventChannel` 名称~~
- ~~方法列表~~
- ~~事件类型列表~~
- ~~错误码约定~~

~~完成标准：~~

- ~~Flutter 可以明确知道每个命令和事件的入参/出参~~
- ~~iOS 可以按固定协议返回结果~~

~~对应配套细则：~~

- ~~见“6.2 Step 2 配套细则：Channel 协议”~~

### ~~Step 3: 搭建 Flutter 运动状态机~~

~~输出内容：~~

- ~~`MotionStatus` 状态枚举~~
- ~~`Riverpod` provider 设计~~
- ~~状态变更规则~~

~~完成标准：~~

- ~~页面按钮行为由状态驱动~~
- ~~页面展示不直接依赖零散布尔变量~~

~~对应配套细则：~~

- ~~见“6.3 Step 3 配套细则：Flutter 状态设计”~~

### ~~Step 4: 接入 iOS 原生地图容器~~

~~输出内容：~~

- ~~原生高德地图显示在 Flutter 页面内~~
- ~~地图支持定位点和轨迹线更新~~

~~完成标准：~~

- ~~运动页能正常展示地图~~
- ~~原生层可控制地图刷新当前位置和折线~~

~~对应配套细则：~~

- ~~见“6.4 已完成记录：iOS 原生基础实现拆解”~~

### ~~Step 5: 接入 iOS 原生定位与权限~~

~~输出内容：~~

- ~~定位权限申请~~
- ~~定位服务状态检查~~
- ~~连续定位监听~~

~~完成标准：~~

- ~~真机可获取持续定位~~
- ~~权限状态可回传 Flutter~~

~~对应配套细则：~~

- ~~见“6.4 已完成记录：iOS 原生基础实现拆解”~~

### ~~Step 6: 打通实时事件流~~

~~输出内容：~~

- ~~位置点事件~~
- ~~实时统计事件~~
- ~~状态变更事件~~
- ~~错误事件~~

~~完成标准：~~

- ~~Flutter 可持续接收原生事件~~
- ~~页面数据可以实时刷新~~

~~对应配套细则：~~

- ~~见“6.4 已完成记录：iOS 原生基础实现拆解”~~

### ~~Step 7: 完成运动页核心交互~~

~~输出内容：~~

- ~~开始运动~~
- ~~暂停运动~~
- ~~继续运动~~
- ~~结束运动~~

~~完成标准：~~

- ~~整个运动流程可以走通~~
- ~~状态切换正确~~

~~补充说明：~~

- ~~本步骤可以继续完善调试页上的交互承接能力。~~
- ~~本步骤不等于正式 UI 开发。~~
- ~~如需开始正式 UI 布局与视觉实现，必须先通知用户并等待设计图。~~

~~对应配套细则：~~

- ~~见“6.3 Step 3 配套细则：Flutter 状态设计”~~
- ~~见“6.5 Step 7 配套细则：页面交互顺序”~~

### ~~Step 8: 补统计逻辑与异常处理~~

~~输出内容：~~

- ~~跳点过滤~~
- ~~精度过滤~~
- ~~速度平滑~~
- ~~结束后生成完整记录~~
- ~~基础错误处理~~

~~完成标准：~~

- ~~结果数据可用~~
- ~~明显漂移和异常点不会直接污染结果~~

~~对应配套细则：~~

- ~~见“6.1 Step 1 配套细则：数据模型定义”~~
- ~~见“6.2 Step 2 配套细则：Channel 协议”~~
- ~~见“6.5 Step 7 配套细则：页面交互顺序”~~

### ~~Step 9: 拆解 Figma 正式 UI~~

~~输出内容：~~

- ~~目标页面结构拆解~~
- ~~页面主要区块清单~~
- ~~状态页或状态区切换清单~~
- ~~待确认设计点记录~~
- ~~本轮范围边界说明~~

~~完成标准：~~

- ~~能明确页面由哪些主要区块组成~~
- ~~能明确哪些状态需要在正式 UI 中展示~~
- ~~对无法直接从现有设计输入确认的细节已单独列出~~

~~补充说明：~~

- ~~本步骤只做设计拆解与实施确认，不开始代码实现。~~
- ~~本轮明确忽略首页模块，只关注底部 `TabBar` 和运动模块相关页面。~~

### ~~Step 10: 设计正式页面结构与组件边界~~

~~输出内容：~~

- ~~正式页面对应的 Flutter 页面结构~~
- ~~组件拆分方案~~
- ~~调试页与正式页的职责划分~~
- ~~底部 `TabBar` 导航职责定义~~

~~完成标准：~~

- ~~能明确哪些组件复用现有能力，哪些组件需要新增~~
- ~~能明确正式页不继续直接复用调试页布局~~
- ~~页面结构可支持后续逐步接入真实状态~~
- ~~底部导航层的交互职责与页面内容职责清晰分离~~

~~完成记录：~~

- ~~正式 `MotionPage` 改为 Figma 页面骨架入口，调试页职责后续已完成下线清理~~
- ~~底部 `TabBar` 继续由 `AppShellPage` 统一承接，页面内容区不再自己重复承担导航职责~~
- ~~正式页底部区块已分为开始前主操作区与运动中临时承接区，为后续状态稿接入保留边界~~

### ~~Step 11: 搭建正式 UI 骨架与样式基线~~

~~输出内容：~~

- ~~正式页面 Scaffold 与主要布局容器~~
- ~~颜色、字号、圆角、间距等视觉基线~~
- ~~主要区块的静态占位或初版布局~~

~~完成标准：~~

- ~~页面结构已接近设计稿层级~~
- ~~主要视觉风格已建立~~
- ~~地图区、信息区、操作区、底部浮层关系已稳定~~

### ~~Step 12: 接入正式 UI 的业务状态与地图区~~

~~输出内容：~~

- ~~正式页面接入现有 `motion` 状态~~
- ~~地图区与实时信息区联动~~
- ~~按钮区与当前状态联动~~

~~完成标准：~~

- ~~正式 UI 可以展示真实运动状态~~
- ~~地图和统计数据不再只停留在调试字段形式~~
- ~~不破坏现有运动控制链路~~

### ~~Step 13: 补齐状态页与异常态表现~~

~~输出内容：~~

- ~~准备中、运动中、暂停、结束、错误等状态表现~~
- ~~权限或定位异常时的提示表现~~
- ~~需要时的空态、加载态或结果态~~

~~完成标准：~~

- ~~主要状态切换在 UI 上可见且逻辑一致~~
- ~~异常态有明确提示，不退化成静默失败~~
- ~~结束态可承接本次运动结果展示~~

### ~~Step 14: 完成适配、验收与入口整理~~

~~输出内容：~~

- ~~常见 iPhone 尺寸适配~~
- ~~安全区与底部浮层适配~~
- ~~正式入口与调试入口整理方案~~
- ~~分析校验结果~~

~~完成标准：~~

- ~~页面在主要目标尺寸下无明显布局破损~~
- ~~正式 UI 与调试 UI 入口职责清晰~~
- ~~通过 `fvm flutter analyze`~~

## 6. 步骤配套细则

说明：

- 本章所有内容都服务于“5. 实施步骤”。
- 本章不是新的阶段，也不是额外任务列表。
- 如果实施步骤已经完成，对应细则只作为实现依据和回查依据保留。

### 6.1 Step 1 配套细则：数据模型定义

以下字段作为 Flutter 与 iOS 间的统一协议。

#### MotionStatus

表示运动状态。

| 字段值 | 含义 |
| --- | --- |
| `idle` | 未开始 |
| `preparing` | 准备中，通常是权限检查或启动定位 |
| `running` | 运动中 |
| `paused` | 已暂停 |
| `finished` | 已结束 |
| `error` | 发生错误 |

#### MotionPoint

单个轨迹点。

| 字段名 | 类型 | 必填 | 单位 | 说明 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `latitude` | `double` | 是 | 度 | 纬度 | iOS |
| `longitude` | `double` | 是 | 度 | 经度 | iOS |
| `timestamp` | `int` | 是 | ms | 定位时间戳 | iOS |
| `speedMps` | `double` | 否 | m/s | 当前速度 | iOS |
| `accuracyMeters` | `double` | 否 | m | 水平精度 | iOS |
| `altitudeMeters` | `double` | 否 | m | 海拔 | iOS |

#### MotionRealtime

运动中的实时统计。

| 字段名 | 类型 | 必填 | 单位 | 说明 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `status` | `String` | 是 | - | 当前运动状态 | iOS |
| `durationSeconds` | `int` | 是 | s | 已运动时长 | iOS |
| `distanceMeters` | `double` | 是 | m | 累计距离 | iOS |
| `currentSpeedMps` | `double` | 否 | m/s | 当前速度 | iOS |
| `averageSpeedMps` | `double` | 否 | m/s | 平均速度 | iOS |
| `pointCount` | `int` | 是 | - | 已采集轨迹点数 | iOS |
| `latestPoint` | `Map` | 否 | - | 最新轨迹点 | iOS |

#### MotionSession

一次完整运动记录。

| 字段名 | 类型 | 必填 | 单位 | 说明 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `sessionId` | `String` | 是 | - | 本次运动唯一标识 | Flutter |
| `startTime` | `int` | 是 | ms | 开始时间 | Flutter/iOS |
| `endTime` | `int` | 是 | ms | 结束时间 | Flutter/iOS |
| `durationSeconds` | `int` | 是 | s | 总时长 | Flutter |
| `totalDistanceMeters` | `double` | 是 | m | 总距离 | Flutter |
| `averageSpeedMps` | `double` | 否 | m/s | 平均速度 | Flutter |
| `points` | `List<Map>` | 是 | - | 轨迹点列表 | Flutter |

#### MotionError

错误事件模型。

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `code` | `String` | 是 | 错误码 |
| `message` | `String` | 是 | 错误说明 |
| `detail` | `String` | 否 | 扩展信息 |

建议错误码：

- `permission_denied`
- `permission_denied_forever`
- `location_service_disabled`
- `location_start_failed`
- `location_update_failed`
- `invalid_motion_state`
- `native_internal_error`

### 6.2 Step 2 配套细则：Channel 协议

#### Channel 名称

- `MethodChannel`: `walkworld/motion_method`
- `EventChannel`: `walkworld/motion_event`

#### MethodChannel 接口

##### `requestLocationPermission`

用途：
请求定位权限。

入参：
无

返回：

```json
{
  "granted": true,
  "status": "granted_when_in_use"
}
```

可能错误：

- `permission_denied`
- `native_internal_error`

##### `getLocationServiceStatus`

用途：
查询系统定位服务状态。

入参：
无

返回：

```json
{
  "enabled": true
}
```

##### `startWorkout`

用途：
开始运动。

入参：

```json
{
  "sessionId": "uuid-string"
}
```

返回：

```json
{
  "accepted": true,
  "status": "running",
  "startTime": 1770000000000
}
```

可能错误：

- `permission_denied`
- `location_service_disabled`
- `invalid_motion_state`
- `location_start_failed`

##### `pauseWorkout`

用途：
暂停运动。

入参：
无

返回：

```json
{
  "accepted": true,
  "status": "paused"
}
```

##### `resumeWorkout`

用途：
继续运动。

入参：
无

返回：

```json
{
  "accepted": true,
  "status": "running"
}
```

##### `stopWorkout`

用途：
结束运动并返回本次最终汇总。

入参：
无

返回：

```json
{
  "accepted": true,
  "status": "finished",
  "summary": {
    "startTime": 1770000000000,
    "endTime": 1770000300000,
    "durationSeconds": 300,
    "totalDistanceMeters": 523.4,
    "averageSpeedMps": 1.74,
    "points": []
  }
}
```

#### EventChannel 事件

事件统一结构：

```json
{
  "event": "motionUpdated",
  "payload": {}
}
```

##### `permissionChanged`

用途：
权限状态发生变化时推送。

`payload` 示例：

```json
{
  "status": "granted_when_in_use"
}
```

##### `statusChanged`

用途：
运动状态变化时推送。

`payload` 示例：

```json
{
  "status": "running"
}
```

##### `locationUpdated`

用途：
推送最新轨迹点。

`payload`：`MotionPoint`

##### `motionUpdated`

用途：
推送实时统计。

`payload`：`MotionRealtime`

##### `error`

用途：
推送原生运行时错误。

`payload`：`MotionError`

### 6.3 Step 3 配套细则：Flutter 状态设计

#### 状态枚举

Flutter 侧直接使用：

- `idle`
- `preparing`
- `running`
- `paused`
- `finished`
- `error`

#### Provider 建议

建议至少拆成以下 provider：

- `motionControllerProvider`
  - 负责开始、暂停、继续、结束
  - 负责监听 EventChannel
- `motionStatusProvider`
  - 当前状态
- `motionRealtimeProvider`
  - 当前实时数据
- `motionSessionDraftProvider`
  - 当前这次运动的记录草稿
- `motionErrorProvider`
  - 最近一次错误

#### 状态变更规则

- 页面初始进入：`idle`
- 点击开始：`preparing`
- 原生开始成功：`running`
- 点击暂停：`paused`
- 点击继续：`running`
- 点击结束：`finished`
- 任一步骤失败：`error`

#### UI 响应规则

- `idle`：显示开始按钮
- `preparing`：按钮禁用，显示准备中
- `running`：显示暂停和结束
- `paused`：显示继续和结束
- `finished`：展示本次汇总
- `error`：展示错误信息和重试入口

说明：

- 这里的 UI 响应规则用于约束状态与交互，不代表已经进入正式 UI 视觉开发。

### 6.4 已完成记录：iOS 原生基础实现拆解

说明：

- 本节用于记录前期 iOS 原生基础能力的拆解过程，主要对应上方已完成的 `Step 4`、`Step 5`、`Step 6`。
- 本节只保留为已完成记录，便于后续排查与回顾。

#### 子项 1

集成高德 iOS 地图 SDK。

验收：

- 原生地图 view 可正常初始化

#### 子项 2

集成高德 iOS 定位 SDK。

验收：

- 能触发定位权限申请

#### 子项 3

配置 `Info.plist` 权限项。

至少包含：

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`（如果后续需要后台能力，可预留）

验收：

- 真机首次启动能正确弹权限框

#### 子项 4

创建 Flutter Channel。

验收：

- Flutter 可调用原生方法
- 原生可向 Flutter 推送事件

#### 子项 5

实现地图容器视图和 Flutter 嵌入。

验收：

- Flutter 运动页可显示原生地图

#### 子项 6

实现定位 manager。

验收：

- 可持续接收定位点

#### 子项 7

实现轨迹点缓存和距离累计。

验收：

- 每次新点到达后，距离可正确累计

#### 子项 8

实现实时事件推送。

验收：

- Flutter 页面可实时刷新位置和统计数据

### 6.5 Step 7 配套细则：页面交互顺序

#### 进入页面

1. 初始化状态为 `idle`
2. 检查定位服务是否开启
3. 准备监听 EventChannel

#### 点击开始

1. 生成 `sessionId`
2. 调用 `startWorkout`
3. 原生开始定位和轨迹采集
4. 页面进入 `running`

#### 点击暂停

1. 调用 `pauseWorkout`
2. 停止有效运动累计
3. 页面进入 `paused`

#### 点击继续

1. 调用 `resumeWorkout`
2. 恢复定位采集和统计
3. 页面进入 `running`

#### 点击结束

1. 调用 `stopWorkout`
2. 接收最终汇总
3. 生成 `MotionSession`
4. 页面进入 `finished`

### 6.6 Step 9-14 配套细则：正式 UI 开发约束

#### 页面职责约束

- 当前 `MotionPage` 作为调试页保留，不默认直接演变成正式运动页面。
- 正式 UI 优先使用新的页面结构承接，必要时再决定是否切换主入口。
- 调试信息面板应与正式视觉展示解耦，避免调试字段直接进入正式页面主体。

#### 组件拆分建议

正式 UI 至少应从以下层面拆分：

- 页面级容器
- 地图区容器
- 顶部信息区
- 实时统计区
- 底部操作区
- 状态提示或结果区

说明：

- 是否最终完全按上述命名落地，可以根据代码结构调整。
- 但必须保证组件职责清晰，不把所有正式 UI 逻辑重新堆回单文件。

#### 状态接入原则

- 先复用现有 `Riverpod` 状态与控制器，不在正式 UI 开发第一轮重构底层服务协议。
- 展示层只做格式化与状态映射，不新增与底层状态相冲突的第二套状态源。
- 若发现现有状态字段不足以支撑设计稿，需要先补齐文档说明，再决定是否扩展状态。

#### Figma 对齐原则

- 优先对齐信息层级、布局结构、主要视觉样式和交互状态。
- 对于无法稳定从现有链接中提取的精确数值，可先按比例和视觉一致性实现，再记录待确认项。
- 若设计稿中包含多个状态页，需先明确哪些属于本轮范围，避免实现范围失控。

#### 当前已确认范围

- 忽略首页模块及其具体内容
- 保留并实现底部 `TabBar`
- 聚焦运动模块相关页面与状态

#### 当前已识别的运动模块状态页

基于 Figma Make 返回的页面结构，当前已识别出以下运动相关页面或状态：

- `ExerciseBefore`
- `ExerciseTypeSheet`
- `ExerciseInProgress`
- `ExercisePaused`
- `ExerciseResult`

说明：

- 上述命名来自设计稿导出的页面源码结构，用于指导 Flutter 页面拆分。
- 后续实现时可以根据代码命名规范调整 Flutter 侧文件名，但状态边界应保持一致。

#### Step 10 页面结构方案

正式 UI 采用“应用导航容器 + 运动模块容器 + 状态内容层”的三层结构。

第一层：应用导航容器

- 提供页面根 Scaffold
- 承载底部 `TabBar`
- 负责当前 tab 切换
- 行为上参考 iOS `UITabBar`，即：
  - `TabBar` 是稳定存在的系统级导航层
  - 每个 tab 对应一个主模块入口
  - 当前选中态清晰、非选中态弱化
  - 不把页面主操作按钮混入 `TabBar`

第二层：运动模块容器

- 作为运动 tab 的主内容区域
- 负责组织地图、顶部信息、统计信息、底部操作面板、弹层入口
- 负责根据运动状态切换对应内容层
- 负责与现有 `motionControllerProvider` 和地图能力对接

第三层：状态内容层

- `ExerciseBefore`
- `ExerciseTypeSheet`
- `ExerciseInProgress`
- `ExercisePaused`
- `ExerciseResult`

说明：

- `ExerciseTypeSheet` 属于模态层，不作为独立 tab。
- `ExerciseBefore`、`ExerciseInProgress`、`ExercisePaused`、`ExerciseResult` 属于运动模块内部状态页或状态视图。

#### Step 10 组件边界方案

建议按以下组件边界拆分 Flutter 页面：

- `AppTabScaffold`
  - 应用级页面框架
  - 负责底部 `TabBar`
  - 负责 tab 对应页面切换

- `AppBottomTabBar`
  - 独立底部导航组件
  - 视觉和行为参考 iOS `UITabBar`
  - 只处理导航，不处理运动业务状态

- `MotionHomePage`
  - 运动模块正式页面入口
  - 承接运动模块全部正式 UI

- `MotionMapSection`
  - 地图区
  - 复用现有原生地图容器能力

- `MotionTopSummarySection`
  - 顶部摘要信息区
  - 展示当前模式、状态、关键指标或标题

- `MotionStatsPanel`
  - 运动统计面板
  - 展示距离、时长、速度等核心数据

- `MotionActionPanel`
  - 主操作区
  - 承接开始、暂停、继续、结束等动作

- `MotionResultPanel`
  - 结束结果展示区
  - 承接本次运动汇总

- `MotionExerciseTypeSheet`
  - 运动类型选择弹层
  - 独立于主页面内容层

#### 调试页与正式页职责划分

- 现有 `MotionPage` 保留为调试页
- 正式 UI 不继续在 `MotionPage` 上叠加视觉实现
- 新的正式页面承接产品 UI
- 调试页只保留联调、日志观察、原生链路验证等用途

#### 复用与新增边界

优先复用：

- 现有 `motion` 状态管理
- 现有运动控制逻辑
- 现有原生地图容器
- 现有数据模型

建议新增：

- 正式页面容器
- 底部 `TabBar` 组件
- 正式 UI 的各区块组件
- 运动类型选择弹层组件

#### 待确认实现约束

- 当前仓库尚无完整多 tab 页面结构，后续实现时需要决定正式入口是否直接切到 `AppTabScaffold`
- 如果当前阶段只开发运动模块，可先以单页形式预埋 `TabBar` 框架，再逐步补齐其他 tab 占位

#### 应用级主题能力引用

- 主题 token 与明暗模式等应用级主题设计，统一维护在独立文档 [app-theme-foudation.md](/Users/dongliang/Desktop/DLLT.git/walkWord/docs/app-theme-foudation.md:1)
- 运动模块实施时只关注“如何引用这些主题能力”，不在本文件重复定义应用级主题设计

#### 运动模块在主题层的使用边界

- 运动模块可以定义自己的语义映射 token
- 运动模块不重复定义应用级基础色值
- 如果运动模块确实新增了专属业务色，应先判断是否需要回收到应用级基础文档统一维护

#### 验收关注点

- 地图、浮层、按钮和信息卡片的叠放关系是否稳定
- 页面在安全区、底部 Home Indicator 区域是否有遮挡
- 运动中的实时数据刷新是否影响布局稳定性
- 暂停、结束、错误等状态切换是否出现按钮错位或内容闪动
