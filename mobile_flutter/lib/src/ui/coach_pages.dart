import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'common.dart';

class CoachShell extends StatefulWidget {
  const CoachShell({super.key});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  final _dashboardKey = GlobalKey<_CoachDashboardTabState>();
  final _climbersKey = GlobalKey<_ClimberRosterTabState>();
  final _feedbackKey = GlobalKey<_CoachFeedbackTabState>();
  final _badgeRulesKey = GlobalKey<_BadgeRulesTabState>();

  int _currentIndex = 0;

  Future<void> _openFeedbackEditor([int? feedbackId, int? climberId]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FeedbackEditorPage(
          editingFeedbackId: feedbackId,
          initialClimberId: climberId,
        ),
      ),
    );

    if (saved == true) {
      await _dashboardKey.currentState?.reload();
      await _climbersKey.currentState?.reload();
      await _feedbackKey.currentState?.reload();
      await _badgeRulesKey.currentState?.reload();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sign out?"),
            content: const Text("The coach session will be removed from this device."),
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
      "Coach Dashboard",
      "Climber Roster",
      "Feedback Queue",
      "Badge Rules",
    ];
    final subtitles = [
      "Team pulse for ${user.name}",
      "Search and open climber profiles",
      "Create, edit, and remove reviews",
      "Persistent milestone logic",
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
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _openFeedbackEditor,
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text("New feedback"),
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
            icon: Icon(Icons.query_stats_rounded),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_rounded),
            label: "Climbers",
          ),
          NavigationDestination(
            icon: Icon(Icons.feedback_rounded),
            label: "Feedback",
          ),
          NavigationDestination(
            icon: Icon(Icons.military_tech_rounded),
            label: "Badges",
          ),
        ],
      ),
      child: IndexedStack(
        index: _currentIndex,
        children: [
          CoachDashboardTab(key: _dashboardKey),
          ClimberRosterTab(
            key: _climbersKey,
            onOpenFeedbackDraft: (climberId) => _openFeedbackEditor(null, climberId),
          ),
          CoachFeedbackTab(
            key: _feedbackKey,
            onEditFeedback: _openFeedbackEditor,
          ),
          BadgeRulesTab(key: _badgeRulesKey),
        ],
      ),
    );
  }
}

class CoachDashboardTab extends StatefulWidget {
  const CoachDashboardTab({super.key});

  @override
  State<CoachDashboardTab> createState() => _CoachDashboardTabState();
}

class _CoachDashboardTabState extends State<CoachDashboardTab> {
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
            message: "Reconnect the backend and refresh.",
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
                const SectionLabel("Coach pulse"),
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
                  color: const Color(0xFF7BE0FF),
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
                    ? const Color(0xFF7BE0FF)
                    : const Color(0xFFFFB26D);
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
                const SectionLabel("Roster breakdown"),
                const SizedBox(height: 10),
                Text("Live counts across the team", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SummaryList(items: dashboard.breakdown, valueSuffix: " logs"),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Recent coaching activity"),
                const SizedBox(height: 10),
                if (dashboard.recentActivity.isEmpty)
                  const EmptyCard(
                    title: "No activity yet",
                    message: "Submit feedback to populate the coaching feed.",
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
        ],
      ),
    );
  }
}

class ClimberRosterTab extends StatefulWidget {
  const ClimberRosterTab({
    required this.onOpenFeedbackDraft,
    super.key,
  });

  final Future<void> Function(int climberId) onOpenFeedbackDraft;

  @override
  State<ClimberRosterTab> createState() => _ClimberRosterTabState();
}

class _ClimberRosterTabState extends State<ClimberRosterTab> {
  static const _sortOptions = [
    ("createdAt:desc", "Newest joined"),
    ("name:asc", "Name A-Z"),
    ("name:desc", "Name Z-A"),
    ("email:asc", "Email A-Z"),
  ];

  final _queryController = TextEditingController();
  Timer? _debounce;

