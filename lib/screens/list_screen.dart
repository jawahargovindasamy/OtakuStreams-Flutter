import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/unified_scaffold.dart';
import '../widgets/section_header.dart';
import '../widgets/anime_grid.dart';
import '../widgets/genres_list.dart';
import '../widgets/top10_sidebar.dart';

class ListScreen extends StatefulWidget {
  final String mode; // 'category', 'genre', 'producer', 'az'
  final String arg; // category key, genre name, producer name, or letter
  const ListScreen({super.key, required this.mode, required this.arg});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  bool _loading = true;
  List<Anime> _animes = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _title = '';
  Map<String, dynamic> _localResult = {};
  final List<int> _pageHistory = [1];
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode || oldWidget.arg != widget.arg) {
      _currentPage = 1;
      _pageHistory.clear();
      _pageHistory.add(1);
      _loadList();
    }
  }

  Future<void> _loadList() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    Map<String, dynamic> result = {};

    try {
      if (widget.mode == 'category') {
        result = await dataProvider.fetchcategories(widget.arg, _currentPage);
        _title = result['category'] ?? widget.arg.replaceAll('-', ' ').toUpperCase();
      } else if (widget.mode == 'genre') {
        result = await dataProvider.fetchgenres(widget.arg, _currentPage);
        _title = '${result['genreName'] ?? widget.arg.replaceAll('-', ' ').toUpperCase()} Anime';
      } else if (widget.mode == 'producer') {
        result = await dataProvider.fetchproducers(widget.arg, _currentPage);
        _title = '${result['producerName'] ?? widget.arg.replaceAll('-', ' ').toUpperCase()} Anime';
      }
    } catch (e) {
      debugPrint('Load list page error: $e');
    }

    if (mounted) {
      setState(() {
        _localResult = result;
        _animes = List<Anime>.from(result['animes'] ?? []);
        _totalPages = result['totalPages'] ?? 1;
        _loading = false;
      });
    }
  }

  void _handlePageChange(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages && newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
        _pageHistory.add(newPage);
      });
      _loadList();
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
      if (_currentPage <= 3) {
        for (int i = 1; i <= 4; i++) {
          pages.add(i);
        }
        pages.add('...');
        pages.add(_totalPages);
      } else if (_currentPage >= _totalPages - 2) {
        pages.add(1);
        pages.add('...');
        for (int i = _totalPages - 3; i <= _totalPages; i++) {
          pages.add(i);
        }
      } else {
        pages.add(1);
        pages.add('...');
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
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
    final homeData = context.select<DataProvider, Map<String, dynamic>?>((p) => p.homeData) ?? {};

    // Standard genres and rankings fallbacks
    final genres = List<String>.from(_localResult['genres'] ?? homeData['genres'] ?? []);
    
    // Construct local top 10 mapping
    final top10Data = _localResult['top10Animes'] ?? homeData['top10Animes'];
    final homeDataMock = top10Data != null ? {'top10Animes': top10Data} : homeData;

    return PopScope(
      canPop: _pageHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_pageHistory.length > 1) {
          setState(() {
            _pageHistory.removeLast();
            _currentPage = _pageHistory.last;
          });
          _loadList();
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      },
      child: UnifiedScaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadList(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isDesktop = constraints.maxWidth > 1000;
  
                        final mainContent = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: _title, padding: EdgeInsets.zero),
                            const SizedBox(height: 16),
                            if (_animes.isEmpty)
                              Container(
                                height: 240,
                                alignment: Alignment.center,
                                child: const Text(
                                  'No anime found.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            else ...[
                              AnimeGrid(animes: _animes, padding: EdgeInsets.zero),
                              const SizedBox(height: 32),
                              // Chronological Page pagination bar
                              if (_totalPages > 1) _buildPaginationBar(),
                            ],
                          ],
                        );
  
                        final sidebarContent = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (genres.isNotEmpty) ...[
                              GenresList(genres: genres),
                              const SizedBox(height: 24),
                            ],
                            if (top10Data != null)
                              Top10Sidebar(homeData: homeDataMock),
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
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final pages = _getPageNumbers();

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useVertical = constraints.maxWidth < 600;

              final infoText = Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );

              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prev arrow
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _currentPage > 1 ? () => _handlePageChange(_currentPage - 1) : null,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Page numbers
                  Wrap(
                    spacing: 4,
                    children: pages.map((pageNum) {
                      if (pageNum == '...') {
                        return const SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Text(
                              '...',
                              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                      
                      final isSelected = pageNum == _currentPage;

                      return SizedBox(
                        width: 32,
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _handlePageChange(pageNum as int),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : Theme.of(context).dividerColor.withValues(alpha: 0.25),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            '$pageNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 6),
                  // Next arrow
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _currentPage < _totalPages ? () => _handlePageChange(_currentPage + 1) : null,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                ],
              );

              if (useVertical) {
                return Column(
                  children: [
                    controls,
                    const SizedBox(height: 12),
                    infoText,
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
