import 'package:flutter/material.dart';

import 'voice_service.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

/// Full-screen transparent overlay that hosts both the chat panel and the
/// draggable panda button.  Add this as the last child of your root [Stack].
class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({super.key, required this.service});

  final VoiceService service;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with SingleTickerProviderStateMixin {
  // Panda position — distance from right / bottom screen edges.
  double _right = 16;
  double _bottom = 90;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  VoiceState _prevState = VoiceState.idle;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    widget.service.addListener(_onServiceChange);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChange);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onServiceChange() {
    final s = widget.service.state;

    if (s == VoiceState.listening) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      if (_pulseCtrl.isAnimating) {
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    }

    // Show error as snackbar (only once on transition into error).
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
          // ── Chat panel ────────────────────────────────────────────────────
          if (open)
            Positioned(
              bottom: _bottom + 76,
              left: 8,
              right: 8,
              child: _ConversationPanel(service: widget.service),
            ),

          // ── Panda button ──────────────────────────────────────────────────
          Positioned(
            right: _right,
            bottom: _bottom,
            child: GestureDetector(
              onTap: _onPandaTap,
              onPanUpdate: (d) {
                setState(() {
                  _right = (_right - d.delta.dx).clamp(0.0, size.width - 72);
                  _bottom =
                      (_bottom - d.delta.dy).clamp(0.0, size.height - 72);
                });
              },
              child: _buildPanda(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanda() {
    final state = widget.service.state;
    final color = _stateColor(state);

    Widget panda = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color == Colors.white
                ? Colors.black.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.55),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _PandaPainter(ringColor: color),
        size: const Size(68, 68),
      ),
    );

    // Pulse when listening.
    if (state == VoiceState.listening) {
      panda = ScaleTransition(scale: _pulseScale, child: panda);
    }

    // Spinner overlay when processing.
    if (state == VoiceState.processing) {
      panda = Stack(
        alignment: Alignment.center,
        children: [
          panda,
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    // Tooltip.
    final tip = switch (state) {
      VoiceState.idle => "点击开始对话",
      VoiceState.listening => "点击停止录音",
      VoiceState.processing => "思考中...",
      VoiceState.responding => "回复中...",
      VoiceState.error => "点击重置",
    };

    return Tooltip(message: tip, child: panda);
  }

  static Color _stateColor(VoiceState state) => switch (state) {
        VoiceState.idle => Colors.white,
        VoiceState.listening => const Color(0xFFEF5350),
        VoiceState.processing => const Color(0xFFFFA726),
        VoiceState.responding => const Color(0xFF42A5F5),
        VoiceState.error => const Color(0xFF9E9E9E),
      };
}

// ── Panda painter ─────────────────────────────────────────────────────────────

class _PandaPainter extends CustomPainter {
  const _PandaPainter({required this.ringColor});
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Coloured ring background ──────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = ringColor,
    );

    // ── White face base ───────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.84, Paint()..color = Colors.white);

    // ── Black ears ────────────────────────────────────────────────────────
    final earPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - r * 0.44, cy - r * 0.62), r * 0.27, earPaint);
    canvas.drawCircle(Offset(cx + r * 0.44, cy - r * 0.62), r * 0.27, earPaint);

    // White inner ear
    final innerEarPaint = Paint()..color = const Color(0xFFD4A0A0);
    canvas.drawCircle(
        Offset(cx - r * 0.44, cy - r * 0.62), r * 0.14, innerEarPaint);
    canvas.drawCircle(
        Offset(cx + r * 0.44, cy - r * 0.62), r * 0.14, innerEarPaint);

    // White face on top of ears
    canvas.drawCircle(Offset(cx, cy), r * 0.74, Paint()..color = Colors.white);

    // ── Eye patches ───────────────────────────────────────────────────────
    final patchPaint = Paint()..color = const Color(0xFF1A1A1A);
    final patch1 = Rect.fromCenter(
      center: Offset(cx - r * 0.27, cy - r * 0.1),
      width: r * 0.37,
      height: r * 0.42,
    );
    final patch2 = Rect.fromCenter(
      center: Offset(cx + r * 0.27, cy - r * 0.1),
      width: r * 0.37,
      height: r * 0.42,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(patch1, Radius.circular(r * 0.14)), patchPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(patch2, Radius.circular(r * 0.14)), patchPaint);

    // White pupils
    final pupilPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - r * 0.26, cy - r * 0.08), r * 0.11, pupilPaint);
    canvas.drawCircle(Offset(cx + r * 0.26, cy - r * 0.08), r * 0.11, pupilPaint);

    // Black eyeballs
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.08), r * 0.065, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.25, cy - r * 0.08), r * 0.065, eyePaint);

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - r * 0.22, cy - r * 0.1), r * 0.028, shinePaint);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.1), r * 0.028, shinePaint);

    // ── Nose ──────────────────────────────────────────────────────────────
    final noseRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.22),
      width: r * 0.22,
      height: r * 0.14,
    );
    canvas.drawOval(noseRect, Paint()..color = const Color(0xFF1A1A1A));

    // ── Mouth (gentle smile) ──────────────────────────────────────────────
    final mouthPath = Path()
      ..moveTo(cx - r * 0.14, cy + r * 0.33)
      ..quadraticBezierTo(cx, cy + r * 0.44, cx + r * 0.14, cy + r * 0.33);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.045
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PandaPainter old) => old.ringColor != ringColor;
}

// ── Conversation panel ────────────────────────────────────────────────────────

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

    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xF5121212),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
            child: Row(
              children: [
                const CustomPaint(
                  painter: _PandaPainter(ringColor: Colors.white),
                  size: Size(28, 28),
                ),
                const SizedBox(width: 8),
                const Text(
                  "攀达 Panda",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _StateChip(state: svc.state),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: svc.closeConversation,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x22FFFFFF)),

          // ── Message list ─────────────────────────────────────────────────
          ListenableBuilder(
            listenable: svc,
            builder: (context, _) {
              final msgs = svc.messages;
              final interim = svc.interimText;
              final itemCount = msgs.length + (interim != null ? 1 : 0);

              if (itemCount == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "说点什么开始对话吧…",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 270),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  itemCount: itemCount,
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

          // ── Listening indicator ──────────────────────────────────────────
          ListenableBuilder(
            listenable: svc,
            builder: (context, _) {
              if (svc.state != VoiceState.listening) return const SizedBox();
              return const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PulseDot(color: Color(0xFFEF5350)),
                    SizedBox(width: 6),
                    Text("正在聆听…",
                        style:
                            TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CustomPaint(
              painter: _PandaPainter(ringColor: Colors.white),
              size: Size(26, 26),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFBF360C).withValues(
                        alpha: isInterim ? 0.5 : 1.0)
                    : const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isInterim ? Colors.white54 : Colors.white,
                  fontSize: 13.5,
                  fontStyle:
                      isInterim ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── State chip ────────────────────────────────────────────────────────────────

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      VoiceState.idle => ("待命", const Color(0xFF9E9E9E)),
      VoiceState.listening => ("聆听中", const Color(0xFFEF5350)),
      VoiceState.processing => ("思考中", const Color(0xFFFFA726)),
      VoiceState.responding => ("回复中", const Color(0xFF42A5F5)),
      VoiceState.error => ("出错了", const Color(0xFFEF5350)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Pulsing dot (listening indicator) ────────────────────────────────────────

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
    _anim = Tween<double>(begin: 0.4, end: 1.0)
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
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
