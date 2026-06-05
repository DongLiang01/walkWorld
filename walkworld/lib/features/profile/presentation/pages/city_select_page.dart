import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/svg/svg.dart';
import '../../../../app/theme/app_theme_tokens.dart';
import '../../domain/city_model.dart';
import '../../application/city_data_provider.dart';
import '../../application/goal_route_provider.dart';
import 'package:flutter/services.dart';

// ============================================================
// 城市选择页面 — 支持日夜间两套主题，像素级还原设计稿
// ============================================================

class CitySelectPage extends ConsumerStatefulWidget {
  const CitySelectPage({super.key, required this.isOrigin});

  /// 是否是选择出发地 (true: 出发地, false: 目的地)
  final bool isOrigin;

  @override
  ConsumerState<CitySelectPage> createState() => _CitySelectPageState();
}

class _CitySelectPageState extends ConsumerState<CitySelectPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  // 用来为每个拼音分组绑定 GlobalKey，以便右侧侧边栏平滑滚动定位
  final Map<String, GlobalKey> _groupKeys = {};

  // ---------------------- 生命周期 ----------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  // ---------------------- 页面入口 ----------------------

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final routeState = ref.watch(goalRouteProvider);
    final citySelectDataAsync = ref.watch(
      filteredCitySelectDataProvider(widget.isOrigin),
    );

    // 获取当前维度的选中城市
    final currentSelectedCity = widget.isOrigin
        ? routeState.originCity
        : routeState.destinationCity;

    //根据数据状态，展示不同的ui
    return citySelectDataAsync.when(
      data: (citySelectData) => _buildCityScaffold(
        tokens,
        currentSelectedCity,
        citySelectData.cities,
        citySelectData.groupedCities,
      ),
      loading: () => _buildStateScaffold(
        tokens,
        currentSelectedCity.name,
        const CircularProgressIndicator(strokeWidth: 2),
        '城市数据加载中…',
      ),
      error: (error, stackTrace) => _buildStateScaffold(
        tokens,
        currentSelectedCity.name,
        Text(
          '!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: tokens.brandPrimary,
          ),
        ),
        '城市数据加载失败：$error',
      ),
    );
  }

  // =====================================================
  //  页面主体 — 数据加载完成后的完整 Scaffold
  // =====================================================

  Widget _buildCityScaffold(
    AppThemeTokens tokens,
    City currentSelectedCity,
    List<City> allCities,
    Map<String, List<City>> groupedCities,
  ) {
    final searchHistory = ref.watch(searchHistoryProvider);
    //键盘是否弹出
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // 搜索过滤
    final displayGroupedCities = _filterCities(
      allCities,
      groupedCities,
      _searchQuery,
    );

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 自定义精致 AppBar (带模糊分割线与日夜色值还原)
            _CitySelectAppBar(
              tokens: tokens,
              titleText: widget.isOrigin
                  ? '出发地：${currentSelectedCity.name}'
                  : '目的地：${currentSelectedCity.name}',
              onBack: () => Navigator.pop(context),
            ),
            //搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: _buildSearchBar(tokens),
            ),
            //搜索记录
            if (searchHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: 4,
                  left: 13,
                  bottom: 10,
                  right: 13,
                ),
                child: _buildSearchHistorySection(
                  tokens,
                  searchHistory,
                  allCities,
                ),
              ),
            // 城市列表区
            Expanded(
              child: Container(
                color: tokens.surfacePrimary,
                child: Stack(
                  children: [
                    // 主滚动区域
                    _buildScrollContent(
                      tokens,
                      currentSelectedCity,
                      allCities,
                      displayGroupedCities,
                      searchHistory,
                    ),

                    // 拼音侧边字母表浮动导航 (仅当非搜索态且数据非空时显示)
                    if (_searchQuery.isEmpty && displayGroupedCities.isNotEmpty)
                      Positioned(
                        right: 4,
                        top: 10,
                        bottom: 10,
                        child: _AlphabetScrollbar(
                          tokens: tokens,
                          alphabets: displayGroupedCities.keys.toList(),
                          onTap: _scrollToGroup,
                          keyboardVisible: keyboardVisible,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 主滚动内容区（搜索框 + 搜索记录 + 城市列表卡片）
  Widget _buildScrollContent(
    AppThemeTokens tokens,
    City currentSelectedCity,
    List<City> allCities,
    Map<String, List<City>> displayGroupedCities,
    List<String> searchHistory,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(), //iOS 风格弹性
      slivers: [
        // 3. 城市列表卡片区
        SliverPadding(
          padding: EdgeInsets.only(
            left: 13,
            right: _searchQuery.isEmpty ? 32 : 13, // 有侧边栏时右边留白
            top: 8,
            bottom: 30,
          ),
          sliver: displayGroupedCities.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState(tokens))
              : SliverToBoxAdapter(
                  child: _buildGroupedCityCard(
                    tokens,
                    displayGroupedCities,
                    currentSelectedCity,
                  ),
                ),
        ),
      ],
    );
  }

  // =====================================================
  //  异步状态页面 (loading / error)
  // =====================================================

  Widget _buildStateScaffold(
    AppThemeTokens tokens,
    String currentCityName,
    Widget icon,
    String message,
  ) {
    return Scaffold(
      backgroundColor: tokens.profilePageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CitySelectAppBar(
              tokens: tokens,
              titleText: widget.isOrigin
                  ? '出发地：$currentCityName'
                  : '目的地：$currentCityName',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  //  搜索输入框
  // =====================================================

  /// 搜索输入框 (像素还原 Figma bg, border & icons)
  Widget _buildSearchBar(AppThemeTokens tokens) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.citySelectSearchBackground,
        borderRadius: BorderRadius.circular(9.1),
        border: Border.all(color: tokens.borderPrimary, width: 0.65),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          AppSvgIcon(
            AppSvgAssets.common('search'),
            width: 13,
            height: 13,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: TextStyle(fontSize: 12, color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索城市…',
                hintStyle: TextStyle(fontSize: 12, color: tokens.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _focusNode.unfocus();
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: tokens.borderPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvgIcon(
                    AppSvgAssets.common('clear_x'),
                    width: 8.5,
                    height: 8.5,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  //  搜索/历史记录栏
  // =====================================================

  /// 搜索/历史记录栏 (小闹钟 + wrap 标签 + 清除)
  Widget _buildSearchHistorySection(
    AppThemeTokens tokens,
    List<String> history,
    List<City> allCities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              tokens: tokens,
              iconAsset: 'history_clock',
              label: '搜索记录',
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(searchHistoryProvider.notifier).clearHistory(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  '清除',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 历史标签列表
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history.map((cityName) {
            return _HistoryTag(
              tokens: tokens,
              cityName: cityName,
              onTap: () {
                final target = allCities.firstWhere(
                  (c) => c.name == cityName,
                  orElse: () =>
                      City(name: cityName, country: 'China', zone: 'domestic', lat: 0, lng: 0),
                );
                if (target.lat != 0) {
                  _selectCityAndPop(target);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // =====================================================
  //  城市列表分组卡片
  // =====================================================

  /// 城市列表分组卡片 (12px 圆角大卡槽，内部自带分组标题和分割线)
  Widget _buildGroupedCityCard(
    AppThemeTokens tokens,
    Map<String, List<City>> groupedMap,
    City currentSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "城市列表"小标题 (非搜索态时显示)
        if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: _SectionHeader(
              tokens: tokens,
              iconAsset: 'city_pin',
              label: '城市列表',
            ),
          ),

        // 圆角卡片容器
        Container(
          decoration: BoxDecoration(
            color: tokens.citySelectCardBackground,
            borderRadius: BorderRadius.circular(11.7),
            border: Border.all(color: tokens.borderPrimary, width: 0.65),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildGroupedCityItems(
              tokens,
              groupedMap,
              currentSelected,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建分组内的所有子元素（拼音标题 + 城市行 + 分割线）
  List<Widget> _buildGroupedCityItems(
    AppThemeTokens tokens,
    Map<String, List<City>> groupedMap,
    City currentSelected,
  ) {
    final items = <Widget>[];

    groupedMap.forEach((pinyin, cities) {
      // 每一个分组绑定一个 GlobalKey
      final key = _groupKeys.putIfAbsent(pinyin, () => GlobalKey());

      // 拼音首字母标题栏 (B, C, D...)
      items.add(
        _PinyinGroupHeader(tokens: tokens, pinyin: pinyin, groupKey: key),
      );

      // 分组内的城市列表项
      for (int i = 0; i < cities.length; i++) {
        final city = cities[i];
        final isSelected = city.name == currentSelected.name;

        items.add(
          _CityListTile(
            tokens: tokens,
            city: city,
            isSelected: isSelected,
            onTap: () => _selectCityAndPop(city),
          ),
        );

        // 分割线 (最后项除外)
        if (i < cities.length - 1) {
          items.add(
            Divider(
              height: 0.65,
              thickness: 0.65,
              color: tokens.borderPrimary,
              indent: 12,
            ),
          );
        }
      }
    });

    return items;
  }

  // =====================================================
  //  空状态
  // =====================================================

  /// 无匹配搜索结果的空状态表现
  Widget _buildEmptyState(AppThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          // TODO: 此处暂用 Flutter 自带 Icon，后续替换为 Figma 导出的 SVG 图标
          Icon(
            Icons.location_city_rounded,
            size: 40,
            color: tokens.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '未找到相关城市',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  //  交互方法
  // =====================================================

  /// 平滑定位到指定首字母分组
  void _scrollToGroup(String alphabet) {
    final key = _groupKeys[alphabet];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 选择城市并返回
  void _selectCityAndPop(City city) {
    if (widget.isOrigin) {
      ref.read(goalRouteProvider.notifier).updateOrigin(city);
    } else {
      ref.read(goalRouteProvider.notifier).updateDestination(city);
    }
    Navigator.pop(context);
  }

  // =====================================================
  //  搜索过滤逻辑（纯数据处理，不涉及 UI）
  // =====================================================

  /// 根据搜索关键词过滤城市并重新分组
  Map<String, List<City>> _filterCities(
    List<City> allCities,
    Map<String, List<City>> groupedCities,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return groupedCities;

    // 模糊匹配拼音、名称、国家
    final query = searchQuery.toLowerCase();
    final filtered = allCities.where((city) {
      return city.name.toLowerCase().contains(query) ||
          city.country.toLowerCase().contains(query) ||
          getCityPinyinGroup(city).toLowerCase() == query;
    }).toList();

    // 对过滤后的数据进行重新分组
    final result = <String, List<City>>{};
    for (final city in filtered) {
      result.putIfAbsent(getCityPinyinGroup(city), () => []).add(city);
    }

    // 重建分组序
    final sortedKeys = result.keys.toList()..sort();
    final sorted = <String, List<City>>{};
    for (final k in sortedKeys) {
      sorted[k] = result[k]!..sort((a, b) => a.name.compareTo(b.name));
    }
    return sorted;
  }
}

// =============================================================
//  以下为页面级私有组件 — 仅服务本页面，不对外导出
// =============================================================

/// 自定义导航栏 (完美映射设计稿 AppBar)
class _CitySelectAppBar extends StatelessWidget {
  const _CitySelectAppBar({
    required this.tokens,
    required this.titleText,
    required this.onBack,
  });

  final AppThemeTokens tokens;
  final String titleText;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: tokens.borderPrimary, width: 0.65),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 左侧返回箭头按钮
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AppSvgIcon(
                  AppSvgAssets.common('back_arrow'),
                  width: 20,
                  height: 20,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 标题文字
          Expanded(
            child: Text(
              titleText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 小节标题组件 (Icon + 文字)，用于「搜索记录」和「城市列表」
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.tokens,
    required this.iconAsset,
    required this.label,
  });

  final AppThemeTokens tokens;
  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(
          AppSvgAssets.common(iconAsset),
          width: 14,
          height: 14,
          color: tokens.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 搜索历史标签
class _HistoryTag extends StatelessWidget {
  const _HistoryTag({
    required this.tokens,
    required this.cityName,
    required this.onTap,
  });

  final AppThemeTokens tokens;
  final String cityName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tokens.citySelectHistoryBackground,
          borderRadius: BorderRadius.circular(6.5),
          border: Border.all(color: tokens.borderPrimary, width: 0.65),
        ),
        child: Text(
          cityName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 拼音首字母分组标题栏 (B, C, D...)
class _PinyinGroupHeader extends StatelessWidget {
  const _PinyinGroupHeader({
    required this.tokens,
    required this.pinyin,
    required this.groupKey,
  });

  final AppThemeTokens tokens;
  final String pinyin;
  final GlobalKey groupKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: groupKey,
      width: double.infinity,
      color: tokens.citySelectHeaderBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        pinyin,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: tokens.brandPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// 城市列表行 — 使用 Material + InkWell 替代 GestureDetector，提供水波纹反馈
class _CityListTile extends StatelessWidget {
  const _CityListTile({
    required this.tokens,
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeTokens tokens;
  final City city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  city.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? tokens.brandPrimary
                        : tokens.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                AppSvgIcon(
                  AppSvgAssets.common('checkmark'),
                  width: 15,
                  height: 15,
                  color: tokens.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 字母侧边滑块导航栏 (B, C, D...)
class _AlphabetScrollbar extends StatelessWidget {
  const _AlphabetScrollbar({
    required this.tokens,
    required this.alphabets,
    required this.onTap,
    required this.keyboardVisible,
  });

  final AppThemeTokens tokens;
  final List<String> alphabets;
  final ValueChanged<String> onTap;
  final bool keyboardVisible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = constraints.maxHeight / alphabets.length;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            //用户手指在屏幕上按下后，沿着垂直方向拖动时，不断触发。
            onVerticalDragUpdate: (details) {
              final index = (details.localPosition.dy ~/ itemHeight).clamp(
                0,
                alphabets.length - 1,
              );
              onTap(alphabets[index]);
            },
            child: Column(
              children: alphabets.map((letter) {
                return SizedBox(
                  height: itemHeight,
                  child: GestureDetector(
                    onTap: (){
                      HapticFeedback.selectionClick();
                      onTap(letter);
                    },
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: keyboardVisible ? 9 : 9,
                          fontWeight: FontWeight.w700,
                          color: tokens.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
