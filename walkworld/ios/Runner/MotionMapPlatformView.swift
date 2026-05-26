import Flutter
import MAMapKit
import UIKit
import CoreLocation

/// 当前阶段的地图原生容器。
///
/// 这里已经使用高德 `MAMapView` 作为底层地图视图。
/// 后续定位点刷新、轨迹绘制、相机控制都会继续在这个原生容器里扩展。
final class MotionMapPlatformView: NSObject, FlutterPlatformView, MAMapViewDelegate {
  private enum MapCameraConfig {
    /// 运动页默认进入时使用的基础缩放级别。
    static let initialZoomLevel: CGFloat = 16
  }

  private enum SessionStatusValue: String {
    case idle
    case preparing
    case running
    case paused
    case finished
    case error
  }

  private enum MapAnnotationConfig {
    /// 起点标识复用标识。
    static let startMarkerReuseIdentifier = "motion_start_marker"
    /// 终点标识复用标识。
    static let endMarkerReuseIdentifier = "motion_end_marker"
    /// 轨迹末端当前位置点外圈直径。
    static let outerDotSize = CGSize(width: 36, height: 36)
    /// 轨迹末端当前位置点内圈直径。
    static let innerDotSize = CGSize(width: 24, height: 24)
    /// 轨迹末端当前位置点复用标识。
    static let trackDotReuseIdentifier = "motion_track_dot"
    /// 起终点标识内容尺寸。
    static let markerSize = CGSize(width: 28, height: 28)
  }

