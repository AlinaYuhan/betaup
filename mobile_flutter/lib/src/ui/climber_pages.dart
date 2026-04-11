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
  List<GradeStat>? _gradeStats;
  bool _isLoading = true;
  String _error = "";
  String _range = "LAST_180_DAYS";

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadGradeStats();
  }

  Future<void> reload() {
    _loadGradeStats();
    return _loadDashboard();
  }

  Future<void> _loadGradeStats() async {
    try {
      final stats = await SessionScope.of(context).api.fetchGradeStats();
      if (mounted) setState(() => _gradeStats = stats);
    } catch (_) {}
  }

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
          // Grade stats card
          if (_gradeStats != null && _gradeStats!.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("难度完成率"),
                  const SizedBox(height: 10),
                  Text("各V级完成情况", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ..._gradeStats!.map((stat) => _GradeStatRow(stat: stat)),
                ],
              ),
            ),
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

class _GradeStatRow extends StatelessWidget {
  const _GradeStatRow({required this.stat});
  final GradeStat stat;

  @override
  Widget build(BuildContext context) {
    final sendFrac = stat.total > 0 ? stat.sends / stat.total : 0.0;
    final flashFrac = stat.total > 0 ? stat.flashes / stat.total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(stat.difficulty,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7A18),
                    )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                // background track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // send bar (green)
                FractionallySizedBox(
                  widthFactor: sendFrac.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5ED9A6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                // flash bar (gold, narrower overlay)
                FractionallySizedBox(
                  widthFactor: flashFrac.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${stat.sends}/${stat.total}",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF92A5BF),
                ),
          ),
          if (stat.flashes > 0) ...[
            const SizedBox(width: 4),
            Text("⚡${stat.flashes}",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFFFD700),
                    )),
          ],
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
                              Text(
                                climb.routeName.isNotEmpty ? climb.routeName : climb.difficulty,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${climb.difficulty}  •  ${climb.venue}",
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(
                              label: climb.result.shortLabel,
                              color: resultColor(climb.result),
                            ),
                            if (climb.result != ClimbResult.flash) ...[
                              const SizedBox(height: 4),
                              Text(
                                "${climb.attempts}次",
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF92A5BF),
                                    ),
                              ),
                            ],
                          ],
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
    this.activeSessionId,
    this.defaultVenue,
  });

  final int? existingId;
  final int? activeSessionId; // set when launched from SessionPage
  final String? defaultVenue; // pre-fill venue from session

  @override
  State<ClimbEditorPage> createState() => _ClimbEditorPageState();
}

// V-grade ordering: VB, V0 ... V12
const _kGrades = ["VB", "V0", "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10", "V11", "V12"];

class _ClimbEditorPageState extends State<ClimbEditorPage> {
  final _routeController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate = DateTime.now();
  String _selectedDifficulty = _kGrades[0]; // default VB, slider always has position
  ClimbResult _result = ClimbResult.send;
  int _attempts = 1;
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = "";

  bool get _isEditing => widget.existingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else if (widget.defaultVenue != null && widget.defaultVenue!.isNotEmpty) {
      _venueController.text = widget.defaultVenue!;
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
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
      if (!mounted) return;
      setState(() {
        _routeController.text = climb.routeName;
        _venueController.text = climb.venue;
        _notesController.text = climb.notes;
        _selectedDate = climb.date;
        _selectedDifficulty = climb.difficulty.isNotEmpty ? climb.difficulty : _kGrades[0];
        _result = climb.result;
        _attempts = climb.attempts;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_venueController.text.trim().isEmpty || _selectedDate == null) {
      setState(() { _error = "请填写场馆和日期。"; });
      return;
    }

    setState(() { _isSaving = true; _error = ""; });

    final payload = <String, dynamic>{
      "routeName": _routeController.text.trim().isEmpty ? null : _routeController.text.trim(),
      "difficulty": _selectedDifficulty,
      "date": formatShortDate(_selectedDate),
      "venue": _venueController.text.trim(),
      "result": _result.rawValue,
      "attempts": _attempts,
      "notes": _notesController.text.trim(),
      if (widget.activeSessionId != null) "sessionId": widget.activeSessionId,
    };

    try {
      final api = SessionScope.of(context).api;
      if (_isEditing) {
        await api.updateClimb(widget.existingId!, payload);
      } else {
        await api.createClimb(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetaUpScaffold(
      title: _isEditing ? "编辑记录" : "记录攀爬",
      subtitle: _isEditing ? "修改已有记录" : "记录这次攀爬",
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
                  // ── Difficulty slider ──────────────────────────────────────
                  const SectionLabel("难度"),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _selectedDifficulty,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A18),
                      ),
                    ),
                  ),
                  Slider(
                    value: _kGrades.indexOf(_selectedDifficulty).toDouble(),
                    min: 0,
                    max: (_kGrades.length - 1).toDouble(),
                    divisions: _kGrades.length - 1,
                    activeColor: const Color(0xFFFF7A18),
                    onChanged: (v) => setState(() => _selectedDifficulty = _kGrades[v.round()]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("VB", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        Text("V12", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Result selector ───────────────────────────────────────
                  const SectionLabel("结果"),
                  const SizedBox(height: 10),
                  Row(
                    children: ClimbResult.values.map((r) {
                      final selected = _result == r;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _result = r;
                              if (r == ClimbResult.flash) _attempts = 1;
                            }),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected ? resultColor(r).withValues(alpha: 0.15) : null,
                              side: BorderSide(
                                color: selected ? resultColor(r) : Colors.grey.shade700,
                                width: selected ? 2 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              r.label,
                              style: TextStyle(
                                color: selected ? resultColor(r) : null,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Attempts counter (hidden for Flash) ───────────────────
                  if (_result != ClimbResult.flash) ...[
                    const SectionLabel("尝试次数"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _attempts > 1 ? () => setState(() => _attempts--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_attempts",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _attempts++),
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Route name (optional) ──────────────────────────────────
                  const SectionLabel("线路名（选填）"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      hintText: "留空表示未命名路线",
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Date picker ────────────────────────────────────────────
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(20),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: "日期"),
                      child: Text(formatShortDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Venue ──────────────────────────────────────────────────
                  TextField(
                    controller: _venueController,
                    decoration: const InputDecoration(
                      labelText: "场馆",
                      hintText: "Campus Wall",
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Notes ──────────────────────────────────────────────────
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "备注（选填）",
                      hintText: "动作心得、Beta、下次目标…",
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
                    label: Text(_isSaving ? "保存中..." : (_isEditing ? "更新记录" : "保存记录")),
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
