import AMapLocationKit
import CoreLocation
import Flutter
import Foundation
import UIKit

/// 负责运动模块在 iOS 侧的 MethodChannel / EventChannel / 定位能力接入。
///
/// 当前阶段主要承接 Step 8 的数据质量与异常处理：
/// 1. 定位权限申请与状态回传
/// 2. 系统定位服务开关检查
/// 3. 持续定位监听、轨迹过滤与实时事件推送
/// 4. 为 Flutter 侧提供可用的运动统计与基础错误处理
final class MotionNativeBridge: NSObject, FlutterStreamHandler {
  /// 按运动类型差异化的定位过滤参数包。
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


  private enum MotionMethod {
    static let requestLocationPermission = "requestLocationPermission"
    static let getLocationServiceStatus = "getLocationServiceStatus"
    static let startWorkout = "startWorkout"
    static let pauseWorkout = "pauseWorkout"
    static let resumeWorkout = "resumeWorkout"
    static let stopWorkout = "stopWorkout"
  }

  private enum MotionEvent {
    static let permissionChanged = "permissionChanged"
    static let statusChanged = "statusChanged"
    static let motionUpdated = "motionUpdated"
    static let error = "error"
  }

  private enum MotionStatusValue {
    static let idle = "idle"
    static let preparing = "preparing"
    static let running = "running"
    static let paused = "paused"
    static let finished = "finished"
    static let error = "error"
  }

  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let permissionManager = CLLocationManager()
  private let locationManager = AMapLocationManager()
  weak var mapView: MotionMapPlatformView?

  private var eventSink: FlutterEventSink?
  private var pendingPermissionResult: FlutterResult?
  private var lastPermissionStatusValue: String?

  private var currentStatus = MotionStatusValue.idle
  private var currentSessionId: String?
  private var sessionStartTimeMillis: Int64?
  private var accumulatedPausedDurationMillis: Int64 = 0
  private var pauseStartedAtMillis: Int64?
  private var totalDistanceMeters: Double = 0
  private var recordedLocations: [CLLocation] = []
  private var recentSpeedSamples: [Double] = []
  private var realtimeTicker: Timer?
  /// 速度平滑窗口大小，保留最近 N 个速度样本做平均。
  private let smoothedSpeedSampleWindow = 5
  /// 当前运动类型对应的过滤参数包，开始运动时根据 motionType 写入。
  private var filterConfig: MotionFilterConfig = .hiking
  /// 用于方向角突变检测的短时间窗口内的最近几个点（最多保留 3 个）。
  private var recentDirectionCheckPoints: [CLLocation] = []
  /// 后台期间若仍有新轨迹点入列，则在回前台时补一次全量恢复。
  private var needsTrackRestoreOnBecomeActive = false

  func attachMapView(_ mapView: MotionMapPlatformView) {
    self.mapView = mapView
  }

  func detachMapView(_ mapView: MotionMapPlatformView) {
    if self.mapView === mapView {
      self.mapView = nil
    }
  }

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

