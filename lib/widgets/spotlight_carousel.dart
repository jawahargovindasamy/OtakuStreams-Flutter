import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/anime.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class SpotlightCarousel extends StatefulWidget {
  final List<Anime> spotlight;

  const SpotlightCarousel({
    super.key,
    required this.spotlight,
  });

  @override
  State<SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<SpotlightCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _spotlightTimer;

  @override
  void initState() {
    super.initState();
    _startSpotlightTimer();
  }

  @override
  void dispose() {
    _spotlightTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startSpotlightTimer() {
    _spotlightTimer?.cancel();
    if (widget.spotlight.length <= 1) return;
    _spotlightTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.spotlight.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spotlight.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.spotlight.length,
            itemBuilder: (context, index) {
              final item = widget.spotlight[index];
              final auth = Provider.of<AuthProvider>(context);
              final progress = auth.continueWatching.firstWhere(
                (e) => e['animeId'] == item.id,
                orElse: () => null,
              );
              
              // Map metadata row elements
              final List<String> metadata = [];
              if (item.rating != null) {
                final doubleVal = double.tryParse(item.rating!);
                if (doubleVal != null) {
                  metadata.add('${(doubleVal * 10).toInt()}%');
                }
              }
              if (item.year != null) {
                metadata.add('${item.year}');
              }
              if (item.type.isNotEmpty) {
                metadata.add(item.type.replaceAll('_', ' '));
              }
              if (item.subEpisodes.isNotEmpty && item.subEpisodes != '?') {
                metadata.add('${item.subEpisodes} Episodes');
              }

              final String title = AnimeUtils.getTitle(context, item);

              return GestureDetector(
                onTap: () => context.push('/${AnimeUtils.slugify(title)}/${item.id}'),
                child: Stack(
                  children: [
                    // Banner background
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.8,
                        child: item.banner != null
                            ? CachedNetworkImage(imageUrl: item.banner!, fit: BoxFit.cover)
                            : CachedNetworkImage(imageUrl: item.poster, fit: BoxFit.cover),
                      ),
                    ),
                    // Multi-layered gradients for beautiful text readability
                    // Bottom-to-top gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.95),
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // Left-to-right gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 20,
                      bottom: 40,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${index + 1} Spotlight',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Metadata info row
                          if (metadata.isNotEmpty)
                            Row(
                              children: List.generate(metadata.length, (mIdx) {
                                return Row(
                                  children: [
                                    if (mIdx > 0)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white60,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      metadata[mIdx],
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          const SizedBox(height: 8),
                          // Truncated Description text
                          if (item.description != null && item.description!.isNotEmpty)
                            Text(
                              item.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          const SizedBox(height: 14),
                          // Button row
                          Row(
                            children: [
                              // Watch button
                              ElevatedButton(
                                onPressed: () {
                                  if (progress != null) {
                                    context.push(
                                      '/watch/${item.id}/${progress['currentEpisode']}',
                                      extra: {
                                        'server': progress['server'],
                                        'dub': progress['dub'],
                                      },
                                    );
                                  } else {
                                    context.push('/watch/${item.id}/1');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  minimumSize: const Size(100, 36),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      progress != null
                                          ? 'Continue Ep ${progress['currentEpisode']}'
                                          : 'Watch Now',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Detail button
                              OutlinedButton(
                                onPressed: () => context.push('/${AnimeUtils.slugify(title)}/${item.id}'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  minimumSize: const Size(80, 36),
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Expandable Animated indicator dots row in bottom center
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.spotlight.length, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isSelected ? 20 : 6,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
