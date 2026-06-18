import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../core/unified_scaffold.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _activeTab = 'all';

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

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Clear all notifications?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'This will permanently remove all notifications from your history.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                Provider.of<AuthProvider>(context, listen: false).clearNotifications();
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final notifications = context.select<AuthProvider, List<dynamic>>((p) => p.notifications);

    final List<dynamic> filtered = _activeTab == 'unread'
        ? notifications.where((n) => n['read'] == false).toList()
        : notifications;

    final unreadCount = notifications.where((n) => n['read'] == false).length;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.bell, color: Color(0xFF3B82F6), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                if (notifications.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                    onPressed: () => _showClearConfirmation(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab headers
            if (notifications.isNotEmpty) ...[
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _activeTab = 'all'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'all' ? const Color(0xFF3B82F6) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'All',
                            style: TextStyle(
                              color: _activeTab == 'all' ? Colors.white : Colors.grey,
                              fontWeight: _activeTab == 'all' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${notifications.length}',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _activeTab = 'unread'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'unread' ? const Color(0xFF3B82F6) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Unread',
                            style: TextStyle(
                              color: _activeTab == 'unread' ? Colors.white : Colors.grey,
                              fontWeight: _activeTab == 'unread' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
            ],

            // Content List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bellOff, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            _activeTab == 'unread' ? 'No unread notifications' : 'No notifications yet',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _activeTab == 'unread'
                                ? "You're all caught up!"
                                : "We will notify you when new episodes of your watchlist release.",
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final notif = filtered[index];
                        final notifId = notif['_id'];
                        final isUnread = notif['read'] == false;
                        final animeId = notif['animeId'];
                        final episodeNum = notif['episode'] ?? '1';
                        final poster = notif['animeImage'] ?? '';
                        final title = notif['animeTitle'] ?? 'New Episode';
                        final msg = notif['message'] ?? 'New episode is available now!';
                        final dateStr = notif['createdAt'] ?? '';

                        return Container(
                          color: isUnread ? const Color(0xFF3B82F6).withValues(alpha: 0.03) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            leading: GestureDetector(
                              onTap: () {
                                auth.markRead(notifId);
                                context.push('/watch/$animeId/$episodeNum');
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: poster,
                                      width: 50,
                                      height: 75,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                                      errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                                    ),
                                  ),
                                  if (isUnread)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3B82F6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: GestureDetector(
                              onTap: () {
                                auth.markRead(notifId);
                                context.push('/watch/$animeId/$episodeNum');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('NEW EPISODE', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isUnread ? Colors.white : Colors.grey,
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  msg,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _timeAgo(dateStr),
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isUnread
                                ? IconButton(
                                    icon: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 18),
                                    onPressed: () => auth.markRead(notifId),
                                  )
                                : const Icon(LucideIcons.chevronRight, color: Colors.white30, size: 18),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