  PageResult<ClimberOverview>? _pageResult;
  bool _isLoading = true;
  String _error = "";
  String _sort = "createdAt:desc";
  int _page = 0;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    _loadClimbers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> reload() => _loadClimbers();

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = _queryController.text.trim();
        _page = 0;
      });
      _loadClimbers();
    });
  }

  Future<void> _loadClimbers() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    final parts = sortParts(_sort, "createdAt:desc");
    try {
      final result = await SessionScope.of(context).api.fetchClimbers(
        query: _query,
        page: _page,
        size: 8,
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

  Future<void> _openDetail(ClimberOverview climber) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ClimberDetailPage(
          climberId: climber.id,
          onOpenFeedbackDraft: widget.onOpenFeedbackDraft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _pageResult;
    return RefreshIndicator(
      onRefresh: _loadClimbers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Coach directory"),
                const SizedBox(height: 14),
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: "Search name or email",
                    hintText: "Type to filter climbers",
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
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
                    _loadClimbers();
                  },
                  decoration: const InputDecoration(labelText: "Sort"),
                ),
                if (result != null) ...[
                  const SizedBox(height: 14),
                  StatusChip(
                    label: "${result.totalElements} climbers",
                    color: const Color(0xFF7BE0FF),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading && result == null) const LoaderCard(label: "Loading climbers"),
          if (_error.isNotEmpty && result == null)
            ErrorCard(message: _error, onRetry: _loadClimbers),
          if (!_isLoading && result != null && result.items.isEmpty)
            EmptyCard(
              title: _query.isNotEmpty ? "No climbers match" : "No climbers yet",
              message: _query.isNotEmpty
                  ? "Try a different search term."
                  : "Register a climber account first.",
            ),
          if (result != null && result.items.isNotEmpty)
            ...result.items.map((climber) {
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(climber.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(climber.email, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        StatusChip(
                          label: "${climber.climbCount} climbs",
                          color: const Color(0xFF7BE0FF),
                        ),
                        StatusChip(
                          label: "${climber.feedbackCount} reviews",
                          color: const Color(0xFFFFB26D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openDetail(climber),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text("Open profile"),
                    ),
                  ],
                ),
              );
            }),
          if (_error.isNotEmpty && result != null)
            ErrorCard(message: _error, onRetry: _loadClimbers),
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
                _loadClimbers();
              },
            ),
        ],
      ),
    );
  }
}

class ClimberDetailPage extends StatefulWidget {
  const ClimberDetailPage({
    required this.climberId,
    required this.onOpenFeedbackDraft,
    super.key,
  });

  final int climberId;
  final Future<void> Function(int climberId) onOpenFeedbackDraft;

  @override
  State<ClimberDetailPage> createState() => _ClimberDetailPageState();
}

class _ClimberDetailPageState extends State<ClimberDetailPage> {
  static const _sortOptions = [
    ("createdAt:desc", "Newest feedback"),
    ("createdAt:asc", "Oldest feedback"),
    ("rating:desc", "Highest rating"),
    ("rating:asc", "Lowest rating"),
  ];

