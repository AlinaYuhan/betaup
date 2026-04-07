import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'common.dart';

class ClimberShell extends StatefulWidget {
  const ClimberShell({super.key});

  @override
  State<ClimberShell> createState() => _ClimberShellState();
}

class _ClimberShellState extends State<ClimberShell> {
  final _dashboardKey = GlobalKey<ClimberDashboardTabState>();
  final _logsKey = GlobalKey<ClimbLogsTabState>();
  final _badgesKey = GlobalKey<BadgeProgressTabState>();
  final _feedbackKey = GlobalKey<_MyFeedbackTabState>();

  int _currentIndex = 0;

  Future<void> _openClimbEditor([int? climbId]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClimbEditorPage(existingId: climbId),
      ),
    );

    if (saved == true) {
      await _dashboardKey.currentState?.reload();
      await _logsKey.currentState?.reload();
      await _badgesKey.currentState?.reload();
      await _feedbackKey.currentState?.reload();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sign out?"),
            content: const Text("Your JWT session will be removed from this device."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Sign out"),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout || !mounted) {
      return;
    }

    await SessionScope.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user!;
    const titles = [
      "Climber Dashboard",
      "Climb Logs",
      "Badge Progress",
      "My Feedback",
    ];
    final subtitles = [
      "Welcome back, ${user.name}",
      "Session journal and edits",
      "Automatic milestones from backend rules",
      "Coach review stream",
    ];

    return BetaUpScaffold(
      title: titles[_currentIndex],
      subtitle: subtitles[_currentIndex],
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          tooltip: "Sign out",
        ),
      ],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openClimbEditor,
              icon: const Icon(Icons.add_rounded),
              label: const Text("New log"),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_graph_rounded),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.terrain_rounded),
            label: "Logs",
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_rounded),
            label: "Badges",
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_rounded),
            label: "Feedback",
          ),
        ],
      ),
      child: IndexedStack(
        index: _currentIndex,
        children: [
          ClimberDashboardTab(key: _dashboardKey),
          ClimbLogsTab(key: _logsKey, onEditRequested: _openClimbEditor),
          BadgeProgressTab(key: _badgesKey),
          MyFeedbackTab(key: _feedbackKey),
        ],
      ),
    );
  }
}

class ClimberDashboardTab extends StatefulWidget {
  const ClimberDashboardTab({super.key});

  @override
  State<ClimberDashboardTab> createState() => ClimberDashboardTabState();
}

class ClimberDashboardTabState extends State<ClimberDashboardTab> {
  static const _ranges = [
    ("LAST_30_DAYS", "30d"),
    ("LAST_90_DAYS", "90d"),
    ("LAST_180_DAYS", "180d"),
    ("ALL_TIME", "All"),
  ];

  DashboardSummary? _dashboard;
  bool _isLoading = true;
  String _error = "";
  String _range = "LAST_180_DAYS";

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> reload() => _loadDashboard();

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final dashboard = await SessionScope.of(context).api.fetchDashboard(_range);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [LoaderCard(label: "Loading dashboard")],
      );
    }

    if (_error.isNotEmpty && _dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorCard(message: _error, onRetry: _loadDashboard),
        ],
      );
    }

    final dashboard = _dashboard;
    if (dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyCard(
            title: "No dashboard data",
            message: "Try refreshing after the backend is available.",
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Climber pulse"),
                const SizedBox(height: 12),
                Text(dashboard.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(dashboard.summary, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _ranges.map((entry) {
                    return ChoiceChip(
                      label: Text(entry.$2),
                      selected: _range == entry.$1,
                      onSelected: (_) {
                        setState(() {
                          _range = entry.$1;
                        });
                        _loadDashboard();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                StatusChip(
                  label: dashboard.rangeLabel.isNotEmpty
                      ? dashboard.rangeLabel
                      : dashboard.audience,
                  color: const Color(0xFF5ED9A6),
                ),
              ],
            ),
          ),
          GlassCard(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: dashboard.metrics.length,
              itemBuilder: (context, index) {
                final metric = dashboard.metrics[index];
                final color = index.isEven
                    ? const Color(0xFFFF7A18)
                    : const Color(0xFF7BE0FF);
                return MetricTile(
                  label: metric.label,
                  value: metric.value,
                  helper: metric.helper,
                  highlight: color,
                );
              },
            ),
          ),
          if (_error.isNotEmpty)
            ErrorCard(message: _error, onRetry: _loadDashboard),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Breakdown"),
                const SizedBox(height: 10),
                Text("Performance distribution", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SummaryList(items: dashboard.breakdown),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Recent activity"),
                const SizedBox(height: 10),
                Text("Latest training story", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (dashboard.recentActivity.isEmpty)
                  const EmptyCard(
                    title: "No activity yet",
                    message: "Create climbs or receive feedback to populate the feed.",
                  )
                else
                  ActivityFeed(items: dashboard.recentActivity),
              ],
            ),
          ),
          ...dashboard.charts.map((chart) {
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(chart.title),
                  const SizedBox(height: 10),
                  Text(chart.subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 18),
                  MiniBarChart(points: chart.points),
                ],
              ),
            );
          }),
          if (dashboard.highlights.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Highlights"),
                  const SizedBox(height: 12),
                  ...dashboard.highlights.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFFFB26D),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item, style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ClimbLogsTab extends StatefulWidget {
  const ClimbLogsTab({
    required this.onEditRequested,
    super.key,
  });

  final Future<void> Function(int? climbId) onEditRequested;

  @override
  State<ClimbLogsTab> createState() => ClimbLogsTabState();
}

