import Flutter
import MAMapKit
import UIKit
import CoreLocation
import Foundation

/// 当前阶段的地图原生容器。
///
/// 这里已经使用高德 `MAMapView` 作为底层地图视图。
/// 后续定位点刷新、轨迹绘制、相机控制都会继续在这个原生容器里扩展。
///  Flutter iOS SDK 基于 Objective-C Runtime，所以flutter要嵌入的插件一般都继承NSObject，Delegate 体系很多依赖 NSObject
final class MotionMapPlatformView: NSObject, FlutterPlatformView, MAMapViewDelegate {
    
    // MARK: - 常量配置
    
    private enum MapCameraConfig {
        /// 运动页默认进入时使用的基础缩放级别。
        static let initialZoomLevel: CGFloat = 16
        /// 开始运动后聚焦起跑点时使用的缩放级别，要比初始态更聚焦。
        static let workoutStartZoomLevel: CGFloat = 18
        /// 结束弹窗路线截图的留白，避免轨迹贴边。
        static let finishSnapshotEdgePadding = UIEdgeInsets(top: 28, left: 24, bottom: 28, right: 24)
        /// 结束弹窗路线截图导出宽度，控制传给 Flutter 的图片体积。
        static let finishSnapshotTargetWidth: CGFloat = 640
        /// 结束弹窗路线截图导出压缩质量。
        static let finishSnapshotCompressionQuality: CGFloat = 0.74
        /// 结束截图时，在自动拟合轨迹后额外缩小一个缩放级别，避免起终点过于贴近画面边缘。
        static let finishSnapshotZoomOutDelta: CGFloat = 1
    }
    
    //和flutter一侧对应的运动状态
    private enum SessionStatusValue: String {
        //运动尚未开始。
        case idle
        //运动准备中，通常用于权限检查或原生初始化。
        case preparing
        //运动进行中，正在持续记录运动数据。
        case running
        //运动已暂停。
        case paused
        //运动已结束，并且已经生成最终结果。
        case finished
        //运动流程进入错误状态。
        case error
    }
    
    private enum FinishSnapshotStep {
        case waitingForFit
        case waitingForZoomOut
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
    
    // MARK: - 属性声明
    
    private let mapView: MAMapView
    private let methodChannel: FlutterMethodChannel
    private weak var bridge: MotionNativeBridge?
    /// 轨迹折线覆盖物，运动过程中持续追加点位。
    private var trackPolyline: MAPolyline?
    /// 起点标注，首次产生有效轨迹点时创建。
    private var startAnnotation: MAPointAnnotation?
    /// 终点标注，运动结束时贴到最后一个轨迹点。
    private var endAnnotation: MAPointAnnotation?
    /// 轨迹末端的当前位置蓝点标注。
    private var trackAnnotation: MAPointAnnotation?
    /// 原生侧维护的完整轨迹坐标序列，用于折线同步和截图拟合。
    private var nativeTrackCoordinates: [CLLocationCoordinate2D] = []
    /// 标记是否已将地图中心对准过用户位置，避免重复居中。
    private var hasCenteredOnUserLocation = false
    /// 当前运动会话状态，与 Flutter 侧保持同步。
    private var sessionStatus: SessionStatusValue = .idle
    /// 当前是否处于自动跟随用户状态。
    private var isFollowingUser = false
    /// 标记最近一次地图中心变化是否由代码主动触发，用于避免误判为用户手势。
    private var isProgrammaticCameraChange = false
    /// 结束截图的当前步骤，用于驱动「拟合 → 缩放 → 截图」的状态机。
    private var finishSnapshotStep: FinishSnapshotStep?
    /// 结束截图完成后的回调闭包，持有期间不可重入。
    private var finishSnapshotCompletion: ((String?) -> Void)?
    /// 结束截图的超时兜底任务，防止高德相机回调丢失导致永远等待。
    private var finishSnapshotFallbackWorkItem: DispatchWorkItem?
    
    // MARK: - 生命周期
    
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
}

// MARK: - FlutterPlatformView 官方协议

/// 允许flutter一侧嵌入遵守这个协议的原生view
extension MotionMapPlatformView {
    func view() -> UIView {
        mapView
    }
}

// MARK: - 地图初始化与 Channel 绑定

/// 地图视图的初始化配置和 Flutter MethodChannel 绑定。
/// 包含高德地图基础参数设置、Channel 方法路由及参数解析。
extension MotionMapPlatformView {
    
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
            case "focusCurrentLocation":
                self.handleFocusCurrentLocation(call: call, result: result)
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
    
