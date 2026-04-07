import 'package:flutter/material.dart';

import 'climber_pages.dart';

class RecordTab extends StatefulWidget {
  const RecordTab({super.key});

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _logsKey = GlobalKey<ClimbLogsTabState>();
  final _dashboardKey = GlobalKey<ClimberDashboardTabState>();
  final _badgesKey = GlobalKey<BadgeProgressTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openClimbEditor([int? climbId]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClimbEditorPage(existingId: climbId),
      ),
    );
    if (saved == true) {
      await _logsKey.currentState?.reload();
      await _dashboardKey.currentState?.reload();
      await _badgesKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("训练记录"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.terrain_rounded), text: "攀爬日志"),
            Tab(icon: Icon(Icons.auto_graph_rounded), text: "进步统计"),
            Tab(icon: Icon(Icons.workspace_premium_rounded), text: "我的徽章"),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _openClimbEditor,
                icon: const Icon(Icons.add_rounded),
                label: const Text("记录攀爬"),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClimbLogsTab(key: _logsKey, onEditRequested: _openClimbEditor),
          ClimberDashboardTab(key: _dashboardKey),
          BadgeProgressTab(key: _badgesKey),
        ],
      ),
    );
  }
}

