import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════

class BookNode {
  final String name;
  final String id;
  final String type; // "file" or "folder"
  final String? mimeType;
  final String? size;
  final String? url;
  final List<BookNode> children;

  const BookNode({
    required this.name,
    required this.id,
    required this.type,
    this.mimeType,
    this.size,
    this.url,
    this.children = const [],
  });

  bool get isFolder => type == 'folder';
  bool get isFile => type == 'file';

  factory BookNode.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'file';
    final rawChildren = json['children'];
    final children = (rawChildren is List)
        ? rawChildren
            .whereType<Map<String, dynamic>>()
            .map((c) => BookNode.fromJson(c))
            .toList()
        : <BookNode>[];

    return BookNode(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      type: type,
      mimeType: json['mimeType']?.toString(),
      size: json['size']?.toString(),
      url: json['url']?.toString(),
      children: children,
    );
  }

  int get totalFiles {
    if (isFile) return 1;
    return children.fold(0, (sum, c) => sum + c.totalFiles);
  }
}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

String _formatSize(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final bytes = int.tryParse(raw);
  if (bytes == null) return raw;
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

String _toDownloadUrl(String viewUrl) {
  final regex = RegExp(r'/file/d/([^/]+)/');
  final match = regex.firstMatch(viewUrl);
  if (match != null) {
    final fileId = match.group(1)!;
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }
  return viewUrl;
}

Future<void> _launchLink(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ═══════════════════════════════════════════════════════════════
// Page
// ═══════════════════════════════════════════════════════════════

class IslamicBooksPage extends StatefulWidget {
  const IslamicBooksPage({super.key});

  @override
  State<IslamicBooksPage> createState() => _IslamicBooksPageState();
}

class _IslamicBooksPageState extends State<IslamicBooksPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamci_book.json';
  static const _cacheKey = 'islamic_books_cache';

  BookNode? _root;
  bool _loading = true;
  String? _error;
  bool _offline = false;

  final List<BookNode> _folderStack = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও (no wait) ─────────────
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final root = BookNode.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _root = root;
            _folderStack
              ..clear()
              ..add(root);
            _loading = false;
            _offline = true; // assume offline until network confirms
          });
        }
      } catch (_) {}
    }

    // ── ২. Network থেকে silent refresh ───────────────────────
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        final root = BookNode.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        await prefs.setString(_cacheKey, raw);
        if (mounted) {
          setState(() {
            _root = root;
            _folderStack
              ..clear()
              ..add(root);
            _loading = false;
            _offline = false; // fresh data — go online
          });
        }
        return;
      }
    } catch (_) {}

    // ── ৩. Network failed — stay on cache or show error ───────
    if (mounted) {
      if (_root != null) {
        // already showing cached data, just keep offline banner
        setState(() {
          _loading = false;
          _offline = true;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'ডেটা লোড করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        });
      }
    }
  }

  void _openFolder(BookNode folder) {
    setState(() {
      _folderStack.add(folder);
      _searchCtrl.clear();
    });
  }

  void _goBack() {
    if (_folderStack.length > 1) {
      setState(() {
        _folderStack.removeLast();
        _searchCtrl.clear();
      });
    }
  }

  BookNode get _currentFolder => _folderStack.last;

  List<BookNode> get _currentChildren {
    final children = _currentFolder.children;
    if (_searchQuery.isEmpty) return children;
    return children
        .where((n) => n.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: _buildAppBar(isDark),
      body: _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final canGoBack = _folderStack.length > 1;
    final title = canGoBack ? _currentFolder.name : 'ইসলামিক কিতাব';

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: _goBack,
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (_offline)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.wifi_off_rounded, size: 20, color: Colors.white70),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            _folderStack.clear();
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_root == null) return const SizedBox.shrink();

    return Column(
      children: [
        // ── Offline banner ──────────────────────────────────
        if (_offline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: Colors.orange.withOpacity(0.15),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 11, color: Colors.orange),
                  ),
                ),
                GestureDetector(
                  onTap: _loadData,
                  child: Text(
                    'রিফ্রেশ',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildSearchBar(isDark),
        Expanded(child: _buildList(isDark)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.hindSiliguri(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'খুঁজুন...',
          hintStyle: GoogleFonts.hindSiliguri(color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    final items = _currentChildren;

    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'কোনো ফলাফল পাওয়া যায়নি'
              : 'এখানে কিছু নেই',
          style: GoogleFonts.hindSiliguri(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final sorted = [...items]
      ..sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.compareTo(b.name);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _buildItem(sorted[index], isDark),
    );
  }

  Widget _buildItem(BookNode node, bool isDark) {
    return node.isFolder
        ? _buildFolderTile(node, isDark)
        : _buildFileTile(node, isDark);
  }

  Widget _buildFolderTile(BookNode node, bool isDark) {
    final count = node.totalFiles;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isDark
          ? Colors.white10
          : AppColors.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_rounded,
              color: AppColors.primary, size: 26),
        ),
        title: Text(
          node.name,
          style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: count > 0
            ? Text(
                '$count টি ফাইল',
                style:
                    GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        onTap: () => _openFolder(node),
      ),
    );
  }

  Widget _buildFileTile(BookNode node, bool isDark) {
    final isPdf = node.mimeType?.contains('pdf') == true ||
        node.name.toLowerCase().endsWith('.pdf');
    final sizeStr = _formatSize(node.size);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPdf
                ? Colors.red.withOpacity(0.12)
                : AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.insert_drive_file_rounded,
            color: isPdf ? Colors.red : AppColors.primary,
            size: 26,
          ),
        ),
        title: Text(
          node.name,
          style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: sizeStr.isNotEmpty
            ? Text(
                sizeStr,
                style:
                    GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing: node.url != null
            ? IconButton(
                icon: const Icon(Icons.download_rounded,
                    color: AppColors.primary),
                onPressed: () => _launchLink(_toDownloadUrl(node.url!)),
              )
            : null,
        onTap: node.url != null
            ? () => _launchLink(_toDownloadUrl(node.url!))
            : null,
      ),
    );
  }
}
