import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'climber_pages.dart';
import 'common.dart';
import 'heart_rate_service.dart';

/// Full-screen training session page.
/// Shown when user taps "开始训练".
class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.session});
  final ClimbSession session;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late Timer _ticker;
  Duration _elapsed = Duration.zero;
  int _logCount = 0;
  bool _ending = false;

  // ── Heart rate state ─────────────────────────────────────────────────────
  int? _currentBpm;
  final List<HeartRateSample> _hrSamples = [];
  bool _bleConnecting = false;
  bool _bleConnected = false;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.session.startTime);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(widget.session.startTime));
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    BleHeartRateService.disconnect();
    MockHeartRateSimulator.stop();
    super.dispose();
  }

  String get _timerLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  Future<void> _connectHeartRate() async {
    setState(() => _bleConnecting = true);
    // Small delay so the connecting spinner is visible briefly.
    await Future.delayed(const Duration(milliseconds: 800));
    MockHeartRateSimulator.start(onSample: (sample) {
      if (mounted) {
        setState(() {
          _currentBpm = sample.bpm;
          _hrSamples.add(sample);
        });
      }
    });
    if (mounted) {
      setState(() {
        _bleConnecting = false;
        _bleConnected = true;
      });
      // Mark this session as having HR data so the detail page can show it.
      try {
        final prefs = await SharedPreferences.getInstance();
        final ids = prefs.getStringList('hr_session_ids') ?? [];
        final key = widget.session.id.toString();
        if (!ids.contains(key)) {
          ids.add(key);
          await prefs.setStringList('hr_session_ids', ids);
        }
      } catch (_) {}
    }
  }

  Future<void> _logRoute() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClimbEditorPage(
          existingId: null,
          activeSessionId: widget.session.id,
          defaultVenue: widget.session.venue,
        ),
      ),
    );
    if (saved == true && mounted) setState(() => _logCount++);
  }

  Future<void> _endSession() async {
    setState(() => _ending = true);
    try {
      final api = SessionScope.of(context).api;
      final summary = await api.endSession(widget.session.id);
      // Disconnect watch before showing report
      BleHeartRateService.disconnect();

      if (!mounted) return;
      if (summary.newlyUnlockedBadges.isNotEmpty) {
        await showBadgeUnlockDialog(context, summary.newlyUnlockedBadges);
        if (!mounted) return;
      }
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _WarReportSheet(
          summary: summary,
          heartRateSamples: List.unmodifiable(_hrSamples),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _ending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("结束失败：$e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.session.venue.isNotEmpty ? widget.session.venue : "未知场馆";
    final startStr = DateFormat("HH:mm").format(widget.session.startTime);

    return Scaffold(
      backgroundColor: const Color(0xFF09111F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: "返回（不结束训练）",
        ),
        title: Text(venue, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Timer display ──────────────────────────────────────────────
            Text(
              _timerLabel,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                letterSpacing: 4,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "开始于 $startStr",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),

            const Spacer(flex: 1),

            // ── Stats row ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(label: "已记录", value: "$_logCount 条"),
                  const SizedBox(width: 40),
                  _StatItem(
                    label: "训练时长",
                    value: _elapsed.inMinutes > 0
                        ? "${_elapsed.inMinutes}分 ${_elapsed.inSeconds.remainder(60)}秒"
                        : "${_elapsed.inSeconds}秒",
                  ),
                  if (_bleConnected && _currentBpm != null) ...[
                    const SizedBox(width: 40),
                    _StatItem(
                      label: "心率",
                      value: "$_currentBpm",
                      valueColor: const Color(0xFFFF4D6D),
                      suffix: " bpm",
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Apple Watch connect button ──────────────────────────────────
            _WatchConnectButton(
              connected: _bleConnected,
              connecting: _bleConnecting,
              onTap: _bleConnected ? null : _connectHeartRate,
            ),

            const Spacer(flex: 2),

            // ── Action buttons ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _logRoute,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text("记录一条", style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A18),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _ending ? null : _endSession,
                icon: _ending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(_ending ? "结束中..." : "结束训练"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Watch connect button ──────────────────────────────────────────────────────

class _WatchConnectButton extends StatelessWidget {
  const _WatchConnectButton({
    required this.connected,
    required this.connecting,
    required this.onTap,
  });
  final bool connected;
  final bool connecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF4D6D);

    if (connected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_rounded, color: red, size: 14),
          const SizedBox(width: 6),
          Text(
            "Apple Watch 已连接",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Real BLE connect button
        GestureDetector(
          onTap: connecting ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (connecting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFFFF4D6D),
                    ),
                  )
                else
                  const Icon(Icons.watch_rounded, size: 16, color: Color(0xFFFF4D6D)),
                const SizedBox(width: 8),
                Text(
                  connecting ? "搜索中..." : "连接 Apple Watch 心率",
                  style: TextStyle(
                    fontSize: 13,
                    color: connecting ? Colors.grey.shade400 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.suffix,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
            children: [
              TextSpan(text: value),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: valueColor ?? Colors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ── War Report Sheet ─────────────────────────────────────────────────────────

class _WarReportSheet extends StatelessWidget {
  const _WarReportSheet({
    required this.summary,
    required this.heartRateSamples,
  });
  final SessionSummary summary;
  final List<HeartRateSample> heartRateSamples;

  @override
  Widget build(BuildContext context) {
    final dur = summary.endTime != null
        ? summary.endTime!.difference(summary.startTime)
        : Duration(minutes: summary.durationMinutes);
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    final s = dur.inSeconds.remainder(60);
    final durationStr = h > 0
        ? "$h时$m分$s秒"
        : m > 0
            ? "$m分$s秒"
            : "$s秒";

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            "训练战报",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (summary.venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              summary.venue,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),

          // Duration + hardest
          Row(
            children: [
              Expanded(
                child: _ReportCard(
                  icon: Icons.timer_outlined,
                  label: "训练时长",
                  value: durationStr,
                  color: const Color(0xFF7BE0FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportCard(
                  icon: Icons.emoji_events_outlined,
                  label: "最高完成",
                  value: summary.hardestSend ?? "—",
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Log stats
          Row(
            children: [
              Expanded(
                child: _ReportCard(
                  icon: Icons.bolt_rounded,
                  label: "Flash",
                  value: "${summary.flashes}",
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportCard(
                  icon: Icons.check_circle_outline,
                  label: "完成",
                  value: "${summary.sends}",
                  color: const Color(0xFF5ED9A6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportCard(
                  icon: Icons.fitness_center_outlined,
                  label: "尝试",
                  value: "${summary.attempts}",
                  color: const Color(0xFFFFB26D),
                ),
              ),
            ],
          ),

          // Grade breakdown
          if (summary.gradeSummary.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "难度分布",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ...summary.gradeSummary.map((stat) {
              final attemptOnly = stat.sends == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(stat.difficulty,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7A18))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          if (attemptOnly)
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB26D).withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            )
                          else ...[
                            FractionallySizedBox(
                              widthFactor: (stat.total > 0
                                      ? stat.sends / stat.total
                                      : 0.0)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5ED9A6),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (stat.total > 0
                                      ? stat.flashes / stat.total
                                      : 0.0)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (attemptOnly)
                      Text("💪${stat.total}",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFFFB26D)))
                    else ...[
                      Text("${stat.sends}/${stat.total}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                      if (stat.flashes > 0) ...[
                        const SizedBox(width: 4),
                        Text("⚡${stat.flashes}",
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFFFD700))),
                      ],
                    ],
                  ],
                ),
              );
            }),
          ],

          // ── Heart Rate Section ──────────────────────────────────────────
          const SizedBox(height: 24),
          _HeartRateSection(samples: heartRateSamples),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A18),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("完成", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ── Heart Rate Section ────────────────────────────────────────────────────────

class _HeartRateSection extends StatelessWidget {
  const _HeartRateSection({required this.samples});
  final List<HeartRateSample> samples;

  static const _red = Color(0xFFFF4D6D);

  @override
  Widget build(BuildContext context) {
    final hasData = samples.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: _red, size: 18),
            const SizedBox(width: 6),
            const Text(
              "心率记录",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            if (hasData) ...[
              _HrBadge(
                label: "均值",
                value: "${BleHeartRateService.averageBpm(samples)} bpm",
              ),
              const SizedBox(width: 8),
              _HrBadge(
                label: "峰值",
                value: "${BleHeartRateService.maxBpm(samples)} bpm",
                accent: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (!hasData)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.watch_outlined, color: Colors.grey.shade600, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    "本次未连接 Apple Watch",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  Text(
                    "下次训练开始后点击「连接 Apple Watch 心率」",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
        else
          _HeartRateChart(samples: samples),
      ],
    );
  }
}

class _HrBadge extends StatelessWidget {
  const _HrBadge({required this.label, required this.value, this.accent = false});
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF4D6D);
    final color = accent ? red : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: color),
          children: [
            TextSpan(text: "$label  "),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartRateChart extends StatelessWidget {
  const _HeartRateChart({required this.samples});
  final List<HeartRateSample> samples;

  @override
  Widget build(BuildContext context) {
    final origin = samples.first.time;
    final spots = samples
        .map((s) => FlSpot(
              s.time.difference(origin).inSeconds / 60.0,
              s.bpm.toDouble(),
            ))
        .toList();

    final minY = (BleHeartRateService.minBpm(samples) - 10).clamp(40, 200).toDouble();
    final maxY = (BleHeartRateService.maxBpm(samples) + 10).clamp(80, 220).toDouble();
    final totalMin = spots.last.x;
    final xInterval = totalMin > 10
        ? (totalMin / 3).roundToDouble()
        : totalMin > 3
            ? 2.0
            : 1.0;

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFFFF4D6D),
              barWidth: 2,
              dotData: FlDotData(
                show: spots.length <= 30,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFFFF4D6D),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
              ),
            ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 20,
                getTitlesWidget: (v, _) => Text(
                  "${v.toInt()}",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                getTitlesWidget: (v, _) => Text(
                  "${v.toInt()}min",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        "${s.y.toInt()} bpm",
                        const TextStyle(color: Colors.white, fontSize: 11),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Report Card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
