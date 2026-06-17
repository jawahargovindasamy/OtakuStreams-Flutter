import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import 'section_header.dart';
import 'vertical_anime_list.dart';

class Top10Sidebar extends StatefulWidget {
  final Map<String, dynamic> homeData;

  const Top10Sidebar({
    super.key,
    required this.homeData,
  });

  @override
  State<Top10Sidebar> createState() => _Top10SidebarState();
}

class _Top10SidebarState extends State<Top10Sidebar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top10Data = widget.homeData['top10Animes'];
    if (top10Data == null) return const SizedBox.shrink();

    final todayList = List<Anime>.from(top10Data['today'] ?? []);
    final weekList = List<Anime>.from(top10Data['week'] ?? []);
    final monthList = List<Anime>.from(top10Data['month'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Top 10', padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        // Pill switcher tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: List.generate(3, (index) {
              final periods = ['Today', 'Week', 'Month'];
              final isSelected = _tabController.index == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      periods[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          child: SizedBox(
            height: 925,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                VerticalAnimeList(title: '', listItems: todayList, link: '', isSidebarRankMode: true),
                VerticalAnimeList(title: '', listItems: weekList, link: '', isSidebarRankMode: true),
                VerticalAnimeList(title: '', listItems: monthList, link: '', isSidebarRankMode: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
