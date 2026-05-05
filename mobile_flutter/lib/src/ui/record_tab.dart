import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'climber_pages.dart';
import 'common.dart';
import 'session_page.dart';

Color _gradeColor(String? grade) {
  if (grade == null) return const Color(0xFF6B8299);
  final n = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  if (n <= 2) return const Color(0xFF4ADE80);
  if (n <= 4) return const Color(0xFF60A5FA);
  if (n <= 6) return const Color(0xFFFF7A18);
  if (n <= 8) return const Color(0xFFE879F9);
  return const Color(0xFFF43F5E);
}

// ── Main tab shell ──────────────────────────────────────────────────────────

class RecordTab extends StatefulWidget {
  const RecordTab({super.key});

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _statsKey = GlobalKey<StatsTabState>();
  final _badgesKey = GlobalKey<BadgeProgressTabState>();

  AppSession? _session;
  int _lastVoiceVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (_session != session) {
      _session?.removeListener(_onSessionChange);
      _session = session;
      _session!.addListener(_onSessionChange);
      _lastVoiceVersion = session.voiceVersion;
    }
  }

  void _onSessionChange() {
    final vv = _session?.voiceVersion ?? 0;
    if (vv != _lastVoiceVersion) {
      _lastVoiceVersion = vv;
      _refreshAll();
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChange);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    _statsKey.currentState?.reload();
    _badgesKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09111F),
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: "TRAIN"),
            Tab(text: "PROGRESS"),
            Tab(text: "BADGES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TrainingHomeTab(onRefreshAll: _refreshAll),
          StatsTab(key: _statsKey),
          BadgeProgressTab(key: _badgesKey),
        ],
      ),
    );
  }
}

// ── GPS state ───────────────────────────────────────────────────────────────

enum _GpsStatus { loading, found, farAway, failed }

class _NearbyResult {
  const _NearbyResult({required this.gym, required this.distanceMeters});
  final Gym gym;
  final double distanceMeters;
}

Future<Position> _acquirePosition() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) throw Exception("位置服务未开启");
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception("未授权位置权限");
  }
  return Geolocator.getCurrentPosition()
      .timeout(const Duration(seconds: 8));
}

// ── Training Home Tab ────────────────────────────────────────────────────────

class _TrainingHomeTab extends StatefulWidget {
  const _TrainingHomeTab({required this.onRefreshAll});
  final VoidCallback onRefreshAll;

  @override
  State<_TrainingHomeTab> createState() => _TrainingHomeTabState();
}

class _TrainingHomeTabState extends State<_TrainingHomeTab> {
  ClimbSession? _activeSession;

  List<SessionSummary> _sessions = [];
  List<SessionSummary> _monthSessions = [];
  bool _sessionsLoading = true;

  _GpsStatus _gpsStatus = _GpsStatus.loading;
  _NearbyResult? _gpsResult;
  List<Gym> _gyms = [];

  bool _starting = false;
  bool _initialized = false;

