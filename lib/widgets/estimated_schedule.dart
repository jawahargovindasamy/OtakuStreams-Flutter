import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/data_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'section_header.dart';

class EstimatedSchedule extends StatefulWidget {
  final EdgeInsetsGeometry headerPadding;
  final double contentHorizontalPadding;

  const EstimatedSchedule({
    super.key,
    this.headerPadding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
    this.contentHorizontalPadding = 16.0,
  });

  @override
  State<EstimatedSchedule> createState() => _EstimatedScheduleState();
}

class _EstimatedScheduleState extends State<EstimatedSchedule> {
  List<ScheduledAnime> _scheduledAnimes = [];
  DateTime _selectedScheduleDate = DateTime.now();
  bool _isScheduleLoading = false;
  bool _showAllSchedules = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedScheduleDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduleForDate(_selectedScheduleDate);
      _scrollToDate(_selectedScheduleDate, animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getMonthDays(DateTime date) {
    final year = date.year;
    final month = date.month;
    final totalDays = DateTime(year, month + 1, 0).day;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return List.generate(totalDays, (i) {
      final d = DateTime(year, month, i + 1);
      final weekdayStr = weekdays[d.weekday - 1].toUpperCase();
      final monthStr = months[d.month - 1];
      return {
        'day': weekdayStr,
        'date': i + 1,
        'fullDate': d,
        'month': monthStr,
      };
    });
  }

  void _scrollToDate(DateTime date, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final days = _getMonthDays(date);
    final index = date.day - 1;
    if (index < 0 || index >= days.length) return;

    final double cardItemWidth = 62.0; // 54.0 width + 8.0 margin
    final double selectedCardWidth = 76.0; // 68.0 width + 8.0 margin

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;
    final double contentPadding = 2 * widget.contentHorizontalPadding + 32.0;
    final double chevronSpace = isMobile ? 0.0 : 80.0;
    final double viewportWidth = screenWidth - contentPadding - chevronSpace;

    double targetOffset = (index * cardItemWidth) + (selectedCardWidth / 2) - (viewportWidth / 2);
    final maxScroll = _scrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  Widget _buildDateCard(Map<String, dynamic> dayMap, DateTime today) {
    final dayDate = dayMap['fullDate'] as DateTime;
    final isSelected = dayDate.year == _selectedScheduleDate.year &&
        dayDate.month == _selectedScheduleDate.month &&
        dayDate.day == _selectedScheduleDate.day;
    final isTodayDate = dayDate.year == today.year &&
        dayDate.month == today.month &&
        dayDate.day == today.day;

    final double cardWidth = isSelected ? 68.0 : 54.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: _isScheduleLoading
            ? null
            : () {
                _fetchScheduleForDate(dayDate);
                _scrollToDate(dayDate);
              },
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isSelected
                ? null
                : isTodayDate
                    ? Theme.of(context).cardColor
                    : Theme.of(context).cardColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : isTodayDate
                      ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
              width: isTodayDate && !isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (dayMap['day'] as String).toUpperCase(),
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${dayMap['date']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (dayMap['month'] as String).toUpperCase(),
                style: TextStyle(
                  fontSize: 9.0,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              if (isTodayDate) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.8) 
                            : AppTheme.primaryBlue.withValues(alpha: 0.8),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchScheduleForDate(DateTime date) async {
    if (!mounted) return;
    setState(() {
      _selectedScheduleDate = date;
      _isScheduleLoading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final dateFormatted = '$y-$m-$d';

    try {
      final data = await dataProvider.fetchestimatedschedules(dateFormatted);
      if (mounted) {
        setState(() {
          _scheduledAnimes = data['scheduledAnimes'] ?? [];
          _isScheduleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scheduledAnimes = [];
          _isScheduleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Estimated Schedule', showTime: true, padding: widget.headerPadding),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.contentHorizontalPadding),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateCarousel(),
                const SizedBox(height: 16),
                _buildScheduleEpisodeList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateCarousel() {
    final days = _getMonthDays(_selectedScheduleDate);
    
    final monthsLong = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final headerTitle = '${monthsLong[_selectedScheduleDate.month - 1]} ${_selectedScheduleDate.year}';
    final today = DateTime.now();
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.calendar, color: AppTheme.primaryBlue, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    headerTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_isScheduleLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Loading...',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: days.map((dayMap) => _buildDateCard(dayMap, today)).toList(),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.calendar, color: AppTheme.primaryBlue, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  headerTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_isScheduleLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Loading schedule...',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 16),
              onPressed: _isScheduleLoading
                  ? null
                  : () {
                      final target = (_scrollController.offset - 200.0).clamp(0.0, _scrollController.position.maxScrollExtent);
                      _scrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                disabledBackgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.3),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: days.map((dayMap) => _buildDateCard(dayMap, today)).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 16),
              onPressed: _isScheduleLoading
                  ? null
                  : () {
                      final target = (_scrollController.offset + 200.0).clamp(0.0, _scrollController.position.maxScrollExtent);
                      _scrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                disabledBackgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.3),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleEpisodeList() {
    if (_scheduledAnimes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.calendarX, size: 28, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Text(
              'No episodes scheduled for this date',
              style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for updates',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      );
    }

    const int initialCount = 7;
    final hasMore = _scheduledAnimes.length > initialCount;
    final displayedAnimes = _showAllSchedules ? _scheduledAnimes : _scheduledAnimes.take(initialCount).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedAnimes.length,
          itemBuilder: (context, index) {
            final anime = displayedAnimes[index];
            final title = AnimeUtils.getTitle(context, anime);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () => context.push('/${AnimeUtils.slugify(title)}/${anime.id}'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.clock, size: 12, color: Colors.grey[500]),
                            const SizedBox(height: 2),
                            Text(
                              anime.time,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Episode ${anime.episode}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SUB',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• ${anime.type}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.play, size: 10, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            const Text(
                              'EP ',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                            Text(
                              '${anime.episode}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
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
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllSchedules = !_showAllSchedules;
                });
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAllSchedules ? 'Show Less' : 'Show ${_scheduledAnimes.length - initialCount} More Episodes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllSchedules ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
