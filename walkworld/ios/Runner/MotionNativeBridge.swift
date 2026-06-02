import AMapLocationKit
import CoreLocation
import Flutter
import Foundation
import UIKit

// MARK: - MotionNativeBridge（运动原生桥接）

/// 负责运动模块在 iOS 侧的 MethodChannel / EventChannel / 定位能力接入。
///
/// 整体架构概览：
/// ┌──────────────────────────────────────────────────┐
/// │  Flutter (Dart)                                   │
/// │   MethodChannel ← 调用原生能力（开始/暂停/恢复/结束）│
/// │   EventChannel  ← 接收实时事件流（状态/位置/统计）   │
/// └────────────┬─────────────────────┬────────────────┘
///              │                     │
///   ┌──────────▼─────────────────────▼──────────────┐
///   │  MotionNativeBridge (本文件)                    │
///   │  - 权限管理：申请 & 监听定位权限                  │
///   │  - 运动生命周期：idle → running ⇌ paused → finished │
///   │  - 轨迹采集与过滤：精度 / 跳点 / 距离 / 方向角   │
///   │  - 实时统计：时长 / 距离 / 速度（平滑 & 平均）     │
///   │  - 事件推送：统一收敛到 pushEvent 发给 Flutter    │
///   └────────────┬─────────────────────┬─────────────┘
///                │                     │
///     ┌──────────▼──────┐   ┌──────────▼──────────┐
///     │ CLLocationManager│   │ AMapLocationManager │
///     │ (权限管理专用)    │   │ (持续定位 & 轨迹采集) │
///     └─────────────────┘   └─────────────────────┘
///
/// 当前阶段主要承接 Step 8 的数据质量与异常处理：
/// 1. 定位权限申请与状态回传
/// 2. 系统定位服务开关检查
/// 3. 持续定位监听、轨迹过滤与实时事件推送
/// 4. 为 Flutter 侧提供可用的运动统计与基础错误处理
final class MotionNativeBridge: NSObject, FlutterStreamHandler {

  // MARK: - 轨迹过滤参数配置

  /// 按运动类型差异化的定位过滤参数包。
  ///
  /// 不同运动类型的速度、精度特性差异很大，需要不同的过滤策略：
  /// - 徒步（hiking）：速度最慢，对毛刺最敏感，精度要求最高
  /// - 跑步（running）：速度适中，放宽最小距离门限
  /// - 骑行（cycling）：速度最快，精度容忍最宽
  struct MotionFilterConfig {
    /// 水平精度容忍上限（米），超过则认为是飘移点直接丢弃。
    let maxAcceptedHorizontalAccuracy: CLLocationAccuracy
    /// 最小有效移动距离（米），低于此值视为原地抖动丢弃。
    let minMovementDistanceMeters: Double
    /// 跳点速度阈值（m/s），推算速度超过此值则判定为 GPS 跳点。
    let maxAcceptedDerivedSpeedMps: Double
    /// 跳点检测最小时间间隔（秒），间隔太短不做跳点判定。
    let minIntervalForJumpDetectionSeconds: TimeInterval
    /// 方向角检测时间窗口（秒）。
    let directionCheckWindowSeconds: TimeInterval
    /// 方向角突变阈值（度），超过此值且速度低于阈值时判定为漂移。
    let maxDirectionChangeForSlowMoveDegrees: Double
    /// "低速"判定阈值（m/s），低于此速度时方向角突变才触发漂移过滤。
    let slowMoveSpeedThresholdMps: Double

    /// 徒步参数组：精度要求最高，速度慢，对毛刺最敏感。
    static let hiking = MotionFilterConfig(
      maxAcceptedHorizontalAccuracy: 15,
      minMovementDistanceMeters: 1.2,
      maxAcceptedDerivedSpeedMps: 6,
      minIntervalForJumpDetectionSeconds: 0.5,
      directionCheckWindowSeconds: 3.0,
      maxDirectionChangeForSlowMoveDegrees: 150,
      slowMoveSpeedThresholdMps: 1.5
    )

    /// 跑步参数组：速度比徒步快，最小距离略放宽，跳点阈值稍提高。
    static let running = MotionFilterConfig(
      maxAcceptedHorizontalAccuracy: 17,
      minMovementDistanceMeters: 2.0,
      maxAcceptedDerivedSpeedMps: 8,
      minIntervalForJumpDetectionSeconds: 0.5,
      directionCheckWindowSeconds: 3.0,
      maxDirectionChangeForSlowMoveDegrees: 120,
      slowMoveSpeedThresholdMps: 2.0
    )

    /// 骑行参数组：速度最快，精度容忍最宽，跳点和方向角阈值均放大。
    static let cycling = MotionFilterConfig(
      maxAcceptedHorizontalAccuracy: 20,
      minMovementDistanceMeters: 3.0,
      maxAcceptedDerivedSpeedMps: 14,
      minIntervalForJumpDetectionSeconds: 0.5,
      directionCheckWindowSeconds: 2.0,
      maxDirectionChangeForSlowMoveDegrees: 150,
      slowMoveSpeedThresholdMps: 5.0
    )
  }

  // MARK: - 通道方法名 & 事件名 & 运动状态值（常量定义）

  /// Flutter MethodChannel 方法名枚举，用于匹配 `call.method`。
  private enum MotionMethod {
    static let requestLocationPermission = "requestLocationPermission"
    static let getLocationServiceStatus = "getLocationServiceStatus"
    static let startWorkout = "startWorkout"
    static let pauseWorkout = "pauseWorkout"
    static let resumeWorkout = "resumeWorkout"
    static let stopWorkout = "stopWorkout"
  }

