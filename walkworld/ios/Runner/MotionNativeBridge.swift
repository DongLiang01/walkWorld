import AMapLocationKit
import CoreLocation
import Flutter
import Foundation

/// 负责运动模块在 iOS 侧的 MethodChannel / EventChannel / 定位能力接入。
///
/// 当前阶段先完成 Step 5 所需的最小闭环：
/// 1. 定位权限申请与状态回传
/// 2. 系统定位服务开关检查
/// 3. 持续定位监听
/// 4. 为现有 Flutter 控制器补齐最小可用的运动命令状态机
final class MotionNativeBridge: NSObject, FlutterStreamHandler {
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
    pushStatusChangedEvent()

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

    result([
      "accepted": true,
      "status": currentStatus,
      "summary": compactDictionary(summary)
    ])
  }

  private func handleAuthorizationChanged(_ status: CLAuthorizationStatus) {
    pushPermissionChangedEvent(status: status)

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

    if let lastLocation = recordedLocations.last {
      totalDistanceMeters += max(0, location.distance(from: lastLocation))
    }

    recordedLocations.append(location)

    let locationPayload = buildLocationPayload(location)
    pushEvent(name: MotionEvent.locationUpdated, payload: locationPayload)
    pushEvent(
      name: MotionEvent.motionUpdated,
      payload: compactDictionary([
        "status": currentStatus,
        "durationSeconds": currentDurationSeconds(referenceTimeMillis: currentTimestampMillis()),
        "distanceMeters": totalDistanceMeters,
        "currentSpeedMps": normalizedSpeed(from: location),
        "averageSpeedMps": buildAverageSpeed(),
        "pointCount": recordedLocations.count,
        "latestPoint": locationPayload
      ])
    )
  }

  private func handleLocationError(_ error: NSError) {
    pushEvent(
      name: MotionEvent.error,
      payload: [
        "code": errorCode(for: error),
        "message": "原生定位更新失败。",
        "detail": error.localizedDescription
      ]
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

  private func buildAverageSpeed() -> Double? {
    let durationSeconds = currentDurationSeconds(referenceTimeMillis: currentTimestampMillis())
    guard durationSeconds > 0 else {
      return nil
    }

    return totalDistanceMeters / Double(durationSeconds)
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
    currentSessionId = nil
    sessionStartTimeMillis = nil
    accumulatedPausedDurationMillis = 0
    pauseStartedAtMillis = nil
    totalDistanceMeters = 0
    recordedLocations.removeAll()
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
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
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
