import Flutter
import AMapFoundationKit
import AMapLocationKit
import MAMapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var motionNativeBridge: MotionNativeBridge?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAMapIfNeeded()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    //AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate  代表AppDelegate继承了FlutterAppDelegate，同时遵循了FlutterImplicitEngineDelegate协议，就具备了管理flutter引擎的能力
    //flutter渲染页面时，都会通过FlutterViewController去加载，里面跑着一个flutter引擎，引擎才是真正的运行载体——执行Dart代码、驱动渲染管线、管理平台通道。
    //FlutterViewController里面还有个flutterview，就是用来展示flutterUI的。
    //首次渲染flutter页面时，会初始化引擎，FlutterViewController不创建引擎，而是找UIApplication.shared.delegate要，也就是现在的AppDelegate，引擎初始化完毕之后，就会执行下面这个方法
    //里面一般做三件事：注册所有flutter插件（必须）、注册自定义 Platform View 工厂、创建自定义 MethodChannel/EventChannel
    //engineBridge：隐式引擎初始化后，Flutter SDK 传的桥接对象。它是访问这个引擎一切资源的入口
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        //flutter pub get 自动生成的 Swift 代码，把 pubspec.yaml 里所有 Dart 插件一一注册到该引擎的注册表中。不调用这行，所有 Flutter 插件在 Native 侧都不可用。
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        //在 Flutter 引擎里以 "MotionMapViewFactory" 这个 key 创建（或查找）一个 registrar 席位
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MotionMapViewFactory") {
            //拿到通信管道，创建桥阶层
            motionNativeBridge = MotionNativeBridge(messenger: registrar.messenger())
            //创建工厂
            let factory = MotionMapViewFactory(
                messenger: registrar.messenger(),
                bridge: motionNativeBridge!
            )
            //创建viewtype和工厂的映射关系，一个工程只对应一个viewtype
            registrar.register(factory, withId: "walkworld/motion_map_view")
            //当flutter引擎需要创建 viewType = "walkworld/motion_map_view" 的原生视图时，找到工厂，调用工厂的create()方法创建一个view出来，然后嵌入widget树
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
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)
        
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