class ClimbLogsTabState extends State<ClimbLogsTab> {
  static const _sortOptions = [
    ("date:desc", "Newest session date"),
    ("date:asc", "Oldest session date"),
    ("createdAt:desc", "Recently created"),
    ("routeName:asc", "Route name A-Z"),
    ("difficulty:asc", "Difficulty A-Z"),
  ];

  PageResult<ClimbLog>? _pageResult;
  bool _isLoading = true;
  String _error = "";
  String _sort = "date:desc";
  int _page = 0;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _loadClimbs();
  }

  Future<void> reload() => _loadClimbs();

  Future<void> _loadClimbs() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    final parts = sortParts(_sort, "date:desc");
    try {
      final result = await SessionScope.of(context).api.fetchClimbs(
        page: _page,
        size: 6,
        sortBy: parts[0],
        sortDir: parts[1],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pageResult = result;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteClimb(ClimbLog climb) async {
    final api = SessionScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete climb log?"),
            content: const Text(
              "Logs linked to coach feedback cannot be deleted on the backend.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    setState(() {
      _deletingId = climb.id;
      _error = "";
    });

    try {
      await api.deleteClimb(climb.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(messenger, "Climb log deleted.");
      await _loadClimbs();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _deletingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _pageResult;
    return RefreshIndicator(
      onRefresh: _loadClimbs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Route list"),
                const SizedBox(height: 10),
                Text("Climb log library", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _sort,
                  items: _sortOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _sort = value;
                      _page = 0;
                    });
                    _loadClimbs();
                  },
                  decoration: const InputDecoration(labelText: "Sort"),
                ),
                if (result != null) ...[
                  const SizedBox(height: 14),
                  StatusChip(
                    label: "${result.totalElements} entries",
                    color: const Color(0xFF7BE0FF),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading && result == null) const LoaderCard(label: "Loading climbs"),
          if (_error.isNotEmpty && result == null)
            ErrorCard(message: _error, onRetry: _loadClimbs),
          if (!_isLoading && result != null && result.items.isEmpty)
            const EmptyCard(
              title: "No climbs yet",
              message: "Create your first climb log to start building session history.",
            ),
          if (result != null && result.items.isNotEmpty)
            ...result.items.map((climb) {
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(climb.routeName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(
                                "${climb.difficulty} at ${climb.venue}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatShortDate(climb.date),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: const Color(0xFF92A5BF),
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusChip(
                          label: climb.status.label,
                          color: statusColor(climb.status),
                        ),
                      ],
                    ),
                    if (climb.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(climb.notes, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onEditRequested(climb.id),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text("Edit"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deletingId == climb.id
                                ? null
                                : () => _deleteClimb(climb),
                            icon: Icon(
                              _deletingId == climb.id
                                  ? Icons.hourglass_top_rounded
                                  : Icons.delete_outline_rounded,
                            ),
                            label: Text(
                              _deletingId == climb.id ? "Deleting..." : "Delete",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (_error.isNotEmpty && result != null)
            ErrorCard(message: _error, onRetry: _loadClimbs),
          if (result != null)
            PagingControls(
              page: result.page,
              totalPages: result.totalPages,
              hasNext: result.hasNext,
              hasPrevious: result.hasPrevious,
              onChanged: (page) {
                setState(() {
                  _page = page;
                });
                _loadClimbs();
              },
            ),
        ],
      ),
    );
  }
}

class ClimbEditorPage extends StatefulWidget {
  const ClimbEditorPage({
    super.key,
    this.existingId,
  });

  final int? existingId;

  @override
  State<ClimbEditorPage> createState() => _ClimbEditorPageState();
}

class _ClimbEditorPageState extends State<ClimbEditorPage> {
  final _routeController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate = DateTime.now();
  ClimbStatus _status = ClimbStatus.completed;
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = "";

  bool get _isEditing => widget.existingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _difficultyController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final climb = await SessionScope.of(context).api.fetchClimb(widget.existingId!);
      if (!mounted) {
        return;
      }
      setState(() {
        _routeController.text = climb.routeName;
        _difficultyController.text = climb.difficulty;
        _venueController.text = climb.venue;
        _notesController.text = climb.notes;
        _selectedDate = climb.date;
        _status = climb.status;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final routeName = _routeController.text.trim();
    final difficulty = _difficultyController.text.trim();
    final venue = _venueController.text.trim();

    if (routeName.isEmpty ||
        difficulty.isEmpty ||
        venue.isEmpty ||
        _selectedDate == null) {
      setState(() {
        _error = "Route, difficulty, date, and venue are required.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = "";
    });

    final payload = <String, dynamic>{
      "routeName": routeName,
      "difficulty": difficulty,
      "date": formatShortDate(_selectedDate),
      "venue": venue,
      "status": _status.rawValue,
      "notes": _notesController.text.trim(),
    };

    try {
      final api = SessionScope.of(context).api;
      if (_isEditing) {
        await api.updateClimb(widget.existingId!, payload);
      } else {
        await api.createClimb(payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetaUpScaffold(
      title: _isEditing ? "Edit Climb" : "New Climb",
      subtitle: _isEditing ? "Update an existing session" : "Write directly to the backend",
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_isLoading)
            const LoaderCard(label: "Loading climb log")
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Climb form"),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: "Route name",
                      hintText: "Orange Arete",
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _difficultyController,
                    decoration: const InputDecoration(
                      labelText: "Difficulty",
                      hintText: "V5 / 6c",
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(20),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: "Date"),
                      child: Text(formatShortDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _venueController,
                    decoration: const InputDecoration(
                      labelText: "Venue",
                      hintText: "Campus Wall",
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ClimbStatus>(
                    initialValue: _status,
                    items: ClimbStatus.values
                        .map(
                          (status) => DropdownMenuItem<ClimbStatus>(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (status) {
                      if (status != null) {
                        setState(() {
                          _status = status;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: "Status"),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      hintText: "How the session felt, attempts, beta, and next steps.",
                    ),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x33FF7B7B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x55FF7B7B)),
                      ),
                      child: Text(_error),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: Icon(_isSaving ? Icons.hourglass_top_rounded : Icons.save_rounded),
                    label: Text(_isSaving ? "Saving..." : (_isEditing ? "Update climb" : "Save climb")),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BadgeProgressTab extends StatefulWidget {
  const BadgeProgressTab({super.key});

  @override
  State<BadgeProgressTab> createState() => BadgeProgressTabState();
}

class BadgeProgressTabState extends State<BadgeProgressTab> {
  List<BadgeProgress> _items = const [];
  bool _isLoading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> reload() => _loadProgress();

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final items = await SessionScope.of(context).api.fetchBadgeProgress();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final earned = _items.where((item) => item.earned).toList();
    final inProgress = _items.where((item) => !item.earned).toList();

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_isLoading && _items.isEmpty) const LoaderCard(label: "Loading badges"),
          if (_error.isNotEmpty && _items.isEmpty)
            ErrorCard(message: _error, onRetry: _loadProgress),
          if (!_isLoading && earned.isEmpty)
            const EmptyCard(
              title: "No earned badges yet",
              message: "Keep logging climbs and receiving coach feedback to unlock milestones.",
            ),
          if (earned.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Earned badges"),
                  const SizedBox(height: 14),
                  ...earned.map((badge) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(badge.name, style: Theme.of(context).textTheme.titleMedium),
                              ),
                              StatusChip(label: badge.criteriaType.label, color: const Color(0xFF5ED9A6)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(badge.description, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 10),
                          Text(
                            "Awarded ${formatReadableDateTime(badge.awardedAt)}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("In progress"),
                const SizedBox(height: 14),
                if (inProgress.isEmpty)
                  const Text("Everything unlocked.")
                else
                  ...inProgress.map((badge) {
                    final ratio = badge.threshold == 0
                        ? 0.0
                        : (badge.currentValue / badge.threshold).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            badge.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: ratio,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${badge.criteriaType.label}: ${badge.currentValue}/${badge.threshold}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ErrorCard(message: _error, onRetry: _loadProgress),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyFeedbackTab extends StatefulWidget {
  const MyFeedbackTab({super.key});

  @override
  State<MyFeedbackTab> createState() => _MyFeedbackTabState();
}

class _MyFeedbackTabState extends State<MyFeedbackTab> {
  static const _sortOptions = [
    ("createdAt:desc", "Newest notes"),
    ("createdAt:asc", "Oldest notes"),
    ("rating:desc", "Highest rating"),
    ("rating:asc", "Lowest rating"),
  ];

  PageResult<FeedbackEntry>? _pageResult;
  bool _isLoading = true;
  String _error = "";
  int _page = 0;
  int? _ratingFilter;
  String _sort = "createdAt:desc";

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> reload() => _loadFeedback();

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    final parts = sortParts(_sort, "createdAt:desc");
    try {
      final result = await SessionScope.of(context).api.fetchFeedback(
        page: _page,
        size: 6,
        rating: _ratingFilter,
        sortBy: parts[0],
        sortDir: parts[1],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pageResult = result;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _pageResult;
    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Feedback filters"),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  initialValue: _ratingFilter,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("All ratings"),
                    ),
                    ...[5, 4, 3, 2, 1].map(
                      (rating) => DropdownMenuItem<int?>(
                        value: rating,
                        child: Text("$rating stars"),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _ratingFilter = value;
                      _page = 0;
                    });
                    _loadFeedback();
                  },
                  decoration: const InputDecoration(labelText: "Rating"),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _sort,
                  items: _sortOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _sort = value;
                      _page = 0;
                    });
                    _loadFeedback();
                  },
                  decoration: const InputDecoration(labelText: "Sort"),
                ),
              ],
            ),
          ),
          if (_isLoading && result == null) const LoaderCard(label: "Loading feedback"),
          if (_error.isNotEmpty && result == null)
            ErrorCard(message: _error, onRetry: _loadFeedback),
          if (!_isLoading && result != null && result.items.isEmpty)
            const EmptyCard(
              title: "No feedback yet",
              message: "Coach reviews will appear here after feedback is submitted for your climbs.",
            ),
          if (result != null && result.items.isNotEmpty)
            ...result.items.map((item) {
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.coachName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(
                                "${item.routeName} | ${item.difficulty} | ${item.venue}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${formatShortDate(item.climbDate)} | ${item.climbStatus.label}",
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: const Color(0xFF92A5BF),
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        StatusChip(
                          label: "${item.rating}/5",
                          color: item.rating >= 4
                              ? const Color(0xFF5ED9A6)
                              : item.rating == 3
                                  ? const Color(0xFF7BE0FF)
                                  : const Color(0xFFFFB26D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(item.comment, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              );
            }),
          if (_error.isNotEmpty && result != null)
            ErrorCard(message: _error, onRetry: _loadFeedback),
          if (result != null)
            PagingControls(
              page: result.page,
              totalPages: result.totalPages,
              hasNext: result.hasNext,
              hasPrevious: result.hasPrevious,
              onChanged: (page) {
                setState(() {
                  _page = page;
                });
                _loadFeedback();
              },
            ),
        ],
      ),
    );
  }
}
