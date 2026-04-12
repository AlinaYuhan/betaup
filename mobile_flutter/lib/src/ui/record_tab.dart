import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'climber_pages.dart';
import 'common.dart';
import 'session_page.dart';

// ── Main tab shell ──────────────────────────────────────────────────────────

class RecordTab extends StatefulWidget {
  const RecordTab({super.key});

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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

  void _refreshAll() {
    _dashboardKey.currentState?.reload();
    _badgesKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09111F),
        elevation: 0,
        title: const Text(
          "记录",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF7A18),
          labelColor: const Color(0xFFFF7A18),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center_rounded), text: "训练"),
            Tab(icon: Icon(Icons.auto_graph_rounded), text: "进步"),
            Tab(icon: Icon(Icons.workspace_premium_rounded), text: "徽章"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TrainingHomeTab(onRefreshAll: _refreshAll),
          ClimberDashboardTab(key: _dashboardKey),
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
  // Active session
  ClimbSession? _activeSession;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // Session history
  List<SessionSummary> _sessions = [];
  bool _sessionsLoading = true;

  // GPS
  _GpsStatus _gpsStatus = _GpsStatus.loading;
  _NearbyResult? _gpsResult;
  List<Gym> _gyms = [];

  bool _starting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _init();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      setState(() {
        _activeSession = s;
        if (s != null) _startTicker(s.startTime);
      });
    } catch (_) {}
  }

  void _startTicker(DateTime startTime) {
    _ticker?.cancel();
    _elapsed = DateTime.now().difference(startTime);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(startTime));
      }
    });
  }

  Future<void> _loadSessions() async {
    setState(() => _sessionsLoading = true);
    try {
      final list =
          await SessionScope.of(context).api.fetchSessions(size: 10);
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _sessionsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sessionsLoading = false);
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
      builder: (ctx) => AlertDialog(
        title: const Text("Go Climb"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_gpsStatus == _GpsStatus.failed || _gpsStatus == _GpsStatus.loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_rounded,
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      _gpsStatus == _GpsStatus.loading
                          ? "定位中，请手动填写场馆"
                          : "定位不可用，请手动填写",
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: venueCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "场馆名称（选填）",
                hintText: "例：Campus Wall",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text("取消")),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(venueCtrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A18)),
            child: const Text("开始"),
          ),
        ],
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
        _startTicker(session.startTime);
      });
      _openSessionPage(session);
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("启动失败：$e")));
      }
    }
  }

  Future<void> _openClimbEditor() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const ClimbEditorPage(existingId: null)),
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
    _ticker?.cancel();
    await _checkActiveSession();
    if (popped == true) {
      _loadSessions();
      widget.onRefreshAll();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  String get _elapsedLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthSessions = _sessions
        .where((s) =>
            s.startTime.year == now.year && s.startTime.month == now.month)
        .toList();
    final totalDuration = monthSessions.fold(Duration.zero, (sum, s) {
      if (s.endTime != null) return sum + s.endTime!.difference(s.startTime);
      return sum + Duration(minutes: s.durationMinutes);
    });

    return RefreshIndicator(
      color: const Color(0xFFFF7A18),
      backgroundColor: const Color(0xFF1A2535),
      onRefresh: _init,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ── Month stats ──────────────────────────────────────────────
          _buildStatsStrip(monthSessions.length, totalDuration),

          // ── GPS card ─────────────────────────────────────────────────
          _buildGpsCard(),

          // ── Hero (Go Climb / active session) ─────────────────────────
          _buildHeroSection(),

          // ── Session history ───────────────────────────────────────────
          if (!_sessionsLoading && _sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
              child: Row(
                children: [
                  const Text(
                    "最近训练",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    "共 ${_sessions.length} 次",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            ..._sessions.map((s) => _SessionCard(summary: s)),
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
                  "还没有训练记录\n点击上方按钮开始第一次攀岩吧！",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600, height: 1.9),
                ),
              ),
            ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(int count, Duration total) {
    final durationStr = count == 0 ? "—" : formatDuration(total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _StatPill(label: "本月训练", value: "$count 次"),
          const SizedBox(width: 12),
          _StatPill(label: "累计时长", value: durationStr),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    final IconData icon;
    final Color iconColor;
    final String text;

    switch (_gpsStatus) {
      case _GpsStatus.loading:
        icon = Icons.location_searching_rounded;
        iconColor = Colors.white38;
        text = "正在定位...";
      case _GpsStatus.found:
        icon = Icons.location_on_rounded;
        iconColor = const Color(0xFF5ED9A6);
        text =
            "${_gpsResult!.gym.name}  ·  ${_gpsResult!.distanceMeters.round()}m";
      case _GpsStatus.farAway:
        icon = Icons.location_on_rounded;
        iconColor = Colors.white38;
        text = _gpsResult != null
            ? "最近：${_gpsResult!.gym.name}（${(_gpsResult!.distanceMeters / 1000).toStringAsFixed(1)}km）"
            : "附近未找到岩馆";
      case _GpsStatus.failed:
        icon = Icons.location_off_rounded;
        iconColor = Colors.white38;
        text = "定位不可用，开始时手动输入场馆";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            if (_gpsStatus == _GpsStatus.loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38),
              )
            else
              Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: iconColor, fontSize: 13)),
            ),
            if (_gpsStatus != _GpsStatus.loading)
              GestureDetector(
                onTap: _detectNearby,
                child: const Icon(Icons.refresh_rounded,
                    size: 17, color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    if (_activeSession != null) {
      // ── Active session ─────────────────────────────────────────────
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange),
                      ),
                      const SizedBox(width: 7),
                      const Text("训练进行中",
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _activeSession!.venue.isNotEmpty
                        ? _activeSession!.venue
                        : "未知场馆",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _elapsedLabel,
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openSessionPage(_activeSession!),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text("继续训练",
                        style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A18),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openClimbEditor,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text("记录"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    minimumSize: const Size(90, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── No active session: Go Climb button ────────────────────────────
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _starting ? null : _startSession,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A18),
                minimumSize: const Size.fromHeight(68),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 6,
                shadowColor:
                    const Color(0xFFFF7A18).withValues(alpha: 0.45),
              ),
              child: _starting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text(
                      "Go Climb",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _openClimbEditor,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text("单条记录"),
            style: TextButton.styleFrom(foregroundColor: Colors.white30),
          ),
        ],
      ),
    );
  }
}

// ── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.summary});
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final venue =
        summary.venue.isNotEmpty ? summary.venue : "未知场馆";
    final dateStr = DateFormat("M月d日 HH:mm").format(summary.startTime);
    final sessionDuration = summary.endTime != null
        ? summary.endTime!.difference(summary.startTime)
        : Duration(minutes: summary.durationMinutes);
    final durationStr = formatDuration(sessionDuration);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(venue,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                if (summary.hardestSend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x26FF7A18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "最高 ${summary.hardestSend}",
                      style: const TextStyle(
                          color: Color(0xFFFF7A18), fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(dateStr,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(durationStr,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.terrain_rounded,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text("${summary.totalLogs} 条",
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip("⚡ ${summary.flashes}", const Color(0xFFFFD700)),
                const SizedBox(width: 8),
                _Chip("✅ ${summary.sends}", const Color(0xFF5ED9A6)),
                const SizedBox(width: 8),
                _Chip("💪 ${summary.attempts}", const Color(0xFFFFB26D)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
