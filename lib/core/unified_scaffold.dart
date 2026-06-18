import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/anime.dart';
import 'theme.dart';
import 'utils.dart';

/* ================= SEARCH DELEGATE ================= */

class AnimeSearchDelegate extends SearchDelegate {
  final DataProvider dataProvider;

  AnimeSearchDelegate(this.dataProvider);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) return const Center(child: Text('Search for anime...'));
    
    return FutureBuilder<Map<String, dynamic>>(
      future: dataProvider.fetchsearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data?['animes'] as List).isEmpty) {
          return const Center(child: Text('No results found'));
        }

        final List<Anime> list = snapshot.data!['animes'];

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return GestureDetector(
              onTap: () {
                close(context, null);
                context.push('/${AnimeUtils.slugify(item.name)}/${item.id}');
              },
              child: Card(
                color: Theme.of(context).cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: CachedNetworkImage(
                          imageUrl: item.poster,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(AnimeUtils.getTitle(context, item), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) return const Center(child: Text('Type to search anime...'));

    return FutureBuilder<Map<String, dynamic>>(
      future: dataProvider.fetchsearch(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final List<Anime> list = snapshot.data?['animes'] ?? [];
        return ListView.builder(
          itemCount: list.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final item = list[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(imageUrl: item.poster, width: 40, height: 60, fit: BoxFit.cover),
              ),
              title: Text(AnimeUtils.getTitle(context, item)),
              subtitle: Text(item.type),
              onTap: () {
                close(context, null);
                context.push('/${AnimeUtils.slugify(item.name)}/${item.id}');
              },
            );
          },
        );
      },
    );
  }
}

/* ================= DRAWER ================= */

class NavigationDrawerMenu extends StatelessWidget {
  const NavigationDrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;

    final navItems = [
      {'path': '/home', 'label': 'Home', 'icon': LucideIcons.home},
      {'path': '/most-popular', 'label': 'Most Popular', 'icon': LucideIcons.flame},
      {'path': '/movie', 'label': 'Movies', 'icon': LucideIcons.film},
      {'path': '/tv', 'label': 'TV Series', 'icon': LucideIcons.tv},
      {'path': '/ova', 'label': 'OVAs', 'icon': LucideIcons.layers},
      {'path': '/ona', 'label': 'ONAs', 'icon': LucideIcons.playCircle},
      {'path': '/special', 'label': 'Specials', 'icon': LucideIcons.sparkles},
    ];

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header with Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'CLOSE MENU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Logo Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Image.asset(
                  isDark ? 'assets/Logo Light.png' : 'assets/Logo Dark.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Divider(height: 1),

            // 3. Mobile Controls Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Shuffle/Random button
                  _buildShuffleButton(
                    context: context,
                    icon: LucideIcons.shuffle,
                    tooltip: 'Random Anime',
                    onPressed: () async {
                      final dataProvider = Provider.of<DataProvider>(context, listen: false);
                      try {
                        final result = await dataProvider.fetchsearch('popular');
                        final animes = result['animes'] as List?;
                        if (animes != null && animes.isNotEmpty && context.mounted) {
                          final random = animes[DateTime.now().millisecond % animes.length];
                          Navigator.pop(context);
                          context.push('/${AnimeUtils.slugify(random.name)}/${random.id}');
                        }
                      } catch (e) {
                        debugPrint('Random anime error: $e');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildLanguageToggle(context, authProvider),
                  const SizedBox(width: 12),
                  _buildThemeToggle(context, authProvider),
                ],
              ),
            ),
            const Divider(height: 1),

