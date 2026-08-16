import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';

import '../../core/quran/quran_goal_service.dart';
import '../../core/theme/app_theme.dart';

class QuranGoalsPage extends StatefulWidget {
  const QuranGoalsPage({super.key});

  @override
  State<QuranGoalsPage> createState() => _QuranGoalsPageState();
}

class _QuranGoalsPageState extends State<QuranGoalsPage> {
  QuranGoalPlan? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await QuranGoalService.instance.load();
    final lastPage = await QuranGoalService.instance.lastReadPage();
    var resolved = plan;
    if (lastPage != null && lastPage > plan.currentPage) {
      resolved = await QuranGoalService.instance.setCurrentPage(plan, lastPage);
    }
    if (!mounted) return;
    setState(() {
      _plan = resolved;
      _loading = false;
    });
  }

  Future<void> _newPlan(int days) async {
    final lastPage = await QuranGoalService.instance.lastReadPage() ?? 1;
    final plan = await QuranGoalService.instance.createPlan(days: days, startPage: lastPage);
    if (mounted) setState(() => _plan = plan);
  }

  Future<void> _changePage(int delta) async {
    final plan = _plan;
    if (plan == null) return;
    final updated = await QuranGoalService.instance.setCurrentPage(plan, plan.currentPage + delta);
    if (mounted) setState(() => _plan = updated);
  }

  Future<void> _changeHifz(int delta) async {
    final plan = _plan;
    if (plan == null) return;
    final updated = await QuranGoalService.instance.addHifz(plan, delta);
    if (mounted) setState(() => _plan = updated);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBg : const Color(0xFFF4F1E8);
    final card = dark ? AppColors.darkCard : Colors.white;
    final plan = _plan;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('কুরআন লক্ষ্য ও হিফজ')),
      body: _loading || plan == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A4A2D), Color(0xFF19754B)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('খতম প্ল্যান', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        '${(plan.progress * 100).toStringAsFixed(0)}% সম্পন্ন',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: plan.progress.clamp(0, 1),
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(99),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'পৃষ্ঠা ${plan.currentPage} • বাকি ${plan.pagesRemaining} পৃষ্ঠা • লক্ষ্য ${plan.dailyTargetPages} পৃষ্ঠা/দিন',
                        style: const TextStyle(color: Colors.white, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('আজকের পড়া আপডেট করুন', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('বর্তমান পৃষ্ঠা: ${plan.currentPage}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _changePage(-1), icon: const Icon(Icons.remove), label: const Text('১ পৃষ্ঠা'))),
                          const SizedBox(width: 8),
                          Expanded(child: FilledButton.icon(onPressed: () => _changePage(1), icon: const Icon(Icons.add), label: const Text('১ পৃষ্ঠা'))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _changePage(plan.dailyTargetPages),
                          icon: const Icon(Icons.done_all_rounded),
                          label: Text('আজকের ${plan.dailyTargetPages} পৃষ্ঠা সম্পন্ন'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('প্ল্যান পরিবর্তন', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [7, 15, 30, 60, 90].map((days) => ActionChip(
                          avatar: const Icon(Icons.calendar_month_rounded, size: 17),
                          label: Text('$days দিনে খতম'),
                          onPressed: () => _newPlan(days),
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'বর্তমান reading page থেকে নতুন plan শুরু হবে। ৬০৪-পৃষ্ঠার মুসহাফ ভিত্তিতে দৈনিক লক্ষ্য স্বয়ংক্রিয়ভাবে হিসাব করা হয়।',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('হিফজ ট্র্যাকার', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                          Text('${plan.hifzCompletedAyahs} আয়াত', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('মুখস্থ করা আয়াতের মোট সংখ্যা local-first ভাবে সংরক্ষণ করুন।'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => _changeHifz(-1), child: const Text('− ১ আয়াত'))),
                          const SizedBox(width: 8),
                          Expanded(child: FilledButton(onPressed: () => _changeHifz(1), child: const Text('+ ১ আয়াত'))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () => _changeHifz(plan.hifzDailyAyahs),
                          child: Text('আজকের লক্ষ্য +${plan.hifzDailyAyahs} আয়াত'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: .08)),
        ),
        child: child,
      );
}
