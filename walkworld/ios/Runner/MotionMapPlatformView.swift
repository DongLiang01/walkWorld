import Flutter
import MAMapKit
import UIKit

/// 当前阶段的地图原生容器。
///
/// 这里已经使用高德 `MAMapView` 作为底层地图视图。
/// 后续定位点刷新、轨迹绘制、相机控制都会继续在这个原生容器里扩展。
final class MotionMapPlatformView: NSObject, FlutterPlatformView, MAMapViewDelegate {
  private let mapView: MAMapView
  private let methodChannel: FlutterMethodChannel
  private var trackPolyline: MAPolyline?
  private var trackAnnotation: MAPointAnnotation?
  private var hasAdjustedCamera = false
  private var hasCenteredOnUserLocation = false

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
    mapView.zoomLevel = 16

    if let arguments = arguments as? [String: Any],
       let showUserLocation = arguments["showUserLocation"] as? Bool {
      mapView.showsUserLocation = showUserLocation

      if showUserLocation {
        mapView.userTrackingMode = .follow
      }
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
        self.clearTrack()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
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

    if !hasAdjustedCamera {
      mapView.setCenter(coordinate, animated: false)
      hasAdjustedCamera = true
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

    if coordinates.count == 1, let firstCoordinate = coordinates.first {
      mapView.setCenter(firstCoordinate, animated: false)
      hasAdjustedCamera = true
      hasCenteredOnUserLocation = true
      return
    }

    mapView.showOverlays([polyline], edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40), animated: false)
    hasAdjustedCamera = true
    hasCenteredOnUserLocation = true
  }

  /// 清空当前位置标记和轨迹折线。
  private func clearTrack() {
    if let annotation = trackAnnotation {
      mapView.removeAnnotation(annotation)
      trackAnnotation = nil
    }

    if let polyline = trackPolyline {
      mapView.remove(polyline)
      trackPolyline = nil
    }

    hasAdjustedCamera = false
    hasCenteredOnUserLocation = false
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
    hasAdjustedCamera = true
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