  ClimberDetail? _detail;
  PageResult<FeedbackEntry>? _feedbackPage;
  bool _isLoading = true;
  bool _isFeedbackLoading = true;
  String _error = "";
  String _feedbackError = "";
  int _page = 0;
  int? _ratingFilter;
  String _sort = "createdAt:desc";

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadFeedback();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final detail = await SessionScope.of(context).api.fetchClimberDetail(widget.climberId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
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

  Future<void> _loadFeedback() async {
    setState(() {
      _isFeedbackLoading = true;
      _feedbackError = "";
    });

    final parts = sortParts(_sort, "createdAt:desc");
    try {
      final result = await SessionScope.of(context).api.fetchFeedback(
        climberId: widget.climberId,
        rating: _ratingFilter,
        page: _page,
        size: 4,
        sortBy: parts[0],
        sortDir: parts[1],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _feedbackPage = result;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _feedbackError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFeedbackLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return BetaUpScaffold(
      title: detail?.name ?? "Climber Detail",
      subtitle: detail?.email ?? "Loading profile",
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_isLoading && detail == null)
            const LoaderCard(label: "Loading climber detail")
          else if (_error.isNotEmpty && detail == null)
            ErrorCard(message: _error, onRetry: _loadDetail)
          else if (detail != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Profile"),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _CountPill(label: "Total logs", value: detail.climbCount),
                      _CountPill(label: "Completed", value: detail.completedCount),
                      _CountPill(label: "Attempted", value: detail.attemptedCount),
                      _CountPill(label: "Feedback", value: detail.feedbackCount),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => widget.onOpenFeedbackDraft(detail.id),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text("Draft feedback"),
                  ),
                ],
              ),
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Recent climbs"),
                  const SizedBox(height: 12),
                  if (detail.recentClimbs.isEmpty)
                    const Text("This climber has not logged any sessions yet.")
                  else
                    ...detail.recentClimbs.map((climb) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(climb.routeName, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${climb.difficulty} | ${climb.venue}",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatShortDate(climb.date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: climb.status.label,
                              color: statusColor(climb.status),
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
                  const SectionLabel("Feedback history"),
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
                  const SizedBox(height: 16),
                  if (_isFeedbackLoading && _feedbackPage == null)
                    const LoaderCard(label: "Loading feedback")
                  else if (_feedbackError.isNotEmpty && _feedbackPage == null)
                    ErrorCard(message: _feedbackError, onRetry: _loadFeedback)
                  else if (_feedbackPage != null && _feedbackPage!.items.isEmpty)
                    const EmptyCard(
                      title: "No feedback yet",
                      message: "Write the first review from the coach workspace.",
                    )
                  else if (_feedbackPage != null) ...[
                    ..._feedbackPage!.items.map((feedback) {
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
                                  child: Text(
                                    feedback.routeName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                StatusChip(
                                  label: "${feedback.rating}/5",
                                  color: feedback.rating >= 4
                                      ? const Color(0xFF5ED9A6)
                                      : feedback.rating == 3
                                          ? const Color(0xFF7BE0FF)
                                          : const Color(0xFFFFB26D),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${feedback.difficulty} | ${feedback.venue}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(feedback.comment, style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      );
                    }),
                    PagingControls(
                      page: _feedbackPage!.page,
                      totalPages: _feedbackPage!.totalPages,
                      hasNext: _feedbackPage!.hasNext,
                      hasPrevious: _feedbackPage!.hasPrevious,
                      onChanged: (page) {
                        setState(() {
                          _page = page;
                        });
                        _loadFeedback();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CoachFeedbackTab extends StatefulWidget {
  const CoachFeedbackTab({
    required this.onEditFeedback,
    super.key,
  });

  final Future<void> Function(int? feedbackId, int? climberId) onEditFeedback;

  @override
  State<CoachFeedbackTab> createState() => _CoachFeedbackTabState();
}

class _CoachFeedbackTabState extends State<CoachFeedbackTab> {
  static const _sortOptions = [
    ("createdAt:desc", "Newest feedback"),
    ("createdAt:asc", "Oldest feedback"),
    ("rating:desc", "Highest rating"),
    ("rating:asc", "Lowest rating"),
  ];

  List<ClimberOverview> _climbers = const [];
  PageResult<FeedbackEntry>? _pageResult;
  bool _isBootstrapping = true;
  bool _isLoading = true;
  String _error = "";
  int _page = 0;
  int? _selectedClimberId;
  int? _ratingFilter;
  int? _deletingId;
  String _sort = "createdAt:desc";

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> reload() => _loadFeedback();

  Future<void> _bootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _error = "";
    });

    try {
      final climbers = await SessionScope.of(context).api.fetchClimberOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _climbers = climbers;
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
          _isBootstrapping = false;
        });
      }
    }

    await _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    final parts = sortParts(_sort, "createdAt:desc");
    try {
      final result = await SessionScope.of(context).api.fetchFeedback(
        climberId: _selectedClimberId,
        rating: _ratingFilter,
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

  Future<void> _deleteFeedback(FeedbackEntry item) async {
    final api = SessionScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete feedback?"),
            content: const Text("This removes the review from the backend."),
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
      _deletingId = item.id;
      _error = "";
    });

    try {
      await api.deleteFeedback(item.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(messenger, "Feedback deleted.");
      await _loadFeedback();
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
      onRefresh: _loadFeedback,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Coach filters"),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedClimberId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("All climbers"),
                    ),
                    ..._climbers.map(
                      (climber) => DropdownMenuItem<int?>(
                        value: climber.id,
                        child: Text(climber.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClimberId = value;
                      _page = 0;
                    });
                    _loadFeedback();
                  },
                  decoration: const InputDecoration(labelText: "Climber"),
                ),
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
          if (_isBootstrapping && _climbers.isEmpty) const LoaderCard(label: "Loading climber filters"),
          if (_isLoading && result == null) const LoaderCard(label: "Loading feedback"),
          if (_error.isNotEmpty && result == null)
            ErrorCard(message: _error, onRetry: _bootstrap),
          if (!_isLoading && result != null && result.items.isEmpty)
            const EmptyCard(
              title: "No feedback found",
              message: "Adjust the filters or create a new review.",
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
                              Text(item.routeName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(
                                "${item.climberName} | ${item.difficulty} | ${item.venue}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${formatShortDate(item.climbDate)} | ${item.climbStatus.label}",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onEditFeedback(item.id, item.climberId),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text("Edit"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deletingId == item.id
                                ? null
                                : () => _deleteFeedback(item),
                            icon: Icon(
                              _deletingId == item.id
                                  ? Icons.hourglass_top_rounded
                                  : Icons.delete_outline_rounded,
                            ),
                            label: Text(
                              _deletingId == item.id ? "Deleting..." : "Delete",
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

class FeedbackEditorPage extends StatefulWidget {
  const FeedbackEditorPage({
    super.key,
    this.editingFeedbackId,
    this.initialClimberId,
  });

  final int? editingFeedbackId;
  final int? initialClimberId;

  @override
  State<FeedbackEditorPage> createState() => _FeedbackEditorPageState();
}

class _FeedbackEditorPageState extends State<FeedbackEditorPage> {
  final _commentController = TextEditingController();

  List<ClimberOverview> _climbers = const [];
  List<ClimbLog> _availableClimbs = const [];
  bool _isBootstrapping = true;
  bool _isLoadingExisting = false;
  bool _isSaving = false;
  String _error = "";
  int? _selectedClimberId;
  int? _selectedClimbId;
  int _rating = 5;

  bool get _isEditing => widget.editingFeedbackId != null;

  @override
  void initState() {
    super.initState();
    _selectedClimberId = widget.initialClimberId;
    _bootstrap();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _error = "";
    });

    try {
      final api = SessionScope.of(context).api;
      final climbers = await api.fetchClimberOptions();
      if (!mounted) {
        return;
      }

      setState(() {
        _climbers = climbers;
      });

      if (_selectedClimberId != null) {
        await _loadClimbsForClimber(_selectedClimberId!);
      }

      if (_isEditing) {
        await _loadExisting();
      }
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
          _isBootstrapping = false;
        });
      }
    }
  }

  Future<void> _loadExisting() async {
    setState(() {
      _isLoadingExisting = true;
      _error = "";
    });

    try {
      final api = SessionScope.of(context).api;
      final feedback = await api.fetchFeedbackEntry(widget.editingFeedbackId!);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedClimberId = feedback.climberId;
        _selectedClimbId = feedback.climbLogId;
        _commentController.text = feedback.comment;
        _rating = feedback.rating;
      });

      await _loadClimbsForClimber(feedback.climberId);
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
          _isLoadingExisting = false;
        });
      }
    }
  }

  Future<void> _loadClimbsForClimber(int climberId) async {
    try {
      final detail = await SessionScope.of(context).api.fetchClimberDetail(climberId);
      if (!mounted) {
        return;
      }
      setState(() {
        _availableClimbs = detail.recentClimbs;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _error = "Comment is required.";
      });
      return;
    }

    if (!_isEditing && (_selectedClimberId == null || _selectedClimbId == null)) {
      setState(() {
        _error = "Choose a climber and one of their climb logs.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = "";
    });

    try {
      final api = SessionScope.of(context).api;
      if (_isEditing) {
        await api.updateFeedback(
          widget.editingFeedbackId!,
          {
            "comment": _commentController.text.trim(),
            "rating": _rating,
          },
        );
      } else {
        await api.createFeedback(
          {
            "climberId": _selectedClimberId,
            "climbLogId": _selectedClimbId,
            "comment": _commentController.text.trim(),
            "rating": _rating,
          },
        );
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
    final isLoading = _isBootstrapping || _isLoadingExisting;
    return BetaUpScaffold(
      title: _isEditing ? "Edit Feedback" : "New Feedback",
      subtitle: _isEditing
          ? "Update review text and rating"
          : "Link review to a climber and climb log",
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (isLoading)
            const LoaderCard(label: "Loading feedback form")
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel("Coach form"),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedClimberId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Select climber"),
                      ),
                      ..._climbers.map(
                        (climber) => DropdownMenuItem<int?>(
                          value: climber.id,
                          child: Text(climber.name),
                        ),
                      ),
                    ],
                    onChanged: _isEditing
                        ? null
                        : (value) async {
                            setState(() {
                              _selectedClimberId = value;
                              _selectedClimbId = null;
                              _availableClimbs = const [];
                            });
                            if (value != null) {
                              await _loadClimbsForClimber(value);
                            }
                          },
                    decoration: const InputDecoration(labelText: "Climber"),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedClimbId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Select climb log"),
                      ),
                      ..._availableClimbs.map(
                        (climb) => DropdownMenuItem<int?>(
                          value: climb.id,
                          child: Text("${climb.routeName} (${climb.difficulty})"),
                        ),
                      ),
                    ],
                    onChanged: _isEditing
                        ? null
                        : (value) {
                            setState(() {
                              _selectedClimbId = value;
                            });
                          },
                    decoration: const InputDecoration(labelText: "Climb log"),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _rating,
                    items: [5, 4, 3, 2, 1]
                        .map(
                          (rating) => DropdownMenuItem<int>(
                            value: rating,
                            child: Text("Rating: $rating"),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _rating = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: "Rating"),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: "Comment",
                      hintText: "Write focused coaching notes.",
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
                    label: Text(_isSaving ? "Saving..." : (_isEditing ? "Update feedback" : "Submit feedback")),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BadgeRulesTab extends StatefulWidget {
  const BadgeRulesTab({super.key});

  @override
  State<BadgeRulesTab> createState() => _BadgeRulesTabState();
}

class _BadgeRulesTabState extends State<BadgeRulesTab> {
  List<BadgeRule> _rules = const [];
  bool _isLoading = true;
  String _error = "";
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> reload() => _loadRules();

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final rules = await SessionScope.of(context).api.fetchBadgeRules();
      if (!mounted) {
        return;
      }
      setState(() {
        _rules = rules;
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

  Future<void> _openEditor([BadgeRule? rule]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BadgeRuleEditorSheet(rule: rule),
    );

    if (saved == true) {
      await _loadRules();
    }
  }

  Future<void> _deleteRule(BadgeRule rule) async {
    final api = SessionScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete badge rule?"),
            content: const Text("Earned copies of this badge will be removed as well."),
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
      _deletingId = rule.id;
      _error = "";
    });

    try {
      await api.deleteBadgeRule(rule.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(messenger, "Badge rule deleted.");
      await _loadRules();
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
    return RefreshIndicator(
      onRefresh: _loadRules,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Rule catalog"),
                const SizedBox(height: 12),
                Text("Persisted badge automation rules", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Create rule"),
                ),
              ],
            ),
          ),
          if (_isLoading && _rules.isEmpty) const LoaderCard(label: "Loading badge rules"),
          if (_error.isNotEmpty && _rules.isEmpty)
            ErrorCard(message: _error, onRetry: _loadRules),
          if (!_isLoading && _rules.isEmpty)
            const EmptyCard(
              title: "No badge rules yet",
              message: "Create the first rule to define milestone logic.",
            ),
          ..._rules.map((rule) {
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
                            Text(rule.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(rule.description, style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                StatusChip(label: rule.badgeKey, color: const Color(0xFF7BE0FF)),
                                StatusChip(label: rule.criteriaType.label, color: const Color(0xFFFFB26D)),
                                StatusChip(label: "Threshold ${rule.threshold}", color: const Color(0xFF5ED9A6)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditor(rule),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text("Edit"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deletingId == rule.id ? null : () => _deleteRule(rule),
                          icon: Icon(
                            _deletingId == rule.id
                                ? Icons.hourglass_top_rounded
                                : Icons.delete_outline_rounded,
                          ),
                          label: Text(_deletingId == rule.id ? "Deleting..." : "Delete"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_error.isNotEmpty && _rules.isNotEmpty)
            ErrorCard(message: _error, onRetry: _loadRules),
        ],
      ),
    );
  }
}

class BadgeRuleEditorSheet extends StatefulWidget {
  const BadgeRuleEditorSheet({
    super.key,
    this.rule,
  });

  final BadgeRule? rule;

  @override
  State<BadgeRuleEditorSheet> createState() => _BadgeRuleEditorSheetState();
}

class _BadgeRuleEditorSheetState extends State<BadgeRuleEditorSheet> {
  final _badgeKeyController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _thresholdController = TextEditingController(text: "1");

  BadgeCriteriaType _criteriaType = BadgeCriteriaType.totalLogs;
  bool _isSaving = false;
  String _error = "";

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule != null) {
      _badgeKeyController.text = rule.badgeKey;
      _nameController.text = rule.name;
      _descriptionController.text = rule.description;
      _thresholdController.text = rule.threshold.toString();
      _criteriaType = rule.criteriaType;
    }
  }

  @override
  void dispose() {
    _badgeKeyController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final threshold = int.tryParse(_thresholdController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        (!_isEditing && _badgeKeyController.text.trim().isEmpty) ||
        threshold == null ||
        threshold < 1) {
      setState(() {
        _error = "Provide a valid key, name, description, and threshold.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = "";
    });

    try {
      final api = SessionScope.of(context).api;
      if (_isEditing) {
        await api.updateBadgeRule(
          widget.rule!.id,
          {
            "name": _nameController.text.trim(),
            "description": _descriptionController.text.trim(),
            "threshold": threshold,
            "criteriaType": _criteriaType.rawValue,
          },
        );
      } else {
        await api.createBadgeRule(
          {
            "badgeKey": _badgeKeyController.text.trim(),
            "name": _nameController.text.trim(),
            "description": _descriptionController.text.trim(),
            "threshold": threshold,
            "criteriaType": _criteriaType.rawValue,
          },
        );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel("Badge form"),
            const SizedBox(height: 12),
            Text(
              _isEditing ? "Edit rule" : "Create rule",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _badgeKeyController,
              enabled: !_isEditing,
              decoration: const InputDecoration(labelText: "Badge key"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Display name"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Threshold"),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<BadgeCriteriaType>(
              initialValue: _criteriaType,
              items: BadgeCriteriaType.values
                  .map(
                    (type) => DropdownMenuItem<BadgeCriteriaType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _criteriaType = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: "Criteria type"),
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
              label: Text(_isSaving ? "Saving..." : (_isEditing ? "Update rule" : "Create rule")),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            "$value",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFB26D),
                ),
          ),
        ],
      ),
    );
  }
}
