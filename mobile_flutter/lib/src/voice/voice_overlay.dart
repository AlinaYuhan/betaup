import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../ui/common.dart';
import 'voice_service.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({super.key, required this.service});
  final VoiceService service;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin {
  double _right = 16;
  double _bottom = 160;

  // _breathCtrl: runs only while listening/responding, drives the glow-ring painter
  late final AnimationController _breathCtrl;
  // _rippleCtrl: runs only while listening, drives the particle-ring painter
  late final AnimationController _rippleCtrl;

  VoiceState _prevState = VoiceState.idle;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    widget.service.addListener(_onServiceChange);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChange);
    _breathCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _onServiceChange() {
    final s = widget.service.state;

    if (s == VoiceState.listening || s == VoiceState.responding) {
      if (!_breathCtrl.isAnimating) _breathCtrl.repeat(reverse: true);
      if (s == VoiceState.listening && !_rippleCtrl.isAnimating) _rippleCtrl.repeat();
    } else {
      _breathCtrl.stop();
      _rippleCtrl.stop();
      _rippleCtrl.reset();
    }

    // Badge unlock dialog
    final badges = widget.service.pendingBadges;
    if (badges.isNotEmpty) {
      widget.service.clearPendingBadges();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showBadgeUnlockDialog(context, badges);
      });
    }

    // Error snackbar (once per transition)
    if (s == VoiceState.error && _prevState != VoiceState.error) {
      final err = widget.service.errorMessage ?? "未知错误";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text("⚠️ $err"),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ));
        }
      });
    }

    _prevState = s;
    if (mounted) setState(() {});
  }

  void _onPandaTap() {
    switch (widget.service.state) {
      case VoiceState.idle:
        widget.service.openConversation();
      case VoiceState.listening:
        widget.service.stopListening();
      case VoiceState.error:
        widget.service.reset();
      case VoiceState.processing:
        break;
      case VoiceState.responding:
        widget.service.interruptSpeaking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final open = widget.service.conversationOpen;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          if (open)
            Positioned(
              bottom: _bottom + 80,
              left: 8,
              right: 8,
              child: _ConversationPanel(service: widget.service),
            ),
          Positioned(
            right: _right,
            bottom: _bottom,
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: _onPandaTap,
                onPanUpdate: (d) {
                  setState(() {
                    _right = (_right - d.delta.dx).clamp(0.0, size.width - 96);
                    _bottom = (_bottom - d.delta.dy).clamp(0.0, size.height - 96);
                  });
                },
                child: _buildPanda(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanda() {
    final state = widget.service.state;
    final color = _stateColor(state);

    // Panda face — FIXED at 68×68, never moves or scales
    const pandaFace = SizedBox(
      width: 68,
      height: 68,
      child: CustomPaint(
        painter: _PandaPainter(ringColor: Colors.white),
        size: Size(68, 68),
      ),
    );

    // ── Ring / halo layer — drawn via CustomPainter so the panda stays still ──
    Widget ringLayer;
    switch (state) {
      case VoiceState.idle:
        // No ring when idle — just the clean panda icon
        ringLayer = const SizedBox(width: 96, height: 96);

      case VoiceState.listening:
        // Same breathing glow as idle, but in red — calm and readable
        ringLayer = AnimatedBuilder(
          animation: _breathCtrl,
          builder: (_, __) => CustomPaint(
            painter: _BreathRingPainter(
              phase: _breathCtrl.value,
              color: color,
            ),
            size: const Size(96, 96),
          ),
        );

      case VoiceState.processing:
        // Thin rotating arc
        ringLayer = SizedBox(
          width: 96,
          height: 96,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          ),
        );

      case VoiceState.responding:
        // Breathing glow in blue — same feel as listening
        ringLayer = AnimatedBuilder(
          animation: _breathCtrl,
          builder: (_, __) => CustomPaint(
            painter: _BreathRingPainter(
              phase: _breathCtrl.value,
              color: color,
            ),
            size: const Size(96, 96),
          ),
        );

      case VoiceState.error:
        // Static glow for error — no animation, clearly distinct
        ringLayer = CustomPaint(
          painter: _StaticGlowPainter(color: color),
          size: const Size(96, 96),
        );
    }

    final tip = switch (state) {
      VoiceState.idle       => '点击开始对话',
      VoiceState.listening  => '点击停止录音',
      VoiceState.processing => '思考中...',
      VoiceState.responding => '回复中...',
      VoiceState.error      => '点击重置',
    };

    // Fixed 96×96 container — ring layer behind, panda face always centred
    return Tooltip(
      message: tip,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ringLayer,
            pandaFace,
          ],
        ),
      ),
    );
  }

  static Color _stateColor(VoiceState state) => switch (state) {
        VoiceState.idle       => const Color(0xFFFF7A18),
        VoiceState.listening  => const Color(0xFFEF5350),
        VoiceState.processing => const Color(0xFFFFA726),
        VoiceState.responding => const Color(0xFF42A5F5),
        VoiceState.error      => const Color(0xFF9E9E9E),
      };
}

