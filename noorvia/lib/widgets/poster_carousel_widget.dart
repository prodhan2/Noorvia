import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/poster_model.dart';
import '../services/poster_service.dart';
import '../screens/poster_details_screen.dart';
import 'poster_shimmer_widget.dart';

class PosterCarouselWidget extends StatefulWidget {
  final double height;
  final bool autoSlide;
  final Duration autoSlideDuration;
  final bool showIndicator;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const PosterCarouselWidget({
    super.key,
    this.height = 200,
    this.autoSlide = true,
    this.autoSlideDuration = const Duration(seconds: 3),
    this.showIndicator = true,
    this.borderRadius,
    this.margin,
  });

  @override
  State<PosterCarouselWidget> createState() => _PosterCarouselWidgetState();
}

class _PosterCarouselWidgetState extends State<PosterCarouselWidget> {
  final PosterService _posterService = PosterService();
  final PageController _pageController = PageController();
  List<PosterModel> _posters = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;
  bool _autoSlideEnabled = true;
  bool _showShimmer = true;
  StreamSubscription<List<PosterModel>>? _posterSubscription;

  @override
  void initState() {
    super.initState();
    _autoSlideEnabled = widget.autoSlide;
    _loadPosters();
    _posterSubscription = _posterService.watchPosters().listen((posters) {
      if (!mounted) return;
      setState(() {
        _posters = posters;
        _isLoading = false;
        _hasError = false;
        _showShimmer = false;
        if (posters.isEmpty || _currentPage >= posters.length) _currentPage = 0;
      });
    });
  }

  Future<void> _loadPosters() async {
    try {
      // Check if we have cached data
      final hasCached = await _posterService.hasCachedData();
      
      setState(() {
        _isLoading = true;
        _hasError = false;
        _showShimmer = !hasCached; // Show shimmer only if no cache
      });

      final posters = await _posterService.fetchPosters();

      if (mounted) {
        setState(() {
          _posters = posters;
          _isLoading = false;
          _showShimmer = false;
        });

        if (_autoSlideEnabled && _posters.isNotEmpty) {
          _startAutoSlide();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = _posters.isEmpty; // Only show error if no cached data
          _showShimmer = false;
        });
      }
    }
  }

  void _startAutoSlide() {
    Future.delayed(widget.autoSlideDuration, () {
      if (!mounted || !_autoSlideEnabled || _posters.isEmpty) return;

      final nextPage = (_currentPage + 1) % _posters.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      _startAutoSlide();
    });
  }

  @override
  void dispose() {
    _posterSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer while loading and no cached data
    if (_showShimmer && _isLoading) {
      return PosterShimmerWidget(
        height: widget.height,
        borderRadius: widget.borderRadius,
        margin: widget.margin,
      );
    }

    // Show cached data while refreshing in background
    if (_posters.isNotEmpty) {
      return _buildCarousel();
    }

    // Show error only if no cached data available
    if (_hasError) {
      return _buildErrorWidget();
    }

    // Firestore can intentionally contain zero active banners.
    if (!_isLoading) return const SizedBox.shrink();

    return PosterShimmerWidget(
      height: widget.height,
      borderRadius: widget.borderRadius,
      margin: widget.margin,
    );
  }

  Widget _buildCarousel() {
    return Container(
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _posters.length,
            itemBuilder: (context, index) {
              return _buildPosterCard(_posters[index]);
            },
          ),
          // Page Indicator
          if (widget.showIndicator && _posters.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _posters.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          // Auto Slide Toggle Button
          if (_posters.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    _autoSlideEnabled ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoSlideEnabled = !_autoSlideEnabled;
                      if (_autoSlideEnabled) {
                        _startAutoSlide();
                      }
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'লোড করতে সমস্যা হয়েছে',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadPosters,
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCard(PosterModel poster) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PosterDetailsScreen(poster: poster),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: poster.imglink,
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
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('ছবি লোড করা যায়নি'),
                    ],
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
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Tap Indicator
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'বিস্তারিত দেখুন',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
    );
  }
}
