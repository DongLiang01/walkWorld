/// 统一管理应用内 SVG 资源路径，避免页面层散落硬编码路径。
class AppSvgAssets {
  const AppSvgAssets._();

  static const String _common = 'assets/icons/common';
  static const String _tabbar = 'assets/icons/tabbar';
  static const String _motion = 'assets/icons/motion';
  static const String _home = 'assets/icons/home';
  static const String _profile = 'assets/icons/profile';

  /// 生成通用图标路径。
  static String common(String name) => '$_common/$name.svg';

  /// 生成底部导航图标路径。
  static String tabbar(String name) => '$_tabbar/$name.svg';

  /// 生成运动模块图标路径。
  static String motion(String name) => '$_motion/$name.svg';

  /// 生成首页图标路径。
  static String home(String name) => '$_home/$name.svg';

  /// 生成我的页面图标路径。
  static String profile(String name) => '$_profile/$name.svg';
}
