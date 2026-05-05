import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'follow_list_sheet.dart';
import 'post_detail_sheet.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key, this.onRead});
  final VoidCallback? onRead;

  @override
  State<NotificationTab> createState() => NotificationTabState();
}

class NotificationTabState extends State<NotificationTab> {
  List<AppNotification> _items = [];
  bool _loading = true;
  bool _loaded = false;

  Future<void> reload() => _load();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = SessionScope.of(context);
      final items = await session.api.fetchNotifications();
      if (mounted) setState(() { _items = items; _loading = false; });
      session.api.markAllNotificationsRead();
      widget.onRead?.call();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFollowerList() async {
    final session = SessionScope.of(context);
    final me = session.user;
    if (me == null) return;
    final client = ApiClient(readToken: () => session.token);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FollowListSheet(userId: me.id, isFollowers: true, client: client),
    );
  }

  Future<void> _openPost(int postId) async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PostDetailSheet(
        postId: postId,
        client: client,
        currentUserId: session.user?.id,
      ),
    );
  }

  void _onTap(AppNotification item) {
    if (item.type == 'FOLLOW') _openFollowerList();
    else if (item.type != 'BADGE') _openPost(item.referenceId);
  }

  Map<String, List<AppNotification>> _grouped() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final today = <AppNotification>[];
    final thisWeek = <AppNotification>[];
    final earlier = <AppNotification>[];
    for (final n in _items) {
      final t = n.createdAt;
      if (t == null || t.isAfter(now)) { earlier.add(n); continue; }
      if (!t.isBefore(todayStart)) today.add(n);
      else if (!t.isBefore(weekStart)) thisWeek.add(n);
      else earlier.add(n);
    }
    return {
      if (today.isNotEmpty) 'TODAY': today,
      if (thisWeek.isNotEmpty) 'THIS WEEK': thisWeek,
      if (earlier.isNotEmpty) 'EARLIER': earlier,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09111F),
        elevation: 0,
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 20, color: Color(0xFF3A5070)),
            tooltip: 'Mark all read',
            onPressed: () async {
              final session = SessionScope.of(context);
              await session.api.markAllNotificationsRead();
              setState(() {
                _items = _items.map((n) => AppNotification(
                  id: n.id, type: n.type, actorId: n.actorId,
                  actorName: n.actorName, referenceId: n.referenceId,
                  content: n.content, isRead: true, createdAt: n.createdAt,
                )).toList();
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A18), strokeWidth: 2))
          : _items.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFFF7A18),
                  backgroundColor: const Color(0xFF1A2535),
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
                    children: _buildList(),
                  ),
                ),
    );
  }

  List<Widget> _buildList() {
    final groups = _grouped();
    final widgets = <Widget>[];
    groups.forEach((label, items) {
      widgets.add(_SectionLabel(label));
      for (int i = 0; i < items.length; i++) {
        widgets.add(_NotifRow(
          item: items[i],
          onTap: items[i].type == 'BADGE' ? null : () => _onTap(items[i]),
        ));
        if (i < items.length - 1) {
          widgets.add(Divider(
            height: 1,
            indent: 64,
            endIndent: 0,
            color: Colors.white.withValues(alpha: 0.05),
          ));
        }
      }
      widgets.add(const SizedBox(height: 8));
    });
    return widgets;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 48, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(fontFamily: 'Oswald', fontSize: 15, letterSpacing: 1, color: Color(0xFF3A5070))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Oswald',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.5,
          color: Color(0xFF3A5070),
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.item, this.onTap});
  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (item.type) {
      'FOLLOW' => (Icons.person_add_rounded,      const Color(0xFF60A5FA)),
      'LIKE'   => (Icons.favorite_rounded,         const Color(0xFFF43F5E)),
      'BADGE'  => (Icons.military_tech_rounded,    const Color(0xFFFFD700)),
      _        => (Icons.chat_bubble_outline_rounded, const Color(0xFFFF7A18)),
    };

    final isBadge = item.type == 'BADGE';
    final timeStr = item.createdAt != null ? _fmt(item.createdAt!) : '';

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Container(
        color: item.isRead ? Colors.transparent : const Color(0xFFFF7A18).withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot + icon
            SizedBox(
              width: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, color: iconColor, size: 17),
                  ),
                  if (!item.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBadge ? const Color(0xFFFFD700) : const Color(0xFFFF7A18),
                          border: Border.all(color: const Color(0xFF09111F), width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: item.isRead ? const Color(0xFF8BA4BF) : Colors.white,
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3A5070),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isBadge)
              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2A3F55)),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MM/dd').format(t);
  }
}
