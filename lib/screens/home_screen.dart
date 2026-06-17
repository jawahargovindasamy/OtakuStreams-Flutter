import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../core/utils.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/anime.dart';
import '../core/unified_scaffold.dart';
import '../widgets/section_header.dart';
import '../widgets/spotlight_carousel.dart';
import '../widgets/trending_row.dart';
import '../widgets/vertical_anime_list.dart';
import '../widgets/anime_grid.dart';
import '../widgets/estimated_schedule.dart';
import '../widgets/genres_list.dart';
import '../widgets/top10_sidebar.dart';
import '../widgets/continue_watching_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    // Proactively fetch home data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.homeData == null) {
        dataProvider.fetchHomedata();
      }
    });
  }

  Future<void> _deleteItem(String animeId) async {
    if (_deletingIds.contains(animeId)) return;
    setState(() {
      _deletingIds.add(animeId);
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .removeContinueWatching(animeId);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Removed from continue watching'),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(animeId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeData = context.select<DataProvider, Map<String, dynamic>?>((p) => p.homeData);
    final continueWatching = context.select<AuthProvider, List<dynamic>>((p) => p.continueWatching);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          final canPop = Navigator.of(context).canPop();
          if (canPop) {
            Navigator.of(context).pop();
          } else {
            final shouldExit = await AnimeUtils.showExitConfirmationDialog(context);
            if (shouldExit) {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: UnifiedScaffold(
        body: homeData == null
            ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: () => context.read<DataProvider>().fetchHomedata(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spotlight Carousel
                    SpotlightCarousel(spotlight: List<Anime>.from(homeData['spotlightAnimes'] ?? [])),

                    // Trending Section
                    const SectionHeader(title: 'Trending'),
                    TrendingRow(trending: List<Anime>.from(homeData['trendingAnimes'] ?? [])),

                    // Vertical Lists Grid (Top Airing, Most Popular, Most Favorite, Completed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final topAiring = List<Anime>.from(homeData['topAiringAnimes'] ?? []);
                          final mostPopular = List<Anime>.from(homeData['mostPopularAnimes'] ?? []);
                          final mostFavorite = List<Anime>.from(homeData['mostFavoriteAnimes'] ?? []);
                          final completed = List<Anime>.from(homeData['latestCompletedAnimes'] ?? []);

                          if (constraints.maxWidth > 1100) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Expanded(child: VerticalAnimeList(title: 'Top Airing', listItems: topAiring, link: '/top-airing')),
                                  const SizedBox(width: 20),
                                  Expanded(child: VerticalAnimeList(title: 'Most Popular', listItems: mostPopular, link: '/most-popular')),
                                  const SizedBox(width: 20),
                                  Expanded(child: VerticalAnimeList(title: 'Most Favorite', listItems: mostFavorite, link: '/most-favorite')),
                                  const SizedBox(width: 20),
                                  Expanded(child: VerticalAnimeList(title: 'Completed', listItems: completed, link: '/completed')),
                              ],
                            );
                          } else if (constraints.maxWidth > 650) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: VerticalAnimeList(title: 'Top Airing', listItems: topAiring, link: '/top-airing')),
                                    const SizedBox(width: 20),
                                    Expanded(child: VerticalAnimeList(title: 'Most Popular', listItems: mostPopular, link: '/most-popular')),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: VerticalAnimeList(title: 'Most Favorite', listItems: mostFavorite, link: '/most-favorite')),
                                    const SizedBox(width: 20),
                                    Expanded(child: VerticalAnimeList(title: 'Completed', listItems: completed, link: '/completed')),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                VerticalAnimeList(title: 'Top Airing', listItems: topAiring, link: '/top-airing'),
                                const SizedBox(height: 24),
                                VerticalAnimeList(title: 'Most Popular', listItems: mostPopular, link: '/most-popular'),
                                const SizedBox(height: 24),
                                VerticalAnimeList(title: 'Most Favorite', listItems: mostFavorite, link: '/most-favorite'),
                                const SizedBox(height: 24),
                                VerticalAnimeList(title: 'Completed', listItems: completed, link: '/completed'),
                              ],
                            );
                          }
                        },
                      ),
                    ),

                    // Main Grid/Sidebar Layout Builder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final latestEpisodes = List<Anime>.from(homeData['latestEpisodeAnimes'] ?? []);
                          final topUpcoming = List<Anime>.from(homeData['topUpcomingAnimes'] ?? []);
                          final genres = List<String>.from(homeData['genres'] ?? []);
                          final bool isDesktop = constraints.maxWidth > 1000;

                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Continue Watching, Latest Episodes, Estimated Schedule, Top Upcoming
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (continueWatching.isNotEmpty) ...[
                                        SectionHeader(
                                          title: 'Continue Watching',
                                          onTap: continueWatching.length > 5
                                              ? () => context.push('/continue-watching')
                                              : null,
                                          padding: EdgeInsets.zero,
                                        ),
                                        ContinueWatchingGrid(
                                          items: continueWatching,
                                          deletingIds: _deletingIds,
                                          onDelete: _deleteItem,
                                          limit: 5,
                                          isDesktop: true,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                      SectionHeader(title: 'Latest Episodes', onTap: () => context.push('/recently-updated'), padding: EdgeInsets.zero),
                                      const SizedBox(height: 12),
                                      AnimeGrid(animes: latestEpisodes, padding: EdgeInsets.zero),
                                      const SizedBox(height: 24),
                                      const EstimatedSchedule(headerPadding: EdgeInsets.symmetric(vertical: 12), contentHorizontalPadding: 0),
                                      const SizedBox(height: 24),
                                      SectionHeader(title: 'Top Upcoming', onTap: () => context.push('/top-upcoming'), padding: EdgeInsets.zero),
                                      const SizedBox(height: 12),
                                      AnimeGrid(animes: topUpcoming, padding: EdgeInsets.zero),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Right Column: Sidebar (Genres List, Top 10)
                                SizedBox(
                                  width: 340,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GenresList(genres: genres),
                                      const SizedBox(height: 24),
                                      Top10Sidebar(homeData: homeData),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mobile/Tablet Layout: Single Column Stacked
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (continueWatching.isNotEmpty) ...[
                                  SectionHeader(
                                    title: 'Continue Watching',
                                    onTap: continueWatching.length > 5
                                        ? () => context.push('/continue-watching')
                                        : null,
                                    padding: EdgeInsets.zero,
                                  ),
                                  ContinueWatchingGrid(
                                    items: continueWatching,
                                    deletingIds: _deletingIds,
                                    onDelete: _deleteItem,
                                    limit: 5,
                                    isDesktop: false,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                SectionHeader(title: 'Latest Episodes', onTap: () => context.push('/recently-updated'), padding: EdgeInsets.zero),
                                const SizedBox(height: 12),
                                AnimeGrid(animes: latestEpisodes, padding: EdgeInsets.zero),
                                const SizedBox(height: 24),
                                const EstimatedSchedule(headerPadding: EdgeInsets.symmetric(vertical: 12), contentHorizontalPadding: 0),
                                const SizedBox(height: 24),
                                SectionHeader(title: 'Top Upcoming', onTap: () => context.push('/top-upcoming'), padding: EdgeInsets.zero),
                                const SizedBox(height: 12),
                                AnimeGrid(animes: topUpcoming, padding: EdgeInsets.zero),
                                const SizedBox(height: 32),
                                GenresList(genres: genres),
                                const SizedBox(height: 32),
                                Top10Sidebar(homeData: homeData),
                              ],
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 240, color: Colors.black),
            const SizedBox(height: 24),
            Row(children: [
              const SizedBox(width: 16),
              Container(width: 150, height: 20, color: Colors.black),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, index) => Container(width: 130, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
