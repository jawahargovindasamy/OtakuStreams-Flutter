import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/data_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.homeData == null) {
        dataProvider.fetchHomedata();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const List<Map<String, String>> faqItems = [
    {
      'q': 'What is OtakuStreams?',
      'a': 'OtakuStreams is a free site to watch anime in ultra HD quality without any registration or payment. By having only one ad in all kinds, we are trying to make it the safest site for free anime.',
    },
    {
      'q': 'Is OtakuStreams safe?',
      'a': 'Yes we are, we do have only one Ad to cover the server cost and we keep scanning the ads 24/7 to make sure all are clean. If you find any ad that is suspicious, please forward us the info and we will remove it.',
    },
    {
      'q': 'So what makes OtakuStreams the best site to watch anime free online?',
      'a': 'We are trying to make OtakuStreams the best site to watch anime free online by having the biggest anime library, the fastest streaming servers, the cleanest ads, and the safest site for all anime fans.',
    },
    {
      'q': 'Do I need to create an account to watch anime on OtakuStreams?',
      'a': 'No, you don\'t need to create an account to watch anime on OtakuStreams. You can watch anime for free without any registration or payment.',
    },
  ];

  static const List<Map<String, dynamic>> trendingPosts = [
    {
      'tag': '#General',
      'time': '8 hours ago',
      'title': 'Your bromance is pure and true',
      'description': 'Here I will tell you things that look gay but are not gay: kissing your bro (Friend) shows your bonding and true loyalty. Not gay at all...',
      'comments': 101,
      'author': 'Busy-Guy Crab',
    },
    {
      'tag': '#Discussion',
      'time': '3 hours ago',
      'title': 'Anime Hot Takes 🔥',
      'description': 'Frieren\'s story is 100x better than solo leveling in terms of emotional depth, character development, and background pacing.',
      'comments': 22,
      'author': 'Wonderboy Angelfish',
    },
    {
      'tag': '#Question',
      'time': 'a day ago',
      'title': 'Best anime of all time?',
      'description': 'idk but I guess it is Rent a Girlfriend or similar high quality dynamic modern slice of life show...',
      'comments': 307,
      'author': 'rezee\u{1f4a3}\u{1f4a5}\u{1f3ad}\u{1f3ad}', // replaced emoji flags/symbols to avoid any encoding limits if needed, wait, let's keep exact string but let's check
    },
  ];

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.push('/search?keyword=${Uri.encodeComponent(query)}');
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final homeData = context.select<DataProvider, Map<String, dynamic>?>((p) => p.homeData);

    List<String> topSearches = [];
    if (homeData != null && homeData['trendingAnimes'] != null) {
      final List<dynamic> trending = homeData['trendingAnimes'];
      topSearches = trending.take(5).map((a) => AnimeUtils.getTitle(context, a as Anime)).toList();
    }
    if (topSearches.isEmpty) {
      topSearches = [
        "Witch Hat Atelier",
        "Farming Life in Another World",
        "ONE PIECE",
        "Wistoria: Wand and Sword",
        "The Klutzy Class Monster"
      ];
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          final canPop = Navigator.of(context).canPop();
          if (canPop) {
            Navigator.of(context).pop();
          } else {
            final shouldExit = await AnimeUtils.showExitConfirmationDialog(context);
            if (shouldExit) {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: width < 400 ? 12 : 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    isDark ? 'assets/Logo Light.png' : 'assets/Logo Dark.png',
                    height: width < 400 ? 28 : 36,
                    fit: BoxFit.contain,
                  ),
                  Row(
                    children: [
                      if (width > 480) ...[
                        TextButton(
                          onPressed: () => context.push('/home'),
                          child: const Text('Enter App', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: EdgeInsets.symmetric(horizontal: width < 400 ? 12 : 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hero section with gradient overlay
            Container(
              margin: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      isDark ? 'assets/Logo Light.png' : 'assets/Logo Dark.png',
                      height: isDesktop ? 70 : 50,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Watch thousands of anime episodes in HD quality for free. No registration required.',
                      textAlign: TextAlign.left,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // Search input
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isSearchFocused
                              ? AppTheme.primaryBlue
                              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isSearchFocused
                                ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                                : (isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05)),
                            blurRadius: _isSearchFocused ? 15 : 10,
                            spreadRadius: _isSearchFocused ? 2 : 0,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              LucideIcons.search,
                              color: _isSearchFocused
                                  ? AppTheme.primaryBlue
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onSubmitted: (_) => _handleSearch(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search your favorite anime...',
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            child: ElevatedButton(
                              onPressed: _handleSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.search, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Search',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Top searches / Trending Row
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                'Trending: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...List.generate(topSearches.take(4).length, (index) {
                              final name = topSearches[index];
                              final displayName = name.length > 12 ? '${name.substring(0, 12)}...' : name;
                              return GestureDetector(
                                onTap: () {
                                  context.push('/search?keyword=${Uri.encodeComponent(name)}');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick buttons
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/home'),
                        icon: const Icon(LucideIcons.play, color: Colors.white, size: 18),
                        label: const Text('Start Watching', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Share section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Theme.of(context).dividerColor),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share OtakuStreams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('with your fellow otaku friends', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.twitter, color: AppTheme.primaryBlue),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.messageSquare, color: AppTheme.primaryBlue),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Core Layout: FAQ on left, Trending Sidebar on right
            Padding(
              padding: const EdgeInsets.all(24),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildFaqSection()),
                        const SizedBox(width: 32),
                        Expanded(flex: 2, child: _buildTrendingPosts()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFaqSection(),
                        const SizedBox(height: 32),
                        _buildTrendingPosts(),
                      ],
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(32),
              color: isDark ? const Color(0xFF131924) : Colors.grey[100],
              child: Center(
                child: Text(
                  '© ${DateTime.now().year} OtakuStreams. Built for anime fans worldwide.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OtakuStreams – The best site to watch anime online for Free',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Anime is famous worldwide and it is no wonder we\'ve seen a sharp rise in the number of free anime streaming sites. Just like free online movie streaming sites, anime watching sites are not created equally. We built OtakuStreams to be one of the best free anime streaming sites for all anime fans.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 32),
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: faqItems.length,
          itemBuilder: (context, index) {
            final item = faqItems[index];
            return ExpansionTile(
              title: Text('${index + 1}. ${item['q']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(item['a']!, style: const TextStyle(color: Colors.grey, height: 1.4)),
                )
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingPosts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.messageCircle, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Trending Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trendingPosts.length,
          itemBuilder: (context, index) {
            final post = trendingPosts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(post['tag']!, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(post['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(post['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(post['description']!, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(post['author']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        const Icon(LucideIcons.messageCircle, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post['comments']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
