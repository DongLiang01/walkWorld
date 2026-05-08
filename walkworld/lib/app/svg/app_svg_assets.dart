/// 统一管理应用内 SVG 资源路径，避免页面层散落硬编码路径。
class AppSvgAssets {
  const AppSvgAssets._();

  static const String _common = 'assets/icons/common';
  static const String _tabbar = 'assets/icons/tabbar';
  static const String _motion = 'assets/icons/motion';

  /// 生成通用图标路径。
  static String common(String name) => '$_common/$name.svg';

  /// 生成底部导航图标路径。
  static String tabbar(String name) => '$_tabbar/$name.svg';

  /// 生成运动模块图标路径。
  static String motion(String name) => '$_motion/$name.svg';
}
