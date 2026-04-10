import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import 'user_profile_sheet.dart';

/// Bottom sheet showing a user's follower list or following list.
/// Set [isFollowers] = true for 粉丝, false for 关注.
/// Build [client] from a valid context BEFORE calling showModalBottomSheet.
class FollowListSheet extends StatefulWidget {
  const FollowListSheet({
    super.key,
    required this.userId,
    required this.isFollowers,
    required this.client,
  });
  final int userId;
  final bool isFollowers;
  final ApiClient client;

  @override
  State<FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<FollowListSheet> {
  List<FollowUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = widget.isFollowers
          ? await widget.client.fetchFollowers(widget.userId)
          : await widget.client.fetchFollowing(widget.userId);
      if (mounted) {
        setState(() { _users = users; _loading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openProfile(FollowUser user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserProfileSheet(userId: user.id, client: widget.client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFollowers ? "粉丝" : "关注";
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(widget.isFollowers ? "还没有粉丝" : "还没有关注任何人"),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(
                                u.name.isNotEmpty ? u.name[0].toUpperCase() : "?",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(u.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (u.isCoachCertified) ...[
                                  const SizedBox(width: 6),
                                  const Chip(
                                    label: Text("认证教练",
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white)),
                                    backgroundColor: Colors.deepOrange,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _openProfile(u),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
