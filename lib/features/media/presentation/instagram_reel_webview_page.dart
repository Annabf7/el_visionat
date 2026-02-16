import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class InstagramReelWebviewPage extends StatefulWidget {
  final String reelUrl;
  final String? title;

  const InstagramReelWebviewPage({
    super.key,
    required this.reelUrl,
    this.title,
  });

  @override
  State<InstagramReelWebviewPage> createState() =>
      _InstagramReelWebviewPageState();
}

class _InstagramReelWebviewPageState extends State<InstagramReelWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final sanitizedUrl = _sanitizeUrl(widget.reelUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // En iOS/Android alguns errors no són crítics, però si no carrega res...
            // Deixem que l'usuari vegi el botó de fallback si la pantalla queda en blanc o error.
          },
          onNavigationRequest: (NavigationRequest request) {
            // Bloquejar navegació fora d'Instagram si calgués, però per ara permetem tot.
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(sanitizedUrl));
  }

  String _sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    try {
      final uri = Uri.parse(url);
      // Reconstruir sense query params (elimina ?igsh=...)
      return Uri(scheme: uri.scheme, host: uri.host, path: uri.path).toString();
    } catch (_) {
      return url;
    }
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.reelUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.porpraFosc,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Clip',
          style: const TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.porpraFosc,
        foregroundColor: AppTheme.mostassa,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // WebView
          if (!_hasError) WebViewWidget(controller: _controller),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.mostassa),
            ),

          // Fallback UI (sempre visible si hi ha error o com a opció flotant)
          // Aquí optem per posar un botó flotant discret o una pantalla d'error si falla tot.
          // Com que detectar fallada de càrrega web exacta és complex,
          // posem un botó a la barra inferior o flotant per si de cas.
        ],
      ),
      // Botó persistent per obrir a Instagram si el WebView falla o no es veu bé
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchExternal,
        backgroundColor: AppTheme.mostassa,
        foregroundColor: AppTheme.porpraFosc,
        icon: const Icon(Icons.open_in_new),
        label: const Text('Obrir a Instagram'),
      ),
    );
  }
}
