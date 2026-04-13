import 'package:flutter/material.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'admin_tab.dart';
import 'community_tab.dart';
import 'explore_tab.dart';
import 'notification_tab.dart';
import 'profile_tab.dart';
import 'record_tab.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  final _notifKey = GlobalKey<NotificationTabState>();
  final _profileKey = GlobalKey<ProfileTabState>();

  static const _notifIndex = 3;
  static const _profileIndex = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final session = SessionScope.of(context);
      final count = await session.api.fetchUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("退出登录？"),
            content: const Text("确认退出当前账号吗？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("取消"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("退出"),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout && mounted) {
      await SessionScope.of(context).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user!;
    final isAdmin = user.role == UserRole.admin;

    final pages = [
      const ExploreTab(),
      const RecordTab(),
      const CommunityTab(),
      NotificationTab(key: _notifKey, onRead: _refreshUnreadCount),
      ProfileTab(key: _profileKey, user: user, onLogout: _logout),
      if (isAdmin) const AdminTab(),
    ];

    Widget notifIcon(IconData icon) {
      if (_unreadCount == 0) return Icon(icon);
      return Badge(
        label: Text(_unreadCount > 99 ? "99+" : "$_unreadCount"),
        child: Icon(icon),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == _notifIndex) {
            _unreadCount = 0;
            _notifKey.currentState?.reload();
          } else {
            _refreshUnreadCount();
            if (index == _profileIndex) _profileKey.currentState?.reloadLeaderboard();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: "探索",
          ),
          const NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: "记录",
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: "社区",
          ),
          NavigationDestination(
            icon: notifIcon(Icons.notifications_outlined),
            selectedIcon: notifIcon(Icons.notifications),
            label: "通知",
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "我的",
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: "管理",
            ),
        ],
      ),
    );
  }
}