            // 5. Nav Scroll List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  // Check if this path matches active route
                  final bool isActive = GoRouterState.of(context).uri.toString().startsWith(item['path'] as String);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(item['path'] as String);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 18,
                              color: isActive ? AppTheme.primaryBlue : Colors.grey[500],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive ? AppTheme.primaryBlue : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Auth buttons at bottom for logged-out users
            if (!isLoggedIn) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Sign in to sync your watchlist and track your progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/register');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                        ),
                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // User info and Logout button at bottom for logged-in users
            if (isLoggedIn) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  children: [
                    // User info card (Avatar + Name & Email)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.primaryBlue.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: user?['avatar'] != null && (user?['avatar'] as String).isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user!['avatar'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, error, stackTrace) => Center(
                                          child: Text(
                                            (user['username'] as String)[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        (user?['username'] as String? ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?['username'] ?? 'User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user?['email'] != null && (user?['email'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      user!['email'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Redesigned Logout button with icon
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          authProvider.logout();
                          context.go('/');
                        },
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        label: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]


          ],
        ),
      ),
    );
  }

  Widget _buildShuffleButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 80,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 16),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, AuthProvider authProvider) {
    final currentLang = authProvider.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 80,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageItem(
              label: 'EN',
              isActive: currentLang == 'EN',
              onTap: () => authProvider.setLanguage('EN'),
            ),
          ),
          Expanded(
            child: _buildLanguageItem(
              label: 'JP',
              isActive: currentLang == 'JP',
              onTap: () => authProvider.setLanguage('JP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, AuthProvider authProvider) {
    final isDark = authProvider.themeMode == ThemeMode.dark;
    
    return GestureDetector(
      onTap: () => authProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 80,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  LucideIcons.sun,
                  size: 13,
                  color: isDark ? Colors.grey[700] : Colors.amber[600],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  LucideIcons.moon,
                  size: 13,
                  color: isDark ? Colors.indigo[400] : Colors.grey[400],
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(
                  isDark ? LucideIcons.moon : LucideIcons.sun,
                  size: 12,
                  color: isDark ? Colors.indigo[300] : Colors.amber[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/* ================= UNIFIED SCAFFOLD ================= */

class UnifiedScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBarBottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const UnifiedScaffold({
    super.key,
    required this.body,
    this.appBarBottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  State<UnifiedScaffold> createState() => _UnifiedScaffoldState();
}

class _UnifiedScaffoldState extends State<UnifiedScaffold> {
  bool _isSearchOpen = false;
  String _searchQuery = '';
  List<Anime> _suggestions = [];
  bool _isLoadingSuggestions = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _debounceTimer?.cancel();
    setState(() {
      _isLoadingSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        final result = await dataProvider.fetchsearch(query);
        if (mounted && _searchQuery == query) {
          setState(() {
            _suggestions = List<Anime>.from(result['animes'] ?? []);
          });
        }
      } catch (e) {
        debugPrint('Search suggestions fetch error: $e');
      } finally {
        if (mounted && _searchQuery == query) {
          setState(() {
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  Widget _buildSearchOverlay(BuildContext context, bool isDark) {
    if (!_isSearchOpen) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevents tapping from closing search if clicked inside search panel
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.98) : Colors.white.withValues(alpha: 0.98),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Redesigned Search Box Row (with custom single-border text field)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? AppTheme.primaryBlue
                              : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(LucideIcons.search, size: 16, color: Colors.grey),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  setState(() {
                                    _isSearchOpen = false;
                                  });
                                  context.push('/search?keyword=${Uri.encodeComponent(val.trim())}');
                                }
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Search anime...',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          // "Filter" button
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isSearchOpen = false;
                                });
                                context.push('/search');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(60, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // 2. Suggestions / Empty State below
              if (_searchQuery.trim().isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 32,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Type to search anime...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: _isLoadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _suggestions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No results found',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _suggestions.length.clamp(0, 6) + (_suggestions.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                final bool isButton = index == _suggestions.length.clamp(0, 6);
                                if (isButton) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSearchOpen = false;
                                        });
                                        final trimmed = _searchQuery.trim();
                                        context.push('/search?keyword=${Uri.encodeComponent(trimmed)}');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'View all results',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  );
                                }

                                final item = _suggestions[index];
                                final title = AnimeUtils.getTitle(context, item);
                                
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isSearchOpen = false;
                                      _searchController.clear();
                                      _suggestions = [];
                                      _searchQuery = '';
                                    });
                                    context.push('/${AnimeUtils.slugify(item.name)}/${item.id}');
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Poster Thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: item.poster,
                                            width: 44,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Details
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
                                              Text(
                                                item.name != title ? item.name : item.jname,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
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
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.08)
                                                            : Colors.black.withValues(alpha: 0.05),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        item.type.replaceAll('_', ' '),
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  if (item.year != null)
                                                    Text(
                                                      '${item.year}',
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                    ),
                                                  if (item.rating != null)
                                                    Row(
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
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBackdrop(BuildContext context) {
    if (!_isSearchOpen) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSearchOpen = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _timeAgo(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(parsed);
      if (diff.inDays >= 1) return '${diff.inDays} days ago';
      if (diff.inHours >= 1) return '${diff.inHours} hours ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} minutes ago';
      return 'just now';
    } catch (e) {
      return '';
    }
  }

  Widget _buildNavbarAlertIcon(
    BuildContext context,
    int unreadCount,
    AuthProvider authProvider,
    bool isDark,
  ) {
    final notifications = authProvider.notifications;

    return PopupMenuButton<void>(
      offset: const Offset(0, 48),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08) 
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      icon: Badge(
        label: Text('$unreadCount'),
        isLabelVisible: unreadCount > 0,
        child: const Icon(LucideIcons.bell, size: 20),
      ),
      padding: EdgeInsets.zero,
      onOpened: () {
        authProvider.fetchNotifications();
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // Notifications list
                  Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: notifications.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.bell,
                                  size: 40,
                                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "We'll notify you when new episodes arrive",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              final isUnread = item['read'] == false;
                              final dateStr = item['createdAt'] ?? '';

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  authProvider.markRead(item['_id']);
                                  context.push('/watch/${item['animeId']}/${item['episode'] ?? '1'}');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  color: isUnread
                                      ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image + unread dot stack
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              imageUrl: item['animeImage'] ?? '',
                                              width: 40,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(color: Colors.grey[900]),
                                              errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                                            ),
                                          ),
                                          if (isUnread)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['animeTitle'] ?? 'New Episode',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['message'] ?? 'New episode available NOW!',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _timeAgo(dateStr),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer
                  if (notifications.isNotEmpty) ...[
                    const Divider(height: 1, thickness: 1),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/notification');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'View all notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildNavbarProfileIcon(
    BuildContext context,
    Map<String, dynamic>? user,
    bool isDark,
    AuthProvider authProvider,
  ) {
    final username = user?['username'] ?? 'User';
    final email = user?['email'] ?? '';
    final avatar = user?['avatar'] as String?;

    return PopupMenuButton<void>(
      offset: const Offset(0, 48),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08) 
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: avatar != null && avatar.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatar,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => Center(
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) {
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header (Username & Email)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // Menu Items
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.user,
                    label: 'Profile',
                    iconBgColor: isDark 
                        ? Colors.blueGrey.withValues(alpha: 0.15) 
                        : Colors.blueGrey.withValues(alpha: 0.08),
                    iconColor: isDark ? Colors.blue[300]! : Colors.blueGrey[700]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.playCircle,
                    label: 'Continue Watching',
                    iconBgColor: isDark 
                        ? Colors.teal.withValues(alpha: 0.15) 
                        : Colors.teal.withValues(alpha: 0.08),
                    iconColor: isDark ? Colors.teal[300]! : Colors.teal[700]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/continue-watching');
                    },
                  ),
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.heart,
                    label: 'Watchlist',
                    iconBgColor: isDark 
                        ? Colors.pink.withValues(alpha: 0.15) 
                        : Colors.pink.withValues(alpha: 0.08),
                    iconColor: isDark ? Colors.pink[300]! : Colors.pink[700]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/watchlist');
                    },
                  ),
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.bell,
                    label: 'Notification',
                    iconBgColor: isDark 
                        ? Colors.purple.withValues(alpha: 0.15) 
                        : Colors.purple.withValues(alpha: 0.08),
                    iconColor: isDark ? Colors.purple[300]! : Colors.purple[700]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notification');
                    },
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    iconBgColor: isDark 
                        ? Colors.grey.withValues(alpha: 0.15) 
                        : Colors.grey.withValues(alpha: 0.08),
                    iconColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildPopupItem(
                    context: context,
                    icon: LucideIcons.logOut,
                    label: 'Logout',
                    iconBgColor: isDark 
                        ? Colors.red.withValues(alpha: 0.15) 
                        : Colors.red.withValues(alpha: 0.08),
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      authProvider.logout();
                      context.go('/');
                    },
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildPopupItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;
    final unreadCount = authProvider.notifications.where((n) => n['read'] != true).length;

    return Scaffold(
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Image.asset(
          isDark ? 'assets/Logo Light.png' : 'assets/Logo Dark.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? LucideIcons.x : LucideIcons.search),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (_isSearchOpen) {
                  _searchFocusNode.requestFocus();
                } else {
                  _searchFocusNode.unfocus();
                }
              });
            },
          ),
          if (isLoggedIn) ...[
            _buildNavbarAlertIcon(context, unreadCount, authProvider, isDark),
            _buildNavbarProfileIcon(context, user, isDark, authProvider),
            const SizedBox(width: 8),
          ] else ...[
            Center(
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
        bottom: widget.appBarBottom,
      ),
      drawer: const NavigationDrawerMenu(),
      body: Stack(
        children: [
          widget.body,
          _buildSearchBackdrop(context),
          _buildSearchOverlay(context, isDark),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
