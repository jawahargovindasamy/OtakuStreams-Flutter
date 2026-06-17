import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/data_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/unified_scaffold.dart';
import '../widgets/section_header.dart';
import '../widgets/anime_grid.dart';
import '../widgets/vertical_anime_list.dart';
import '../widgets/filter_panel.dart';

class SearchScreen extends StatefulWidget {
  final String keyword;
  final int page;
  final String type;
  final String status;
  final String rated;
  final String score;
  final String season;
  final String language;
  final String sort;
  final String startDate;
  final String endDate;
  final List<String> genres;

  const SearchScreen({
    super.key,
    required this.keyword,
    this.page = 1,
    this.type = 'all',
    this.status = 'all',
    this.rated = 'all',
    this.score = 'all',
    this.season = 'all',
    this.language = 'all',
    this.sort = 'default',
    this.startDate = '',
    this.endDate = '',
    required this.genres,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _loading = false;
  List<Anime> _animes = [];
  List<Anime> _mostPopular = [];
  int _totalPages = 1;
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword ||
        oldWidget.page != widget.page ||
        oldWidget.type != widget.type ||
        oldWidget.status != widget.status ||
        oldWidget.rated != widget.rated ||
        oldWidget.score != widget.score ||
        oldWidget.season != widget.season ||
        oldWidget.language != widget.language ||
        oldWidget.sort != widget.sort ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        !_listEquals(oldWidget.genres, widget.genres)) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    try {
      final isAdvanced = _checkIsAdvanced();
      Map<String, dynamic> result;

      if (isAdvanced || widget.keyword.isEmpty) {
        result = await dataProvider.fetchadvancedsearch(
          q: widget.keyword.isNotEmpty ? widget.keyword : null,
          page: widget.page,
          type: widget.type,
          status: widget.status,
          rated: widget.rated,
          score: widget.score,
          season: widget.season,
          sort: widget.sort,
          startDate: widget.startDate.isNotEmpty ? widget.startDate : null,
          endDate: widget.endDate.isNotEmpty ? widget.endDate : null,
          genres: widget.genres.isNotEmpty ? widget.genres : null,
        );
      } else {
        result = await dataProvider.fetchsearch(widget.keyword, widget.page);
      }

      if (mounted) {
        setState(() {
          _animes = List<Anime>.from(result['animes'] ?? []);
          _mostPopular = List<Anime>.from(result['mostPopularAnimes'] ?? []);
          _totalPages = result['totalPages'] ?? 1;
          _searchQuery = result['searchQuery'] ?? widget.keyword;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load search results failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool _checkIsAdvanced() {
    return widget.type != 'all' ||
        widget.status != 'all' ||
        widget.rated != 'all' ||
        widget.score != 'all' ||
        widget.season != 'all' ||
        widget.language != 'all' ||
        widget.sort != 'default' ||
        widget.startDate.isNotEmpty ||
        widget.endDate.isNotEmpty ||
        widget.genres.isNotEmpty;
  }

  int _getActiveFilterCount() {
    return [
      widget.type != 'all',
      widget.status != 'all',
      widget.rated != 'all',
      widget.score != 'all',
      widget.season != 'all',
      widget.language != 'all',
      widget.sort != 'default',
      widget.startDate.isNotEmpty,
      widget.endDate.isNotEmpty,
      widget.genres.isNotEmpty,
    ].where((e) => e == true).length;
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    final Map<String, String> queryParams = {};
    if (widget.keyword.isNotEmpty) {
      queryParams['keyword'] = widget.keyword;
    }

    if (newFilters['type'] != 'all') queryParams['type'] = newFilters['type'];
    if (newFilters['status'] != 'all') queryParams['status'] = newFilters['status'];
    if (newFilters['rated'] != 'all') queryParams['rated'] = newFilters['rated'];
    if (newFilters['score'] != 'all') queryParams['score'] = newFilters['score'];
    if (newFilters['season'] != 'all') queryParams['season'] = newFilters['season'];
    if (newFilters['language'] != 'all') queryParams['language'] = newFilters['language'];
    if (newFilters['sort'] != 'default') queryParams['sort'] = newFilters['sort'];
    if (newFilters['startDate'] != '') queryParams['startDate'] = newFilters['startDate'];
    if (newFilters['endDate'] != '') queryParams['endDate'] = newFilters['endDate'];

    final List<String> genresList = List<String>.from(newFilters['genres'] ?? []);
    if (genresList.isNotEmpty) {
      queryParams['genres'] = genresList.join(',');
    }

    context.go(Uri(path: '/search', queryParameters: queryParams).toString());
  }

  void _resetFilters() {
    final Map<String, String> queryParams = {};
    if (widget.keyword.isNotEmpty) {
      queryParams['keyword'] = widget.keyword;
    }
    context.go(Uri(path: '/search', queryParameters: queryParams).toString());
  }

  void _handlePageChange(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages && newPage != widget.page) {
      final Map<String, String> queryParams = {};
      if (widget.keyword.isNotEmpty) {
        queryParams['keyword'] = widget.keyword;
      }
      if (newPage > 1) {
        queryParams['page'] = newPage.toString();
      }

      if (widget.type != 'all') queryParams['type'] = widget.type;
      if (widget.status != 'all') queryParams['status'] = widget.status;
      if (widget.rated != 'all') queryParams['rated'] = widget.rated;
      if (widget.score != 'all') queryParams['score'] = widget.score;
      if (widget.season != 'all') queryParams['season'] = widget.season;
      if (widget.language != 'all') queryParams['language'] = widget.language;
      if (widget.sort != 'default') queryParams['sort'] = widget.sort;
      if (widget.startDate.isNotEmpty) queryParams['startDate'] = widget.startDate;
      if (widget.endDate.isNotEmpty) queryParams['endDate'] = widget.endDate;

      if (widget.genres.isNotEmpty) {
        queryParams['genres'] = widget.genres.join(',');
      }

      context.go(Uri(path: '/search', queryParameters: queryParams).toString());
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  List<dynamic> _getPageNumbers() {
    final pages = [];
    const maxVisible = 5;
    if (_totalPages <= maxVisible) {
      for (int i = 1; i <= _totalPages; i++) {
        pages.add(i);
      }
    } else {
      if (widget.page <= 3) {
        for (int i = 1; i <= 4; i++) {
          pages.add(i);
        }
        pages.add('...');
        pages.add(_totalPages);
      } else if (widget.page >= _totalPages - 2) {
        pages.add(1);
        pages.add('...');
        for (int i = _totalPages - 3; i <= _totalPages; i++) {
          pages.add(i);
        }
      } else {
        pages.add(1);
        pages.add('...');
        for (int i = widget.page - 1; i <= widget.page + 1; i++) {
          pages.add(i);
        }
        pages.add('...');
        pages.add(_totalPages);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilters = _getActiveFilterCount();
    final isAdvanced = _checkIsAdvanced();

    final Map<String, dynamic> activeFiltersMap = {
      'type': widget.type,
      'status': widget.status,
      'rated': widget.rated,
      'score': widget.score,
      'season': widget.season,
      'language': widget.language,
      'sort': widget.sort,
      'startDate': widget.startDate,
      'endDate': widget.endDate,
      'genres': widget.genres,
    };

    return UnifiedScaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters Panel at the top
              FilterPanel(
                filters: activeFiltersMap,
                onFilterChange: _applyFilters,
                onReset: _resetFilters,
                keyword: widget.keyword,
              ),
              const SizedBox(height: 16),

              // Two-column grid / stacks layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth > 1000;

                  final mainContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SectionHeader(
                              title: _searchQuery.isNotEmpty
                                  ? _searchQuery
                                  : (widget.keyword.isNotEmpty ? widget.keyword : 'Browse Anime'),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          if (isAdvanced && activeFilters > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.sliders, color: AppTheme.primaryBlue, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$activeFilters active',
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isAdvanced) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Using advanced filters • ${_animes.length} results found',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Main List Content
                      if (_loading)
                        Container(
                          height: 350,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue)),
                              SizedBox(height: 16),
                              Text(
                                'Curating results...',
                                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      else if (_animes.isEmpty)
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.sliders, color: theme.hintColor.withValues(alpha: 0.5), size: 32),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No results found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try adjusting your filters or search terms to find what you are looking for.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.hintColor, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _resetFilters,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Clear all filters', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        AnimeGrid(animes: _animes, padding: EdgeInsets.zero),
                        const SizedBox(height: 32),
                        // Pagination
                        if (_totalPages > 1) _buildPaginationBar(),
                      ],
                    ],
                  );

                  final sidebarContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mostPopular.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          ),
                          child: VerticalAnimeList(
                            title: 'Most Popular',
                            listItems: _mostPopular,
                            link: '/most-popular',
                          ),
                        ),
                      ],
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainContent),
                        const SizedBox(width: 32),
                        SizedBox(width: 340, child: sidebarContent),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mainContent,
                        const SizedBox(height: 32),
                        sidebarContent,
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final pages = _getPageNumbers();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useVertical = constraints.maxWidth < 600;

              final infoText = Text(
                'Page ${widget.page} of $_totalPages',
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );

              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prev arrow
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 16),
                    onPressed: widget.page > 1 ? () => _handlePageChange(widget.page - 1) : null,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Page numbers
                  Wrap(
                    spacing: 4,
                    children: pages.map<Widget>((pageNum) {
                      if (pageNum == '...') {
                        return Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Text('...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        );
                      }

                      final int pageInt = pageNum as int;
                      final bool isCurrent = pageInt == widget.page;

                      return SizedBox(
                        width: 32,
                        height: 32,
                        child: TextButton(
                          onPressed: () => _handlePageChange(pageInt),
                          style: TextButton.styleFrom(
                            backgroundColor: isCurrent ? AppTheme.primaryBlue : Colors.transparent,
                            foregroundColor: isCurrent ? Colors.white : theme.textTheme.bodyLarge?.color,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            '$pageInt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),

                  // Next arrow
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 16),
                    onPressed: widget.page < _totalPages ? () => _handlePageChange(widget.page + 1) : null,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              );

              if (useVertical) {
                return Column(
                  children: [
                    infoText,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoText,
                    controls,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