  /// EventChannel 事件类型标识，通过 `pushEvent(name:)` 推送给 Flutter。
  private enum MotionEvent {
    static let permissionChanged = "permissionChanged"
    static let statusChanged = "statusChanged"
    static let motionUpdated = "motionUpdated"
    static let error = "error"
  }

  /// 运动状态值，对应 Flutter 侧 `MotionStatus` 枚举。
  /// 状态流转：idle → running ⇌ paused → finished / error
  private enum MotionStatusValue {
    static let idle = "idle"
    static let preparing = "preparing"
    static let running = "running"
    static let paused = "paused"
    static let finished = "finished"
    static let error = "error"
  }

  // MARK: - 通道 & 定位管理器

  /// MethodChannel：Flutter → 原生的方法调用通道。
  private let methodChannel: FlutterMethodChannel
  /// EventChannel：原生 → Flutter 的事件流通道。
  private let eventChannel: FlutterEventChannel
  /// 系统定位权限管理器（仅用于权限申请和状态查询，不做持续定位）。
  private let permissionManager = CLLocationManager()
  /// 高德定位管理器（负责持续定位和轨迹采集）。
  private let locationManager = AMapLocationManager()
  /// 关联的原生地图视图，用于实时画轨迹线和截图。
  weak var mapView: MotionMapPlatformView?

  // MARK: - Flutter EventChannel 相关状态

  /// EventChannel 的事件下沉器，为 nil 表示 Flutter 侧未监听。
  private var eventSink: FlutterEventSink?
  /// 权限请求的异步回调暂存，用户授权/拒绝后回填。
  private var pendingPermissionResult: FlutterResult?
  /// 上一次推送的权限状态值，去重用。
  private var lastPermissionStatusValue: String?

  // MARK: - 运动会话状态

  /// 当前运动状态（idle / running / paused / finished / error）。
  private var currentStatus = MotionStatusValue.idle
  /// 当前运动会话 ID，Flutter 端生成并在 startWorkout 时传入。
  private var currentSessionId: String?
  /// 运动开始时间（毫秒级时间戳），用于计算运动时长。
  private var sessionStartTimeMillis: Int64?
  /// 累计暂停时长（毫秒），用于在计算活跃运动时长时扣除。
  private var accumulatedPausedDurationMillis: Int64 = 0
  /// 最近一次暂停开始的时间戳（毫秒），恢复时累加到 accumulatedPausedDurationMillis。
  private var pauseStartedAtMillis: Int64?

  // MARK: - 轨迹与统计数据

  /// 累计运动距离（米）。
  private var totalDistanceMeters: Double = 0
  /// 已采纳的定位点序列（经过四关过滤后的有效轨迹）。
  private var recordedLocations: [CLLocation] = []
  /// 最近几个速度样本，用于做滑动窗口平均计算实时速度。
  private var recentSpeedSamples: [Double] = []
  /// 每秒一次的定时器，用于在无新定位点时仍然刷新时长和均速。
  private var realtimeTicker: Timer?
  /// 速度平滑窗口大小，保留最近 N 个速度样本做平均。
  private let smoothedSpeedSampleWindow = 5
  /// 当前运动类型对应的过滤参数包，开始运动时根据 motionType 写入。
  private var filterConfig: MotionFilterConfig = .hiking

  // MARK: - 方向角检测 & 前后台恢复

  /// 用于方向角突变检测的短时间窗口内的最近几个点（最多保留 3 个）。
  private var recentDirectionCheckPoints: [CLLocation] = []
  /// 后台期间若仍有新轨迹点入列，则在回前台时补一次全量恢复。
  private var needsTrackRestoreOnBecomeActive = false

  // MARK: - 地图视图绑定

  /// 绑定原生地图视图，运动中实时向地图画线和截图时需要。
  func attachMapView(_ mapView: MotionMapPlatformView) {
    self.mapView = mapView
  }

  /// 解绑原生地图视图，仅在传入的是当前绑定实例时才清空。
  func detachMapView(_ mapView: MotionMapPlatformView) {
    if self.mapView === mapView {
      self.mapView = nil
    }
  }

  // MARK: - 初始化 & 析构