    /// 手动点击“回到当前位置”时回中地图。
    ///
    /// 规则：
    /// 1. running 时恢复自动跟随
    /// 2. paused/finished 时只回中，不进入持续跟随
    private func handleFocusCurrentLocation(
        call: FlutterMethodCall,
        result: FlutterResult
    ) {
        let shouldResumeFollow = sessionStatus == .running
        focusCurrentLocation(resumeFollow: shouldResumeFollow)
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
        if sessionStatus != .running {
            isFollowingUser = false
        }
        if sessionStatus == .finished {
            clearTrack()
            return
        }
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
}

// MARK: - 标注（Annotation）管理

/// 起点「起」、终点「终」、轨迹末端蓝点等地图标注的创建、更新与移除，
/// 以及系统蓝点的显隐策略切换。
extension MotionMapPlatformView {
    
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
            setMapCenter(coordinate, animated: false)
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
        case .idle, .finished, .error:
            shouldShowSystemUserLocation = true
        case .preparing, .running, .paused:
            shouldShowSystemUserLocation = false
        }
        
        if mapView.showsUserLocation != shouldShowSystemUserLocation {
            mapView.showsUserLocation = shouldShowSystemUserLocation
            mapView.userTrackingMode = .none
        }
    }
}

// MARK: - 轨迹数据与折线管理

/// 轨迹点的追加、前台恢复、折线同步，以及起终点标注的联动状态维护。
/// 包含清空轨迹和重置相机的完整生命周期。
extension MotionMapPlatformView {
    
    /// 原生定位采到新点时，直接追加到地图轨迹，无需 Flutter 中转。
    func appendTrackPoint(_ location: CLLocation) {
        if nativeTrackCoordinates.isEmpty {
            updateStartAnnotationIfNeeded(coordinate: location.coordinate)
        }
        nativeTrackCoordinates.append(location.coordinate)
        syncTrackPolyline()
        syncTrackTerminalAnnotations()
        if sessionStatus == .running, isFollowingUser {
            setMapCenter(location.coordinate, animated: false)
        }
    }
    
    /// App 回前台时，用原生完整历史点重绘整条轨迹。
    func restoreTrack(_ locations: [CLLocation]) {
        if sessionStatus == .finished {
            clearTrack()
            return
        }
        
        if let startLocation = locations.first {
            updateStartAnnotationIfNeeded(coordinate: startLocation.coordinate)
        }
        if let latestLocation = locations.last,
           sessionStatus == .running,
           isFollowingUser {
            setMapCenter(latestLocation.coordinate, animated: false)
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
            return
        }
        
        let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
        trackPolyline = polyline
        mapView.add(polyline)
    }
    
    /// 根据运动状态和轨迹点数量，统一维护起点、终点和末端蓝点。
    ///
    /// 规则：
    /// 1. 开始运动后未形成线段前，只显示“起”
    /// 2. 形成线段后，显示“起 + 末端蓝点”
    /// 3. 结束运动后清空所有自绘覆盖物，仅保留系统默认蓝点
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
            if let annotation = startAnnotation {
                mapView.removeAnnotation(annotation)
                startAnnotation = nil
            }
            removeTrackAnnotationIfNeeded()
            removeEndAnnotationIfNeeded()
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
        isFollowingUser = false
        mapView.setZoomLevel(MapCameraConfig.initialZoomLevel, animated: false)
        
        // 新一轮运动开始前清空旧轨迹时，优先把视角恢复到当前用户位置，
        // 避免上一段轨迹留下的大范围视口影响本次起跑体验。
        if let focusCoordinate {
            setMapCenter(focusCoordinate, animated: false)
            hasCenteredOnUserLocation = true
            return
        }
        
        if let userLocation = mapView.userLocation,
           CLLocationCoordinate2DIsValid(userLocation.coordinate) {
            setMapCenter(userLocation.coordinate, animated: false)
            hasCenteredOnUserLocation = true
        }
    }
    
    /// 开始新一轮运动时，强制把地图缩放和中心恢复到起跑态。
    private func resetCameraForWorkoutStart(focusCoordinate: CLLocationCoordinate2D? = nil) {
        clearTrack(focusCoordinate: focusCoordinate)
        hasCenteredOnUserLocation = false
        isFollowingUser = true
        mapView.setZoomLevel(MapCameraConfig.workoutStartZoomLevel, animated: false)
        
        if let focusCoordinate {
            setMapCenter(focusCoordinate, animated: false)
            hasCenteredOnUserLocation = true
            updateStartAnnotationIfNeeded(coordinate: focusCoordinate)
            return
        }
        
        if let userLocation = mapView.userLocation,
           CLLocationCoordinate2DIsValid(userLocation.coordinate) {
            setMapCenter(userLocation.coordinate, animated: false)
            hasCenteredOnUserLocation = true
            updateStartAnnotationIfNeeded(coordinate: userLocation.coordinate)
        }
    }
}

