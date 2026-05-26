import Flutter
import UIKit

/// 负责向 Flutter 注册运动地图原生视图工厂。
final class MotionMapViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let bridge: MotionNativeBridge

  init(messenger: FlutterBinaryMessenger, bridge: MotionNativeBridge) {
    self.messenger = messenger
    self.bridge = bridge
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let view = MotionMapPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger,
      bridge: bridge
    )
    return view
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
