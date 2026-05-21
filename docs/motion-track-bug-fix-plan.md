# 运动轨迹 Bug 修复 & 画线原生化方案

### 问题 2：骑行进后台后轨迹断，回前台只剩直线

**根因：`trackRestored` 机制依赖 `onListen`，但进后台时 EventChannel 不会取消，导致回前台后 `onListen` 不再触发。**

#### 链路分析

```
骑行中（前台）：
  iOS 原生                            Flutter Dart
  AMapLocationManager                 MotionController
  locationUpdated → eventSink() →→→  _handleNativeEvent()
                                           ↓
                                      recordedPoints.add(point)
                                           ↓
                                      updateTrack() → 地图画线 ✓

进后台后：
  iOS 原生                            Flutter Dart ❄️（Dart VM 已冻结）
  eventSink() 被调用 →→→  [事件静默丢失，无人接收] ✗
  recordedLocations 继续记录 ✓

回前台：
  Dart VM 解冻 ✓
  EventChannel 从未断开 → onCancel 未触发 → onListen 不再调用
  trackRestored 永远不发 ✗
  新 locationUpdated 开始发 → Flutter 只收到新点 → 直线 ✗
```

**关键**：EventChannel 的连接本身没断，但 Dart 运行时被冻结，所有发过来的事件静默丢失。回前台后由于连接未断，`onListen` 也不会重新触发，`trackRestored` 的补丁机制完全失效。

---

## 二、修复方案：画线全面迁移原生

### 核心思路

将实时画线的职责**完全从 Flutter 侧移除**，交给 iOS 原生直接处理。
定位点过滤通过后，直接在原生地图上追加，完全绕过 Dart 层。

### 架构变化

**现在：**
```
AMapLocationManager
    ↓ handleLocationUpdate（过滤通过）
    ├─ recordedLocations.append()
    ├─ eventSink → locationUpdated → Flutter recordedPoints
    │                                       ↓
    │                               MethodChannel updateTrack
    │                                       ↓
    └─────────────────────────────────► MAMapView 画线
                                        ↑ Dart 冻结就断
```

**改后：**
```
AMapLocationManager
    ↓ handleLocationUpdate（过滤通过）
    ├─ 直接调用 → MotionMapPlatformView.appendTrackPoint()  ← 画线（纯原生）
    ├─ recordedLocations.append()                            ← 统计（不动）
    └─ eventSink → locationUpdated → Flutter recordedPoints  ← 结束页兜底（保留）

App 回前台：
    UIApplication.didBecomeActiveNotification
    → mapView?.restoreTrack(recordedLocations)               ← 全量重绘
    → pushEvent(trackRestored)                               ← 同步 Flutter 侧
```

---

## 三、逐文件改动说明

---

### iOS 原生侧

---

#### [MODIFY] `AppDelegate.swift`（+2 行）

先创建 Bridge，再把它传给 Factory：

```swift
// 改前
let factory = MotionMapViewFactory(messenger: registrar.messenger())
registrar.register(factory, withId: "walkworld/motion_map_view")
motionNativeBridge = MotionNativeBridge(messenger: registrar.messenger())

// 改后
motionNativeBridge = MotionNativeBridge(messenger: registrar.messenger())
let factory = MotionMapViewFactory(
    messenger: registrar.messenger(),
    bridge: motionNativeBridge!        // ← 新增
)
registrar.register(factory, withId: "walkworld/motion_map_view")
```

---

#### [MODIFY] `MotionMapViewFactory.swift`（+5 行）

持有 Bridge 引用，创建 PlatformView 后注册回 Bridge：

```swift
final class MotionMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let bridge: MotionNativeBridge        // ← 新增

    init(messenger: FlutterBinaryMessenger, bridge: MotionNativeBridge) {
        self.messenger = messenger
        self.bridge = bridge
        super.init()
    }

    func create(...) -> FlutterPlatformView {
        let view = MotionMapPlatformView(
            frame: frame, viewIdentifier: viewId,
            arguments: args, messenger: messenger
        )
        bridge.mapView = view     // ← 新增：把地图视图注册给 Bridge
        return view
    }
}
```