// ── Breathing glow ring (idle) ─────────────────────────────────────────────────
// Draws a soft glowing halo whose opacity and blur radius slowly pulse.

class _BreathRingPainter extends CustomPainter {
  const _BreathRingPainter({required this.phase, required this.color});
  final double phase; // 0 → 1 → 0 (reverse: true)
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Panda icon is 68×68 inside this 96×96 canvas → panda radius = 34.
    // Start the ring right at the panda edge so there's no dead gap.
    const baseR = 35.0;

    // phase 0→1→0:  ring visibly expands then contracts
    final expand    = phase * 11.0;           // grows up to 11 px outward
    final brightness = 0.35 + phase * 0.65;  // faint at rest → full at peak

    // Outermost diffuse halo — biggest radius, heavy blur
    canvas.drawCircle(
      center, baseR + expand + 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = color.withValues(alpha: brightness * 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + expand * 0.7),
    );

    // Mid soft glow — expands with the halo
    canvas.drawCircle(
      center, baseR + expand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: brightness * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Inner crisp ring — visible size change is the key cue
    canvas.drawCircle(
      center, baseR + expand * 0.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: brightness * 0.92),
    );
  }

  @override
  bool shouldRepaint(_BreathRingPainter old) => old.phase != phase || old.color != color;
}

// ── Static glow ring (responding / error) ─────────────────────────────────────

class _StaticGlowPainter extends CustomPainter {
  const _StaticGlowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;

    canvas.drawCircle(
      center, r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center, r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_StaticGlowPainter old) => old.color != color;
}

// ── Panda painter ─────────────────────────────────────────────────────────────

class _PandaPainter extends CustomPainter {
  const _PandaPainter({required this.ringColor});
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final center = Offset(cx, cy);
    final rect = Rect.fromCircle(center: center, radius: r);

    // ── Glass orb base: dark navy with off-center radial gradient ────────
    canvas.drawCircle(
      center, r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [Color(0xFF2C3E50), Color(0xFF0D1520)],
        ).createShader(rect),
    );

    // Subtle white rim
    canvas.drawCircle(
      center, r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    // ── Ears ─────────────────────────────────────────────────────────────
    final earPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - r * 0.44, cy - r * 0.62), r * 0.27, earPaint);
    canvas.drawCircle(Offset(cx + r * 0.44, cy - r * 0.62), r * 0.27, earPaint);

    final innerEarPaint = Paint()..color = const Color(0xFFD4A0A0);
    canvas.drawCircle(Offset(cx - r * 0.44, cy - r * 0.62), r * 0.14, innerEarPaint);
    canvas.drawCircle(Offset(cx + r * 0.44, cy - r * 0.62), r * 0.14, innerEarPaint);

    // ── Face ─────────────────────────────────────────────────────────────
    // Slightly frosted white instead of pure white
    canvas.drawCircle(center, r * 0.74,
        Paint()..color = Colors.white.withValues(alpha: 0.93));

    final patchPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - r * 0.27, cy - r * 0.1),
                width: r * 0.37,
                height: r * 0.42),
            Radius.circular(r * 0.14)),
        patchPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + r * 0.27, cy - r * 0.1),
                width: r * 0.37,
                height: r * 0.42),
            Radius.circular(r * 0.14)),
        patchPaint);

    canvas.drawCircle(
        Offset(cx - r * 0.26, cy - r * 0.08), r * 0.11, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx + r * 0.26, cy - r * 0.08), r * 0.11, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.08), r * 0.065,
        Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(Offset(cx + r * 0.25, cy - r * 0.08), r * 0.065,
        Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(
        Offset(cx - r * 0.22, cy - r * 0.1), r * 0.028, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx + r * 0.28, cy - r * 0.1), r * 0.028, Paint()..color = Colors.white);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.22), width: r * 0.22, height: r * 0.14),
        Paint()..color = const Color(0xFF1A1A1A));

    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.14, cy + r * 0.33)
        ..quadraticBezierTo(cx, cy + r * 0.44, cx + r * 0.14, cy + r * 0.33),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.045
        ..strokeCap = StrokeCap.round,
    );

    // ── Glass gloss: large soft sheen top-left + small bright spot ───────
    canvas.drawCircle(
      center, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.50),
          radius: 0.80,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
    // tiny bright specular dot
    final specCenter = Offset(cx - r * 0.30, cy - r * 0.48);
    canvas.drawCircle(
      specCenter,
      r * 0.16,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: specCenter, radius: r * 0.16)),
    );
  }

  @override
  bool shouldRepaint(_PandaPainter old) => old.ringColor != ringColor;
}

