import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/presentation/pages/app_shell_page.dart';
import 'app/theme/app_theme.dart';
import 'features/profile/application/city_data_provider.dart';
import 'features/profile/data/goal_route_preferences_repository.dart';

/// 应用主题模式。
///
/// 默认跟随系统，仅在首页测试按钮点击后切换为显式白天或黑夜模式。
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// 声明状态类型是ThemeMode
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// 在白天与黑夜模式之间切换，供首页测试按钮直接调用。
  void toggleForTest(Brightness brightness) {
    state = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Riverpod 入口，启动时预热城市数据并开启全局状态容器
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final providerContainer = ProviderContainer();
  //app启动前先解析好城市数据
  await providerContainer.read(citiesProvider.future);
  await providerContainer.read(groupedCitiesProvider.future);
  //app启动前恢复上次选择的出发地、目的地和搜索记录
  await GoalRoutePreferencesRepository.initialize();

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: const MyApp(),
    ),
  );
}

/// ConsumerWidget = 能消费 provider 的 Widget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  /// WidgetRef 是 Riverpod 提供的引用对象，用来在 Widget 中访问 providers
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() 监听 provider 变化，变化时 rebuild
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Walkworld',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppShellPage(),
    );
  }
}