  init(messenger: FlutterBinaryMessenger) {
    self.methodChannel = FlutterMethodChannel(
      name: "walkworld/motion_method",
      binaryMessenger: messenger
    )
    self.eventChannel = FlutterEventChannel(
      name: "walkworld/motion_event",
      binaryMessenger: messenger
    )
    super.init()

    setupPermissionManager()
    setupLocationManager()
    bindChannels()

    // 监听应用回到前台通知，用于补偿后台期间丢失的轨迹绘制。
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - 管理器初始化

  /// 配置系统权限管理器的代理（用于接收权限变更回调）。
  private func setupPermissionManager() {
    permissionManager.delegate = self
  }

  /// 配置高德定位管理器的参数和代理。
  private func setupLocationManager() {
    locationManager.delegate = self
    //小于5米的距离，不更新定位
    locationManager.distanceFilter = 5
    //允许app后台更新定位
    locationManager.allowsBackgroundLocationUpdates = true
  }

  // MARK: - 通道绑定

  /// 将 MethodChannel 和 EventChannel 绑定到当前实例。
  ///
  /// - MethodChannel：接收 Flutter 侧的方法调用（权限请求、运动控制等）
  /// - EventChannel：作为流式事件的 StreamHandler，Flutter 监听时触发 onListen
  private func bindChannels() {
    eventChannel.setStreamHandler(self)

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "native_internal_error",
            message: "运动原生桥接已经释放。",
            details: nil
          )
        )
        return
      }

      // 根据方法名分发到对应的处理函数。
      switch call.method {
      case MotionMethod.requestLocationPermission:
        self.handleRequestLocationPermission(result: result)
      case MotionMethod.getLocationServiceStatus:
        self.handleGetLocationServiceStatus(result: result)
      case MotionMethod.startWorkout:
        self.handleStartWorkout(call.arguments, result: result)
      case MotionMethod.pauseWorkout:
        self.handlePauseWorkout(result: result)
      case MotionMethod.resumeWorkout:
        self.handleResumeWorkout(result: result)
      case MotionMethod.stopWorkout:
        self.handleStopWorkout(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - MethodChannel 方法处理（权限 & 定位服务）

  /// 处理定位权限请求。
  ///
  /// 逻辑：
  /// 1. 如果权限状态为 notDetermined（首次请求），弹出系统授权弹窗，
  ///    暂存 result 等用户操作后通过代理回调回填。
  /// 2. 如果权限已有明确状态（granted/denied/restricted），直接返回当前状态。
  private func handleRequestLocationPermission(result: @escaping FlutterResult) {
    let status = currentAuthorizationStatus()
    if status == .notDetermined {
      pendingPermissionResult = result
      permissionManager.requestWhenInUseAuthorization()
      return
    }

    result(buildPermissionResultPayload(status: status))
  }

  /// 查询系统定位服务开关状态（全局开关，非本 App 的权限）。
  private func handleGetLocationServiceStatus(result: FlutterResult) {
    result([
      "enabled": CLLocationManager.locationServicesEnabled()
    ])
  }

  // MARK: - MethodChannel 方法处理（运动生命周期）

  /// 处理「开始运动」请求。
  ///
  /// 前置校验（按顺序）：
  /// 1. 当前状态必须是 idle 或 finished（防止重复开始）
  /// 2. 系统定位服务必须开启
  /// 3. 定位权限必须已授予
  /// 4. 必须传入有效的 sessionId
  ///
  /// 通过校验后：
  /// - 重置所有运动状态数据
  /// - 根据 motionType 加载对应的过滤参数包
  /// - 启动高德持续定位
  /// - 推送状态变更和首次统计事件
  /// - 启动每秒一次的实时刷新定时器
  private func handleStartWorkout(_ arguments: Any?, result: FlutterResult) {
    // 校验 1：只有 idle 或 finished 状态才能开始新的运动会话。
    guard currentStatus == MotionStatusValue.idle ||
            currentStatus == MotionStatusValue.finished else {
      result(
        FlutterError(
          code: "invalid_motion_state",
          message: "当前状态不允许开始运动。",
          details: currentStatus
        )
      )
      return
    }

    // 校验 2：系统定位服务（全局开关）必须开启。
    guard CLLocationManager.locationServicesEnabled() else {
      result(
        FlutterError(
          code: "location_service_disabled",
          message: "系统定位服务未开启。",
          details: nil
        )
      )
      return
    }

    // 校验 3：应用的定位权限必须已授予（whenInUse 或 always）。
    let authorizationStatus = currentAuthorizationStatus()
    guard isPermissionGranted(authorizationStatus) else {
      result(
        FlutterError(
          code: "permission_denied",
          message: "当前未获得可用的定位权限。",
          details: permissionStatusValue(for: authorizationStatus)
        )
      )
      return
    }

    // 校验 4：Flutter 传入的参数中必须包含非空的 sessionId。
    guard let payload = arguments as? [String: Any],
          let sessionId = payload["sessionId"] as? String,
          !sessionId.isEmpty else {
      result(
        FlutterError(
          code: "invalid_motion_state",
          message: "开始运动缺少有效的 sessionId。",
          details: arguments
        )
      )
      return
    }

    // 根据运动类型加载对应的过滤参数包，未传或未识别时默认徒步。
    let motionTypeValue = payload["motionType"] as? String ?? "hiking"
    filterConfig = resolveFilterConfig(motionTypeValue)

    // 重置上一次运动的所有残余数据，初始化新会话。
    resetWorkoutState()
    currentSessionId = sessionId
    sessionStartTimeMillis = currentTimestampMillis()
    currentStatus = MotionStatusValue.running

    // 启动持续定位，推送状态和初始统计，开启定时器。
    locationManager.startUpdatingLocation()
    pushStatusChangedEvent()
    pushMotionUpdatedEvent()
    startRealtimeTickerIfNeeded()

    result([
      "accepted": true,
      "status": currentStatus,
      "startTime": sessionStartTimeMillis ?? currentTimestampMillis()
    ])
  }

  /// 处理「暂停运动」请求。
  ///
  /// - 记录暂停开始时间（用于后续计算暂停时长）
  /// - 停止持续定位和定时刷新
  /// - 推送状态变更事件
  private func handlePauseWorkout(result: FlutterResult) {
    guard currentStatus == MotionStatusValue.running else {
      result(
        FlutterError(
          code: "invalid_motion_state",
          message: "当前状态不允许暂停运动。",
          details: currentStatus
        )
      )
      return
    }

    currentStatus = MotionStatusValue.paused
    pauseStartedAtMillis = currentTimestampMillis()
    locationManager.stopUpdatingLocation()
    stopRealtimeTicker()
    pushStatusChangedEvent()
    pushMotionUpdatedEvent()

    result([
      "accepted": true,
      "status": currentStatus
    ])
  }

  /// 处理「恢复运动」请求。
  ///
  /// - 将暂停期间的时长累加到 accumulatedPausedDurationMillis
  /// - 重新启动持续定位和定时刷新
  /// - 推送状态变更事件
  private func handleResumeWorkout(result: FlutterResult) {
    guard currentStatus == MotionStatusValue.paused else {
      result(
        FlutterError(
          code: "invalid_motion_state",
          message: "当前状态不允许继续运动。",
          details: currentStatus
        )
      )
      return
    }

    // 累加本次暂停的持续时长。
    if let pauseStartedAtMillis {
      accumulatedPausedDurationMillis += max(0, currentTimestampMillis() - pauseStartedAtMillis)
    }
    pauseStartedAtMillis = nil
    currentStatus = MotionStatusValue.running

    locationManager.startUpdatingLocation()
    pushStatusChangedEvent()
    pushMotionUpdatedEvent()
    startRealtimeTickerIfNeeded()

    result([
      "accepted": true,
      "status": currentStatus
    ])
  }

  /// 处理「结束运动」请求。
  ///
  /// 流程：
  /// 1. 如果当前是暂停状态，先把暂停时长累加
  /// 2. 停止定位和定时器
  /// 3. 计算最终统计数据（总距离、持续时长、平均速度）
  /// 4. 如果关联了地图视图，异步截取路线快照（base64 图片）
  /// 5. 组装最终的 summary 字典，通过 result 返回给 Flutter
  //运动结束
  private func handleStopWorkout(result: @escaping FlutterResult) {
    guard currentStatus == MotionStatusValue.running ||
            currentStatus == MotionStatusValue.paused else {
      result(
        FlutterError(
          code: "invalid_motion_state",
          message: "当前状态不允许结束运动。",
          details: currentStatus
        )
      )
      return
    }

    // 如果是从暂停状态结束，需要累加最后一段暂停的时长。
    if currentStatus == MotionStatusValue.paused,
       let pauseStartedAtMillis {
      accumulatedPausedDurationMillis += max(0, currentTimestampMillis() - pauseStartedAtMillis)
      self.pauseStartedAtMillis = nil
    }

    locationManager.stopUpdatingLocation()
    stopRealtimeTicker()
    currentStatus = MotionStatusValue.finished

    // 计算最终统计数据。
    let endTimeMillis = currentTimestampMillis()
    let durationSeconds = currentDurationSeconds(referenceTimeMillis: endTimeMillis)
    let averageSpeedMps = durationSeconds > 0
      ? totalDistanceMeters / Double(durationSeconds)
      : nil

    // 组装并返回运动总结的闭包（地图截图完成后或无地图时直接调用）。
    let finishStopResult: (String?) -> Void = { [weak self] routeSnapshotBase64 in
      guard let self else {
        return
      }

      let summary: [String: Any?] = [
        "sessionId": self.currentSessionId ?? "",
        "startTime": self.sessionStartTimeMillis ?? endTimeMillis,
        "endTime": endTimeMillis,
        "durationSeconds": durationSeconds,
        "totalDistanceMeters": self.totalDistanceMeters,
        "averageSpeedMps": averageSpeedMps,
        "points": self.recordedLocations.map(self.buildLocationPayload),
        "routeSnapshotBase64": routeSnapshotBase64
      ]

      self.pushStatusChangedEvent()
      self.pushMotionUpdatedEvent(referenceTimeMillis: endTimeMillis)

      result([
        "accepted": true,
        "status": self.currentStatus,
        "summary": self.compactDictionary(summary)
      ])
    }

    // 如果有关联的地图视图，先异步截取路线快照再回调；否则直接完成。
    if let mapView {
      mapView.captureFinishedRouteSnapshot(completion: finishStopResult)
      return
    }

    finishStopResult(nil)
  }

  // MARK: - 权限变更处理

  /// 统一处理定位权限状态变更（来自 CLLocationManagerDelegate 或 AMapLocationManagerDelegate）。
  ///
  /// 职责：
  /// 1. 推送权限变更事件给 Flutter
  /// 2. 如果运动中权限被收回，转入 error 状态
  /// 3. 如果有待回填的权限请求 result，回填并清空
  private func handleAuthorizationChanged(_ status: CLAuthorizationStatus) {
    // 推送权限变更事件（内部会去重，相同状态不重复推送）。
    pushPermissionChangedEvent(status: status)

    // 运动进行中权限被收回 → 转入 error 状态，通知 Flutter 处理。
    if !isPermissionGranted(status),
       currentStatus == MotionStatusValue.running || currentStatus == MotionStatusValue.paused {
      transitionToError(
        code: status == .denied ? "permission_denied" : "permission_denied_forever",
        message: "运动过程中定位权限已不可用。",
        detail: permissionStatusValue(for: status)
      )
    }

    // 回填挂起的权限请求结果（notDetermined 时不回填，等用户操作完）。
    guard let pendingPermissionResult, status != .notDetermined else {
      return
    }

    self.pendingPermissionResult = nil
    pendingPermissionResult(buildPermissionResultPayload(status: status))
  }

  // MARK: - 定位数据处理（四关过滤）

  /// 核心定位点处理入口：对每一个新定位点依次执行四关过滤。
  ///
  /// 过滤流水线：
  /// ```
  /// 原始定位点
  ///   → 第一关：水平精度过滤（精度太差直接丢弃）
  ///   → 第二关：大跳点过滤（推算速度超阈值，GPS 跳点）
  ///   → 第三关：最小移动距离门限（原地抖动产生的毛刺）
  ///   → 第四关：方向角一致性检测（低速时方向突变的漂移点）
  ///   → ✅ 通过所有过滤 → 采纳并更新统计
  /// ```
  private func handleLocationUpdate(_ location: CLLocation) {
    guard currentStatus == MotionStatusValue.running else {
      return
    }

    // 第一关：水平精度过滤，精度太差的点直接丢弃。
    guard isLocationAccuracyAcceptable(location) else {
      return
    }

    // 第二关：大跳点过滤，推算速度超过阈值则认为是 GPS 跳点。
    guard !isJumpLocation(location) else {
      return
    }

    // 第三关：最小移动距离门限，过滤原地抖动产生的毛刺。
    if let lastLocation = recordedLocations.last {
      let distance = location.distance(from: lastLocation)
      guard distance >= filterConfig.minMovementDistanceMeters else {
        return
      }
    }

    // 第四关：方向角一致性检测，过滤短时间内方向突变的连续飘移点。
    guard !isDirectionAnomalyLocation(location) else {
      return
    }

    // ✅ 所有过滤通过 → 累加距离、记录轨迹点、更新速度样本。
    if let lastLocation = recordedLocations.last {
      totalDistanceMeters += max(0, location.distance(from: lastLocation))
    }

    recordedLocations.append(location)
    // 同步更新方向角检测窗口。
    updateDirectionCheckWindow(location)
    appendSpeedSampleIfNeeded(from: location)
    // 实时画线直接交给原生地图，避免 Flutter 在后台冻结时丢失中间轨迹。
    mapView?.appendTrackPoint(location)

    // 后台运行时标记需要回前台后做全量轨迹恢复。
    if UIApplication.shared.applicationState != .active {
      needsTrackRestoreOnBecomeActive = true
    }

    pushMotionUpdatedEvent(latestLocation: location)
  }

  // MARK: - 前后台切换处理

  /// App 从后台回到前台时触发。
  ///
  /// 职责：
  /// 1. 如果后台期间有新轨迹点，用完整轨迹重绘地图线段（补偿后台渲染丢失）
  /// 2. 如果运动中，确保定时器在运行
  @objc private func handleAppDidBecomeActive() {
    guard currentStatus == MotionStatusValue.running ||
            currentStatus == MotionStatusValue.paused else {
      return
    }

    guard needsTrackRestoreOnBecomeActive else {
      // 没有需要恢复的轨迹，仅确保定时器在运行。
      if currentStatus == MotionStatusValue.running {
        startRealtimeTickerIfNeeded()
      }
      return
    }

    needsTrackRestoreOnBecomeActive = false

    // 回到前台后，用原生完整轨迹重绘地图，补齐后台期间丢失的线段。
    mapView?.restoreTrack(recordedLocations)

    if currentStatus == MotionStatusValue.running {
      startRealtimeTickerIfNeeded()
    }
  }

  // MARK: - 定位错误处理

  /// 高德定位失败回调的统一处理入口。
  private func handleLocationError(_ error: NSError) {
    transitionToError(
      code: errorCode(for: error),
      message: "原生定位更新失败。",
      detail: error.localizedDescription
    )
  }

  // MARK: - 事件推送（统一出口）

  /// 推送运动实时统计事件（motionUpdated），包含当前时长、距离、实时速度、平均速度。
  ///
  /// 调用场景：
  /// - 新定位点被采纳时
  /// - 运动状态切换时（开始/暂停/恢复/结束）
  /// - 每秒定时器触发时（确保时长持续刷新）
  private func pushMotionUpdatedEvent(
    latestLocation: CLLocation? = nil,
    referenceTimeMillis: Int64? = nil
  ) {
    let resolvedTimeMillis = referenceTimeMillis ?? currentTimestampMillis()

    pushEvent(
      name: MotionEvent.motionUpdated,
      payload: compactDictionary([
        "status": currentStatus,
        "durationSeconds": currentDurationSeconds(referenceTimeMillis: resolvedTimeMillis),
        "distanceMeters": totalDistanceMeters,
        "currentSpeedMps": buildSmoothedCurrentSpeed(
          fallbackLocation: latestLocation ?? recordedLocations.last
        ),
        "averageSpeedMps": buildAverageSpeed(referenceTimeMillis: resolvedTimeMillis)
      ])
    )
  }

  /// 推送权限变更事件（permissionChanged），内部去重：相同状态不重复推送。
  private func pushPermissionChangedEvent(status: CLAuthorizationStatus) {
    let statusValue = permissionStatusValue(for: status)

    // 去重：和上次推送的权限状态一致则跳过。
    if lastPermissionStatusValue == statusValue {
      return
    }

    lastPermissionStatusValue = statusValue
    pushEvent(
      name: MotionEvent.permissionChanged,
      payload: [
        "status": statusValue
      ]
    )
  }

  /// 推送运动状态变更事件（statusChanged）。
  private func pushStatusChangedEvent() {
    pushEvent(
      name: MotionEvent.statusChanged,
      payload: [
        "status": currentStatus
      ]
    )
  }

  /// 事件推送的统一出口，将事件名 + 负载字典发送到 Flutter EventChannel。
  private func pushEvent(name: String, payload: [String: Any?]) {
    guard let eventSink else {
      return
    }

    eventSink([
      "event": name,
      "payload": compactDictionary(payload)
    ])
  }

  // MARK: - 数据构建辅助

  /// 构建定位权限查询结果，返回 `{ granted: Bool, status: String }`。
  private func buildPermissionResultPayload(status: CLAuthorizationStatus) -> [String: Any] {
    [
      "granted": isPermissionGranted(status),
      "status": permissionStatusValue(for: status)
    ]
  }

  /// 将单个 CLLocation 转换为 Flutter 可用的字典格式。
  private func buildLocationPayload(_ location: CLLocation) -> [String: Any?] {
    [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "timestamp": Int64(location.timestamp.timeIntervalSince1970 * 1000),
      "speedMps": normalizedSpeed(from: location),
      "accuracyMeters": location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil,
      "altitudeMeters": location.altitude
    ]
  }

  /// 计算平均速度（m/s） = 总距离 / 活跃运动秒数。
  private func buildAverageSpeed(referenceTimeMillis: Int64? = nil) -> Double? {
    let resolvedTimeMillis = referenceTimeMillis ?? currentTimestampMillis()
    let durationSeconds = currentDurationSeconds(referenceTimeMillis: resolvedTimeMillis)
    guard durationSeconds > 0 else {
      return nil
    }

    return totalDistanceMeters / Double(durationSeconds)
  }

  /// 计算平滑后的实时速度：优先取最近 N 个样本的滑动平均，回退到最后定位点速度。
  private func buildSmoothedCurrentSpeed(fallbackLocation: CLLocation?) -> Double? {
    if !recentSpeedSamples.isEmpty {
      let total = recentSpeedSamples.reduce(0, +)
      return total / Double(recentSpeedSamples.count)
    }

    return normalizedSpeed(from: fallbackLocation)
  }

  // MARK: - 时长 & 速度计算

  /// 计算活跃运动时长（秒） = (当前时间 - 开始时间 - 累计暂停时长) / 1000。
  ///
  /// 参数 referenceTimeMillis 用于统一基准时间，
  /// 确保同一次事件中时长和均速用相同时间点计算。
  private func currentDurationSeconds(referenceTimeMillis: Int64) -> Int {
    guard let sessionStartTimeMillis else {
      return 0
    }

    // 计算到参考时间点为止的总暂停毫秒数。
    let pausedDurationMillis: Int64
    if currentStatus == MotionStatusValue.paused, let pauseStartedAtMillis {
      // 暂停中：已累积暂停 + 当前暂停段时长。
      pausedDurationMillis = accumulatedPausedDurationMillis +
        max(0, referenceTimeMillis - pauseStartedAtMillis)
    } else {
      pausedDurationMillis = accumulatedPausedDurationMillis
    }

    let activeDurationMillis = max(0, referenceTimeMillis - sessionStartTimeMillis - pausedDurationMillis)
    return Int(activeDurationMillis / 1000)
  }

  /// 从 CLLocation 提取有效速度值（m/s），负值视为无效返回 nil。
  private func normalizedSpeed(from location: CLLocation) -> Double? {
    guard location.speed >= 0 else {
      return nil
    }

    return location.speed
  }

  /// normalizedSpeed 的 Optional 重载，location 为 nil 时直接返回 nil。
  private func normalizedSpeed(from location: CLLocation?) -> Double? {
    guard let location else {
      return nil
    }

    return normalizedSpeed(from: location)
  }

  // MARK: - 轨迹过滤规则实现

  /// 第一关：水平精度过滤。
  ///
  /// horizontalAccuracy < 0 表示定位无效，直接拒绝。
  /// 大于阈值（如 hiking = 15m）表示精度太差，视为飘移点丢弃。
  private func isLocationAccuracyAcceptable(_ location: CLLocation) -> Bool {
    let horizontalAccuracy = location.horizontalAccuracy
    guard horizontalAccuracy >= 0 else {
      return false
    }

    return horizontalAccuracy <= filterConfig.maxAcceptedHorizontalAccuracy
  }

  /// 第二关：大跳点过滤。
  ///
  /// 根据相邻两点的距离和时间间隔推算速度，如果超过阈值（如 hiking = 6 m/s），
  /// 则判定为 GPS 跳点。时间间隔过短时不做判定，直接放行让后续过滤处理。
  private func isJumpLocation(_ location: CLLocation) -> Bool {
    guard let lastLocation = recordedLocations.last else {
      return false
    }

    let intervalSeconds = location.timestamp.timeIntervalSince(lastLocation.timestamp)
    guard intervalSeconds >= filterConfig.minIntervalForJumpDetectionSeconds else {
      // 时间间隔过短，不做跳点判定，直接放行让后续过滤处理。
      return false
    }

    let distanceMeters = location.distance(from: lastLocation)
    let derivedSpeedMps = distanceMeters / intervalSeconds
    return derivedSpeedMps > filterConfig.maxAcceptedDerivedSpeedMps
  }

  /// 第四关：方向角一致性检测 — 过滤短时间内方向突变的低速漂移点。
  ///
  /// GPS 漂移的典型表现是：在很短时间内，连续几个点的方向从 A 方向跳到 B 方向，
  /// 再跳回 A 方向（或其他方向），形成"Z"字或"锯齿"轨迹。
  /// 真实转弯通常速度较高且方向变化持续，不会在 2-3 秒内突变再突变。
  ///
  /// 判定条件（必须同时满足）：
  /// 1. 窗口内至少有 2 个历史点
  /// 2. 当前点速度低于低速阈值
  /// 3. 窗口时间范围在有效区间内
  /// 4. 窗口内基线方向与候选方向的偏转超过阈值
  private func isDirectionAnomalyLocation(_ location: CLLocation) -> Bool {
    // 至少需要 2 个已记录点才能做方向角判定。
    guard recentDirectionCheckPoints.count >= 2 else {
      return false
    }

    // 只在低速移动时才做方向角过滤（高速转弯是正常行为）。
    let currentSpeed = location.speed >= 0 ? location.speed : 0
    guard currentSpeed < filterConfig.slowMoveSpeedThresholdMps else {
      return false
    }

    // 取窗口内最早的点和最近的点，计算从「最近已采纳点 → 窗口首点」的方向角，
    // 再计算「最近已采纳点 → 当前候选点」的方向角，判断偏转是否过大。
    let windowStart = recentDirectionCheckPoints.first!
    let windowEnd = recentDirectionCheckPoints.last!

    // 确保窗口时间范围在配置范围内。
    let windowInterval = windowEnd.timestamp.timeIntervalSince(windowStart.timestamp)
    guard windowInterval > 0, windowInterval <= filterConfig.directionCheckWindowSeconds else {
      return false
    }

    // 计算窗口内已有轨迹的整体方向角。
    let baselineBearing = bearing(from: windowStart.coordinate, to: windowEnd.coordinate)
    // 计算从窗口末点到当前候选点的方向角。
    let candidateBearing = bearing(from: windowEnd.coordinate, to: location.coordinate)

    let angleDiff = abs(angleDifference(from: baselineBearing, to: candidateBearing))
    return angleDiff > filterConfig.maxDirectionChangeForSlowMoveDegrees
  }

  /// 维护方向角检测用的短时窗口（最多保留最近 3 个点）。
  ///
  /// 操作：
  /// 1. 将新点追加到窗口
  /// 2. 清理超出时间窗口的旧点
  /// 3. 限制窗口最大长度为 3，防止无限增长
  private func updateDirectionCheckWindow(_ location: CLLocation) {
    recentDirectionCheckPoints.append(location)

    // 清理时间窗口外的旧点。
    let cutoff = location.timestamp.addingTimeInterval(-filterConfig.directionCheckWindowSeconds)
    recentDirectionCheckPoints.removeAll { $0.timestamp < cutoff }

    // 最多保留 3 个点，避免窗口无限增长。
    if recentDirectionCheckPoints.count > 3 {
      recentDirectionCheckPoints.removeFirst(recentDirectionCheckPoints.count - 3)
    }
  }

  // MARK: - 地理计算辅助

  /// 计算从坐标 A 到坐标 B 的方位角（度，0-360，正北为 0）。
  ///
  /// 采用球面三角学公式（Haversine 方位角公式）。
  private func bearing(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D
  ) -> Double {
    let startLat = start.latitude * .pi / 180
    let startLon = start.longitude * .pi / 180
    let endLat = end.latitude * .pi / 180
    let endLon = end.longitude * .pi / 180
    let dLon = endLon - startLon
    let x = sin(dLon) * cos(endLat)
    let y = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLon)
    let bearing = atan2(x, y) * 180 / .pi
    return (bearing + 360).truncatingRemainder(dividingBy: 360)
  }

  /// 计算两个方位角之间的最短差值（返回 -180 到 180 之间）。
  private func angleDifference(from angle1: Double, to angle2: Double) -> Double {
    var diff = angle2 - angle1
    while diff > 180 { diff -= 360 }
    while diff < -180 { diff += 360 }
    return diff
  }

  // MARK: - 运动类型映射

  /// 将 Flutter 侧传来的运动类型字符串映射为对应的过滤参数包。
  private func resolveFilterConfig(_ motionType: String) -> MotionFilterConfig {
    switch motionType {
    case "running": return .running
    case "cycling": return .cycling
    default: return .hiking
    }
  }

  // MARK: - 速度样本管理

  /// 采集速度样本并维护滑动窗口（固定大小，超出时移除最早的样本）。
  private func appendSpeedSampleIfNeeded(from location: CLLocation) {
    guard let speedMps = normalizedSpeed(from: location) else {
      return
    }

    recentSpeedSamples.append(speedMps)
    if recentSpeedSamples.count > smoothedSpeedSampleWindow {
      recentSpeedSamples.removeFirst(recentSpeedSamples.count - smoothedSpeedSampleWindow)
    }
  }

  // MARK: - 异常状态转换

  /// 将运动状态转入 error，停止所有定位和定时器，推送错误事件。
  ///
  /// 触发场景：
  /// - 运动中定位权限被收回
  /// - 高德定位回调报错
  private func transitionToError(code: String, message: String, detail: String?) {
    locationManager.stopUpdatingLocation()
    stopRealtimeTicker()
    currentStatus = MotionStatusValue.error

    pushStatusChangedEvent()
    pushMotionUpdatedEvent()
    pushEvent(
      name: MotionEvent.error,
      payload: [
        "code": code,
        "message": message,
        "detail": detail
      ]
    )
  }

  // MARK: - 权限状态辅助

  /// 判断给定权限状态是否为已授权（authorizedAlways 或 authorizedWhenInUse）。
  private func isPermissionGranted(_ status: CLAuthorizationStatus) -> Bool {
    status == .authorizedAlways || status == .authorizedWhenInUse
  }

  /// 将 CLAuthorizationStatus 转换为 Flutter 侧约定的字符串值。
  private func permissionStatusValue(for status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "not_determined"
    case .restricted:
      return "denied_forever"
    case .denied:
      return "denied"
    case .authorizedAlways:
      return "granted_always"
    case .authorizedWhenInUse:
      return "granted_when_in_use"
    @unknown default:
      return "not_determined"
    }
  }

  /// 获取当前定位权限状态（兼容 iOS 14 以下版本）。
  private func currentAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return permissionManager.authorizationStatus
    }

    return CLLocationManager.authorizationStatus()
  }

  // MARK: - 错误码映射

  /// 将原生定位错误（高德 / 系统 CLError）映射为 Flutter 侧约定的错误码字符串。
  private func errorCode(for error: NSError) -> String {
    // 高德定位 SDK 的错误域。
    if error.domain == AMapLocationErrorDomain {
      switch error.code {
      case 2:
        return "location_update_failed"
      case 12:
        return "permission_denied"
      default:
        return "native_internal_error"
      }
    }

    // 系统 Core Location 的错误域。
    if error.domain == kCLErrorDomain {
      switch CLError.Code(rawValue: error.code) {
      case .denied:
        return "permission_denied"
      case .locationUnknown:
        return "location_update_failed"
      default:
        return "native_internal_error"
      }
    }

    return "native_internal_error"
  }

  // MARK: - 运动状态重置

  /// 重置所有运动会话相关的状态数据，为新一轮运动做准备。
  private func resetWorkoutState() {
    stopRealtimeTicker()
    currentSessionId = nil
    sessionStartTimeMillis = nil
    accumulatedPausedDurationMillis = 0
    pauseStartedAtMillis = nil
    needsTrackRestoreOnBecomeActive = false
    totalDistanceMeters = 0
    recentSpeedSamples.removeAll()
    recordedLocations.removeAll()
    recentDirectionCheckPoints.removeAll()
  }

  // MARK: - 定时刷新器

  /// 启动每秒一次的定时器，用于在无新定位点时仍然刷新时长和均速。
  ///
  /// 运行中每秒补发一次统计，让 Flutter 的时长与均速不依赖新定位点才能刷新。
  /// 如果定时器已存在则不重复创建。
  private func startRealtimeTickerIfNeeded() {
    guard realtimeTicker == nil else {
      return
    }

    realtimeTicker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      guard let self else {
        return
      }

      // 非 running 状态时自动停止定时器。
      guard self.currentStatus == MotionStatusValue.running else {
        self.stopRealtimeTicker()
        return
      }

      self.pushMotionUpdatedEvent()
    }
  }

  /// 停止并销毁定时器。
  private func stopRealtimeTicker() {
    realtimeTicker?.invalidate()
    realtimeTicker = nil
  }

  // MARK: - 工具方法

  /// 获取当前毫秒级时间戳。
  private func currentTimestampMillis() -> Int64 {
    Int64(Date().timeIntervalSince1970 * 1000)
  }

  /// 将可能含 nil 值的字典压缩为纯 [String: Any]，移除所有值为 nil 的键。
  ///
  /// 用于向 Flutter 侧传递数据时避免 NSNull 导致的解析问题。
  private func compactDictionary(_ dictionary: [String: Any?]) -> [String: Any] {
    dictionary.reduce(into: [String: Any]()) { partialResult, element in
      if let value = element.value {
        partialResult[element.key] = value
      }
    }
  }

  // MARK: - FlutterStreamHandler 协议实现

  /// Flutter 侧开始监听 EventChannel 时触发。
  ///
  /// 职责：
  /// 1. 保存 eventSink 引用
  /// 2. 立即推送当前权限状态和运动状态（确保 Flutter 重建时能恢复）
  /// 3. 如果有正在进行的运动，推送最新统计数据并确保定时器运行
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    pushPermissionChangedEvent(status: currentAuthorizationStatus())
    pushStatusChangedEvent()

    // 如果运动不在 idle 状态，补发一次当前统计快照。
    if currentStatus != MotionStatusValue.idle {
      pushMotionUpdatedEvent()
    }

    // 如果运动正在进行，确保定时器在跑。
    if currentStatus == MotionStatusValue.running {
      startRealtimeTickerIfNeeded()
    }

    return nil
  }

  /// Flutter 侧取消监听 EventChannel 时触发。
  ///
  /// 清空 eventSink 并停止定时器（无监听者时无需继续推送）。
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    stopRealtimeTicker()
    return nil
  }
}

