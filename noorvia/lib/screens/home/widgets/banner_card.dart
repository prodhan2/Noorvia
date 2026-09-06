import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import '../../../widgets/poster_carousel_widget.dart';

class BannerCard extends StatelessWidget {
  final bool isDark;

  const BannerCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ✅ এখন API থেকে poster images load হবে
    // ✅ Auto slide হবে
    // ✅ Click করলে details page খুলবে
    return const PosterCarouselWidget(
      height: 180,
      autoSlide: true,
      autoSlideDuration: Duration(seconds: 4),
      showIndicator: true,
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.all(Radius.circular(18)),
    );
  }
}
