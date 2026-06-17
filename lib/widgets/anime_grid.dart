import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/anime.dart';
import '../core/utils.dart';

class AnimeGrid extends StatelessWidget {
  final List<Anime> animes;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AnimeGrid({
    super.key,
    required this.animes,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (animes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1100
              ? 6
              : constraints.maxWidth > 800
                  ? 4
                  : constraints.maxWidth > 480
                      ? 3
                      : 2;
          return GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: animes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.60,
            ),
            itemBuilder: (context, index) {
              final item = animes[index];
              final title = AnimeUtils.getTitle(context, item);

              return GestureDetector(
                onTap: () => context.push('/${AnimeUtils.slugify(title)}/${item.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.poster,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[850]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.type.isNotEmpty) ...[
                          Text(item.type.replaceAll('_', ' '), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(width: 4),
                        ],
                        if (item.year != null) ...[
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('${item.year}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(width: 4),
                        ],
                        if (item.rating != null) ...[
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!,
                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
