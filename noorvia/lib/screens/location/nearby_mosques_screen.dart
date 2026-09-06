import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:noorvia/core/localization/app_i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/mosque.dart';
import '../../core/services/mosque_service.dart';
import '../../core/services/mosque_route_service.dart';

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});
  @override State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  final _mosqueService = MosqueService();
  final _routeService = MosqueRouteService();
  List<Mosque> _items = const [];
  bool _loading = true;
  String? _error;
  int _radius = 5000;
  double? _lat;
  double? _lon;
  bool _showMusalla = true;

  @override void initState() { super.initState(); _load(); }
  bool get _english => AppI18n.current('মসজিদ') == 'Mosque';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await _mosqueService.getCurrentLocation();
      final rows = await _mosqueService.getNearbyMosquesWithCache(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusInMeters: _radius,
        onBackgroundRefresh: (fresh) { if (mounted) setState(() => _items = fresh); },
      );
      if (!mounted) return;
      setState(() { _lat = pos.latitude; _lon = pos.longitude; _items = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  List<Mosque> get _visible => _showMusalla ? _items : _items.where((m) => m.type == 'mosque').toList();

  Future<void> _openOsmAttribution() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _navigate(Mosque m) async {
    final uri = Uri.parse(m.getGoogleMapsUrl());
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showDetails(Mosque m) async {
    WalkingRouteEstimate? route;
    if (_lat != null && _lon != null) route = await _routeService.estimate(fromLat: _lat!, fromLon: _lon!, mosque: m);
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(avatar: Icon(m.type == 'musalla' ? Icons.meeting_room : Icons.mosque, size: 18), label: Text(m.type == 'musalla' ? 'মুসাল্লা / Prayer room' : 'মসজিদ / Mosque')),
          Chip(avatar: const Icon(Icons.directions_walk, size: 18), label: Text('${route?.durationMinutes ?? m.estimatedWalkMinutes} ${AppI18n.current('মিনিট হাঁটা')}${route?.routed == true ? ' • ORS' : ''}')),
          if (m.wheelchair) const Chip(avatar: Icon(Icons.accessible, size: 18), label: Text('Wheelchair')),
          if (m.hasWuduHint) const Chip(avatar: Icon(Icons.water_drop_outlined, size: 18), label: Text('Wudu hint')),
          if (m.level != null) Chip(label: Text('${AppI18n.current('লেভেল')}: ${m.level}')),
        ]),
        if (m.address != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(m.address!)),
        if (m.openingHours != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('${AppI18n.current('খোলার সময়')}: ${m.openingHours}')),
        if (m.serviceTimes != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${AppI18n.current('সার্ভিস/জামাত তথ্য')}: ${m.serviceTimes}')),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _navigate(m), icon: const Icon(Icons.directions_walk), label: const Text('হেঁটে যাওয়ার পথ খুলুন'))),
        const SizedBox(height: 6),
        const Text('Walking time ORS key থাকলে routed ETA; না থাকলে straight-line distance ভিত্তিক offline estimate.', style: TextStyle(fontSize: 12)),
      ]),
    )));
  }

  void _radiusSheet() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const ListTile(title: Text('অনুসন্ধান পরিসীমা')),
    for (final r in [1000, 3000, 5000, 10000, 20000]) RadioListTile<int>(value: r, groupValue: _radius, title: Text(r < 1000 ? '$r m' : '${r ~/ 1000} km'), onChanged: (v) { if (v == null) return; Navigator.pop(context); setState(() => _radius = v); _load(); }),
  ])));

  @override Widget build(BuildContext context) {
    final rows = _visible;
    return Scaffold(
      appBar: AppBar(title: const Text('মসজিদ ও মুসাল্লা'), actions: [
        IconButton(onPressed: _radiusSheet, icon: const Icon(Icons.tune), tooltip: AppI18n.current('অনুসন্ধান পরিসীমা')),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: AppI18n.current('রিফ্রেশ করুন')),
      ]),
      body: Column(children: [
        SwitchListTile(
          title: const Text('মুসাল্লা / Prayer room দেখান'),
          subtitle: const Text('Airport, mall, hospital, office-এর prayer room-ও দেখাবে'),
          value: _showMusalla,
          onChanged: (v) => setState(() => _showMusalla = v),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _openOsmAttribution,
            icon: const Icon(Icons.public_rounded, size: 16),
            label: const Text('© OpenStreetMap contributors'),
          ),
        ),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null) Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_off, size: 54), const SizedBox(height: 10), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
        ]))))
        else if (rows.isEmpty) const Expanded(child: Center(child: Text('এই পরিসীমায় কোনো মসজিদ বা মুসাল্লা পাওয়া যায়নি')))
        else Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final m = rows[i];
            return Card(child: ListTile(
              onTap: () => _showDetails(m),
              leading: CircleAvatar(child: Icon(m.type == 'musalla' ? Icons.meeting_room : Icons.mosque)),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text('${m.getFormattedDistance(english: _english)} • ~${m.estimatedWalkMinutes} ${AppI18n.current('মিনিট হাঁটা')}'),
                if (m.address != null) Text(m.address!, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (m.serviceTimes != null) Text(m.serviceTimes!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
              trailing: IconButton(onPressed: () => _navigate(m), icon: const Icon(Icons.directions)),
            ));
          },
        )),
      ]),
    );
  }
}
