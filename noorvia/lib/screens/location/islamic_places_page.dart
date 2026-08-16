import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/islamic_places_service.dart';
import '../../core/services/mosque_service.dart';

class IslamicPlacesPage extends StatefulWidget {
  const IslamicPlacesPage({super.key});
  @override State<IslamicPlacesPage> createState() => _IslamicPlacesPageState();
}

class _IslamicPlacesPageState extends State<IslamicPlacesPage> {
  final _places = IslamicPlacesService();
  final _location = MosqueService();
  List<IslamicPlaceArticle> _items = const [];
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await _location.getCurrentLocation();
      final rows = await _places.nearby(lat: pos.latitude, lon: pos.longitude, english: AppI18n.current('হোম') == 'Home');
      if (!mounted) return;
      setState(() { _items = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = AppI18n.current('কাছাকাছি ইসলামিক স্থান লোড করা যায়নি।'); });
    }
  }

  Future<void> _open(IslamicPlaceArticle a) async {
    final lang = AppI18n.current('হোম') == 'Home' ? 'en' : 'bn';
    final uri = Uri.parse('https://$lang.wikipedia.org/?curid=${a.pageId}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ইসলামিক স্থান এক্সপ্লোরার'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
      : _items.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('১০ কিলোমিটারের মধ্যে Wikipedia-তে বর্ণিত ইসলামিক স্থান পাওয়া যায়নি।')))
      : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final a = _items[i];
          return Card(child: InkWell(onTap: () => _open(a), child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (a.thumbnail != null) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(a.thumbnail!, width: 92, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 92, height: 92, child: Icon(Icons.mosque))))
              else const SizedBox(width: 92, height: 92, child: Icon(Icons.mosque, size: 42)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(a.extract ?? '', maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                const Row(children: [Icon(Icons.open_in_new, size: 14), SizedBox(width: 4), Text('Wikipedia / Wikimedia', style: TextStyle(fontSize: 12))]),
              ])),
            ]),
          )));
        },
      ),
  );
}
