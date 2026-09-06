import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/poster_model.dart';

class PosterDetailsScreen extends StatefulWidget {
  final PosterModel poster;

  const PosterDetailsScreen({super.key, required this.poster});

  @override
  State<PosterDetailsScreen> createState() => _PosterDetailsScreenState();
}

class _PosterDetailsScreenState extends State<PosterDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 200 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Professional AppBar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            elevation: 0,
            backgroundColor: _isScrolled
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isScrolled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isScrolled
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _showShareOptions(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: _isScrolled
                  ? Text(
                      'পোস্টার #${widget.poster.no}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  Hero(
                    tag: 'poster_${widget.poster.no}',
                    child: CachedNetworkImage(
                      imageUrl: widget.poster.imglink,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            SizedBox(height: 8),
                            Text('ছবি লোড করা যায়নি'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Poster Number Badge
                  if (!_isScrolled)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image, size: 18, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'পোস্টার #${widget.poster.no}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  
                  // Details Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.article,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'বিস্তারিত তথ্য',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Markdown Content with Full Width and Justify
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: MarkdownBody(
                            data: widget.poster.details,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              // Headings
                              h1: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              h2: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              h3: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              h4: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              h5: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              h6: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                height: 1.2,
                              ),
                              // Paragraph with Justify Alignment
                              p: const TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: Colors.black87,
                                letterSpacing: 0.3,
                              ),
                              // Text styles
                              strong: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              em: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                              del: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                              // Links
                              a: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                              // Lists
                              listBullet: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              listBulletPadding: const EdgeInsets.only(right: 8),
                              listIndent: 24,
                              // Code
                              code: TextStyle(
                                backgroundColor: Colors.grey[200],
                                color: Colors.red[700],
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              codeblockPadding: const EdgeInsets.all(16),
                              codeblockDecoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 1,
                                ),
                              ),
                              // Blockquote
                              blockquote: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                                fontSize: 15,
                                height: 1.6,
                              ),
                              blockquotePadding: const EdgeInsets.all(16),
                              blockquoteDecoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.blue,
                                    width: 4,
                                  ),
                                ),
                              ),
                              // Horizontal rule
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Tables
                              tableHead: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              tableBody: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              tableBorder: TableBorder.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              tableCellsPadding: const EdgeInsets.all(12),
                              // Spacing
                              h1Padding: const EdgeInsets.only(top: 20, bottom: 12),
                              h2Padding: const EdgeInsets.only(top: 18, bottom: 10),
                              h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
                              h4Padding: const EdgeInsets.only(top: 14, bottom: 6),
                              h5Padding: const EdgeInsets.only(top: 12, bottom: 6),
                              h6Padding: const EdgeInsets.only(top: 10, bottom: 4),
                              pPadding: const EdgeInsets.only(bottom: 16),
                              blockSpacing: 12,
                              // Text alignment - Justify
                              textAlign: WrapAlignment.start,
                              textScaleFactor: 1.0,
                            ),
                            onTapLink: (text, href, title) {
                              if (href != null) {
                                _launchUrl(href);
                              }
                            },
                            imageBuilder: (uri, title, alt) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: uri.toString(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image,
                                              size: 48, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Text(
                                            alt ?? 'Image',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'share',
            onPressed: () => _showShareOptions(context),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'download',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ডাউনলোড শুরু হচ্ছে...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'শেয়ার করুন',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Share options
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image, color: Colors.blue),
              ),
              title: const Text('ছবি শেয়ার করুন'),
              subtitle: const Text('পোস্টার ছবি শেয়ার করুন'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ছবি শেয়ার করা হচ্ছে...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.text_fields, color: Colors.green),
              ),
              title: const Text('টেক্সট শেয়ার করুন'),
              subtitle: const Text('বিস্তারিত তথ্য শেয়ার করুন'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('টেক্সট শেয়ার করা হচ্ছে...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, color: Colors.orange),
              ),
              title: const Text('লিংক কপি করুন'),
              subtitle: const Text('পোস্টার লিংক কপি করুন'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('লিংক কপি করা হয়েছে'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