  AppSession? _appSession;
  int _lastVoiceVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (_appSession != session) {
      _appSession?.removeListener(_onSessionChange);
      _appSession = session;
      _appSession!.addListener(_onSessionChange);
      _lastVoiceVersion = session.voiceVersion;
    }
    if (!_initialized) {
      _initialized = true;
      _init();
    }
  }

  void _onSessionChange() {
    final vv = _appSession?.voiceVersion ?? 0;
    if (vv != _lastVoiceVersion) {
      _lastVoiceVersion = vv;
      _loadSessions();
      _checkActiveSession();
    }
  }

  @override
  void dispose() {
    _appSession?.removeListener(_onSessionChange);
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      _checkActiveSession(),
      _loadSessions(),
      _initGps(),
    ]);
  }

  Future<void> _checkActiveSession() async {
    try {
      final s = await SessionScope.of(context).api.fetchActiveSession();
      if (!mounted) return;
      setState(() => _activeSession = s);
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    setState(() => _sessionsLoading = true);
    try {
      final list = await SessionScope.of(context).api.fetchSessions(size: 10);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _sessions = list;
        _monthSessions = list
            .where((s) => s.startTime.year == now.year && s.startTime.month == now.month)
            .toList();
        _sessionsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  Future<void> _deleteSession(SessionSummary s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Session"),
        content: Text("Delete \"${s.venue.isNotEmpty ? s.venue : 'this session'}\"? All climb records will also be removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SessionScope.of(context).api.deleteSession(s.sessionId);
      if (mounted) setState(() => _sessions.remove(s));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initGps() async {
    try {
      _gyms = await SessionScope.of(context).api.fetchGyms();
    } catch (_) {}
    if (mounted) await _detectNearby();
  }

  Future<void> _detectNearby() async {
    if (!mounted) return;
    setState(() => _gpsStatus = _GpsStatus.loading);
    try {
      final pos = await _acquirePosition();
      if (!mounted) return;
      Gym? nearest;
      double nearestDist = double.infinity;
      for (final gym in _gyms) {
        final d = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, gym.lat, gym.lng);
        if (d < nearestDist) {
          nearestDist = d;
          nearest = gym;
        }
      }
      if (!mounted) return;
      setState(() {
        if (nearest != null) {
          _gpsResult =
              _NearbyResult(gym: nearest, distanceMeters: nearestDist);
          _gpsStatus =
              nearestDist <= 500 ? _GpsStatus.found : _GpsStatus.farAway;
        } else {
          _gpsResult = null;
          _gpsStatus = _GpsStatus.farAway;
        }
      });
      // Make nearby gym available to the voice assistant.
      SessionScope.of(context).setNearbyGym(nearest?.name);
    } catch (_) {
      if (mounted) setState(() => _gpsStatus = _GpsStatus.failed);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _startSession() async {
    // If GPS already detected a nearby gym, skip the dialog entirely.
    if (_gpsStatus == _GpsStatus.found && _gpsResult != null) {
      await _doStartSession(_gpsResult!.gym.name);
      return;
    }

    // Otherwise show the dialog for manual / confirmation input.
    final venueCtrl = TextEditingController(
      text: _gpsStatus == _GpsStatus.farAway ? (_gpsResult?.gym.name ?? "") : "",
    );

    final venue = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _GlassDialog(
        gpsStatus: _gpsStatus,
        venueCtrl: venueCtrl,
      ),
    );

    if (venue == null || !mounted) return;
    await _doStartSession(venue);
  }

  Future<void> _doStartSession(String venue) async {
    if (!mounted) return;
    setState(() => _starting = true);
    try {
      final session = await SessionScope.of(context).api.startSession(venue);
      if (!mounted) return;
      setState(() {
        _activeSession = session;
        _starting = false;
      });
      _openSessionPage(session);
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to start: $e")));
      }
    }
  }

  Future<void> _openClimbEditor() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => ClimbEditorPage(
                existingId: null,
                defaultVenue: _activeSession?.venue.isNotEmpty == true
                    ? _activeSession!.venue
                    : _gpsResult?.gym.name,
              )),
    );
    if (saved == true) {
      _loadSessions();
      widget.onRefreshAll();
    }
  }

  Future<void> _openSessionPage(ClimbSession session) async {
    final popped = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SessionPage(session: session)),
    );
    await _checkActiveSession();
    if (popped == true) {
      _loadSessions();
      widget.onRefreshAll();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFFF7A18),
      backgroundColor: const Color(0xFF1A2535),
      onRefresh: _init,
      child: Stack(
        children: [
          // Ambient glow behind hero area
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF7A18).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ── Photo hero (stats + GPS + Go Climb combined) ──────────────
          _buildPhotoHero(_monthSessions),

          // ── Session history ───────────────────────────────────────────
          if (!_sessionsLoading && _sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Row(
                children: [
                  const Text(
                    "RECENT SESSIONS",
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_sessions.length}×",
                    style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      color: Color(0xFF6B8299),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ..._sessions.map((s) => _SessionCard(
                  summary: s,
                  onDelete: () => _deleteSession(s),
                )),
          ],

          if (_sessionsLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF7A18), strokeWidth: 2),
              ),
            ),

          if (!_sessionsLoading && _sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Center(
                child: Text(
                  "No sessions yet.\nTap a button above to start your first climb!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600, height: 1.9),
                ),
              ),
            ),

          const SizedBox(height: 120),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildPhotoHero(List<SessionSummary> monthSessions) {
    final bestGrade = monthSessions
        .where((s) => s.hardestSend != null)
        .map((s) => s.hardestSend!)
        .fold<String?>(null, (best, g) {
      if (best == null) return g;
      final a = int.tryParse(g.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final b = int.tryParse(best.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return a > b ? g : best;
    });
    final totalFlash = monthSessions.fold(0, (s, e) => s + e.flashes);
    final totalSend  = monthSessions.fold(0, (s, e) => s + e.sends);

    // GPS label
    final String gpsLabel;
    switch (_gpsStatus) {
      case _GpsStatus.found:
        gpsLabel = '${_gpsResult!.gym.name}  ·  ${_gpsResult!.distanceMeters.round()}m away';
      case _GpsStatus.farAway:
        gpsLabel = _gpsResult != null
            ? 'Nearest: ${_gpsResult!.gym.name}  ·  ${(_gpsResult!.distanceMeters / 1000).toStringAsFixed(1)}km'
            : 'No nearby gym found';
      case _GpsStatus.loading:
        gpsLabel = 'Locating...';
      case _GpsStatus.failed:
        gpsLabel = 'Location unavailable';
    }

    if (_activeSession != null) {
      // ── Active session: photo + timer overlay ─────────────────────
      return SizedBox(
        height: 380,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/climb_hero.jpg', fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xDD09111F)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFFF7A18)),
                    ),
                    const SizedBox(width: 8),
                    const Text('SESSION IN PROGRESS',
                        style: TextStyle(fontFamily: 'Oswald', fontSize: 11,
                            letterSpacing: 2, color: Color(0xFFFF7A18))),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _activeSession!.venue.isNotEmpty ? _activeSession!.venue : 'Unknown Gym',
                    style: const TextStyle(fontFamily: 'Oswald', fontSize: 22,
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  _ElapsedTimer(startTime: _activeSession!.startTime),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openSessionPage(_activeSession!),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7A18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Text('CONTINUE',
                              style: TextStyle(fontFamily: 'Oswald',
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  letterSpacing: 2, color: Colors.white))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _openClimbEditor,
                      child: Container(
                        height: 52, width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text('LOG',
                            style: TextStyle(fontFamily: 'Oswald',
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: Colors.white))),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── No active session: photo + stats + Go Climb ───────────────
    return SizedBox(
      height: 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          Image.asset('assets/images/climb_hero.jpg', fit: BoxFit.cover),
          // Gradient overlay — transparent top, dark at bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xF009111F)],
                stops: [0.0, 0.75],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Stats row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEST THIS MONTH',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 10,
                            letterSpacing: 1.8,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          bestGrade ?? '—',
                          style: const TextStyle(
                            fontFamily: 'Barlow Condensed',
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          '${monthSessions.length} sessions this month',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PhotoStat(totalFlash, 'FLASH', const Color(0xFFFFD700)),
                        const SizedBox(height: 8),
                        _PhotoStat(totalSend, 'SEND', const Color(0xFF4ADE80)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // GPS row
                Row(children: [
                  if (_gpsStatus == _GpsStatus.loading)
                    const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                  else
                    Icon(
                      _gpsStatus == _GpsStatus.found
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      size: 14,
                      color: _gpsStatus == _GpsStatus.found
                          ? const Color(0xFF4ADE80)
                          : Colors.white38,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(gpsLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: _gpsStatus == _GpsStatus.found
                              ? const Color(0xFF4ADE80)
                              : Colors.white38,
                        )),
                  ),
                  if (_gpsStatus != _GpsStatus.loading)
                    GestureDetector(
                      onTap: _detectNearby,
                      child: const Icon(Icons.refresh_rounded, size: 15, color: Colors.white24),
                    ),
                ]),
                const SizedBox(height: 16),
                // Go Climb button
                _PulseGoClimbButton(onPressed: _startSession, loading: _starting),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _openClimbEditor,
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Log single climb'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.summary, this.onDelete});
  final SessionSummary summary;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final venue = summary.venue.isNotEmpty ? summary.venue : "Unknown Venue";
    final dateStr = DateFormat("MMM d").format(summary.startTime).toUpperCase();
    final timeStr = DateFormat("HH:mm").format(summary.startTime);
    final sessionDuration = summary.endTime != null
        ? summary.endTime!.difference(summary.startTime)
        : Duration(minutes: summary.durationMinutes);
    final durationStr = formatDuration(sessionDuration);
    final gradeCol = _gradeColor(summary.hardestSend);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onLongPress: onDelete == null
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete_outline,
                              color: Color(0xFFF87171)),
                          title: const Text("Delete Session",
                              style: TextStyle(color: Color(0xFFF87171))),
                          onTap: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.cancel_outlined),
                          title: const Text("Cancel"),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SessionDetailPage(summary: summary),
        )),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gradeCol.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                          venue,
                          style: const TextStyle(
                            fontFamily: 'Oswald',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$dateStr  ·  $timeStr  ·  $durationStr  ·  ${summary.totalLogs} logs",
                          style: const TextStyle(
                            color: Color(0xFF3A5070),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary.hardestSend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gradeCol.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: gradeCol.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        summary.hardestSend!,
                        style: TextStyle(
                          fontFamily: 'Barlow Condensed',
                          color: gradeCol,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ResultChip("Flash", summary.flashes, const Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  _ResultChip("Send", summary.sends, const Color(0xFF4ADE80)),
                  const SizedBox(width: 8),
                  _ResultChip("Attempt", summary.attempts, const Color(0xFF60A5FA)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? color : const Color(0xFF3A5070),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            "$count",
            style: TextStyle(
              fontFamily: 'Barlow Condensed',
              color: active ? color : const Color(0xFF3A5070),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStat extends StatelessWidget {
  const _PhotoStat(this.count, this.label, this.color);
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Barlow Condensed',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: count > 0 ? color : Colors.white24,
            height: 1.0,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 10,
            letterSpacing: 1.5,
            color: count > 0 ? color.withValues(alpha: 0.7) : Colors.white24,
          ),
        ),
      ],
    );
  }
}

class _PulseGoClimbButton extends StatelessWidget {
  const _PulseGoClimbButton({required this.onPressed, required this.loading});
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: loading ? null : onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer orange glow ring
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF7A18).withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A18).withValues(alpha: 0.20),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terrain_rounded,
                            color: Colors.white.withValues(alpha: 0.90),
                            size: 34),
                        const SizedBox(height: 4),
                        Text(
                          "GO",
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 4,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const Text(
                          "CLIMB",
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// ── Glass Dialog ─────────────────────────────────────────────────────────────

class _GlassDialog extends StatelessWidget {
  const _GlassDialog({required this.gpsStatus, required this.venueCtrl});
  final _GpsStatus gpsStatus;
  final TextEditingController venueCtrl;

  @override
  Widget build(BuildContext context) {
    final showGpsWarning =
        gpsStatus == _GpsStatus.failed || gpsStatus == _GpsStatus.loading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'GO CLIMB',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where are you climbing today?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // GPS warning
                    if (showGpsWarning)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.location_off_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.45)),
                            const SizedBox(width: 6),
                            Text(
                              gpsStatus == _GpsStatus.loading
                                  ? 'Locating… enter venue manually'
                                  : 'Location unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Venue input
                    TextField(
                      controller: venueCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Campus Wall',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.10),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF7A18), width: 1.5),
                        ),
                      ),
                      onSubmitted: (v) =>
                          Navigator.of(context).pop(v.trim()),
                    ),
                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(null),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.20)),
                              ),
                              child: const Center(
                                child: Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pop(venueCtrl.text.trim()),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A18),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A18)
                                        .withValues(alpha: 0.40),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'START SESSION',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats Tab (进步) ──────────────────────────────────────────────────────────

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => StatsTabState();
}

