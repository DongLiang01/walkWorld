import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_theme_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 目的地 WebView 页面
// ─────────────────────────────────────────────────────────────────────────────

/// 用 WebView 打开目的地相关的外部页面。
class DestinationWebViewPage extends StatefulWidget {
  const DestinationWebViewPage({
    required this.title,
    required this.url,
    super.key,
  });

  final String title;
  final String url;

  @override
  State<DestinationWebViewPage> createState() => _DestinationWebViewPageState();
}

class _DestinationWebViewPageState extends State<DestinationWebViewPage> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      backgroundColor: tokens.homePageBackground,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(fontSize: 16)),
        backgroundColor: tokens.homePageBackground,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              color: tokens.tabBarActive,
              backgroundColor: tokens.homeProgressBackground,
            ),
        ],
      ),
    );
  }
}