  private let mapView: MAMapView
  private let methodChannel: FlutterMethodChannel
  private weak var bridge: MotionNativeBridge?
  private var trackPolyline: MAPolyline?
  private var startAnnotation: MAPointAnnotation?
  private var endAnnotation: MAPointAnnotation?
  private var trackAnnotation: MAPointAnnotation?
  private var nativeTrackCoordinates: [CLLocationCoordinate2D] = []
  private var hasCenteredOnUserLocation = false
  private var hasFittedTrackViewport = false
  private var sessionStatus: SessionStatusValue = .idle

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger,
    bridge: MotionNativeBridge
  ) {
    self.mapView = MAMapView(frame: frame)
    self.methodChannel = FlutterMethodChannel(
      name: "walkworld/motion_map_control_\(viewId)",
      binaryMessenger: messenger
    )
    self.bridge = bridge
    super.init()

    bridge.attachMapView(self)
    setupMapView(arguments: args)
    bindMethodChannel()
  }

  deinit {
    bridge?.detachMapView(self)
  }

  func view() -> UIView {
    mapView
  }

  /// 初始化高德地图视图的基础展示能力。
  ///
  /// 当前阶段先做最小可见地图：
  /// - 打开指南针
  /// - 打开比例尺
  /// - 读取 Flutter 侧传来的 `showUserLocation` 参数
  /// - 预留后续轨迹和定位点更新的原生扩展空间
  private func setupMapView(arguments: Any?) {
    mapView.delegate = self
    mapView.showsCompass = true
    mapView.showsScale = true
    mapView.zoomLevel = MapCameraConfig.initialZoomLevel

    if let arguments = arguments as? [String: Any],
       let showUserLocation = arguments["showUserLocation"] as? Bool {
      mapView.showsUserLocation = showUserLocation
      mapView.userTrackingMode = .none
    }

    if let arguments = arguments as? [String: Any],
       let rawSessionStatus = arguments["sessionStatus"] as? String,
       let sessionStatus = SessionStatusValue(rawValue: rawSessionStatus) {
      self.sessionStatus = sessionStatus
    }

    applySystemUserLocationVisibility()
  }

  /// 绑定 Flutter 发给当前地图实例的控制方法。
  ///
  /// 这里单独给每个 `PlatformView` 建一个 channel，便于后续在多地图场景下
  /// 精确控制具体实例。
  private func bindMethodChannel() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "map_view_released",
            message: "地图视图已经释放。",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "resetCameraForWorkoutStart":
        self.handleResetCameraForWorkoutStart(call: call, result: result)
        result(nil)
      case "syncSessionStatus":
        self.handleSyncSessionStatus(call: call, result: result)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 每次开始运动时显式重置地图相机，避免依赖轨迹变化才能恢复视角。
  private func handleResetCameraForWorkoutStart(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    let focusCoordinate = buildCoordinate(arguments: call.arguments)
    resetCameraForWorkoutStart(focusCoordinate: focusCoordinate)
  }

  /// 同步 Flutter 侧运动状态，统一切换系统蓝点显示策略。
  private func handleSyncSessionStatus(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
          let rawSessionStatus = arguments["sessionStatus"] as? String,
          let sessionStatus = SessionStatusValue(rawValue: rawSessionStatus) else {
      return
    }

    self.sessionStatus = sessionStatus
    applySystemUserLocationVisibility()
    syncTrackTerminalAnnotations()
  }

  /// 将 Flutter 传来的经纬度字典解析成原生坐标。
  private func buildCoordinate(arguments: Any?) -> CLLocationCoordinate2D? {
    guard let arguments = arguments as? [String: Any],
          let latitude = arguments["latitude"] as? CLLocationDegrees,
          let longitude = arguments["longitude"] as? CLLocationDegrees else {
      return nil
    }

    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
  }

  /// 刷新当前位置标记，并在首次有点位时把相机移动过去。
  private func updateTrackAnnotation(coordinate: CLLocationCoordinate2D) {
    if let annotation = trackAnnotation {
      annotation.coordinate = coordinate
    } else {
      let annotation = MAPointAnnotation()
      annotation.coordinate = coordinate
      trackAnnotation = annotation
      mapView.addAnnotation(annotation)
    }

    if !hasCenteredOnUserLocation {
      mapView.setCenter(coordinate, animated: false)
      hasCenteredOnUserLocation = true
    }
  }

  /// 移除末端蓝点，避免和起点/终点标记叠加。
  private func removeTrackAnnotationIfNeeded() {
    if let annotation = trackAnnotation {
      mapView.removeAnnotation(annotation)
      trackAnnotation = nil
    }
  }

  /// 刷新起点标记，只在首个有效轨迹点确定后创建一次。
  private func updateStartAnnotationIfNeeded(coordinate: CLLocationCoordinate2D) {
    if let annotation = startAnnotation {
      annotation.coordinate = coordinate
      return
    }

    let annotation = MAPointAnnotation()
    annotation.coordinate = coordinate
    startAnnotation = annotation
    mapView.addAnnotation(annotation)
  }

  /// 刷新终点标记，只在运动结束后贴到最后一个轨迹点。
  private func updateEndAnnotationIfNeeded(coordinate: CLLocationCoordinate2D) {
    if let annotation = endAnnotation {
      annotation.coordinate = coordinate
      return
    }

    let annotation = MAPointAnnotation()
    annotation.coordinate = coordinate
    endAnnotation = annotation
    mapView.addAnnotation(annotation)
  }

  /// 移除终点标记，供新一轮运动开始或中途态切换时使用。
  private func removeEndAnnotationIfNeeded() {
    if let annotation = endAnnotation {
      mapView.removeAnnotation(annotation)
      endAnnotation = nil
    }
  }

  /// 根据当前状态统一切换系统蓝点显示，避免和自绘起终点/轨迹点重叠。
  private func applySystemUserLocationVisibility() {
    let shouldShowSystemUserLocation: Bool
    switch sessionStatus {
    case .idle, .error:
      shouldShowSystemUserLocation = true
    case .preparing, .running, .paused, .finished:
      shouldShowSystemUserLocation = false
    }

    if mapView.showsUserLocation != shouldShowSystemUserLocation {
      mapView.showsUserLocation = shouldShowSystemUserLocation
      mapView.userTrackingMode = .none
    }
  }

  /// 原生定位采到新点时，直接追加到地图轨迹，无需 Flutter 中转。
  func appendTrackPoint(_ location: CLLocation) {
    if nativeTrackCoordinates.isEmpty {
      updateStartAnnotationIfNeeded(coordinate: location.coordinate)
    }
    nativeTrackCoordinates.append(location.coordinate)
    syncTrackPolyline()
    syncTrackTerminalAnnotations()
  }

  /// App 回前台时，用原生完整历史点重绘整条轨迹。
  func restoreTrack(_ locations: [CLLocation]) {
    if let startLocation = locations.first {
      updateStartAnnotationIfNeeded(coordinate: startLocation.coordinate)
    }
    if let latestLocation = locations.last {
      if sessionStatus == .finished {
        updateEndAnnotationIfNeeded(coordinate: latestLocation.coordinate)
      }
    }
    nativeTrackCoordinates = locations.map(\.coordinate)
    syncTrackPolyline()
    syncTrackTerminalAnnotations()
  }

  /// 统一同步轨迹折线：
  /// 1. 首次有线时创建 overlay
  /// 2. 后续追加点位时直接复用同一条 polyline，避免反复 remove/add
  private func syncTrackPolyline() {
    guard nativeTrackCoordinates.count >= 2 else {
      if let existingPolyline = trackPolyline {
        mapView.remove(existingPolyline)
        trackPolyline = nil
      }
      return
    }

    var coordinates = nativeTrackCoordinates
    if let existingPolyline = trackPolyline {
      _ = existingPolyline.setPolylineWithCoordinates(
        &coordinates,
        count: coordinates.count
      )
      fitTrackViewportIfNeeded()
      return
    }

    let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
    trackPolyline = polyline
    mapView.add(polyline)
    fitTrackViewportIfNeeded()
  }

  /// 根据运动状态和轨迹点数量，统一维护起点、终点和末端蓝点。
  ///
  /// 规则：
  /// 1. 开始运动后未形成线段前，只显示“起”
  /// 2. 形成线段后，显示“起 + 末端蓝点”
  /// 3. 结束运动后，显示“起 + 终”，隐藏末端蓝点
  private func syncTrackTerminalAnnotations() {
    guard let firstCoordinate = nativeTrackCoordinates.first else {
      removeTrackAnnotationIfNeeded()
      removeEndAnnotationIfNeeded()
      return
    }

    updateStartAnnotationIfNeeded(coordinate: firstCoordinate)

    let hasTrackLine = nativeTrackCoordinates.count >= 2
    let latestCoordinate = nativeTrackCoordinates.last

    switch sessionStatus {
    case .finished:
      removeTrackAnnotationIfNeeded()
      if let latestCoordinate {
        updateEndAnnotationIfNeeded(coordinate: latestCoordinate)
      }
    case .preparing, .running, .paused:
      removeEndAnnotationIfNeeded()
      if hasTrackLine, let latestCoordinate {
        updateTrackAnnotation(coordinate: latestCoordinate)
      } else {
        removeTrackAnnotationIfNeeded()
      }
    case .idle, .error:
      removeTrackAnnotationIfNeeded()
      removeEndAnnotationIfNeeded()
    }
  }

  /// 首次拿到有效轨迹后自动对焦一次，后续保留用户手动拖拽后的视角。
  private func fitTrackViewportIfNeeded() {
    guard !hasFittedTrackViewport else {
      return
    }

    guard let trackPolyline else {
      return
    }

    mapView.showOverlays(
      [trackPolyline],
      edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40),
      animated: false
    )
    hasCenteredOnUserLocation = true
    hasFittedTrackViewport = true
  }

  /// 清空起点标记、终点标记、当前位置标记和轨迹折线。
  private func clearTrack(focusCoordinate: CLLocationCoordinate2D? = nil) {
    nativeTrackCoordinates.removeAll()

    if let annotation = startAnnotation {
      mapView.removeAnnotation(annotation)
      startAnnotation = nil
    }

    removeEndAnnotationIfNeeded()
    removeTrackAnnotationIfNeeded()

    if let polyline = trackPolyline {
      mapView.remove(polyline)
      trackPolyline = nil
    }

    hasCenteredOnUserLocation = false
    hasFittedTrackViewport = false
    mapView.setZoomLevel(MapCameraConfig.initialZoomLevel, animated: false)

    /// 新一轮运动开始前清空旧轨迹时，优先把视角恢复到当前用户位置，
    /// 避免上一段轨迹留下的大范围视口影响本次起跑体验。
    if let focusCoordinate {
      mapView.setCenter(focusCoordinate, animated: false)
      hasCenteredOnUserLocation = true
      return
    }

    if let userLocation = mapView.userLocation,
       CLLocationCoordinate2DIsValid(userLocation.coordinate) {
      mapView.setCenter(userLocation.coordinate, animated: false)
      hasCenteredOnUserLocation = true
    }
  }

  /// 开始新一轮运动时，强制把地图缩放和中心恢复到起跑态。
  private func resetCameraForWorkoutStart(focusCoordinate: CLLocationCoordinate2D? = nil) {
    clearTrack(focusCoordinate: focusCoordinate)
    hasCenteredOnUserLocation = false
    hasFittedTrackViewport = false
    mapView.setZoomLevel(MapCameraConfig.initialZoomLevel, animated: false)

    if let focusCoordinate {
      mapView.setCenter(focusCoordinate, animated: false)
      hasCenteredOnUserLocation = true
      updateStartAnnotationIfNeeded(coordinate: focusCoordinate)
      return
    }

    if let userLocation = mapView.userLocation,
       CLLocationCoordinate2DIsValid(userLocation.coordinate) {
      mapView.setCenter(userLocation.coordinate, animated: false)
      hasCenteredOnUserLocation = true
      updateStartAnnotationIfNeeded(coordinate: userLocation.coordinate)
    }
  }

  /// 首次拿到系统用户定位后，立即把地图中心切到当前位置。
  ///
  /// 这样即便 Flutter 侧实时事件还没推上来，页面初次进入时也不会停留在高德默认中心点。
  func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
    guard updatingLocation,
          let userLocation,
          CLLocationCoordinate2DIsValid(userLocation.coordinate) else {
      return
    }

    if (sessionStatus == .preparing || sessionStatus == .running || sessionStatus == .paused),
       nativeTrackCoordinates.isEmpty {
      updateStartAnnotationIfNeeded(coordinate: userLocation.coordinate)
    }

    guard !hasCenteredOnUserLocation else {
      return
    }

    mapView.setCenter(userLocation.coordinate, animated: false)
    hasCenteredOnUserLocation = true
  }

  /// 为运动中的当前位置点提供统一的蓝色圆点样式。
  func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
    if annotation is MAUserLocation {
      return nil
    }

    if let startAnnotation,
       annotation.isEqual(startAnnotation) {
      return buildMarkerAnnotationView(
        mapView: mapView,
        annotation: annotation,
        reuseIdentifier: MapAnnotationConfig.startMarkerReuseIdentifier,
        text: "起"
      )
    }

    if let endAnnotation,
       annotation.isEqual(endAnnotation) {
      return buildMarkerAnnotationView(
        mapView: mapView,
        annotation: annotation,
        reuseIdentifier: MapAnnotationConfig.endMarkerReuseIdentifier,
        text: "终"
      )
    }

    guard let trackAnnotation,
          annotation.isEqual(trackAnnotation) else {
      return nil
    }

    let annotationView: MAAnnotationView
    if let reusedView = mapView.dequeueReusableAnnotationView(
      withIdentifier: MapAnnotationConfig.trackDotReuseIdentifier
    ) {
      annotationView = reusedView
      annotationView.annotation = annotation
    } else {
      annotationView = MAAnnotationView(
        annotation: annotation,
        reuseIdentifier: MapAnnotationConfig.trackDotReuseIdentifier
      )
      annotationView.canShowCallout = false
      annotationView.isDraggable = false
      annotationView.centerOffset = .zero
      annotationView.bounds = CGRect(origin: .zero, size: MapAnnotationConfig.outerDotSize)

      let outerDotView = UIView(frame: annotationView.bounds)
      outerDotView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.20)
      outerDotView.layer.cornerRadius = MapAnnotationConfig.outerDotSize.width / 2
      outerDotView.isUserInteractionEnabled = false
      outerDotView.tag = 1001
      annotationView.addSubview(outerDotView)

      let innerOrigin = CGPoint(
        x: (MapAnnotationConfig.outerDotSize.width - MapAnnotationConfig.innerDotSize.width) / 2,
        y: (MapAnnotationConfig.outerDotSize.height - MapAnnotationConfig.innerDotSize.height) / 2
      )
      let innerDotView = UIView(
        frame: CGRect(origin: innerOrigin, size: MapAnnotationConfig.innerDotSize)
      )
      innerDotView.backgroundColor = UIColor.systemBlue
      innerDotView.layer.cornerRadius = MapAnnotationConfig.innerDotSize.width / 2
      innerDotView.layer.borderWidth = 2
      innerDotView.layer.borderColor = UIColor.white.cgColor
      innerDotView.isUserInteractionEnabled = false
      innerDotView.tag = 1002
      annotationView.addSubview(innerDotView)
    }

    return annotationView
  }

  /// 为轨迹折线提供渲染样式。
  func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
    if let polyline = overlay as? MAPolyline {
      let renderer = MAPolylineRenderer(polyline: polyline)
      renderer?.strokeColor = UIColor.systemBlue
      renderer?.lineWidth = 6
      return renderer
    }

    return nil
  }

  /// 统一构建起点/终点圆形文字标记，避免样式实现分散。
  private func buildMarkerAnnotationView(
    mapView: MAMapView,
    annotation: MAAnnotation,
    reuseIdentifier: String,
    text: String
  ) -> MAAnnotationView {
    let annotationView: MAAnnotationView
    if let reusedView = mapView.dequeueReusableAnnotationView(
      withIdentifier: reuseIdentifier
    ) {
      annotationView = reusedView
      annotationView.annotation = annotation
    } else {
      annotationView = MAAnnotationView(
        annotation: annotation,
        reuseIdentifier: reuseIdentifier
      )
      annotationView.canShowCallout = false
      annotationView.isDraggable = false
      annotationView.centerOffset = CGPoint(x: 0, y: -MapAnnotationConfig.markerSize.height / 2)
      annotationView.bounds = CGRect(origin: .zero, size: MapAnnotationConfig.markerSize)

      let markerView = UILabel(frame: annotationView.bounds)
      markerView.backgroundColor = UIColor.systemBlue
      markerView.textColor = .white
      markerView.textAlignment = .center
      markerView.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
      markerView.layer.cornerRadius = MapAnnotationConfig.markerSize.width / 2
      markerView.layer.masksToBounds = true
      markerView.isUserInteractionEnabled = false
      markerView.tag = 1000
      annotationView.addSubview(markerView)
    }

    if let markerView = annotationView.viewWithTag(1000) as? UILabel {
      markerView.text = text
    }

    return annotationView
  }
}
