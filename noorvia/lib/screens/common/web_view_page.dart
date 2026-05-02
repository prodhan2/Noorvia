import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Opens [url] in the system's in-app browser (Chrome Custom Tab on Android,
/// SFSafariViewController on iOS).  Falls back to the external browser if
/// in-app mode is unavailable.
Future<void> openWebPage(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.parse(url);

  // Try in-app browser first (Chrome Custom Tab / SFSafari)
  if (await canLaunchUrl(uri)) {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (launched) return;
  }

  // Fallback: external browser
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A simple wrapper page that shows a loading indicator while the
/// in-app browser is being prepared.  On most devices the system browser
/// opens on top of this page, so this widget is mostly a visual placeholder.
class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  @override
  void initState() {
    super.initState();
    // Launch immediately and pop this page once done
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await openWebPage(
        context,
        url: widget.url,
        title: widget.title,
      );
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
