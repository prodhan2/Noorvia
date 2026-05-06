import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';

// ─── Google Maps WebView ──────────────────────────────────────

class GoogleMapsView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String cityName;

  const GoogleMapsView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  @override
  State<GoogleMapsView> createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'ম্যাপ লোড করতে ব্যর্থ',
                  style: GoogleFonts.hindSiliguri(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.google.com/maps/embed/v1/place'
          '?key=AIzaSyDKRX-dHWbHJrwVIWnbVgbJvJmVVKvvfqE'
          '&q=${widget.latitude},${widget.longitude}'
          '&zoom=12',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'গুগল ম্যাপ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              widget.cityName,
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
