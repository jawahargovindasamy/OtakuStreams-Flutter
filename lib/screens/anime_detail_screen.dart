import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/unified_scaffold.dart';
import '../core/utils.dart';
import '../widgets/anime_grid.dart';
import '../widgets/seasons_section.dart';

class AnimeDetailScreen extends StatefulWidget {
  final String id;
  const AnimeDetailScreen({super.key, required this.id});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  bool _loading = true;
  AnimeDetail? _detail;
  bool _isWatchlistUpdating = false;

  static const List<Map<String, String>> _playlistConfig = [
    {'key': 'watching', 'label': 'Watching'},
    {'key': 'plan_to_watch', 'label': 'Plan to Watch'},
    {'key': 'on_hold', 'label': 'On-Hold'},
    {'key': 'completed', 'label': 'Completed'},
    {'key': 'dropped', 'label': 'Dropped'},
    {'key': 'remove', 'label': 'Remove'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnime();
  }

  @override
  void didUpdateWidget(covariant AnimeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadAnime();
    }
  }

  Future<void> _loadAnime() async {
    setState(() {
      _loading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final detail = await dataProvider.fetchanimeinfo(widget.id);

    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  Future<void> _handlePlaylistChange(
    AuthProvider auth,
    dynamic existing,
    Map<String, String> option,
    String name,
    String poster,
  ) async {
    if (_isWatchlistUpdating) return;
    setState(() {
      _isWatchlistUpdating = true;
    });

    final key = option['key']!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (key == 'remove') {
        if (existing != null && existing['_id'] != null) {
          await auth.removeWatchlist(existing['_id']);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Removed from watchlist'),
              backgroundColor: Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (existing != null && existing['_id'] != null) {
          await auth.updateWatchlist(existing['_id'], key);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Updated to ${option['label']}'),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          await auth.addWatchlist(widget.id, name, poster, key);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Added to ${option['label']}'),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWatchlistUpdating = false;
        });
      }
    }
  }

  Widget _buildAddToListButton(
    AuthProvider auth,
    bool isLoggedIn,
    dynamic existing,
    String? currentStatus,
    String name,
    String poster,
  ) {
    final String activeLabel = _playlistConfig.firstWhere(
      (item) => item['key'] == currentStatus,
      orElse: () => {'key': '', 'label': ''},
    )['label']!;

    final buttonChild = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currentStatus != null 
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3) 
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: _isWatchlistUpdating
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentStatus == null) ...[
                  const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text(
                    'Add to List',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ] else ...[
                  const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    activeLabel.isEmpty ? 'Add to List' : activeLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ],
            ),
    );

    final triggerButton = _isWatchlistUpdating
        ? buttonChild
        : (isLoggedIn
            ? PopupMenuButton<Map<String, String>>(
                tooltip: 'Watchlist Status',
                offset: const Offset(0, 44),
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                onSelected: (option) => _handlePlaylistChange(auth, existing, option, name, poster),
                itemBuilder: (context) {
                  return _playlistConfig.map((item) {
                    final isSelected = currentStatus == item['key'];
                    final isRemove = item['key'] == 'remove';

                    return PopupMenuItem<Map<String, String>>(
                      value: item,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['label']!,
                              style: TextStyle(
                                color: isRemove 
                                    ? Colors.redAccent 
                                    : (isSelected ? const Color(0xFF3B82F6) : Colors.white),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            if (isSelected && !isRemove)
                              const Icon(LucideIcons.check, size: 14, color: Color(0xFF3B82F6)),
                          ],
                        ),
                      ),
                    );
                  }).toList();
                },
                child: buttonChild,
              )
            : GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to add to your watchlist'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Opacity(
                  opacity: 0.5,
                  child: buttonChild,
                ),
              ));

    return Align(
      alignment: Alignment.centerLeft,
      child: triggerButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const UnifiedScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_detail == null) {
      return const UnifiedScaffold(
        body: Center(child: Text('Failed to load anime details')),
      );
    }

    final anime = _detail!.anime;
    final auth = context.read<AuthProvider>();
    final language = context.select<AuthProvider, String>((p) => p.language);
    final isLoggedIn = context.select<AuthProvider, bool>((p) => p.isLoggedIn);
    final progress = context.select<AuthProvider, Map<String, dynamic>?>((p) {
      return p.continueWatching.firstWhere(
        (e) => e['animeId'] == widget.id,
        orElse: () => null,
      );
    });
    
    final existing = context.select<AuthProvider, Map<String, dynamic>?>((p) {
      for (final item in p.watchlist) {
        if (item['animeId'] == widget.id) {
          return item;
        }
      }
      return null;
    });
    final String? currentStatus = existing != null ? existing['status'] as String? : null;

    return UnifiedScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Container
            Stack(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: anime.banner != null
                      ? CachedNetworkImage(imageUrl: anime.banner!, fit: BoxFit.cover)
                      : CachedNetworkImage(imageUrl: anime.poster, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster + Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: anime.poster,
                          width: 110,
                          height: 165,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language == 'JP' && anime.jname.isNotEmpty && anime.jname != '?' ? anime.jname : anime.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((language == 'JP' ? anime.name : anime.jname).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                language == 'JP' ? anime.name : anime.jname,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Quick stats
                            Row(
                              children: [
                                if (anime.rating != null) ...[
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(anime.rating!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 16),
                                ],
                                if (anime.type.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      anime.type.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Add to List dropdown button (placed below rating and type stats)
                            _buildAddToListButton(auth, isLoggedIn, existing, currentStatus, anime.name, anime.poster),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Watch Now Button (full width below the poster row)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (progress != null) {
                        context.push(
                          '/watch/${anime.id}/${progress['currentEpisode']}',
                          extra: {
                            'server': progress['server'],
                            'dub': progress['dub'],
                          },
                        );
                      } else {
                        context.push('/watch/${anime.id}/1');
                      }
                    },
                    icon: const Icon(LucideIcons.play, color: Colors.white, size: 20),
                    label: Text(
                      progress != null ? 'Continue Ep ${progress['currentEpisode']}' : 'Watch Now',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    anime.description ?? 'No overview available.',
                    style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Metadata list
                  _buildMetadataSection(),
                  const SizedBox(height: 24),

                  // More Seasons Section
                  SeasonsSection(animeId: widget.id),
                  const SizedBox(height: 24),

                  // Characters
                  if (_detail!.characters.isNotEmpty) ...[
                    const Text('Characters & Voice Actors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCharactersGrid(),
                    const SizedBox(height: 24),
                  ],

                  // Recommendations
                  if (_detail!.recommendations.isNotEmpty) ...[
                    const Text('Recommended For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildRecommendationsRow(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final metadata = [
      {'label': 'Japanese', 'value': _detail!.japaneseTitle},
      {'label': 'Synonyms', 'value': _detail!.synonyms},
      {'label': 'Aired', 'value': _detail!.aired},
      {'label': 'Premiered', 'value': _detail!.premiered},
      {'label': 'Duration', 'value': _detail!.duration},
      {'label': 'Status', 'value': _detail!.status},
      {'label': 'Studios', 'value': _detail!.studios},
      {'label': 'Genres', 'value': _detail!.genres.join(', ')},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: metadata.map((item) {
          if (item['value']!.isEmpty) return const SizedBox.shrink();

          Widget contentWidget;
          if (item['label'] == 'Studios') {
            final studios = _detail!.studios.split(', ').where((s) => s.isNotEmpty).toList();
            contentWidget = Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(studios.length, (idx) {
                final studio = studios[idx];
                final isLast = idx == studios.length - 1;
                return GestureDetector(
                  onTap: () => context.push('/producer/${AnimeUtils.slugify(studio)}'),
                  child: Text(
                    isLast ? studio : '$studio,',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              }),
            );
          } else if (item['label'] == 'Genres') {
            contentWidget = Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _detail!.genres.map((genre) {
                return GestureDetector(
                  onTap: () => context.push('/genre/${Uri.encodeComponent(genre.toLowerCase())}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          } else {
            contentWidget = Text(
              item['value']!,
              style: const TextStyle(fontSize: 13, height: 1.2),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    item['label']!,
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: contentWidget,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCharactersGrid() {
    final items = _detail!.characters.take(6).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : constraints.maxWidth > 650
                ? 2
                : 1;
        final double cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
        const double targetHeight = 72;
        final double aspectRatio = cardWidth / targetHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return CharacterCardWidget(item: items[index]);
          },
        );
      },
    );
  }

  Widget _buildRecommendationsRow() {
    final list = _detail!.recommendations;
    return AnimeGrid(animes: list, padding: EdgeInsets.zero);
  }
}

class CharacterCardWidget extends StatefulWidget {
  final CharacterActor item;
  const CharacterCardWidget({super.key, required this.item});

  @override
  State<CharacterCardWidget> createState() => _CharacterCardWidgetState();
}

class _CharacterCardWidgetState extends State<CharacterCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final char = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
              : Theme.of(context).cardColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Character Image
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: char.characterPoster,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 1.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Character Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    char.characterName.isNotEmpty ? char.characterName : 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isHovered ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    char.characterRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Voice Actor Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (char.voiceActorName != null) ...[
                    Text(
                      char.voiceActorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      char.voiceActorLanguage ?? 'Japanese',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No Voice Actor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Voice Actor Image
            if (char.voiceActorPoster != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: _isHovered
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dstOver)
                        : const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                    child: CachedNetworkImage(
                      imageUrl: char.voiceActorPoster!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[900],
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, size: 20, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