// MARK: - CLLocationManagerDelegate（系统定位权限代理）

extension MotionNativeBridge: CLLocationManagerDelegate {
  /// iOS 14+ 权限变更回调。
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleAuthorizationChanged(currentAuthorizationStatus())
  }

  /// iOS 14 以下权限变更回调。
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    handleAuthorizationChanged(status)
  }
}

// MARK: - AMapLocationManagerDelegate（高德定位代理）

extension MotionNativeBridge: AMapLocationManagerDelegate {
  /// 连续定位关闭逆地理编码时，AMap 会优先走这个纯定位回调。
  ///
  /// 如果只实现带 `reGeocode` 的重载，正式运动链路会表现成：
  /// - 状态能进入 running
  /// - 但持续收不到轨迹点
  /// - 距离、配速、轨迹线都不更新
  func amapLocationManager(
    _ manager: AMapLocationManager!,
    didUpdate location: CLLocation!
  ) {
    guard let location else {
      return
    }

    handleLocationUpdate(location)
  }

  /// 带逆地理编码的定位回调（部分场景高德会走这里而非纯定位回调）。
  func amapLocationManager(
    _ manager: AMapLocationManager!,
    didUpdate location: CLLocation!,
    reGeocode: AMapLocationReGeocode!
  ) {
    guard let location else {
      return
    }

    handleLocationUpdate(location)
  }

  /// 高德定位失败回调。
  func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
    guard let error else {
      return
    }

    handleLocationError(error as NSError)
  }

  /// 高德 SDK 层面的权限变更回调。
  func amapLocationManager(
    _ manager: AMapLocationManager!,
    didChange status: CLAuthorizationStatus
  ) {
    handleAuthorizationChanged(status)
  }

  /// 高德 SDK 层面的权限变更回调（iOS 14+ 新接口）。
  func amapLocationManager(
    _ manager: AMapLocationManager!,
    locationManagerDidChangeAuthorization locationManager: CLLocationManager!
  ) {
    handleAuthorizationChanged(currentAuthorizationStatus())
  }
}
