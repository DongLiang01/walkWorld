# 运动模块实施规格

## 1. 目标与范围

本阶段只交付运动模块最小可用版本，目标是完成一次完整运动记录闭环。

### 本阶段包含

- 运动页基础 UI
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

## 2. 架构拆分

### Flutter 负责

- 运动页 UI
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

## 3. 实施步骤

按下面顺序推进，前一步验收通过后再进入下一步。

### ~~Step 1: 定义数据模型~~

~~输出内容：~~

- ~~Flutter 侧运动实体~~
- ~~Channel 传输字段~~
- ~~原生侧对应模型映射~~

~~完成标准：~~

- ~~Flutter 和 iOS 端使用同一套字段定义~~
- ~~单位和空值约定明确~~

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

### ~~Step 3: 搭建 Flutter 运动状态机~~

~~输出内容：~~

- ~~`MotionStatus` 状态枚举~~
- ~~`Riverpod` provider 设计~~
- ~~状态变更规则~~

~~完成标准：~~

- ~~页面按钮行为由状态驱动~~
- ~~页面展示不直接依赖零散布尔变量~~

### ~~Step 4: 接入 iOS 原生地图容器~~

~~输出内容：~~

- ~~原生高德地图显示在 Flutter 页面内~~
- ~~地图支持定位点和轨迹线更新~~

~~完成标准：~~

- ~~运动页能正常展示地图~~
- ~~原生层可控制地图刷新当前位置和折线~~

### Step 5: 接入 iOS 原生定位与权限

输出内容：

- 定位权限申请
- 定位服务状态检查
- 连续定位监听

完成标准：

- 真机可获取持续定位
- 权限状态可回传 Flutter

### Step 6: 打通实时事件流

输出内容：

- 位置点事件
- 实时统计事件
- 状态变更事件
- 错误事件

完成标准：

- Flutter 可持续接收原生事件
- 页面数据可以实时刷新

### Step 7: 完成运动页核心交互

输出内容：

- 开始运动
- 暂停运动
- 继续运动
- 结束运动

完成标准：

- 整个运动流程可以走通
- 状态切换正确

### Step 8: 补统计逻辑与异常处理

输出内容：

- 跳点过滤
- 精度过滤
- 速度平滑
- 结束后生成完整记录
- 基础错误处理

完成标准：

- 结果数据可用
- 明显漂移和异常点不会直接污染结果

## 4. 数据模型定义

以下字段作为 Flutter 与 iOS 间的统一协议。

### 4.1 MotionStatus

表示运动状态。

| 字段值 | 含义 |
| --- | --- |
| `idle` | 未开始 |
| `preparing` | 准备中，通常是权限检查或启动定位 |
| `running` | 运动中 |
| `paused` | 已暂停 |
| `finished` | 已结束 |
| `error` | 发生错误 |

### 4.2 MotionPoint

单个轨迹点。

| 字段名 | 类型 | 必填 | 单位 | 说明 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `latitude` | `double` | 是 | 度 | 纬度 | iOS |
| `longitude` | `double` | 是 | 度 | 经度 | iOS |
| `timestamp` | `int` | 是 | ms | 定位时间戳 | iOS |
| `speedMps` | `double` | 否 | m/s | 当前速度 | iOS |
| `accuracyMeters` | `double` | 否 | m | 水平精度 | iOS |
| `altitudeMeters` | `double` | 否 | m | 海拔 | iOS |

### 4.3 MotionRealtime

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

### 4.4 MotionSession

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

### 4.5 MotionError

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

## 5. Channel 协议

### 5.1 Channel 名称

- `MethodChannel`: `walkworld/motion_method`
- `EventChannel`: `walkworld/motion_event`

### 5.2 MethodChannel 接口

#### `requestLocationPermission`

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

#### `getLocationServiceStatus`

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

#### `startWorkout`

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

#### `pauseWorkout`

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

#### `resumeWorkout`

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

#### `stopWorkout`

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

### 5.3 EventChannel 事件

事件统一结构：

```json
{
  "event": "motionUpdated",
  "payload": {}
}
```

#### `permissionChanged`

用途：
权限状态发生变化时推送。

`payload` 示例：

```json
{
  "status": "granted_when_in_use"
}
```

#### `statusChanged`

用途：
运动状态变化时推送。

`payload` 示例：

```json
{
  "status": "running"
}
```

#### `locationUpdated`

用途：
推送最新轨迹点。

`payload`：`MotionPoint`

