import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'climber_pages.dart';
import 'common.dart';

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
    super.dispose();
  }

  String get _timerLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? "$h:$m:$s" : "$m:$s";
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
      if (!mounted) return;
      // Show badge unlock dialog first (if any new badges)
      if (summary.newlyUnlockedBadges.isNotEmpty) {
        await showBadgeUnlockDialog(context, summary.newlyUnlockedBadges);
        if (!mounted) return;
      }
      // Show war report then pop
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _WarReportSheet(summary: summary),
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
                ],
              ),
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ── War Report Sheet ─────────────────────────────────────────────────────────

class _WarReportSheet extends StatelessWidget {
  const _WarReportSheet({required this.summary});
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    // Use startTime/endTime for second-level precision; fall back to durationMinutes.
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
                            // Pure attempt: full-width muted orange bar
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB26D)
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            )
                          else ...[
                            FractionallySizedBox(
                              widthFactor: (stat.total > 0 ? stat.sends / stat.total : 0.0).clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5ED9A6),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (stat.total > 0 ? stat.flashes / stat.total : 0.0).clamp(0.0, 1.0),
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
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
