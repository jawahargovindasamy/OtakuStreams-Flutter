import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class TrendingRow extends StatelessWidget {
  final List<Anime> trending;

  const TrendingRow({
    super.key,
    required this.trending,
  });

  @override
  Widget build(BuildContext context) {
    if (trending.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: trending.length,
        itemBuilder: (context, index) {
          final item = trending[index];
          final rank = index + 1;
          final title = AnimeUtils.getTitle(context, item);

          return GestureDetector(
            onTap: () => context.push('/${AnimeUtils.slugify(title)}/${item.id}'),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster with Rank overlay
                  Stack(
                    children: [
                      SizedBox(
                        height: 170,
                        width: 130,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.poster,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[850]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      // Rank Badge overlay
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rank <= 3 ? AppTheme.primaryBlue : Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title clamped to 1 line
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
