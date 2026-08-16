import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import '../../core/models/hadith_record.dart';
import '../../core/services/hadith_service.dart';
import '../../core/data/local/local_store.dart';

class HadithDemoPage extends StatefulWidget {
  final String initialBook;
  const HadithDemoPage({super.key, this.initialBook = 'bukhari'});

  @override
  State<HadithDemoPage> createState() => _HadithDemoPageState();
}

class _HadithDemoPageState extends State<HadithDemoPage> {
  final _service = HadithService();
  final _search = TextEditingController();
  late String _book;
  List<HadithRecord> _all = const [];
  List<HadithRecord> _visible = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _book = HadithService.books.any((b) => b.key == widget.initialBook)
        ? widget.initialBook
        : 'bukhari';
    _loadBookmarks();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _english => AppI18n.current('হাদিস') == 'Hadith';

  Future<void> _loadBookmarks() async {
    final data = await LocalStore.instance.getJson('hadith_user', 'bookmarks');
    if (!mounted) return;
    setState(() => _bookmarks.addAll((data?['items'] as List?)?.map((e) => e.toString()) ?? const []));
  }

  Future<void> _saveBookmarks() => LocalStore.instance.putJson(
        'hadith_user',
        'bookmarks',
        {'items': _bookmarks.toList()},
      );

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.loadBook(bookKey: _book, english: _english, forceRefresh: refresh);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _visible = rows.take(300).toList();
        _loading = false;
      });
      _filter(_search.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppI18n.current('হাদিস লোড করা যায়নি। ইন্টারনেট চেক করুন।');
      });
    }
  }

  void _filter(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _visible = _all.take(300).toList();
      } else {
        _visible = _all.where((h) =>
          h.number.toString() == query ||
          h.text.toLowerCase().contains(query) ||
          (h.sectionName ?? '').toLowerCase().contains(query)
        ).take(500).toList();
      }
    });
  }

  Future<void> _showDetails(HadithRecord h) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HadithDetails(record: h, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = HadithService.books.firstWhere((b) => b.key == _book);
    return Scaffold(
      appBar: AppBar(
        title: const Text('হাদিস সংগ্রহ'),
        actions: [
          IconButton(onPressed: () => _load(refresh: true), icon: const Icon(Icons.refresh), tooltip: AppI18n.current('রিফ্রেশ করুন')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: DropdownButtonFormField<String>(
              value: _book,
              decoration: InputDecoration(labelText: AppI18n.current('হাদিসের কিতাব'), border: const OutlineInputBorder()),
              items: HadithService.books.map((b) => DropdownMenuItem(
                value: b.key,
                child: Text(_english ? b.enName : b.bnName),
              )).toList(),
              onChanged: (v) {
                if (v == null || v == _book) return;
                setState(() => _book = v);
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: AppI18n.current('হাদিসের শব্দ, অধ্যায় বা নম্বর দিয়ে খুঁজুন...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); _filter(''); }),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Expanded(child: Text('${_english ? book.enName : book.bnName} • ${_all.length} ${AppI18n.current('হাদিস')}')),
              const Icon(Icons.offline_bolt, size: 18),
              const SizedBox(width: 4),
              const Text('অফলাইন ক্যাশ'),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'উৎস: Hadith API open corpus। গ্রেড/রেফারেন্স গুরুত্বপূর্ণ হলে বিশ্বস্ত মুদ্রিত সংস্করণ বা আলেমের মাধ্যমে যাচাই করুন।',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null) Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
          ]))))
          else Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: _visible.length,
              itemBuilder: (_, i) {
                final h = _visible[i];
                final id = '${h.bookKey}:${h.number}';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDetails(h),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Chip(label: Text('#${h.number}')),
                          const SizedBox(width: 8),
                          Expanded(child: Text(h.sectionName ?? h.bookName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            icon: Icon(_bookmarks.contains(id) ? Icons.bookmark : Icons.bookmark_border),
                            onPressed: () { setState(() => _bookmarks.contains(id) ? _bookmarks.remove(id) : _bookmarks.add(id)); _saveBookmarks(); },
                          ),
                        ]),
                        Text(h.text, maxLines: 7, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.55)),
                        if (h.grades.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(h.grades.take(2).join(' • '), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithDetails extends StatefulWidget {
  final HadithRecord record;
  final HadithService service;
  const _HadithDetails({required this.record, required this.service});
  @override State<_HadithDetails> createState() => _HadithDetailsState();
}

class _HadithDetailsState extends State<_HadithDetails> {
  String? _arabic;
  bool _loadingArabic = false;

  Future<void> _loadArabic() async {
    setState(() => _loadingArabic = true);
    final text = await widget.service.loadArabic(widget.record.bookKey, widget.record.number);
    if (!mounted) return;
    setState(() { _arabic = text; _loadingArabic = false; });
  }

  @override Widget build(BuildContext context) {
    final h = widget.record;
    return SafeArea(child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .45,
      maxChildSize: .96,
      builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.all(20), children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 16),
        Text('${h.bookName} • #${h.number}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (h.sectionName != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(h.sectionName!, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 18),
        Text(h.text, style: const TextStyle(fontSize: 17, height: 1.65)),
        const SizedBox(height: 18),
        if (_arabic != null) Text(_arabic!, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'NooreHuda', fontSize: 25, height: 1.8))
        else FilledButton.tonalIcon(onPressed: _loadingArabic ? null : _loadArabic, icon: _loadingArabic ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.translate), label: const Text('আরবি মূল পাঠ দেখুন')),
        if (h.grades.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('${AppI18n.current('গ্রেড')}: ${h.grades.join(' • ')}'),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () async { await Clipboard.setData(ClipboardData(text: '${h.text}\n\n${h.bookName} #${h.number}')); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কপি করা হয়েছে'))); },
          icon: const Icon(Icons.copy),
          label: const Text('কপি করুন'),
        ),
      ]),
    ));
  }
}
