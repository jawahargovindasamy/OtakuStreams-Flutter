import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

const List<String> _genres = [
  "Action", "Adventure", "Cars", "Comedy", "Dementia", "Demons", "Drama",
  "Ecchi", "Fantasy", "Game", "Harem", "Historical", "Horror", "Isekai",
  "Josei", "Kids", "Magic", "Martial Arts", "Mecha", "Military", "Music",
  "Mystery", "Parody", "Police", "Psychological", "Romance", "Samurai",
  "School", "Sci-Fi", "Seinen", "Shoujo", "Shoujo Ai", "Shounen", "Shounen Ai",
  "Slice of Life", "Space", "Sports", "Super Power", "Supernatural", "Thriller",
  "Vampire"
];

class FilterPanel extends StatefulWidget {
  final Map<String, dynamic> filters;
  final ValueChanged<Map<String, dynamic>> onFilterChange;
  final VoidCallback onReset;
  final String keyword;

  const FilterPanel({
    super.key,
    required this.filters,
    required this.onFilterChange,
    required this.onReset,
    required this.keyword,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _localFilters;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _localFilters = Map<String, dynamic>.from(widget.filters);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Simple check to sync state from routing changes
    bool changed = false;
    widget.filters.forEach((key, val) {
      if (oldWidget.filters[key] != val) {
        changed = true;
      }
    });
    if (changed) {
      setState(() {
        _localFilters = Map<String, dynamic>.from(widget.filters);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      final genres = List<String>.from(_localFilters['genres'] ?? []);
      if (genres.contains(genre)) {
        genres.remove(genre);
      } else {
        genres.add(genre);
      }
      _localFilters['genres'] = genres;
    });
  }

  void _clearGenres() {
    setState(() {
      _localFilters['genres'] = <String>[];
    });
  }

  void _handleReset() {
    setState(() {
      _localFilters = {
        'type': 'all',
        'status': 'all',
        'rated': 'all',
        'score': 'all',
        'season': 'all',
        'language': 'all',
        'sort': 'default',
        'startDate': '',
        'endDate': '',
        'genres': <String>[],
      };
    });
    widget.onReset();
  }

  void _handleApply() {
    widget.onFilterChange(_localFilters);
  }

  bool get _hasActiveFilters {
    final lf = _localFilters;
    return lf['type'] != 'all' ||
        lf['status'] != 'all' ||
        lf['rated'] != 'all' ||
        lf['score'] != 'all' ||
        lf['season'] != 'all' ||
        lf['language'] != 'all' ||
        lf['sort'] != 'default' ||
        lf['startDate'] != '' ||
        lf['endDate'] != '' ||
        (lf['genres'] as List? ?? []).isNotEmpty;
  }

  int get _activeCount {
    final lf = _localFilters;
    return [
      lf['type'] != 'all',
      lf['status'] != 'all',
      lf['rated'] != 'all',
      lf['score'] != 'all',
      lf['season'] != 'all',
      lf['language'] != 'all',
      lf['sort'] != 'default',
      lf['startDate'] != '',
      lf['endDate'] != '',
      (lf['genres'] as List? ?? []).isNotEmpty,
    ].where((e) => e == true).length;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        if (isStart) {
          _localFilters['startDate'] = formatted;
        } else {
          _localFilters['endDate'] = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genresList = List<String>.from(_localFilters['genres'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb Trail
        _buildBreadcrumb(context),
        const SizedBox(height: 12),

        // Collapsible Filters Panel
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.filter, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Refine your anime discovery',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (_hasActiveFilters)
                            TextButton.icon(
                              onPressed: _handleReset,
                              icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Colors.grey),
                              label: const Text('Reset', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          const SizedBox(width: 8),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                            child: Icon(LucideIcons.chevronDown, color: theme.hintColor, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expanding Area
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 24),

                      // Select Fields Grid (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final crossAxisCount = gridConstraints.maxWidth > 800 ? 6 : (gridConstraints.maxWidth > 500 ? 3 : 2);
                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: crossAxisCount == 6 ? 1.4 : 1.8,
                            ),
                            children: [
                              FilterSelect(
                                placeholder: 'Type',
                                value: _localFilters['type'] ?? 'all',
                                onChange: (val) => setState(() => _localFilters['type'] = val ?? 'all'),
                                options: const [
                                  {'label': 'All Types', 'value': 'all'},
                                  {'label': 'Movie', 'value': 'movie'},
                                  {'label': 'TV Series', 'value': 'tv'},
                                  {'label': 'OVA', 'value': 'ova'},
                                  {'label': 'ONA', 'value': 'ona'},
                                  {'label': 'Special', 'value': 'special'},
                                  {'label': 'Music', 'value': 'music'},
                                ],
                              ),
                              FilterSelect(
                                placeholder: 'Status',
                                value: _localFilters['status'] ?? 'all',
                                onChange: (val) => setState(() => _localFilters['status'] = val ?? 'all'),
                                options: const [
                                  {'label': 'All Status', 'value': 'all'},
                                  {'label': 'Finished Airing', 'value': 'finished-airing'},
                                  {'label': 'Currently Airing', 'value': 'currently-airing'},
                                  {'label': 'Not Yet Aired', 'value': 'not-yet-aired'},
                                ],
                              ),
                              FilterSelect(
                                placeholder: 'Rating',
                                value: _localFilters['rated'] ?? 'all',
                                onChange: (val) => setState(() => _localFilters['rated'] = val ?? 'all'),
                                options: const [
                                  {'label': 'All Ratings', 'value': 'all'},
                                  {'label': 'G - All Ages', 'value': 'g'},
                                  {'label': 'PG - Children', 'value': 'pg'},
                                  {'label': 'PG-13 - Teens', 'value': 'pg-13'},
                                  {'label': 'R - 17+', 'value': 'r'},
                                  {'label': 'R+ - Mild Nudity', 'value': 'r+'},
                                  {'label': 'Rx - Hentai', 'value': 'rx'},
                                ],
                              ),
                              FilterSelect(
                                placeholder: 'Score',
                                value: _localFilters['score'] ?? 'all',
                                onChange: (val) => setState(() => _localFilters['score'] = val ?? 'all'),
                                options: const [
                                  {'label': 'All Scores', 'value': 'all'},
                                  {'label': '10 - Masterpiece', 'value': 'masterpiece'},
                                  {'label': '9 - Great', 'value': 'great'},
                                  {'label': '8 - Very Good', 'value': 'very-good'},
                                  {'label': '7 - Good', 'value': 'good'},
                                  {'label': '6 - Fine', 'value': 'fine'},
                                  {'label': '5 - Average', 'value': 'average'},
                                  {'label': '4 - Bad', 'value': 'bad'},
                                  {'label': '3 - Very Bad', 'value': 'very-bad'},
                                  {'label': '2 - Horrible', 'value': 'horrible'},
                                  {'label': '1 - Appalling', 'value': 'appalling'},
                                ],
                              ),
                              FilterSelect(
                                placeholder: 'Season',
                                value: _localFilters['season'] ?? 'all',
                                onChange: (val) => setState(() => _localFilters['season'] = val ?? 'all'),
                                options: const [
                                  {'label': 'All Seasons', 'value': 'all'},
                                  {'label': 'Spring', 'value': 'spring'},
                                  {'label': 'Summer', 'value': 'summer'},
                                  {'label': 'Fall', 'value': 'fall'},
                                  {'label': 'Winter', 'value': 'winter'},
                                ],
                              ),
                              FilterSelect(
                                placeholder: 'Sort By',
                                value: _localFilters['sort'] ?? 'default',
                                onChange: (val) => setState(() => _localFilters['sort'] = val ?? 'default'),
                                options: const [
                                  {'label': 'Default', 'value': 'default'},
                                  {'label': 'Recently Added', 'value': 'recently-added'},
                                  {'label': 'Recently Updated', 'value': 'recently-updated'},
                                  {'label': 'Name A-Z', 'value': 'name_az'},
                                  {'label': 'Release Date', 'value': 'released-date'},
                                  {'label': 'Most Popular', 'value': 'most-watched'},
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Range picker section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE RANGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.hintColor.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.calendar, size: 14, color: theme.hintColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _localFilters['startDate'] != ''
                                                ? _localFilters['startDate']
                                                : 'Start Date',
                                            style: TextStyle(
                                              color: _localFilters['startDate'] != ''
                                                  ? theme.textTheme.bodyMedium?.color
                                                  : theme.hintColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (_localFilters['startDate'] != '')
                                          IconButton(
                                            icon: const Icon(Icons.clear, size: 12),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => setState(() => _localFilters['startDate'] = ''),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('-', style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.calendar, size: 14, color: theme.hintColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _localFilters['endDate'] != ''
                                                ? _localFilters['endDate']
                                                : 'End Date',
                                            style: TextStyle(
                                              color: _localFilters['endDate'] != ''
                                                  ? theme.textTheme.bodyMedium?.color
                                                  : theme.hintColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (_localFilters['endDate'] != '')
                                          IconButton(
                                            icon: const Icon(Icons.clear, size: 12),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => setState(() => _localFilters['endDate'] = ''),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Genres Checklist Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'GENRES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.hintColor.withValues(alpha: 0.7),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (genresList.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${genresList.length}',
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (genresList.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _clearGenres,
                                  icon: const Icon(Icons.clear, size: 12, color: Colors.red),
                                  label: const Text('Clear genres', style: TextStyle(color: Colors.red, fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Selected Genres list view
                          if (genresList.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: genresList.map((g) {
                                return Chip(
                                  label: Text(g, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  backgroundColor: AppTheme.primaryBlue,
                                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                                  onDeleted: () => _toggleGenre(g),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Genre Choice Grid
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genres.map((g) {
                              final isSelected = genresList.contains(g);
                              return OutlinedButton(
                                onPressed: () => _toggleGenre(g),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? AppTheme.primaryBlue
                                      : theme.brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.black.withValues(alpha: 0.02),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primaryBlue : theme.dividerColor.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      ElevatedButton.icon(
                        onPressed: _hasActiveFilters ? _handleApply : null,
                        icon: const Icon(LucideIcons.filter, size: 16),
                        label: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: theme.disabledColor.withValues(alpha: 0.2),
                          disabledForegroundColor: theme.disabledColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    final theme = Theme.of(context);
    final count = _activeCount;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 13,
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text('/', style: TextStyle(color: theme.dividerColor, fontSize: 13)),
        if (widget.keyword.isNotEmpty) ...[
          Text('Search:', style: TextStyle(color: theme.hintColor, fontSize: 13)),
          Text(
            '"${widget.keyword}"',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else
          Text(
            'Browse All',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (_hasActiveFilters) ...[
          Text('/', style: TextStyle(color: theme.dividerColor, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$count Filter${count != 1 ? 's' : ''} Active',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class FilterSelect extends StatelessWidget {
  final String placeholder;
  final List<Map<String, String>> options;
  final String value;
  final ValueChanged<String?> onChange;
  final IconData? icon;

  const FilterSelect({
    super.key,
    required this.placeholder,
    required this.options,
    required this.value,
    required this.onChange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          placeholder.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.hintColor.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              icon: Icon(Icons.arrow_drop_down, color: theme.hintColor, size: 20),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              onChanged: onChange,
              items: options.map<DropdownMenuItem<String>>((opt) {
                return DropdownMenuItem<String>(
                  value: opt['value'],
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: theme.hintColor),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          opt['label'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
