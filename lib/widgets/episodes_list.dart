import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/anime.dart';
import '../core/theme.dart';

class RangeOption {
  final String label;
  final int start;
  final int end;

  RangeOption({
    required this.label,
    required this.start,
    required this.end,
  });
}

class EpisodesList extends StatefulWidget {
  final List<Episode> episodeList;
  final int totalepisodes;
  final String activeEpisode;
  final ValueChanged<String> onEpisodeChange;
  final double? maxHeight;

  const EpisodesList({
    super.key,
    required this.episodeList,
    required this.totalepisodes,
    required this.activeEpisode,
    required this.onEpisodeChange,
    this.maxHeight,
  });

  @override
  State<EpisodesList> createState() => _EpisodesListState();
}

class _EpisodesListState extends State<EpisodesList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RangeOption? _selectedRange;
  bool _showRangeMenu = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _syncRangeWithActiveEpisode();
  }

  @override
  void didUpdateWidget(covariant EpisodesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeEpisode != widget.activeEpisode ||
        oldWidget.episodeList.length != widget.episodeList.length ||
        oldWidget.totalepisodes != widget.totalepisodes) {
      _syncRangeWithActiveEpisode();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _syncRangeWithSearch();
  }

  bool get _isGridMode => widget.totalepisodes > 25;

  List<RangeOption> _getRanges() {
    final List<RangeOption> list = [];
    final total = widget.totalepisodes > 0 ? widget.totalepisodes : widget.episodeList.length;
    if (total == 0) return list;

    for (int i = 1; i <= total; i += 100) {
      final start = i;
      final end = (i + 99) > total ? total : (i + 99);
      final label = 'EPS: ${start.toString().padLeft(3, '0')}–${end.toString().padLeft(3, '0')}';
      list.add(RangeOption(label: label, start: start, end: end));
    }
    return list;
  }

  void _syncRangeWithActiveEpisode() {
    if (!_isGridMode || widget.episodeList.isEmpty) return;

    final activeNum = int.tryParse(widget.activeEpisode);
    if (activeNum == null) return;

    final activeEp = widget.episodeList.firstWhere(
      (ep) => ep.number == activeNum,
      orElse: () => widget.episodeList.firstWhere(
        (ep) => ep.episodeId.split('ep=').last == widget.activeEpisode,
        orElse: () => widget.episodeList.first,
      ),
    );

    final ranges = _getRanges();
    final correctRange = ranges.firstWhere(
      (r) => activeEp.number >= r.start && activeEp.number <= r.end,
      orElse: () => ranges.isNotEmpty ? ranges.first : RangeOption(label: '', start: 0, end: 0),
    );

    if (correctRange.label.isNotEmpty && (_selectedRange == null || _selectedRange!.label != correctRange.label)) {
      setState(() {
        _selectedRange = correctRange;
      });
    }
  }

  void _syncRangeWithSearch() {
    if (!_isGridMode || _searchQuery.isEmpty || widget.episodeList.isEmpty) return;

    final searchNum = int.tryParse(_searchQuery);
    if (searchNum == null) return;

    final matchedEp = widget.episodeList.firstWhere(
      (ep) => ep.number == searchNum,
      orElse: () => widget.episodeList.firstWhere(
        (ep) => ep.number.toString().contains(_searchQuery),
        orElse: () => widget.episodeList.first,
      ),
    );

    final ranges = _getRanges();
    final correctRange = ranges.firstWhere(
      (r) => matchedEp.number >= r.start && matchedEp.number <= r.end,
      orElse: () => ranges.isNotEmpty ? ranges.first : RangeOption(label: '', start: 0, end: 0),
    );

    if (correctRange.label.isNotEmpty && (_selectedRange == null || _selectedRange!.label != correctRange.label)) {
      setState(() {
        _selectedRange = correctRange;
      });
    }
  }

  List<Episode> _getFilteredEpisodes() {
    return widget.episodeList.where((ep) {
      final matchesSearch = ep.number.toString().contains(_searchQuery);

      if (!_isGridMode) return matchesSearch;

      // In grid mode: if searching, show all matching episodes regardless of range.
      if (_searchQuery.isNotEmpty) return matchesSearch;

      final ranges = _getRanges();
      final currentRange = _selectedRange ?? (ranges.isNotEmpty ? ranges.first : null);
      if (currentRange == null) return matchesSearch;

      final inRange = ep.number >= currentRange.start && ep.number <= currentRange.end;
      return matchesSearch && inRange;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ranges = _getRanges();
    final currentRange = _selectedRange ?? (ranges.isNotEmpty ? ranges.first : null);
    final filtered = _getFilteredEpisodes();

    final cardBgColor = Theme.of(context).cardColor.withValues(alpha: 0.5);
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.15);

    return Container(
      width: double.infinity,
      height: widget.maxHeight,
      constraints: widget.maxHeight == null ? const BoxConstraints(maxHeight: 500) : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Search Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'List of episodes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                height: 36,
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Number of Ep',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(LucideIcons.search, size: 14, color: Colors.grey),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 36),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conditional small view vs grid view
          Expanded(
            child: _buildListContent(currentRange, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(RangeOption? currentRange, List<Episode> filtered) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No episodes found', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    if (!_isGridMode) {
      return ListView.separated(
        shrinkWrap: true,
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final ep = filtered[index];
          final String cleanId = ep.episodeId.split('ep=').last;
          final bool isActive = cleanId == widget.activeEpisode || ep.number.toString() == widget.activeEpisode;
          final bool isFiller = ep.isFiller;

          Color itemBg = Colors.transparent;
          Color itemText = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
          Border? border;

          if (isActive) {
            itemBg = AppTheme.primaryBlue;
            itemText = Colors.white;
          } else if (isFiller) {
            itemBg = Colors.yellow.withValues(alpha: 0.05);
            itemText = Colors.yellow[600]!;
            border = Border.all(color: Colors.yellow.withValues(alpha: 0.2));
          }

          return InkWell(
            onTap: () => widget.onEpisodeChange(cleanId),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(10),
                border: border,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${ep.number}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ep.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontStyle: isFiller && !isActive ? FontStyle.italic : FontStyle.normal,
                        color: itemText,
                      ),
                    ),
                  ),
                  if (isFiller && !isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Filler',
                        style: TextStyle(color: Colors.yellow, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.play, size: 14, color: Colors.white),
                  ],
                ],
              ),
            ),
          );
        },
      );
    } else {
      // GRID MODE WITH RANGE SELECTOR
      final ranges = _getRanges();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range Dropdown Selector
          if (ranges.isNotEmpty && currentRange != null) ...[
            PopupMenuButton<RangeOption>(
              offset: const Offset(0, 44),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onSelected: (RangeOption opt) {
                setState(() {
                  _selectedRange = opt;
                  _showRangeMenu = false;
                });
              },
              onOpened: () => setState(() => _showRangeMenu = true),
              onCanceled: () => setState(() => _showRangeMenu = false),
              itemBuilder: (BuildContext context) {
                return ranges.map((RangeOption opt) {
                  final isCurrent = currentRange.label == opt.label;
                  return PopupMenuItem<RangeOption>(
                    value: opt,
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primaryBlue : null,
                      ),
                    ),
                  );
                }).toList();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentRange.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      _showRangeMenu ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Grid View
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ep = filtered[index];
                final String cleanId = ep.episodeId.split('ep=').last;
                final bool isActive = cleanId == widget.activeEpisode || ep.number.toString() == widget.activeEpisode;
                final bool isFiller = ep.isFiller;

                Color itemBg = Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5);
                Color itemText = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
                Border? border;

                if (isActive) {
                  itemBg = AppTheme.primaryBlue;
                  itemText = Colors.white;
                } else if (isFiller) {
                  itemBg = Colors.yellow.withValues(alpha: 0.05);
                  itemText = Colors.yellow[600]!;
                  border = Border.all(color: Colors.yellow.withValues(alpha: 0.2));
                }

                return Tooltip(
                  message: '${ep.number}: ${ep.title}${isFiller ? " (Filler)" : ""}',
                  child: InkWell(
                    onTap: () => widget.onEpisodeChange(cleanId),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(8),
                        border: border,
                      ),
                      child: Text(
                        '${ep.number}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: itemText,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }
}
