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
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  List<AppNotification> _items = [];
  bool _loading = true;
  bool _loaded = false;

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
      if (mounted) {
        setState(() { _items = items; _loading = false; });
      }
      // Mark all as read after loading
      session.api.markAllNotificationsRead();
      widget.onRead?.call();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// FOLLOW notification → open current user's follower list
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
      builder: (_) => FollowListSheet(
        userId: me.id,
        isFollowers: true,
        client: client,
      ),
    );
  }

  /// LIKE / COMMENT notification → open the post by referenceId
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
    if (item.type == "FOLLOW") {
      _openFollowerList();
    } else {
      // LIKE or COMMENT — referenceId is the postId
      _openPost(item.referenceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("通知"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "全部标为已读",
            onPressed: () async {
              final session = SessionScope.of(context);
              await session.api.markAllNotificationsRead();
              setState(() {
                _items = _items
                    .map((n) => AppNotification(
                          id: n.id,
                          type: n.type,
                          actorId: n.actorId,
                          actorName: n.actorName,
                          referenceId: n.referenceId,
                          content: n.content,
                          isRead: true,
                          createdAt: n.createdAt,
                        ))
                    .toList();
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text("暂无通知"))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _NotificationTile(
                      item: _items[i],
                      onTap: () => _onTap(_items[i]),
                    ),
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = item.createdAt != null
        ? DateFormat("MM-dd HH:mm").format(item.createdAt!)
        : "";

    IconData icon;
    Color iconColor;
    switch (item.type) {
      case "FOLLOW":
        icon = Icons.person_add;
        iconColor = Colors.blue;
      case "LIKE":
        icon = Icons.favorite;
        iconColor = Colors.red;
      default:
        icon = Icons.chat_bubble;
        iconColor = Colors.orange;
    }

    return ListTile(
      tileColor: item.isRead ? null : Colors.orange.withAlpha(15),
      leading: CircleAvatar(
        backgroundColor: iconColor.withAlpha(30),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        item.content,
        style: TextStyle(
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(timeStr,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}