class StatsTabState extends State<StatsTab> {
  String _period = "WEEK";
  ClimbStats? _stats;
  bool _loading = true;
  bool _initialized = false;
  String? _error;

  void reload() => _load();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await SessionScope.of(context).api.fetchStats(_period);
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Period selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              for (final entry in const [
                ("WEEK", "8 Weeks"),
                ("MONTH", "6 Months"),
                ("ALL", "All Time"),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(entry.$2,
                          style: const TextStyle(fontSize: 12)),
                      selected: _period == entry.$1,
                      onSelected: (_) {
                        setState(() => _period = entry.$1);
                        _load();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF7A18), strokeWidth: 2)))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text("Retry")),
                ],
              ),
            ),
          )
        else if (_stats == null)
          const Expanded(child: Center(child: Text("No stats yet")))
        else
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF7A18),
              backgroundColor: const Color(0xFF1A2535),
              onRefresh: _load,
              child: _StatsBody(stats: _stats!),
            ),
          ),
      ],
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});
  final ClimbStats stats;

  @override
  Widget build(BuildContext context) {
    final s = stats.summary;
    final topGradeColor = _gradeColor(s.topGrade);
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── 2×2 big stat cards ─────────────────────────────────────────
          Row(
            children: [
              _BigStatCard(
                value: '${s.totalClimbs}',
                label: 'CLIMBS',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              _BigStatCard(
                value: '${s.flashRatePct}%',
                label: 'FLASH RATE',
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BigStatCard(
                value: s.topGrade ?? '—',
                label: 'BEST GRADE',
                color: topGradeColor,
                highlight: true,
              ),
              const SizedBox(width: 10),
              _BigStatCard(
                value: '${s.totalSessions}',
                label: 'SESSIONS',
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Frequency bar chart ────────────────────────────────────────
          const _SectionTitle("FREQUENCY"),
          const SizedBox(height: 12),
          _FrequencyChart(buckets: stats.buckets),
          const SizedBox(height: 28),

          // ── Grade distribution ─────────────────────────────────────────
          if (stats.gradeDistribution.isNotEmpty) ...[
            const _SectionTitle("GRADE DISTRIBUTION"),
            const SizedBox(height: 12),
            _GradeDistributionBars(grades: stats.gradeDistribution),
            const SizedBox(height: 28),
          ],

          // ── Result breakdown ───────────────────────────────────────────
          const _SectionTitle("RESULT BREAKDOWN"),
          const SizedBox(height: 12),
          _ResultBreakdown(summary: s),
        ],
      );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.value,
    required this.label,
    required this.color,
    this.highlight = false,
  });
  final String value;
  final String label;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: highlight
              ? color.withValues(alpha: 0.09)
              : const Color(0xFF111D2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight
                ? color.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: highlight
              ? [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: highlight ? color : Colors.white,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: color.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({required this.startTime});
  final DateTime startTime;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late Duration _elapsed;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(widget.startTime));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      h > 0 ? '$h:$m:$s' : '$m:$s',
      style: const TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.0,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Oswald',
        color: Color(0xFF6B8299),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _FrequencyChart extends StatelessWidget {
  const _FrequencyChart({required this.buckets});
  final List<StatsBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF111D2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: const Center(
          child: Text("No data",
              style: TextStyle(
                  fontFamily: 'Oswald',
                  color: Color(0xFF3A5070),
                  fontSize: 13,
                  letterSpacing: 1.5)),
        ),
      );
    }

    final maxCount = buckets
        .map((b) => b.climbCount)
        .fold(0, (a, b) => a > b ? a : b);
    final maxY = maxCount.toDouble().clamp(1.0, double.infinity);

    final groups = buckets.asMap().entries.map((e) {
      final isPeak = e.value.climbCount == maxCount && maxCount > 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.climbCount.toDouble(),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFFFF7A18),
                isPeak ? const Color(0xFF7BE0FF) : const Color(0xFF7BE0FF).withValues(alpha: 0.5),
              ],
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.5,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111D2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.5,
            barGroups: groups,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();
                    final count = buckets[idx].climbCount;
                    if (count == 0) return const SizedBox.shrink();
                    final isPeak = count == maxCount;
                    return Text(
                      "$count",
                      style: TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPeak ? const Color(0xFFFF7A18) : const Color(0xFF3A5070),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();
                    final label = buckets[idx].label;
                    final short = label.length > 5 ? label.substring(label.length - 5) : label;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(short,
                          style: const TextStyle(
                              fontFamily: 'Barlow Condensed',
                              color: Color(0xFF3A5070),
                              fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeDistributionBars extends StatelessWidget {
  const _GradeDistributionBars({required this.grades});
  final List<GradeStat> grades;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        grades.map((g) => g.total).fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111D2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: grades.asMap().entries.map((entry) {
          final g = entry.value;
          final fraction = g.total / maxCount;
          final gradeCol = _gradeColor(g.difficulty);
          final isLast = entry.key == grades.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    g.difficulty,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: gradeCol,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: gradeCol.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.04, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: gradeCol,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: gradeCol.withValues(alpha: 0.40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    "${g.total}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Barlow Condensed',
                      color: gradeCol.withValues(alpha: 0.80),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResultBreakdown extends StatelessWidget {
  const _ResultBreakdown({required this.summary});
  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ResultMiniCard(
          value: '${summary.totalFlashes}',
          label: 'FLASH',
          sublabel: '⚡',
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(width: 10),
        _ResultMiniCard(
          value: '${summary.totalSends}',
          label: 'SEND',
          sublabel: '✓',
          color: const Color(0xFF5ED9A6),
        ),
        const SizedBox(width: 10),
        _ResultMiniCard(
          value: '${summary.totalAttempts}',
          label: 'ATTEMPT',
          sublabel: '◎',
          color: const Color(0xFFFF7A18),
        ),
      ],
    );
  }
}

class _ResultMiniCard extends StatelessWidget {
  const _ResultMiniCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });
  final String value;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sublabel,
              style: const TextStyle(fontSize: 16, height: 1),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: color,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: color.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Detail Page ────────────────────────────────────────────────────────

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.summary});
  final SessionSummary summary;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

/// Generates deterministic simulated HR samples for a session.
/// Uses sessionId as seed so the same session always shows the same data.
List<int> _generateHrSamples(int sessionId, Duration duration) {
  final rng = Random(sessionId * 31337);
  final totalSeconds = duration.inSeconds.clamp(60, 7200);
  final count = (totalSeconds / 15).round().clamp(4, 120);
  final samples = <int>[];
  double base = 72 + rng.nextDouble() * 10;
  for (int i = 0; i < count; i++) {
    final t = i / count;
    final warmup = (t * 60).clamp(0.0, 40.0);
    final cycle = (t * 8) % 1.0;
    final burst = cycle < 0.4 ? 50.0 * sin(cycle / 0.4 * pi) : 15.0 * (1.0 - (cycle - 0.4) / 0.6);
    final noise = (rng.nextDouble() - 0.5) * 8;
    base = (base + (rng.nextDouble() - 0.48) * 2).clamp(70, 100);
    samples.add((base + warmup + burst + noise).round().clamp(68, 178));
  }
  return samples;
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  List<ClimbLog>? _climbs;
  bool _loading = true;
  String? _error;
  bool _loaded = false;
  bool _hasHr = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final session = SessionScope.of(context);
      final client = ApiClient(readToken: () => session.token);
      final climbs = await client.fetchSessionClimbs(widget.summary.sessionId);
      bool hasHr = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final ids = prefs.getStringList('hr_session_ids') ?? [];
        hasHr = ids.contains(widget.summary.sessionId.toString());
      } catch (_) {}
      if (mounted) setState(() { _climbs = climbs; _hasHr = hasHr; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final venue = s.venue.isNotEmpty ? s.venue : "Unknown Venue";
    final startStr = DateFormat("MMM d, yyyy  HH:mm").format(s.startTime);
    final dur = s.endTime != null
        ? s.endTime!.difference(s.startTime)
        : Duration(minutes: s.durationMinutes);
    final durStr = formatDuration(dur);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(venue, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(Icons.calendar_today_rounded, "Date", startStr),
                const SizedBox(height: 10),
                _InfoRow(Icons.timer_outlined, "Duration", durStr),
                const SizedBox(height: 10),
                _InfoRow(Icons.location_on_outlined, "Venue", venue),
                if (s.hardestSend != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(Icons.emoji_events_rounded, "Best Send", s.hardestSend!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatBox("⚡ Flash", "${s.flashes}", const Color(0xFFFFD700))),
              const SizedBox(width: 10),
              Expanded(child: _StatBox("✅ Sends", "${s.sends}", const Color(0xFF5ED9A6))),
              const SizedBox(width: 10),
              Expanded(child: _StatBox("💪 Attempts", "${s.attempts}", const Color(0xFFFFB26D))),
            ],
          ),
          const SizedBox(height: 20),
          if (_hasHr)
            _HrSection(sessionId: s.sessionId, duration: dur)
          else
            const _NoHrCard(),
          const SizedBox(height: 24),
          const Text("Climbs",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          else if (_climbs == null || _climbs!.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text("No climbs recorded", style: TextStyle(color: Colors.grey)),
            ))
          else
            ..._climbs!.map((c) => _ClimbTile(c)),
        ],
      ),
    );
  }
}

class _HrSection extends StatelessWidget {
  const _HrSection({required this.sessionId, required this.duration});
  final int sessionId;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final samples = _generateHrSamples(sessionId, duration);
    final avg = (samples.reduce((a, b) => a + b) / samples.length).round();
    final max = samples.reduce((a, b) => a > b ? a : b);
    final min = samples.reduce((a, b) => a < b ? a : b);
    const red = Color(0xFFFF4D6D);

    final spots = samples.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.favorite_rounded, color: Color(0xFFFF4D6D), size: 15),
            SizedBox(width: 6),
            Text("Heart Rate",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HrStat("Avg", "$avg", "bpm"),
              _HrStat("Peak", "$max", "bpm"),
              _HrStat("Min", "$min", "bpm"),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: (min - 10).toDouble(),
                maxY: (max + 10).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: red,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: red.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHrCard extends StatelessWidget {
  const _NoHrCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Icon(Icons.favorite_outline_rounded, color: Colors.grey.shade700, size: 15),
        const SizedBox(width: 8),
        Text("No heart rate recorded",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }
}

class _HrStat extends StatelessWidget {
  const _HrStat(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 22, fontWeight: FontWeight.bold)),
      Text(unit, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label  ", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ClimbTile extends StatelessWidget {
  const _ClimbTile(this.climb);
  final ClimbLog climb;

  @override
  Widget build(BuildContext context) {
    final name = climb.routeName.isNotEmpty ? climb.routeName : climb.difficulty;
    final timeStr = climb.createdAt != null
        ? DateFormat("HH:mm").format(climb.createdAt!)
        : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(climb.difficulty,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  if (climb.attempts > 1)
                    Text("  ·  ${climb.attempts} attempts",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  if (climb.notes.isNotEmpty)
                    Text("  ·  ${climb.notes}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ResultBadge(climb.result),
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(timeStr,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge(this.result);
  final ClimbResult result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      ClimbResult.flash => ("Flash", const Color(0xFFFFD700)),
      ClimbResult.send => ("Send", const Color(0xFF5ED9A6)),
      ClimbResult.attempt => ("Attempt", const Color(0xFFFFB26D)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
