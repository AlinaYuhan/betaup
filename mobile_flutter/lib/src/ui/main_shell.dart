import 'package:flutter/material.dart';

import '../session/app_session.dart';
import 'community_tab.dart';
import 'explore_tab.dart';
import 'profile_tab.dart';
import 'record_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: "探索",
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: "记录",
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: "社区",
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: "我的",
    ),
  ];

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

    final pages = [
      const ExploreTab(),
      const RecordTab(),
      const CommunityTab(),
      ProfileTab(user: user, onLogout: _logout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
