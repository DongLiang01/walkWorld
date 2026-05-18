import AMapLocationKit
import CoreLocation
import Flutter
import Foundation

/// 负责运动模块在 iOS 侧的 MethodChannel / EventChannel / 定位能力接入。
///
/// 当前阶段主要承接 Step 8 的数据质量与异常处理：
/// 1. 定位权限申请与状态回传
/// 2. 系统定位服务开关检查
/// 3. 持续定位监听、轨迹过滤与实时事件推送
/// 4. 为 Flutter 侧提供可用的运动统计与基础错误处理
final class MotionNativeBridge: NSObject, FlutterStreamHandler {
  private enum MotionRuntimeConfig {
    /// 超过这个水平精度的定位点直接丢弃，避免明显漂移污染轨迹。
    static let maxAcceptedHorizontalAccuracy: CLLocationAccuracy = 65

    /// 有效速度样本保留最近 5 个，用于做简单平滑。
    static let smoothedSpeedSampleWindow = 5

    /// 当两点推导出的速度超过这个阈值时，判定为跳点。
    static let maxAcceptedDerivedSpeedMps: Double = 10

    /// 两点时间间隔太短时，不参与跳点判定，避免时钟抖动带来的误杀。
    static let minIntervalForJumpDetectionSeconds: TimeInterval = 1
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
    static let locationUpdated = "locationUpdated"
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

    guard isLocationAccuracyAcceptable(location) else {
      return
    }

    guard !isJumpLocation(location) else {
      return
    }

    if let lastLocation = recordedLocations.last {
      totalDistanceMeters += max(0, location.distance(from: lastLocation))
    }

    recordedLocations.append(location)
    appendSpeedSampleIfNeeded(from: location)

    let locationPayload = buildLocationPayload(location)
    pushEvent(name: MotionEvent.locationUpdated, payload: locationPayload)
    pushMotionUpdatedEvent(latestLocation: location)
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
    let latestPointPayload = latestLocation.map(buildLocationPayload)

    pushEvent(
      name: MotionEvent.motionUpdated,
      payload: compactDictionary([
        "status": currentStatus,
        "durationSeconds": currentDurationSeconds(referenceTimeMillis: resolvedTimeMillis),
        "distanceMeters": totalDistanceMeters,
        "currentSpeedMps": buildSmoothedCurrentSpeed(
          fallbackLocation: latestLocation ?? recordedLocations.last
        ),
        "averageSpeedMps": buildAverageSpeed(referenceTimeMillis: resolvedTimeMillis),
        "pointCount": recordedLocations.count,
        "latestPoint": latestPointPayload
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

    return horizontalAccuracy <= MotionRuntimeConfig.maxAcceptedHorizontalAccuracy
  }

  private func isJumpLocation(_ location: CLLocation) -> Bool {
    guard let lastLocation = recordedLocations.last else {
      return false
    }

    let intervalSeconds = location.timestamp.timeIntervalSince(lastLocation.timestamp)
    guard intervalSeconds >= MotionRuntimeConfig.minIntervalForJumpDetectionSeconds else {
      return false
    }

    let distanceMeters = location.distance(from: lastLocation)
    let derivedSpeedMps = distanceMeters / intervalSeconds
    return derivedSpeedMps > MotionRuntimeConfig.maxAcceptedDerivedSpeedMps
  }

  private func appendSpeedSampleIfNeeded(from location: CLLocation) {
    guard let speedMps = normalizedSpeed(from: location) else {
      return
    }

    recentSpeedSamples.append(speedMps)
    if recentSpeedSamples.count > MotionRuntimeConfig.smoothedSpeedSampleWindow {
      recentSpeedSamples.removeFirst(recentSpeedSamples.count - MotionRuntimeConfig.smoothedSpeedSampleWindow)
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
    totalDistanceMeters = 0
    recentSpeedSamples.removeAll()
    recordedLocations.removeAll()
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