---

#### [MODIFY] `MotionNativeBridge.swift`（+27 行）

**① 新增 mapView 弱引用属性**

```swift
weak var mapView: MotionMapPlatformView?
```

**② `handleLocationUpdate` 过滤通过后直接驱动原生画线**

```swift
recordedLocations.append(location)
updateDirectionCheckWindow(location)
appendSpeedSampleIfNeeded(from: location)

mapView?.appendTrackPoint(location)   // ← 新增：直接调原生地图，不走 Flutter
```

**③ 新增 App 生命周期监听（在 `init` 中注册）**

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleAppDidBecomeActive),
    name: UIApplication.didBecomeActiveNotification,
    object: nil
)
```

**④ 新增回前台回调方法**

```swift
@objc private func handleAppDidBecomeActive() {
    guard currentStatus == MotionStatusValue.running ||
          currentStatus == MotionStatusValue.paused else { return }

    // 原生地图：全量重绘（覆盖后台丢失的段）
    mapView?.restoreTrack(recordedLocations)

    // Flutter 侧：补发 trackRestored，保持 recordedPoints 完整（结束页用）
    if !recordedLocations.isEmpty, eventSink != nil {
        let allPoints = recordedLocations.map(buildLocationPayload)
        pushEvent(name: MotionEvent.trackRestored, payload: ["points": allPoints])
    }

    if currentStatus == MotionStatusValue.running {
        startRealtimeTickerIfNeeded()
    }
}
```

**⑤ 调整 `hiking` 过滤参数（修复问题 1）**

```swift
static let hiking = MotionFilterConfig(
    maxAcceptedHorizontalAccuracy: 12,
    minMovementDistanceMeters: 1.5,
    maxAcceptedDerivedSpeedMps: 6,
    minIntervalForJumpDetectionSeconds: 0.5,
    directionCheckWindowSeconds: 3.0,
    maxDirectionChangeForSlowMoveDegrees: 145,  // ← 由 120 放宽到 145
    slowMoveSpeedThresholdMps: 0.8              // ← 由 1.5 降低到 0.8
)
```

---

#### [MODIFY] `MotionMapPlatformView.swift`（+45 行）

**① 新增存储属性**

```swift
private var nativeTrackCoordinates: [CLLocationCoordinate2D] = []
```

**② 新增 `appendTrackPoint`（逐点追加）**

```swift
/// 原生定位采到新点时，直接追加，无需 Flutter 中转。
func appendTrackPoint(_ location: CLLocation) {
    nativeTrackCoordinates.append(location.coordinate)
    guard nativeTrackCoordinates.count >= 2 else { return }
    rebuildTrackPolyline()
}
```

**③ 新增 `restoreTrack`（回前台全量恢复）**

```swift
/// App 回前台时，用原生完整历史点重绘整条轨迹。
func restoreTrack(_ locations: [CLLocation]) {
    nativeTrackCoordinates = locations.map { $0.coordinate }
    rebuildTrackPolyline()
}
```

**④ 抽取 `rebuildTrackPolyline`（两处共用）**

```swift
private func rebuildTrackPolyline() {
    if let old = trackPolyline {
        mapView.remove(old)
        trackPolyline = nil
    }
    guard nativeTrackCoordinates.count >= 2 else { return }
    var coords = nativeTrackCoordinates
    let polyline = MAPolyline(coordinates: &coords, count: UInt(coords.count))
    trackPolyline = polyline
    mapView.add(polyline)
}
```

**⑤ `clearTrack` 中同步清空坐标数组（在现有清空逻辑前加一行）**

```swift
nativeTrackCoordinates.removeAll()   // ← 新增
```

**⑥ `handleUpdateTrack`（旧入口）保留不删**

作为结束页展示历史轨迹的调用路径，原有逻辑不动。

---

### Flutter 侧

---

#### [MODIFY] `motion_map_view.dart`（-15 行）

删除 `didUpdateWidget` 中向原生推送 `updateTrack` / `updateUserLocation` 的逻辑：

```dart
// 删除以下代码块：
if (pointChanged && widget.currentPoint != null) {
    _nativeController!.updateUserLocation(widget.currentPoint!);
}
if (trackChanged) {
    if (widget.trackPoints.isEmpty) {
        _nativeController!.clearTrack(focusPoint: widget.currentPoint);
    } else {
        _nativeController!.updateTrack(widget.trackPoints);
    }
}
```

**保留：**
- `workoutStartResetChanged` → `resetCameraForWorkoutStart`（新运动开始相机归位）
- `_handlePlatformViewCreated` 中的初始化逻辑（PlatformView 极少数重建时用）

---

#### [MODIFY] `motion_page.dart`（-1 行）

删除 `MotionMapView` 的 `trackPoints` 参数：

```dart
MotionMapView(
    creationParams: { ... },
    workoutStartResetToken: motionState.currentSessionId,
    currentPoint: latestPoint,
)
```

---

#### `motion_controller.dart` — 不改

`recordedPoints` 维护逻辑全部保留，用于：
1. 结束页展示历史轨迹
2. `_normalizeFinishedSession` 兜底

`trackRestored` 处理逻辑同样保留（双保险：原生修复地图，Flutter 同步保留数据）。

---

## 四、统计数据影响评估

| 字段 | 数据来源 | 受影响？ |
|------|---------|---------|
| 实时距离 | 原生 `totalDistanceMeters` | ✅ 不受影响 |
| 实时时长 | 原生 `currentDurationSeconds` | ✅ 不受影响 |
| 实时速度 | 原生 `recentSpeedSamples` | ✅ 不受影响 |
| 最终距离/时长 | `stopWorkout` 返回原生值 | ✅ 不受影响 |
| 最终轨迹点 | `stopWorkout` 返回 `recordedLocations` | ✅ **反而更完整**（含后台段） |
| 结束页地图 | `session.points` → `handleUpdateTrack` | ✅ 不受影响，路径不变 |

---

## 五、改动量汇总

| 文件 | 改动 | 行数 |
|------|------|------|
| `AppDelegate.swift` | +传 bridge 给 factory | +2 |
| `MotionMapViewFactory.swift` | +持有 bridge，注册 mapView | +5 |
| `MotionNativeBridge.swift` | +mapView 属性 + 画线调用 + 回前台监听 + hiking 参数调整 | +27 |
| `MotionMapPlatformView.swift` | +追加/恢复/重建画线方法 + 坐标存储 | +45 |
| `motion_map_view.dart` | -删除 updateTrack/updateUserLocation 推送 | -15 |
| `motion_page.dart` | -删除 trackPoints 参数 | -1 |
| `motion_controller.dart` | 不改 | 0 |

**净变化：iOS +80 行，Flutter -16 行**

---

## 六、验证计划

1. **前台骑行**：持续前台骑行 2 分钟，轨迹连续，无断点
2. **后台恢复**：骑行中按 Home 进后台，等 30 秒回前台，轨迹完整，不出现直线
3. **徒步弯道**：沿弯曲路线徒步，放大地图，轨迹应贴合道路，不出现切角
4. **统计数据**：结束运动，结束页距离/时长/均速与实际感受匹配
5. **结束页轨迹**：结束弹窗地图展示完整历史轨迹（含后台段）
6. **多次运动**：第二次运动开始时，旧轨迹清空，相机归位

---

## 七、注意事项

> **MAPolyline 性能提示**：MAPolyline 不可变，每次 `appendTrackPoint` 都需要移除旧线、重建整条折线。骑行距离较长后（数千个点），可能有轻微性能压力。
> 动手前确认 `Podfile.lock` 中 AMap iOS SDK 版本——若支持 `MAMutablePolyline` 可增量追加，无需每次重建，性能更好。

> **蓝色位置标记（currentPoint）** 目前仍通过 Flutter → MethodChannel 更新，本次方案不动，可后续单独优化。
