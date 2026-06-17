import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'section_header.dart';

class GenresList extends StatefulWidget {
  final List<String> genres;

  const GenresList({
    super.key,
    required this.genres,
  });

  @override
  State<GenresList> createState() => _GenresListState();
}

class _GenresListState extends State<GenresList> {
  bool _showAllGenres = false;

  Color _getGenreColor(String genre) {
    int hash = 0;
    for (int i = 0; i < genre.length; i++) {
      hash = genre.codeUnitAt(i) + ((hash << 5) - hash);
    }
    double hue = (hash % 360).toDouble().abs();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.7).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.genres.isEmpty) return const SizedBox.shrink();

    const int maxInitial = 24;
    final displayGenres = _showAllGenres ? widget.genres : widget.genres.take(maxInitial).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Genres', padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const int crossAxisCount = 3;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayGenres.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final genre = displayGenres[index];
                      final dotColor = _getGenreColor(genre);
                      return GestureDetector(
                        onTap: () {
                          context.push('/genre/${Uri.encodeComponent(genre.toLowerCase())}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  genre,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              if (widget.genres.length > maxInitial) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllGenres = !_showAllGenres;
                    });
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllGenres ? 'Show Less' : 'Show More',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllGenres ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
