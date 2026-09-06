import 'dart:io' show Platform;

import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/theme/app_theme.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, required this.title});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;
  var _progress = 0;
  var _canGoBack = false;
  var _canGoForward = false;

  bool get _supportsEmbeddedWebView =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (!_supportsEmbeddedWebView) return;

    _controller = _createBrowserController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onUrlChange: (change) {
            _updateNavigationState();
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _progress = 0;
              });
            }
            _updateNavigationState();
          },
          onPageFinished: (url) async {
            if (mounted) {
              setState(() => _progress = 100);
            }
            await _injectBrowserBehavior();
            await _updateNavigationState();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _configurePlatformController(_controller!);
  }

  WebViewController _createBrowserController() {
    var params = const PlatformWebViewControllerCreationParams();

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params =
          WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
            allowsInlineMediaPlayback: true,
            javaScriptCanOpenWindowsAutomatically: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params =
          AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    }

    return WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    );
  }

  Future<void> _configurePlatformController(
    WebViewController controller,
  ) async {
    await controller.enableZoom(true);
    await controller.setUserAgent(_browserUserAgent);

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await AndroidWebViewController.enableDebugging(true);
      await platform.setMediaPlaybackRequiresUserGesture(false);
      await platform.setTextZoom(100);
      await platform.setUseWideViewPort(true);
      await platform.setAllowContentAccess(true);
      await platform.setGeolocationEnabled(true);
      await platform.setMixedContentMode(MixedContentMode.compatibilityMode);
      await platform.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (_) async =>
            const GeolocationPermissionsResponse(allow: true, retain: true),
      );

      final cookieManager = WebViewCookieManager().platform;
      if (cookieManager is AndroidWebViewCookieManager) {
        await cookieManager.setAcceptThirdPartyCookies(platform, true);
      }
    }
  }

  String get _browserUserAgent {
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    }
    if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
          'Mobile/15E148 Safari/604.1';
    }
    return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';
  }

  Future<void> _injectBrowserBehavior() async {
    try {
      await _controller?.runJavaScript('''
        (function () {
          window.open = function (url) {
            if (url) window.location.href = url;
            return window;
          };
          document.querySelectorAll('a[target="_blank"], form[target="_blank"]').forEach(function (el) {
            el.setAttribute('target', '_self');
          });
        })();
      ''');
    } catch (_) {
      // Some pages block injected scripts; the WebView still works normally.
    }
  }

  Future<void> _updateNavigationState() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<bool> _handleBack() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  Future<void> _openFallback() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _goHome() async {
    await _controller?.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _goBackInWebView() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  Future<void> _goForwardInWebView() async {
    final controller = _controller;
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _handleBack() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _controller?.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _supportsEmbeddedWebView
            ? _buildWebView()
            : _UnsupportedWebView(url: widget.url, onOpen: _openFallback),
      ),
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        if (_progress < 100)
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress / 100,
            color: AppColors.primary,
            minHeight: 2,
          ),
        Expanded(child: WebViewWidget(controller: _controller!)),
        SafeArea(
          top: false,
          child: Container(
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E6E2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: _canGoBack ? _goBackInWebView : null,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                IconButton(
                  tooltip: 'Forward',
                  onPressed: _canGoForward ? _goForwardInWebView : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                ),
                IconButton(
                  tooltip: 'Home',
                  onPressed: _goHome,
                  icon: const Icon(Icons.home_outlined, size: 22),
                ),
                IconButton(
                  tooltip: 'Reload',
                  onPressed: () => _controller?.reload(),
                  icon: const Icon(Icons.refresh, size: 22),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnsupportedWebView extends StatelessWidget {
  final String url;
  final VoidCallback onOpen;

  const _UnsupportedWebView({required this.url, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.web_asset_off, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'এই ডিভাইসে ইন-অ্যাপ WebView সাপোর্ট নেই।',
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
