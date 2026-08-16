import 'package:flutter/material.dart' hide Text;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import '../../core/services/open_food_facts_service.dart';

class HalalIngredientPage extends StatefulWidget {
  const HalalIngredientPage({super.key});
  @override State<HalalIngredientPage> createState() => _HalalIngredientPageState();
}

class _HalalIngredientPageState extends State<HalalIngredientPage> {
  final _service = OpenFoodFactsService();
  final _controller = TextEditingController();
  FoodProduct? _product;
  bool _loading = false;
  String? _error;

  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _lookup([String? value]) async {
    final barcode = (value ?? _controller.text).trim();
    if (barcode.isEmpty) return;
    setState(() { _loading = true; _error = null; _product = null; });
    try {
      final product = await _service.lookup(barcode);
      if (!mounted) return;
      _controller.text = product.barcode;
      setState(() { _product = product; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = AppI18n.current('পণ্য পাওয়া যায়নি বা ইন্টারনেট সংযোগ নেই।'); });
    }
  }

  Future<void> _scan() async {
    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()));
    if (result != null && mounted) _lookup(result);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('হালাল উপাদান সহায়ক')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('বারকোড স্ক্যান করে উপাদান যাচাই করুন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Noorvia কোনো পণ্যকে হালাল/হারাম ঘোষণা করে না। এটি শুধু ingredient list-এ সম্ভাব্য concern দেখায়—চূড়ান্ত সিদ্ধান্তের জন্য বিশ্বস্ত হালাল সার্টিফিকেশন বা আলেমের পরামর্শ নিন.'),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: AppI18n.current('বারকোড নম্বর'), border: const OutlineInputBorder()),
                    onSubmitted: (_) => _lookup(),
                  )),
                  const SizedBox(width: 10),
                  IconButton.filled(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner), tooltip: AppI18n.current('ক্যামেরা দিয়ে স্ক্যান করুন')),
                ]),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading ? null : _lookup, icon: const Icon(Icons.search), label: const Text('পণ্য খুঁজুন'))),
              ]),
            ),
          ),
          if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.all(20), child: Text(_error!, textAlign: TextAlign.center)),
          if (_product != null) _ProductView(product: _product!),
          const SizedBox(height: 16),
          const Card(child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('Data: Open Food Facts (community-maintained). Ingredient data অসম্পূর্ণ বা ভুল হতে পারে। Offline-এ আগে দেখা পণ্য Isar cache থেকে খোলা যাবে.'),
          )),
        ],
      ),
    );
  }
}

class _ProductView extends StatelessWidget {
  final FoodProduct product;
  const _ProductView({required this.product});
  @override Widget build(BuildContext context) {
    final concerns = product.concernMatches;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (product.imageUrl != null) Center(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(product.imageUrl!, height: 160, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
          Text(product.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (product.brand != null) Text(product.brand!),
          if (product.nutriScore != null) Padding(padding: const EdgeInsets.only(top: 8), child: Chip(label: Text('Nutri-Score ${product.nutriScore}'))),
          const Divider(height: 28),
          const Text('উপাদান', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 6),
          Text(product.ingredients.isEmpty ? AppI18n.current('উপাদানের তথ্য পাওয়া যায়নি') : product.ingredients, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            Icon(concerns.isEmpty ? Icons.info_outline : Icons.warning_amber_rounded, color: concerns.isEmpty ? Colors.blue : Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(concerns.isEmpty ? AppI18n.current('স্বয়ংক্রিয় concern keyword পাওয়া যায়নি') : AppI18n.current('সম্ভাব্য concern — উৎস যাচাই করুন'), style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          if (concerns.isNotEmpty) ...concerns.map((c) => Padding(padding: const EdgeInsets.only(top: 7, left: 30), child: Text('• $c'))),
          if (product.allergens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('${AppI18n.current('অ্যালার্জেন')}: ${product.allergens.join(', ')}'),
          ],
        ]),
      ),
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();
  @override State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  bool _done = false;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('বারকোড স্ক্যান করুন')),
    body: Stack(children: [
      MobileScanner(
        onDetect: (capture) {
          if (_done || capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value == null || value.isEmpty) return;
          _done = true;
          Navigator.pop(context, value);
        },
      ),
      IgnorePointer(child: Center(child: Container(width: 280, height: 170, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(18))))),
      const Positioned(left: 24, right: 24, bottom: 42, child: Card(color: Colors.black54, child: Padding(padding: EdgeInsets.all(12), child: Text('পণ্যের বারকোডটি বক্সের মধ্যে রাখুন', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))))),
    ]),
  );
}
