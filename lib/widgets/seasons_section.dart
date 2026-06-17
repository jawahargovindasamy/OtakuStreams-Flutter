import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'section_header.dart';

class SeasonEntry {
  final String id;
  final int? malId;
  final String title;
  final int? year;
  final String? format;

  SeasonEntry({
    required this.id,
    this.malId,
    required this.title,
    this.year,
    this.format,
  });
}

// Global in-memory cache to store full franchise season chains for each anime ID
final Map<String, List<SeasonEntry>> _seasonsCache = {};

class SeasonsSection extends StatefulWidget {
  final String animeId;

  const SeasonsSection({
    super.key,
    required this.animeId,
  });

  @override
  State<SeasonsSection> createState() => _SeasonsSectionState();
}

class _SeasonsSectionState extends State<SeasonsSection> {
  List<SeasonEntry> _seasons = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSeasonsChain();
  }

  @override
  void didUpdateWidget(covariant SeasonsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animeId != widget.animeId) {
      _loadSeasonsChain();
    }
  }

  Future<void> _loadSeasonsChain() async {
    final stringId = widget.animeId;
    if (stringId.isEmpty) return;

    // Check in-memory cache first
    if (_seasonsCache.containsKey(stringId)) {
      if (mounted) {
        setState(() {
          _seasons = _seasonsCache[stringId]!;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      final Set<String> visited = {};
      final List<SeasonEntry> prequels = [];
      final List<SeasonEntry> sequels = [];

      String formatTitle(Map<String, dynamic>? node) {
        if (node == null) return 'Unknown Title';
        final titleMap = node['title'] ?? {};
        return titleMap['english'] ?? titleMap['romaji'] ?? titleMap['native'] ?? 'Unknown Title';
      }

      // Fetch starting node
      final startNode = await dataProvider.fetchmediarelations(stringId);
      if (startNode == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final startEntry = SeasonEntry(
        id: startNode['id'].toString(),
        malId: startNode['idMal'],
        title: formatTitle(startNode),
        year: startNode['startDate']?['year'] ?? startNode['seasonYear'],
        format: startNode['format']?.toString().toUpperCase(),
      );

      visited.add(startEntry.id);

      // Traverse Prequels (limit depth to 5 to match React logic)
      Map<String, dynamic>? currentPrequel = startNode;
      int prequelDepth = 0;

      while (currentPrequel != null && prequelDepth < 5) {
        final relations = currentPrequel['relations'] ?? {};
        final edges = relations['edges'] as List? ?? [];
        
        final prequelEdge = edges.firstWhere(
          (edge) => edge['relationType'] == 'PREQUEL' && edge['node']?['type'] == 'ANIME',
          orElse: () => null,
        );

        if (prequelEdge != null && prequelEdge['node']?['id'] != null) {
          final nextId = prequelEdge['node']['id'].toString();
          if (visited.contains(nextId)) break;

          visited.add(nextId);
          try {
            final nodeData = await dataProvider.fetchmediarelations(nextId);
            if (nodeData != null) {
              currentPrequel = nodeData;
              prequels.add(SeasonEntry(
                id: nodeData['id'].toString(),
                malId: nodeData['idMal'],
                title: formatTitle(nodeData),
                year: nodeData['startDate']?['year'] ?? nodeData['seasonYear'],
                format: nodeData['format']?.toString().toUpperCase(),
              ));
            } else {
              break;
            }
          } catch (e) {
            debugPrint('Error fetching prequel season: $e');
            break;
          }
        } else {
          break;
        }
        prequelDepth++;
      }

      // Traverse Sequels (limit depth to 5 to match React logic)
      Map<String, dynamic>? currentSequel = startNode;
      int sequelDepth = 0;

      while (currentSequel != null && sequelDepth < 5) {
        final relations = currentSequel['relations'] ?? {};
        final edges = relations['edges'] as List? ?? [];

        final sequelEdge = edges.firstWhere(
          (edge) => edge['relationType'] == 'SEQUEL' && edge['node']?['type'] == 'ANIME',
          orElse: () => null,
        );

        if (sequelEdge != null && sequelEdge['node']?['id'] != null) {
          final nextId = sequelEdge['node']['id'].toString();
          if (visited.contains(nextId)) break;

          visited.add(nextId);
          try {
            final nodeData = await dataProvider.fetchmediarelations(nextId);
            if (nodeData != null) {
              currentSequel = nodeData;
              sequels.add(SeasonEntry(
                id: nodeData['id'].toString(),
                malId: nodeData['idMal'],
                title: formatTitle(nodeData),
                year: nodeData['startDate']?['year'] ?? nodeData['seasonYear'],
                format: nodeData['format']?.toString().toUpperCase(),
              ));
            } else {
              break;
            }
          } catch (e) {
            debugPrint('Error fetching sequel season: $e');
            break;
          }
        } else {
          break;
        }
        sequelDepth++;
      }

      // Combine prequel list (reverse order chronologically), start node, and sequels list
      final fullChain = [
        ...prequels.reversed,
        startEntry,
        ...sequels,
      ];

      // Save built chain in-memory for all IDs in the franchise chain
      for (final entry in fullChain) {
        _seasonsCache[entry.id] = fullChain;
      }

      if (mounted) {
        setState(() {
          _seasons = fullChain;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to build seasons franchise chain: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'More Seasons', padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Only render if there's a franchise chain (i.e. more than just the current anime)
    if (_seasons.length <= 1) {
      return const SizedBox.shrink();
    }

    final activeIndex = _seasons.indexWhere((s) => s.id == widget.animeId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'More Seasons', padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100
                ? 4
                : constraints.maxWidth > 800
                    ? 3
                    : constraints.maxWidth > 480
                        ? 2
                        : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _seasons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 480 ? 2.1 : 3.8,
              ),
              itemBuilder: (context, index) {
                final season = _seasons[index];
                final isActive = season.id == widget.animeId;

                String label = 'Season';
                if (isActive) {
                  label = 'Current Season';
                } else if (activeIndex != -1) {
                  label = index < activeIndex ? 'Prequel' : 'Sequel';
                }

                final chronologicalNumber = (index + 1).toString().padLeft(2, '0');

                return GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      context.push('/${AnimeUtils.slugify(season.title)}/${season.id}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: 0.18),
                                AppTheme.primaryBlue.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActive
                          ? null
                          : Theme.of(context).cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primaryBlue.withValues(alpha: 0.6)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Chronological watermark number
                        Positioned(
                          top: -2,
                          right: 0,
                          child: Opacity(
                            opacity: isActive ? 0.22 : 0.08,
                            child: Text(
                              chronologicalNumber,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isActive ? AppTheme.primaryBlue : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        // Content layout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Label row
                            Row(
                              children: [
                                if (isActive) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: isActive ? AppTheme.primaryBlue : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            // Title text
                            Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(right: 32),
                                child: Text(
                                  season.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                            // Footer row: format & year
                            Row(
                              children: [
                                if (season.format != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isActive
                                            ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                                            : Theme.of(context).dividerColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      season.format!,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: isActive ? AppTheme.primaryBlue : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (season.year != null)
                                  Text(
                                    '${season.year}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
