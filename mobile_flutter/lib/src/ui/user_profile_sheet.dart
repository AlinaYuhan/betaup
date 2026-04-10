import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';

/// Shows another user's public profile with follow / unfollow.
/// Build [client] from a valid context BEFORE calling showModalBottomSheet,
/// then pass it in via the constructor.
class UserProfileSheet extends StatefulWidget {
  const UserProfileSheet({super.key, required this.userId, required this.client});
  final int userId;
  final ApiClient client;

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  PublicUserProfile? _profile;
  bool _loading = true;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.client.fetchUser(widget.userId);
      if (mounted) {
        setState(() { _profile = profile; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final p = _profile;
    if (p == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      if (p.followedByMe) {
        await widget.client.unfollowUser(p.id);
      } else {
        await widget.client.followUser(p.id);
      }
      if (mounted) {
        setState(() {
          _profile = p.copyWith(followedByMe: !p.followedByMe);
          _toggling = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: _loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : _profile == null
              ? const SizedBox(height: 80, child: Center(child: Text("加载失败")))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.orange,
                      child: Text(
                        _profile!.name.isNotEmpty ? _profile!.name[0].toUpperCase() : "?",
                        style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_profile!.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (_profile!.isCoachCertified) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text("认证教练", style: TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: Colors.deepOrange,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ProfileStat(label: "粉丝", value: _profile!.followerCount),
                        ProfileStat(label: "关注", value: _profile!.followingCount),
                        ProfileStat(label: "日志", value: _profile!.totalClimbLogs),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggling ? null : _toggleFollow,
                        icon: Icon(_profile!.followedByMe ? Icons.person_remove : Icons.person_add),
                        label: Text(_profile!.followedByMe ? "取消关注" : "关注"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _profile!.followedByMe ? Colors.grey : Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Reusable stat column (number + label) used in profile views.
class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