  private func setupPermissionManager() {
    permissionManager.delegate = self
  }

  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 5
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.locatingWithReGeocode = false
  }

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

  private func handleRequestLocationPermission(result: @escaping FlutterResult) {
    let status = currentAuthorizationStatus()
    if status == .notDetermined {
      pendingPermissionResult = result
      permissionManager.requestWhenInUseAuthorization()
      return
    }

    result(buildPermissionResultPayload(status: status))
  }

  private func handleGetLocationServiceStatus(result: FlutterResult) {
    result([
      "enabled": CLLocationManager.locationServicesEnabled()
    ])
  }

  private func handleStartWorkout(_ arguments: Any?, result: FlutterResult) {
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

    resetWorkoutState()
    currentSessionId = sessionId
    sessionStartTimeMillis = currentTimestampMillis()
    currentStatus = MotionStatusValue.running

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

  private func handleStopWorkout(result: FlutterResult) {
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

    if currentStatus == MotionStatusValue.paused,
       let pauseStartedAtMillis {
      accumulatedPausedDurationMillis += max(0, currentTimestampMillis() - pauseStartedAtMillis)
      self.pauseStartedAtMillis = nil
    }

    locationManager.stopUpdatingLocation()
    stopRealtimeTicker()
    currentStatus = MotionStatusValue.finished
    let endTimeMillis = currentTimestampMillis()
    let durationSeconds = currentDurationSeconds(referenceTimeMillis: endTimeMillis)
    let averageSpeedMps = durationSeconds > 0
      ? totalDistanceMeters / Double(durationSeconds)
      : nil

    let summary: [String: Any?] = [
      "sessionId": currentSessionId ?? "",
      "startTime": sessionStartTimeMillis ?? endTimeMillis,
      "endTime": endTimeMillis,
      "durationSeconds": durationSeconds,
      "totalDistanceMeters": totalDistanceMeters,
      "averageSpeedMps": averageSpeedMps,
      "points": recordedLocations.map(buildLocationPayload)
    ]

    pushStatusChangedEvent()
    pushMotionUpdatedEvent(referenceTimeMillis: endTimeMillis)

    result([
      "accepted": true,
      "status": currentStatus,
      "summary": compactDictionary(summary)
    ])
  }

  private func handleAuthorizationChanged(_ status: CLAuthorizationStatus) {
    pushPermissionChangedEvent(status: status)

    if !isPermissionGranted(status),
       currentStatus == MotionStatusValue.running || currentStatus == MotionStatusValue.paused {
      transitionToError(
        code: status == .denied ? "permission_denied" : "permission_denied_forever",
        message: "运动过程中定位权限已不可用。",
        detail: permissionStatusValue(for: status)
      )
    }

    guard let pendingPermissionResult, status != .notDetermined else {
      return
    }

    self.pendingPermissionResult = nil
    pendingPermissionResult(buildPermissionResultPayload(status: status))
  }

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

    if let lastLocation = recordedLocations.last {
      totalDistanceMeters += max(0, location.distance(from: lastLocation))
    }

    recordedLocations.append(location)
    // 同步更新方向角检测窗口。
    updateDirectionCheckWindow(location)
    appendSpeedSampleIfNeeded(from: location)
    // 实时画线直接交给原生地图，避免 Flutter 在后台冻结时丢失中间轨迹。
    mapView?.appendTrackPoint(location)
    if UIApplication.shared.applicationState != .active {
      needsTrackRestoreOnBecomeActive = true
    }

    pushMotionUpdatedEvent(latestLocation: location)
  }

  @objc private func handleAppDidBecomeActive() {
    guard currentStatus == MotionStatusValue.running ||
            currentStatus == MotionStatusValue.paused else {
      return
    }

    guard needsTrackRestoreOnBecomeActive else {
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

  private func handleLocationError(_ error: NSError) {
    transitionToError(
      code: errorCode(for: error),
      message: "原生定位更新失败。",
      detail: error.localizedDescription
    )
  }

  /// 将实时统计的组装逻辑收敛到一处，避免定位回调、状态切换、定时刷新各写一份。
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

  private func pushPermissionChangedEvent(status: CLAuthorizationStatus) {
    let statusValue = permissionStatusValue(for: status)

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

  private func pushStatusChangedEvent() {
    pushEvent(
      name: MotionEvent.statusChanged,
      payload: [
        "status": currentStatus
      ]
    )
  }

  private func pushEvent(name: String, payload: [String: Any?]) {
    guard let eventSink else {
      return
    }

    eventSink([
      "event": name,
      "payload": compactDictionary(payload)
    ])
  }

  private func buildPermissionResultPayload(status: CLAuthorizationStatus) -> [String: Any] {
    [
      "granted": isPermissionGranted(status),
      "status": permissionStatusValue(for: status)
    ]
  }

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

  private func buildAverageSpeed(referenceTimeMillis: Int64? = nil) -> Double? {
    let resolvedTimeMillis = referenceTimeMillis ?? currentTimestampMillis()
    let durationSeconds = currentDurationSeconds(referenceTimeMillis: resolvedTimeMillis)
    guard durationSeconds > 0 else {
      return nil
    }

    return totalDistanceMeters / Double(durationSeconds)
  }

  private func buildSmoothedCurrentSpeed(fallbackLocation: CLLocation?) -> Double? {
    if !recentSpeedSamples.isEmpty {
      let total = recentSpeedSamples.reduce(0, +)
      return total / Double(recentSpeedSamples.count)
    }

    return normalizedSpeed(from: fallbackLocation)
  }

  private func currentDurationSeconds(referenceTimeMillis: Int64) -> Int {
    guard let sessionStartTimeMillis else {
      return 0
    }

    let pausedDurationMillis: Int64
    if currentStatus == MotionStatusValue.paused, let pauseStartedAtMillis {
      pausedDurationMillis = accumulatedPausedDurationMillis +
        max(0, referenceTimeMillis - pauseStartedAtMillis)
    } else {
      pausedDurationMillis = accumulatedPausedDurationMillis
    }

    let activeDurationMillis = max(0, referenceTimeMillis - sessionStartTimeMillis - pausedDurationMillis)
    return Int(activeDurationMillis / 1000)
  }

  private func normalizedSpeed(from location: CLLocation) -> Double? {
    guard location.speed >= 0 else {
      return nil
    }

    return location.speed
  }

  private func normalizedSpeed(from location: CLLocation?) -> Double? {
    guard let location else {
      return nil
    }

    return normalizedSpeed(from: location)
  }

  private func isLocationAccuracyAcceptable(_ location: CLLocation) -> Bool {
    let horizontalAccuracy = location.horizontalAccuracy
    guard horizontalAccuracy >= 0 else {
      return false
    }

    return horizontalAccuracy <= filterConfig.maxAcceptedHorizontalAccuracy
  }

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

  /// 方向角一致性检测：在短时间窗口内若方向角变化过大且速度偏低，判定为漂移点。
  ///
  /// GPS 漂移的典型表现是：在很短时间内，连续几个点的方向从 A 方向跳到 B 方向，
  /// 再跳回 A 方向（或其他方向），形成"Z"字或"锯齿"轨迹。
  /// 真实转弯通常速度较高且方向变化持续，不会在 2-3 秒内突变再突变。
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

  /// 计算从坐标 A 到坐标 B 的方位角（度，0-360，正北为 0）。
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

  /// 将 Flutter 侧传来的运动类型字符串映射为对应的过滤参数包。
  private func resolveFilterConfig(_ motionType: String) -> MotionFilterConfig {
    switch motionType {
    case "running": return .running
    case "cycling": return .cycling
    default: return .hiking
    }
  }

  private func appendSpeedSampleIfNeeded(from location: CLLocation) {
    guard let speedMps = normalizedSpeed(from: location) else {
      return
    }

    recentSpeedSamples.append(speedMps)
    if recentSpeedSamples.count > smoothedSpeedSampleWindow {
      recentSpeedSamples.removeFirst(recentSpeedSamples.count - smoothedSpeedSampleWindow)
    }
  }

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

  private func isPermissionGranted(_ status: CLAuthorizationStatus) -> Bool {
    status == .authorizedAlways || status == .authorizedWhenInUse
  }

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

  private func currentAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return permissionManager.authorizationStatus
    }

    return CLLocationManager.authorizationStatus()
  }

  private func errorCode(for error: NSError) -> String {
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

  /// 运行中每秒补发一次统计，让 Flutter 的时长与均速不依赖新定位点才能刷新。
  private func startRealtimeTickerIfNeeded() {
    guard realtimeTicker == nil else {
      return
    }

    realtimeTicker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      guard let self else {
        return
      }

      guard self.currentStatus == MotionStatusValue.running else {
        self.stopRealtimeTicker()
        return
      }

      self.pushMotionUpdatedEvent()
    }
  }

  private func stopRealtimeTicker() {
    realtimeTicker?.invalidate()
    realtimeTicker = nil
  }

  private func currentTimestampMillis() -> Int64 {
    Int64(Date().timeIntervalSince1970 * 1000)
  }

  private func compactDictionary(_ dictionary: [String: Any?]) -> [String: Any] {
    dictionary.reduce(into: [String: Any]()) { partialResult, element in
      if let value = element.value {
        partialResult[element.key] = value
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    pushPermissionChangedEvent(status: currentAuthorizationStatus())
    pushStatusChangedEvent()

    if currentStatus != MotionStatusValue.idle {
      pushMotionUpdatedEvent()
    }

    if currentStatus == MotionStatusValue.running {
      startRealtimeTickerIfNeeded()
    }

    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    stopRealtimeTicker()
    return nil
  }
}

extension MotionNativeBridge: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleAuthorizationChanged(currentAuthorizationStatus())
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    handleAuthorizationChanged(status)
  }
}

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

  func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
    guard let error else {
      return
    }

    handleLocationError(error as NSError)
  }

  func amapLocationManager(
    _ manager: AMapLocationManager!,
    didChange status: CLAuthorizationStatus
  ) {
    handleAuthorizationChanged(status)
  }

  func amapLocationManager(
    _ manager: AMapLocationManager!,
    locationManagerDidChangeAuthorization locationManager: CLLocationManager!
  ) {
    handleAuthorizationChanged(currentAuthorizationStatus())
  }
}
