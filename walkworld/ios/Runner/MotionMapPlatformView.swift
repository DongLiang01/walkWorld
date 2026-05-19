import Flutter
import MAMapKit
import UIKit

/// 当前阶段的地图原生容器。
///
/// 这里已经使用高德 `MAMapView` 作为底层地图视图。
/// 后续定位点刷新、轨迹绘制、相机控制都会继续在这个原生容器里扩展。
final class MotionMapPlatformView: NSObject, FlutterPlatformView, MAMapViewDelegate {
  private enum MapCameraConfig {
    /// 运动页默认进入时使用的基础缩放级别。
    static let initialZoomLevel: CGFloat = 16
  }

  private let mapView: MAMapView
  private let methodChannel: FlutterMethodChannel
  private var trackPolyline: MAPolyline?
  private var trackAnnotation: MAPointAnnotation?
  private var hasCenteredOnUserLocation = false
  private var hasFittedTrackViewport = false

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    self.mapView = MAMapView(frame: frame)
    self.methodChannel = FlutterMethodChannel(
      name: "walkworld/motion_map_control_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    setupMapView(arguments: args)
    bindMethodChannel()
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
      case "updateUserLocation":
        self.handleUpdateUserLocation(call: call, result: result)
      case "updateTrack":
        self.handleUpdateTrack(call: call, result: result)
      case "clearTrack":
        self.handleClearTrack(call: call, result: result)
        result(nil)
      case "resetCameraForWorkoutStart":
        self.handleResetCameraForWorkoutStart(call: call, result: result)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 清空旧轨迹时，允许 Flutter 显式传入本次应聚焦的位置点。
  private func handleClearTrack(call: FlutterMethodCall, result: FlutterResult) {
    let focusCoordinate = buildCoordinate(arguments: call.arguments)
    clearTrack(focusCoordinate: focusCoordinate)
  }

  /// 每次开始运动时显式重置地图相机，避免依赖轨迹变化才能恢复视角。
  private func handleResetCameraForWorkoutStart(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    let focusCoordinate = buildCoordinate(arguments: call.arguments)
    resetCameraForWorkoutStart(focusCoordinate: focusCoordinate)
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

  /// 更新地图上的当前位置标记。
  private func handleUpdateUserLocation(call: FlutterMethodCall, result: FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let latitude = arguments["latitude"] as? CLLocationDegrees,
          let longitude = arguments["longitude"] as? CLLocationDegrees else {
      result(
        FlutterError(
          code: "invalid_location_arguments",
          message: "updateUserLocation 缺少有效经纬度参数。",
          details: call.arguments
        )
      )
      return
    }

    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    updateTrackAnnotation(coordinate: coordinate)
    result(nil)
  }

  /// 更新地图上的轨迹折线。
  private func handleUpdateTrack(call: FlutterMethodCall, result: FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let rawPoints = arguments["points"] as? [[String: Any]] else {
      result(
        FlutterError(
          code: "invalid_track_arguments",
          message: "updateTrack 缺少有效轨迹点参数。",
          details: call.arguments
        )
      )
      return
    }

    let coordinates = rawPoints.compactMap { point -> CLLocationCoordinate2D? in
      guard let latitude = point["latitude"] as? CLLocationDegrees,
            let longitude = point["longitude"] as? CLLocationDegrees else {
        return nil
      }

      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    updateTrackPolyline(coordinates: coordinates)
    result(nil)
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

  /// 刷新轨迹折线，并尝试让地图视口覆盖整条轨迹。
  private func updateTrackPolyline(coordinates: [CLLocationCoordinate2D]) {
    if let existingPolyline = trackPolyline {
      mapView.remove(existingPolyline)
    }

    guard !coordinates.isEmpty else {
      trackPolyline = nil
      return
    }

    var mutableCoordinates = coordinates
    let polyline = MAPolyline(coordinates: &mutableCoordinates, count: UInt(coordinates.count))
    trackPolyline = polyline
    mapView.add(polyline)

    /// 仅在首次拿到轨迹时自动对焦一次，后续保留用户手动拖拽后的视角。
    guard !hasFittedTrackViewport else {
      return
    }

    if coordinates.count == 1, let firstCoordinate = coordinates.first {
      mapView.setCenter(firstCoordinate, animated: false)
      hasCenteredOnUserLocation = true
      hasFittedTrackViewport = true
      return
    }

    mapView.showOverlays([polyline], edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40), animated: false)
    hasCenteredOnUserLocation = true
    hasFittedTrackViewport = true
  }

  /// 清空当前位置标记和轨迹折线。
  private func clearTrack(focusCoordinate: CLLocationCoordinate2D? = nil) {
    if let annotation = trackAnnotation {
      mapView.removeAnnotation(annotation)
      trackAnnotation = nil
    }

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
    hasCenteredOnUserLocation = false
    hasFittedTrackViewport = false
    mapView.setZoomLevel(MapCameraConfig.initialZoomLevel, animated: false)

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

  /// 首次拿到系统用户定位后，立即把地图中心切到当前位置。
  ///
  /// 这样即便 Flutter 侧实时事件还没推上来，页面初次进入时也不会停留在高德默认中心点。
  func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
    guard updatingLocation,
          let userLocation,
          CLLocationCoordinate2DIsValid(userLocation.coordinate),
          !hasCenteredOnUserLocation else {
      return
    }

    mapView.setCenter(userLocation.coordinate, animated: false)
    hasCenteredOnUserLocation = true
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
}