// ── Conversation panel ─────────────────────────────────────────────────────────

class _ConversationPanel extends StatefulWidget {
  const _ConversationPanel({required this.service});
  final VoiceService service;

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.service.removeListener(_scrollToBottom);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              // Slightly more transparent for a floating glass feel
              color: const Color(0xC8070B12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Thin orange accent line at top ───────────────────────────
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF7A18).withValues(alpha: 0.70),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFF7A18).withValues(alpha: 0.35)),
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF7A18).withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const CustomPaint(
                          painter: _PandaPainter(ringColor: Colors.white),
                          size: Size(32, 32),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "攀达 Panda",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Oswald',
                          fontSize: 15,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      ListenableBuilder(
                        listenable: svc,
                        builder: (_, __) => _StateChip(state: svc.state),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: svc.toggleSttLocale,
                        child: ListenableBuilder(
                          listenable: svc,
                          builder: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10)),
                            ),
                            child: Text(
                              svc.sttLocale == 'zh-CN' ? '中' : 'EN',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white30, size: 18),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: svc.closeConversation,
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

                // ── Message list ─────────────────────────────────────────────
                ListenableBuilder(
                  listenable: svc,
                  builder: (context, _) {
                    final msgs   = svc.messages;
                    final interim = svc.interimText;
                    final count  = msgs.length + (interim != null ? 1 : 0);

                    if (count == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.mic_none_rounded,
                                color: Colors.white.withValues(alpha: 0.12),
                                size: 32),
                            const SizedBox(height: 8),
                            Text(
                              "说点什么开始对话吧…",
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        itemCount: count,
                        itemBuilder: (_, i) {
                          if (i == msgs.length && interim != null) {
                            return _ChatBubble(
                                text: interim, isUser: true, isInterim: true);
                          }
                          return _ChatBubble(
                              text: msgs[i].text, isUser: msgs[i].isUser);
                        },
                      ),
                    );
                  },
                ),

                // ── Listening waveform indicator ─────────────────────────────
                ListenableBuilder(
                  listenable: svc,
                  builder: (context, _) {
                    if (svc.state != VoiceState.listening) {
                      return const SizedBox(height: 8);
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _PulseDot(color: Color(0xFFEF5350)),
                          const SizedBox(width: 6),
                          Text(
                            "正在聆听…",
                            style: TextStyle(
                              color: const Color(0xFFEF5350).withValues(alpha: 0.80),
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isInterim = false,
  });

  final String text;
  final bool isUser;
  final bool isInterim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Small panda avatar with orange ring
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF7A18).withValues(alpha: 0.30)),
              ),
              child: const CustomPaint(
                painter: _PandaPainter(ringColor: Colors.white),
                size: Size(28, 28),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                // User: orange gradient; assistant: glass card
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF7A18)
                              .withValues(alpha: isInterim ? 0.30 : 0.90),
                          const Color(0xFFE05A00)
                              .withValues(alpha: isInterim ? 0.22 : 0.75),
                        ],
                      )
                    : null,
                color: isUser
                    ? null
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isInterim
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.92),
                  fontSize: 13.5,
                  fontStyle:
                      isInterim ? FontStyle.italic : FontStyle.normal,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── State chip ─────────────────────────────────────────────────────────────────

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      VoiceState.idle       => ("待命",  const Color(0xFF9E9E9E)),
      VoiceState.listening  => ("聆听中", const Color(0xFFEF5350)),
      VoiceState.processing => ("思考中", const Color(0xFFFFA726)),
      VoiceState.responding => ("回复中", const Color(0xFF42A5F5)),
      VoiceState.error      => ("出错了", const Color(0xFFEF5350)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Pulsing dot (listening indicator) ─────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