// MARK: - 结束截图与视角控制

/// 运动结束时的路线截图生成流程（视口拟合 → 缩放微调 → 截图导出 → Base64 编码），
/// 以及聚焦当前位置、地图中心更新等视角控制辅助方法。
extension MotionMapPlatformView {
    
    /// 为结束弹窗生成路线截图：
    /// 1. 视口缩放到完整轨迹
    /// 2. 临时切成“起 + 终 + 路线”的结束展示态
    /// 3. 等待高德完成自动拟合后，再额外缩小一个缩放级别
    /// 4. 导出压缩后的 Base64 图片给 Flutter
    func captureFinishedRouteSnapshot(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                completion(nil)
                return
            }
            
            self.resetPendingFinishSnapshot()
            self.finishSnapshotCompletion = completion
            self.prepareFinishedRouteSnapshotPresentation()
            
            if self.startFinishedRouteFitIfNeeded() {
                self.scheduleFinishSnapshotFallback()
                return
            }
            
            self.finishFinishedRouteSnapshot()
        }
    }
    
    /// 截图前把地图覆盖物切到结束态展示：
    /// - 保留起点与轨迹
    /// - 移除末端蓝点
    /// - 在最后一个轨迹点上展示“终”
    private func prepareFinishedRouteSnapshotPresentation() {
        removeTrackAnnotationIfNeeded()
        
        if let firstCoordinate = nativeTrackCoordinates.first {
            updateStartAnnotationIfNeeded(coordinate: firstCoordinate)
        }
        
        if let latestCoordinate = nativeTrackCoordinates.last {
            updateEndAnnotationIfNeeded(coordinate: latestCoordinate)
        } else {
            removeEndAnnotationIfNeeded()
        }
    }
    
    /// 聚焦到当前位置，并按调用方要求决定是否恢复自动跟随。
    private func focusCurrentLocation(resumeFollow: Bool) {
        let targetCoordinate: CLLocationCoordinate2D?
        if let latestCoordinate = nativeTrackCoordinates.last {
            targetCoordinate = latestCoordinate
        } else if let userLocation = mapView.userLocation,
                  CLLocationCoordinate2DIsValid(userLocation.coordinate) {
            targetCoordinate = userLocation.coordinate
        } else {
            targetCoordinate = nil
        }
        
        guard let targetCoordinate else {
            return
        }
        
        isFollowingUser = resumeFollow
        setMapCenter(targetCoordinate, animated: true)
        hasCenteredOnUserLocation = true
    }
    
    /// 结束截图前把地图相机调到完整路径可见的视口。
    private func startFinishedRouteFitIfNeeded() -> Bool {
        guard !nativeTrackCoordinates.isEmpty else {
            if let userLocation = mapView.userLocation,
               CLLocationCoordinate2DIsValid(userLocation.coordinate) {
                setMapCenter(userLocation.coordinate, animated: false)
            }
            mapView.setZoomLevel(MapCameraConfig.workoutStartZoomLevel, animated: false)
            return false
        }
        
        if let trackPolyline,
           nativeTrackCoordinates.count >= 2 {
            finishSnapshotStep = .waitingForFit
            isProgrammaticCameraChange = true
            mapView.showOverlays(
                [trackPolyline],
                edgePadding: MapCameraConfig.finishSnapshotEdgePadding,
                animated: false
            )
            return true
        }
        
        if let firstCoordinate = nativeTrackCoordinates.first {
            setMapCenter(firstCoordinate, animated: false)
            mapView.setZoomLevel(MapCameraConfig.workoutStartZoomLevel, animated: false)
        }
        return false
    }
    
    /// 高德完成轨迹自动拟合后，再基于当前实际缩放级别额外缩小一档。
    private func startFinishedRouteZoomOutIfNeeded() {
        guard trackPolyline != nil,
              nativeTrackCoordinates.count >= 2 else {
            finishFinishedRouteSnapshot()
            return
        }
        
        finishSnapshotStep = .waitingForZoomOut
        isProgrammaticCameraChange = true
        let fittedZoomLevel = mapView.zoomLevel
        mapView.setZoomLevel(
            max(mapView.minZoomLevel, fittedZoomLevel - MapCameraConfig.finishSnapshotZoomOutDelta),
            animated: false
        )
        scheduleFinishSnapshotFallback()
    }
    
    /// 推进结束截图状态机：根据当前步骤决定是继续缩放还是完成截图。
    private func advanceFinishSnapshotStepIfNeeded() {
        finishSnapshotFallbackWorkItem?.cancel()
        finishSnapshotFallbackWorkItem = nil
        
        switch finishSnapshotStep {
        case .waitingForFit:
            startFinishedRouteZoomOutIfNeeded()
        case .waitingForZoomOut:
            finishFinishedRouteSnapshot()
        case nil:
            break
        }
    }
    
    /// 高德相机回调缺失时的兜底，避免结束运动一直等待原生截图。
    private func scheduleFinishSnapshotFallback() {
        finishSnapshotFallbackWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.advanceFinishSnapshotStepIfNeeded()
        }
        finishSnapshotFallbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }
    
    /// 执行最终截图并通过回调返回 Base64 结果。
    private func finishFinishedRouteSnapshot() {
        let completion = finishSnapshotCompletion
        resetPendingFinishSnapshot()
        completion?(buildRouteSnapshotBase64())
    }
    
    /// 重置截图流程的所有中间状态，确保下次截图不受残留影响。
    private func resetPendingFinishSnapshot() {
        finishSnapshotFallbackWorkItem?.cancel()
        finishSnapshotFallbackWorkItem = nil
        finishSnapshotStep = nil
        finishSnapshotCompletion = nil
    }
    
    /// 将当前地图画面导出为压缩图片，并编码成 Base64 字符串。
    private func buildRouteSnapshotBase64() -> String? {
        let bounds = mapView.bounds.integral
        guard bounds.width > 0, bounds.height > 0 else {
            return nil
        }
        
        let targetWidth = min(MapCameraConfig.finishSnapshotTargetWidth, bounds.width)
        let scale = max(targetWidth / bounds.width, 0.6)
        let targetSize = CGSize(width: targetWidth, height: bounds.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { _ in
            mapView.drawHierarchy(
                in: CGRect(origin: .zero, size: targetSize),
                afterScreenUpdates: true
            )
        }
        
        guard let imageData = image.jpegData(
            compressionQuality: MapCameraConfig.finishSnapshotCompressionQuality
        ) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    /// 封装地图中心更新，统一标记这是代码驱动的相机变化。
    private func setMapCenter(
        _ coordinate: CLLocationCoordinate2D,
        animated: Bool
    ) {
        isProgrammaticCameraChange = true
        mapView.setCenter(coordinate, animated: animated)
    }
}

// MARK: - MAMapViewDelegate 地图代理回调

/// 处理高德地图的用户定位更新、手势交互判断、区域变化监听，
/// 以及轨迹折线和标注覆盖物的渲染样式提供。
extension MotionMapPlatformView {
    
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
            if sessionStatus == .running, isFollowingUser {
                setMapCenter(userLocation.coordinate, animated: false)
                hasCenteredOnUserLocation = true
            }
        }
        
        guard !hasCenteredOnUserLocation else {
            return
        }
        
        setMapCenter(userLocation.coordinate, animated: false)
        hasCenteredOnUserLocation = true
    }
    
    /// 用户手动拖拽地图时，暂停自动跟随，保留当前缩放比例与浏览视角。
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        guard wasUserAction, !isProgrammaticCameraChange else {
            isProgrammaticCameraChange = false
            return
        }
        
        isFollowingUser = false
    }
    
    /// 用户手动缩放地图时，同样暂停自动跟随，但不重置缩放比例。
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
        guard wasUserAction, !isProgrammaticCameraChange else {
            isProgrammaticCameraChange = false
            return
        }
        
        isFollowingUser = false
    }
    
    /// 一次程序触发的地图位移完成后，清理标记，避免影响后续手势判定。
    func mapView(
        _ mapView: MAMapView!,
        regionDidChangeAnimated animated: Bool,
        wasUserAction: Bool
    ) {
        if !wasUserAction {
            isProgrammaticCameraChange = false
        }
        advanceFinishSnapshotStepIfNeeded()
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
            markerView.backgroundColor = reuseIdentifier == MapAnnotationConfig.endMarkerReuseIdentifier
            ? UIColor.systemRed
            : UIColor.systemBlue
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