#### `motionUpdated`

用途：
推送实时统计。

`payload`：`MotionRealtime`

#### `error`

用途：
推送原生运行时错误。

`payload`：`MotionError`

## 6. Flutter 状态设计

### 6.1 状态枚举

Flutter 侧直接使用：

- `idle`
- `preparing`
- `running`
- `paused`
- `finished`
- `error`

### 6.2 Provider 建议

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

### 6.3 状态变更规则

- 页面初始进入：`idle`
- 点击开始：`preparing`
- 原生开始成功：`running`
- 点击暂停：`paused`
- 点击继续：`running`
- 点击结束：`finished`
- 任一步骤失败：`error`

### 6.4 UI 响应规则

- `idle`：显示开始按钮
- `preparing`：按钮禁用，显示准备中
- `running`：显示暂停和结束
- `paused`：显示继续和结束
- `finished`：展示本次汇总
- `error`：展示错误信息和重试入口

## 7. iOS 原生实现顺序

### Step 1

集成高德 iOS 地图 SDK。

验收：

- 原生地图 view 可正常初始化

### Step 2

集成高德 iOS 定位 SDK。

验收：

- 能触发定位权限申请

### Step 3

配置 `Info.plist` 权限项。

至少包含：

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`（如果后续需要后台能力，可预留）

验收：

- 真机首次启动能正确弹权限框

### Step 4

创建 Flutter Channel。

验收：

- Flutter 可调用原生方法
- 原生可向 Flutter 推送事件

### Step 5

实现地图容器视图和 Flutter 嵌入。

验收：

- Flutter 运动页可显示原生地图

### Step 6

实现定位 manager。

验收：

- 可持续接收定位点

### Step 7

实现轨迹点缓存和距离累计。

验收：

- 每次新点到达后，距离可正确累计

### Step 8

实现实时事件推送。

验收：

- Flutter 页面可实时刷新位置和统计数据

## 8. 页面交互顺序

### 进入页面

1. 初始化状态为 `idle`
2. 检查定位服务是否开启
3. 准备监听 EventChannel

### 点击开始

1. 生成 `sessionId`
2. 调用 `startWorkout`
3. 原生开始定位和轨迹采集
4. 页面进入 `running`

### 点击暂停

1. 调用 `pauseWorkout`
2. 停止有效运动累计
3. 页面进入 `paused`

### 点击继续

1. 调用 `resumeWorkout`
2. 恢复定位采集和统计
3. 页面进入 `running`

### 点击结束

1. 调用 `stopWorkout`
2. 接收最终汇总
3. 生成 `MotionSession`
4. 页面进入 `finished`

## 9. 数据处理规则

### 轨迹点过滤

至少加三条规则：

1. 精度过差的点直接丢弃
2. 明显跳点直接丢弃
3. 时间间隔异常的点不直接参与累计

建议初始阈值：

- `accuracyMeters > 50`：丢弃
- 短时间内速度异常偏高：丢弃

具体阈值后续根据真机效果调整。

### 距离累计

规则：

- 只在 `running` 状态下累计
- 由有效轨迹点之间的距离累加得出
- 暂停期间不累计

### 当前速度

规则：

- 可直接使用定位返回速度
- 若抖动明显，增加简单平滑处理

### 平均速度

公式：

- `averageSpeedMps = totalDistanceMeters / durationSeconds`

前提：

- `durationSeconds > 0`

## 10. 验收标准

### 功能验收

- 进入运动页可正常显示地图
- 点击开始后 3 秒内收到首个定位事件
- 运动中可持续接收位置点
- 地图轨迹线持续更新
- 距离和时长持续增长
- 暂停后距离和时长停止累计
- 继续后恢复累计
- 结束后生成完整 session 汇总

### 数据验收

- 总距离大于 0
- 总时长大于 0
- 平均速度计算正确
- 轨迹点数与实际运动过程基本一致

### 异常验收

- 拒绝权限时页面能提示
- 定位服务关闭时页面能提示
- 原生异常时 Flutter 能收到错误事件

## 11. 当前执行建议

正式开发时按这个顺序：

1. 先实现 Channel 协议和模型
2. 再接 iOS 原生地图与定位
3. 然后搭 Flutter 状态机和运动页
4. 最后补轨迹过滤、统计和异常处理

当前最适合直接开始的工作：

1. 在 Flutter 侧定义运动模型和状态枚举
2. 在 iOS 侧建立 Channel 骨架
3. 把原生地图容器嵌入运动页
