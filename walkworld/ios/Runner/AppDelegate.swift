import Flutter
import AMapFoundationKit
import MAMapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAMapIfNeeded()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MotionMapViewFactory") {
      let factory = MotionMapViewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "walkworld/motion_map_view")
    }
  }

  /// 初始化高德基础配置。
  ///
  /// 当前阶段只处理地图 SDK 所需的最小配置：
  /// 1. 隐私合规状态
  /// 2. API Key
  /// 3. HTTPS 开关
  ///
  /// 注意：这些配置都需要在 `MAMapView` 实例化之前完成。
  private func configureAMapIfNeeded() {
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)

    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String,
          !apiKey.isEmpty,
          apiKey == "5eaf3ff35e9657d50bd91e91f12c0dc1" else {
      assertionFailure("请先在 Info.plist 中配置真实的 AMapApiKey。")
      return
    }

      AMapServices.shared().apiKey = apiKey
      AMapServices.shared().enableHTTPS = true
  }
}
