import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../core/unified_scaffold.dart';
import '../widgets/continue_watching_grid.dart';

class ContinueWatchingScreen extends StatefulWidget {
  const ContinueWatchingScreen({super.key});

  @override
  State<ContinueWatchingScreen> createState() => _ContinueWatchingScreenState();
}

class _ContinueWatchingScreenState extends State<ContinueWatchingScreen> {
  bool _isClearing = false;
  final Set<String> _deletingIds = {};

  void _showClearConfirmation(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final count = auth.continueWatching.length;

    showDialog(
      context: context,
      barrierDismissible: !_isClearing,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Clear All History?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently remove all $count items from your continue watching list. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isClearing ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[300],
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isClearing
                                ? null
                                : () async {
                                    setDialogState(() {
                                      _isClearing = true;
                                    });
                                    setState(() {});
                                    final navigator = Navigator.of(ctx);
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    try {
                                      await Provider.of<AuthProvider>(context, listen: false)
                                          .clearContinueWatching();
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Watch history cleared. All items have been removed.'),
                                          backgroundColor: Color(0xFF1E293B),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Failed to clear: $e');
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isClearing = false;
                                        });
                                      }
                                      navigator.pop();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isClearing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Clear All'),
                          ),
                        ),
                      ],
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

  Future<void> _deleteItem(String animeId) async {
    if (_deletingIds.contains(animeId)) return;
    setState(() {
      _deletingIds.add(animeId);
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .removeContinueWatching(animeId);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Removed from continue watching'),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(animeId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = context.select<AuthProvider, List<dynamic>>((p) => p.continueWatching);

    return UnifiedScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Continue Watching',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (list.isNotEmpty)
                  _isClearing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _showClearConfirmation(context),
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 14),
                          label: const Text('Clear All'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: 24),
            // Items List
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.playCircle,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Continue Watching',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              "Start watching some anime and they'll appear here for easy access.",
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ContinueWatchingGrid(
                      items: list,
                      deletingIds: _deletingIds,
                      onDelete: _deleteItem,
                      isDesktop: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
