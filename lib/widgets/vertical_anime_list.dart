import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class VerticalAnimeList extends StatelessWidget {
  final String title;
  final List<Anime> listItems;
  final String link;
  final bool isSidebarRankMode;

  const VerticalAnimeList({
    super.key,
    required this.title,
    required this.listItems,
    required this.link,
    this.isSidebarRankMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (listItems.isEmpty) return const SizedBox.shrink();

    if (isSidebarRankMode) {
      return _buildSidebarRankList(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column Header Row with "View All" link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push(link),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Standard card column list
        Column(
          children: List.generate(listItems.length.clamp(0, 5), (index) {
            final item = listItems[index];
            final itemTitle = AnimeUtils.getTitle(context, item);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: GestureDetector(
                onTap: () => context.push('/${AnimeUtils.slugify(itemTitle)}/${item.id}'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Poster image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.poster,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[850]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (item.type.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                if (item.year != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${item.year}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                if (item.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 10),
                                        const SizedBox(width: 2),
                                        Text(
                                          item.rating!,
                                          style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSidebarRankList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: listItems.length.clamp(0, 10),
      itemBuilder: (context, index) {
        final item = listItems[index];
        final rank = index + 1;
        final itemTitle = AnimeUtils.getTitle(context, item);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () => context.push('/${AnimeUtils.slugify(itemTitle)}/${item.id}'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  // Rank overlay / indicator in circle matching standard style
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? AppTheme.primaryBlue : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Poster image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.poster,
                      width: 44,
                      height: 66,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[850]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.type.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.type.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            if (item.year != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${item.year}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (item.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.rating!,
                                      style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
