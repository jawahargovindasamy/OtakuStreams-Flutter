import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../core/unified_scaffold.dart';
import '../models/anime.dart';
import '../widgets/anime_grid.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String _activeFilter = 'all';
  bool _loading = false;
  List<dynamic> _items = [];
  int _page = 1;
  static const int _itemsPerPage = 30;

  static const List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'watching', 'label': 'Watching'},
    {'key': 'on_hold', 'label': 'On Hold'},
    {'key': 'plan_to_watch', 'label': 'Plan To Watch'},
    {'key': 'dropped', 'label': 'Dropped'},
    {'key': 'completed', 'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_activeFilter == 'all') {
      await auth.fetchWatchlist();
      if (mounted) {
        setState(() {
          _items = auth.watchlist;
          _loading = false;
        });
      }
    } else {
      final list = await auth.fetchWatchlist({'status': _activeFilter});
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    }
  }

  void _onFilterChanged(String filterKey) {
    setState(() {
      _activeFilter = filterKey;
      _page = 1;
    });
    _loadData();
  }

  List<dynamic> _getPageNumbers(int totalPages) {
    final List<dynamic> pages = [];

    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    pages.add(1);

    if (_page > 3) {
      pages.add("...");
    }

    final start = (_page - 1).clamp(2, totalPages - 1);
    final end = (_page + 1).clamp(2, totalPages - 1);

    final actualStart = _page > 3 ? start : 2;
    final actualEnd = _page < totalPages - 2 ? end : totalPages - 1;

    for (int i = actualStart; i <= actualEnd; i++) {
      pages.add(i);
    }

    if (_page < totalPages - 2) {
      pages.add("...");
    }

    pages.add(totalPages);

    return pages;
  }

  Widget _buildFilterButton(String label, String key) {
    final isActive = _activeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () => _onFilterChanged(key),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
          foregroundColor: isActive ? Colors.white : Colors.grey[300],
          side: BorderSide(
            color: isActive 
                ? const Color(0xFF3B82F6) 
                : Colors.white.withValues(alpha: 0.15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label == 'On Hold' ? 'On-Hold' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPages = (_items.length / _itemsPerPage).ceil();
    final int startIdx = (_page - 1) * _itemsPerPage;
    final int endIdx = (startIdx + _itemsPerPage < _items.length) ? startIdx + _itemsPerPage : _items.length;
    final List<dynamic> paginatedItems = _items.isEmpty ? [] : _items.sublist(startIdx, endIdx);

    return UnifiedScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watchlist',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Filters row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return _buildFilterButton(filter['label']!, filter['key']!);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Items grid
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : paginatedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.playCircle,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Anime in Watchlist',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Start add some anime in watchlist and they'll appear here for easy access.",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: AnimeGrid(
                                animes: paginatedItems.map((item) => Anime.fromBackend(item as Map<String, dynamic>)).toList(),
                                padding: EdgeInsets.zero,
                                physics: const AlwaysScrollableScrollPhysics(),
                                shrinkWrap: false,
                              ),
                            ),
                            if (totalPages > 1) ...[
                              const Divider(color: Colors.white12, height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 600;
                                  final pageWidgets = _getPageNumbers(totalPages).map((pageNum) {
                                    if (pageNum == "...") {
                                      return const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Center(
                                          child: Text('...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ),
                                      );
                                    }
                                    
                                    final isCurrent = _page == pageNum;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _page = pageNum as int;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: isCurrent ? const Color(0xFF3B82F6) : Colors.transparent,
                                            foregroundColor: isCurrent ? Colors.white : Colors.grey[300],
                                            padding: EdgeInsets.zero,
                                            side: BorderSide(
                                              color: isCurrent 
                                                  ? const Color(0xFF3B82F6) 
                                                  : Colors.white.withValues(alpha: 0.15),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            '$pageNum',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList();

                                  final controls = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Left chevron
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: _page > 1 ? () => setState(() => _page--) : null,
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.15),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Icon(Icons.chevron_left, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Page numbers
                                      ...pageWidgets,
                                      const SizedBox(width: 4),
                                      // Right chevron
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: _page < totalPages ? () => setState(() => _page++) : null,
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.15),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Icon(Icons.chevron_right, size: 16),
                                        ),
                                      ),
                                    ],
                                  );

                                  final label = Text(
                                    'Page $_page of $totalPages',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  );

                                  if (isMobile) {
                                    return Column(
                                      children: [
                                        controls,
                                        const SizedBox(height: 12),
                                        label,
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        label,
                                        controls,
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
