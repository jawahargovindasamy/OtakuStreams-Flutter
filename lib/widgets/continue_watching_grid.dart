import 'package:flutter/material.dart';
import 'continue_watching_card.dart';

/// A responsive grid that displays a list of continue watching cards.
///
/// Unifies the grid rendering logic between the homepage (mobile & desktop)
/// and the dedicated continue watching history screen.
class ContinueWatchingGrid extends StatelessWidget {
  final List<dynamic> items;
  final Set<String> deletingIds;
  final Function(String) onDelete;
  final int? limit;
  final bool isDesktop;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ContinueWatchingGrid({
    super.key,
    required this.items,
    required this.deletingIds,
    required this.onDelete,
    this.limit,
    this.isDesktop = false,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = limit != null ? items.take(limit!).toList() : items;

    return LayoutBuilder(
      builder: (context, gridConstraints) {
        final gridWidth = gridConstraints.maxWidth;
        
        // Calculate cross axis columns responsively
        int crossAxisCount;
        if (isDesktop) {
          crossAxisCount = gridWidth > 1100
              ? 5
              : gridWidth > 800
                  ? 4
                  : gridWidth > 480
                      ? 3
                      : 2;
        } else {
          crossAxisCount = gridWidth > 1100
              ? 6
              : gridWidth > 800
                  ? 4
                  : gridWidth > 480
                      ? 3
                      : 2;
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.53,
          ),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final item = displayList[index];
            final animeId = item['animeId'] ?? '';
            final isDeleting = deletingIds.contains(animeId);

            return ContinueWatchingCard(
              item: item,
              onDelete: () => onDelete(animeId),
              isDeleting: isDeleting,
            );
          },
        );
      },
    );
  }
}
