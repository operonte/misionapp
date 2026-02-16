import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../app_config.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final WebViewController _controller = WebViewController()
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {},
      ),
    )
    ..loadRequest(Uri.parse(termsOfUseUrl));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos de uso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
