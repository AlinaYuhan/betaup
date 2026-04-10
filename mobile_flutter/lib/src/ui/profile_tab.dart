import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.user, required this.onLogout});

  final UserProfile user;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isCoach = user.isCoachCertified;

    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "退出登录",
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          _ProfileHeader(user: user, isCoach: isCoach),
          // Tabs: 徽章榜 / 打卡榜
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.workspace_premium), text: "徽章榜"),
              Tab(icon: Icon(Icons.location_on), text: "打卡榜"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _LeaderboardView(type: "badges"),
                _LeaderboardView(type: "checkins"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.user, required this.isCoach});
  final UserProfile user;
  final bool isCoach;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  DashboardSummary? _summary;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadSummary();
    }
  }

  Future<void> _showEditSheet(BuildContext context) async {
    // Read session HERE — valid context from button press
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);
    final user = widget.user;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        initialName: user.name,
        initialCity: user.city,
        initialBio: user.bio,
        client: client,
      ),
    );
    if (updated == true) {
      await session.refreshUser(); // 刷新 session，让头部姓名立刻更新
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    try {
      final session = SessionScope.of(context);
      final summary = await session.api.fetchDashboard("ALL_TIME");
      if (mounted) setState(() => _summary = summary);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final totalLogs = _summary?.metrics
        .where((m) => m.label.toLowerCase().contains("log"))
        .firstOrNull
        ?.numericValue ?? 0;
    final completed = _summary?.metrics
        .where((m) => m.label.toLowerCase().contains("send") || m.label.toLowerCase().contains("complet"))
        .firstOrNull
        ?.numericValue ?? 0;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.orange,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isCoach) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text("认证教练", style: TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => _showEditSheet(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatChip(label: "日志", value: totalLogs),
                    const SizedBox(width: 12),
                    _StatChip(label: "完成", value: completed),
                    const SizedBox(width: 12),
                    _StatChip(label: "关注", value: user.followingCount),
                    const SizedBox(width: 12),
                    _StatChip(label: "粉丝", value: user.followerCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView({required this.type});
  final String type;

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  List<LeaderboardEntry>? _entries;
  String? _error;
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
    setState(() { _loading = true; _error = null; });
    try {
      final session = SessionScope.of(context);
      final client = ApiClient(readToken: () => session.token);
      final entries = await client.fetchLeaderboard(type: widget.type);
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text("重试")),
          ],
        ),
      );
    }

    final entries = _entries ?? [];
    final currentUserId = SessionScope.of(context).user?.id;

    if (entries.isEmpty) {
      return const Center(child: Text("暂无数据，快去攀岩吧！🧗"));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isMe = currentUserId == entry.userId;
          final rankEmoji = entry.rank == 1 ? "🥇" : entry.rank == 2 ? "🥈" : entry.rank == 3 ? "🥉" : "#${entry.rank}";

          return ListTile(
            leading: Text(rankEmoji, style: const TextStyle(fontSize: 20)),
            title: Text(
              entry.name,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                color: isMe ? Colors.orange : null,
              ),
            ),
            trailing: Chip(
              label: Text(
                "${entry.score} ${widget.type == 'badges' ? '徽章' : '打卡'}",
                style: TextStyle(
                  color: isMe ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: isMe ? Colors.orange : null,
            ),
            tileColor: isMe ? Colors.orange.withAlpha(20) : null,
          );
        },
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialName,
    required this.initialCity,
    required this.initialBio,
    required this.client,
  });
  final String initialName;
  final String initialCity;
  final String initialBio;
  final ApiClient client;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _cityCtrl = TextEditingController(text: widget.initialCity);
    _bioCtrl = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _errorMsg = null; });
    try {
      await widget.client.updateProfile(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("编辑资料", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "昵称", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: "所在城市", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "个人简介", border: OutlineInputBorder())),
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Text("保存失败：$_errorMsg", style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text("保存"),
            ),
          ),
        ],
      ),
    );
  }
}
