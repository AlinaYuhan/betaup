import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF06101C);
const _surface = Color(0xFF0F1B2D);
const _glass   = Color(0x8C0C1827);
const _field   = Color(0xFF091422);
const _border  = Color(0xFF1C3050);
const _orange  = Color(0xFFFF7A18);
const _orangeB = Color(0xFFFF9A45);
const _white   = Color(0xFFFFFFFF);
const _muted   = Color(0xFF5E7A96);
const _kErr    = Color(0xFFFF4545);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  // ── Original logic (unchanged) ────────────────────────────────────────────
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _regNameCtrl       = TextEditingController();
  final _regEmailCtrl      = TextEditingController();
  final _regPasswordCtrl   = TextEditingController();

  bool   _registerMode = false;
  bool   _isSubmitting = false;
  String _error        = '';

  // ── UI ────────────────────────────────────────────────────────────────────
  bool _passwordVisible = false;

  // ── Aurora loop ───────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;

  // ── Entry stagger ─────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;

  // ── Mouse (normalised 0‥1) ────────────────────────────────────────────────
  final _mouse = ValueNotifier<Offset>(const Offset(0.80, 0.10));

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) =>
      Tween(begin: const Offset(0, 0.10), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _mouse.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() { _error = ''; _isSubmitting = true; });
    final session = SessionScope.of(context);
    try {
      if (_registerMode) {
        final name     = _regNameCtrl.text.trim();
        final email    = _regEmailCtrl.text.trim();
        final password = _regPasswordCtrl.text;
        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          throw const ApiException('Complete every field before continuing.');
        }
        if (password.length < 8) {
          throw const ApiException('Password must be at least 8 characters.');
        }
        await session.register(
          name: name, email: email, password: password, role: UserRole.climber,
        );
      } else {
        final email    = _loginEmailCtrl.text.trim();
        final password = _loginPasswordCtrl.text;
        if (email.isEmpty || password.isEmpty) {
          throw const ApiException('Email and password are required.');
        }
        await session.login(email: email, password: password);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unexpected error. Try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: MouseRegion(
        onHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(e.position);
          _mouse.value = Offset(
            (local.dx / box.size.width).clamp(0.0, 1.0),
            (local.dy / box.size.height).clamp(0.0, 1.0),
          );
        },
        child: Stack(
          children: [
            // Background always fills the full viewport
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_bgCtrl, _mouse]),
                builder: (_, __) => CustomPaint(
                  painter: _ScenePainter(t: _bgCtrl.value, mouse: _mouse.value),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // SliverFillRemaining: viewport-height column, scrollable if keyboard appears,
            // Spacer works because the sliver provides a bounded height.
            Positioned.fill(
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 100),
                                SlideTransition(
                                  position: _slide(0.00, 0.46),
                                  child: FadeTransition(
                                    opacity: _fade(0.00, 0.40),
                                    child: _buildBrand(),
                                  ),
                                ),
                                const SizedBox(height: 44),
                                SlideTransition(
                                  position: _slide(0.18, 0.66),
                                  child: FadeTransition(
                                    opacity: _fade(0.18, 0.60),
                                    child: _buildCard(),
                                  ),
                                ),
                                const Spacer(),
                                FadeTransition(
                                  opacity: _fade(0.60, 1.0),
                                  child: _buildFooter(),
                                ),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Brand — stacked layout ─────────────────────────────────────────────────
  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon — slightly left-indented for visual interest
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              image: const DecorationImage(
                image: AssetImage('assets/icons/icon.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: _orange.withValues(alpha: 0.55),
                  blurRadius: 32,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: _orange.withValues(alpha: 0.14),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Large title — staggered slightly right of icon
        const Padding(
          padding: EdgeInsets.only(left: 0),
          child: Text(
            'BETAUP',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: _white,
              fontSize: 52,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Accent line + tagline share IntrinsicWidth so line matches text width
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_orange, _orangeB]),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.65),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Track every send.\nProve your progress.',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.42),
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        // Thin divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Log sends · Earn badges · Explore gyms on the map',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _white.withValues(alpha: 0.28),
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'AI voice assistant · Coach connect · Live leaderboard',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _white.withValues(alpha: 0.16),
            fontSize: 10.5,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── Glass card ────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: _glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 64,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fade(0.28, 0.64),
                child: _buildTabs(),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade(0.38, 0.76),
                child: SlideTransition(
                  position: _slide(0.38, 0.76),
                  child: _buildForm(),
                ),
              ),
              _buildError(),
              FadeTransition(
                opacity: _fade(0.52, 0.92),
                child: SlideTransition(
                  position: _slide(0.52, 0.92),
                  child: _buildButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return _SlidingTabs(
      registerMode: _registerMode,
      onLoginTap: () => setState(() {
        _registerMode = false; _error = ''; _passwordVisible = false;
      }),
      onRegisterTap: () => setState(() {
        _registerMode = true; _error = ''; _passwordVisible = false;
      }),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 270),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(_registerMode),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_registerMode) ...[
            _GlowField(
              controller: _regNameCtrl,
              label: 'Full Name',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
          ],
          _GlowField(
            controller: _registerMode ? _regEmailCtrl : _loginEmailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _GlowField(
            controller: _registerMode ? _regPasswordCtrl : _loginPasswordCtrl,
            label: 'Password',
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _passwordVisible = !_passwordVisible),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  _passwordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: _muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: _error.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(Icons.warning_amber_rounded,
                        color: _kErr, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(
                        color: _kErr, fontSize: 12.5, height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Button ────────────────────────────────────────────────────────────────
  Widget _buildButton() {
    return _PressButton(
      onTap: _isSubmitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isSubmitting
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF5E00), _orange, _orangeB],
                  stops: [0.0, 0.5, 1.0],
                ),
          color: _isSubmitting ? _surface : null,
          boxShadow: _isSubmitting
              ? null
              : [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.50),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: _white, strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _registerMode ? 'Create Account' : 'Continue',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Full scene painter ────────────────────────────────────────────────────────
// Layers: base → aurora blobs → rope → glowing holds + route lines → mouse glow → vignette
// Mouse parallax: blobs 3%, ropes 6%, holds 10% — creates 3-layer depth
class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.t, required this.mouse});
  final double t;
  final Offset mouse;

  // Parallax: returns a pixel offset for a layer given its depth factor
  Offset _px(Size size, double depth) => Offset(
    (mouse.dx - 0.5) * size.width  * depth,
    (mouse.dy - 0.5) * size.height * depth,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final a  = t * 2 * math.pi;
    final p1 = _px(size, 0.03);  // blobs — very slow
    final p2 = _px(size, 0.06);  // ropes — medium
    final p3 = _px(size, 0.10);  // holds — most reactive

    // 1. Base
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    // 2. Aurora blobs with parallax layer 1
    canvas.save();
    canvas.translate(p1.dx, p1.dy);
    _blob(canvas, size, cx: 0.80 + 0.07*math.cos(a*0.60), cy: 0.06 + 0.05*math.sin(a*0.45), r: 0.65, alpha: 0.22, color: _orange);
    _blob(canvas, size, cx: 0.10 + 0.06*math.sin(a*0.50), cy: 0.78 + 0.07*math.cos(a*0.38), r: 0.70, alpha: 0.24, color: const Color(0xFF0B3A7E));
    _blob(canvas, size, cx: 0.50 + 0.05*math.sin(a*0.75+1.0), cy: 0.48 + 0.05*math.cos(a*0.60+0.8), r: 0.52, alpha: 0.14, color: const Color(0xFF0A2A52));
    _blob(canvas, size, cx: 0.78 + 0.05*math.cos(a*0.55+2.0), cy: 0.92 + 0.04*math.sin(a*0.70+1.5), r: 0.60, alpha: 0.20, color: _orange);
    _blob(canvas, size, cx: 0.18 + 0.05*math.sin(a*0.45+0.5), cy: 0.96 + 0.03*math.cos(a*0.50+1.0), r: 0.50, alpha: 0.16, color: const Color(0xFF0C3D80));
    _blob(canvas, size, cx: 0.55 + 0.04*math.cos(a*0.80+3.0), cy: 0.72 + 0.04*math.sin(a*0.65+2.0), r: 0.38, alpha: 0.12, color: _orangeB);
    canvas.restore();

    // 3. Ropes with parallax layer 2
    canvas.save();
    canvas.translate(p2.dx, p2.dy);
    _drawRopes(canvas, size, a);
    canvas.restore();

    // 4. Holds + route connection lines with parallax layer 3
    canvas.save();
    canvas.translate(p3.dx, p3.dy);
    _drawRouteLines(canvas, size, a);
    _drawGlowHolds(canvas, size, a);
    canvas.restore();

    // 5. Mouse spotlight (no parallax — tracks cursor exactly)
    _blob(canvas, size, cx: mouse.dx, cy: mouse.dy, r: 0.32, alpha: 0.13, color: _orange, blur: 72);

    // 6. Soft vignette
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF020A14).withValues(alpha: 0.68)],
          radius: 0.88,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _blob(Canvas canvas, Size size, {
    required double cx, required double cy,
    required double r, required double alpha,
    required Color color, double blur = 52,
  }) {
    final center = Offset(cx * size.width, cy * size.height);
    final radius = r * size.width;
    canvas.drawCircle(
      center, radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ).createShader(Rect.fromCenter(center: center, width: radius*2, height: radius*2))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  // Faint dotted lines connecting nearby holds — simulates a climbing route overlay
  void _drawRouteLines(Canvas canvas, Size size, double a) {
    // Connect holds that are "close enough" — pairs chosen by hand for aesthetics
    const pairs = [
      (0, 2), (2, 5), (5, 7), (7, 9),   // right-side route
      (1, 3), (3, 6), (6, 8),            // left-side route
      (12, 0), (13, 3),                  // crossing connectors
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final p in pairs) {
      final h1 = _holds[p.$1];
      final h2 = _holds[p.$2];
      final c1 = Offset(h1.$1 * size.width,  h1.$2 * size.height);
      final c2 = Offset(h2.$1 * size.width,  h2.$2 * size.height);
      // Pulse opacity on the line using average seed
      final avg  = (h1.$4 + h2.$4) / 2.0;
      final alpha = (math.sin(a + avg * 0.9) * 0.5 + 0.5) * 0.10 + 0.02;
      paint.color = _orange.withValues(alpha: alpha);

      // Slightly curved line via quadratic bezier (mid-point offset)
      final mid = Offset(
        (c1.dx + c2.dx) / 2 + (c2.dy - c1.dy) * 0.08,
        (c1.dy + c2.dy) / 2 - (c2.dx - c1.dx) * 0.08,
      );
      final path = Path()
        ..moveTo(c1.dx, c1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, c2.dx, c2.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _drawRopes(Canvas canvas, Size size, double a) {
    void rope(double xN, double amp, double freq, double phase, double strokeW, double alpha) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = _orange.withValues(alpha: alpha);
      final path = Path()..moveTo(xN * size.width, 0);
      for (double y = 0; y <= size.height; y += 3) {
        path.lineTo(xN * size.width + math.sin(y * freq + a * math.pi * 2 + phase) * amp, y);
      }
      canvas.drawPath(path, paint);
    }
    rope(0.87, 6.0, 0.040, 0.0, 1.1, 0.10);
    rope(0.93, 4.5, 0.035, 1.2, 0.7, 0.06);
    rope(0.04, 5.0, 0.038, 2.5, 0.9, 0.07);
  }

  // Rock hold definitions: (normalised x, y, radius, seed for shape, isWarm)
  static const _holds = [
    (0.82, 0.14, 9.0,  1, true),
    (0.07, 0.28, 7.0,  2, false),
    (0.68, 0.38, 11.0, 3, true),
    (0.22, 0.55, 8.0,  4, false),
    (0.88, 0.52, 7.0,  5, true),
    (0.45, 0.68, 10.0, 6, true),
    (0.12, 0.72, 8.5,  7, false),
    (0.72, 0.80, 9.0,  8, true),
    (0.30, 0.88, 7.5,  9, false),
    (0.58, 0.92, 8.0, 10, true),
    (0.90, 0.88, 6.5, 11, true),
    (0.18, 0.94, 7.0, 12, false),
    (0.50, 0.20, 6.0, 13, true),
    (0.35, 0.42, 7.0, 14, false),
  ];

  void _drawGlowHolds(Canvas canvas, Size size, double a) {
    for (final h in _holds) {
      final cx = h.$1, cy = h.$2, r = h.$3, seed = h.$4, warm = h.$5;
      final center = Offset(cx * size.width, cy * size.height);
      // Each hold breathes at its own phase
      final pulse = (math.sin(a + seed * 1.618) * 0.5 + 0.5);
      final alpha  = pulse * 0.38 + 0.08;
      final color  = warm ? _orange : const Color(0xFF4AACFF);

      // Outer soft glow
      canvas.drawCircle(
        center, r * 2.6,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Hold silhouette — organic blob shape
      final path = _holdPath(center, r, seed);

      // Faint fill
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: alpha * 0.08),
      );

      // Glowing outline
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = color.withValues(alpha: alpha * 0.65)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 + pulse * 2),
      );
    }
  }

  // Organic hold shape — irregular polygon via quadratic bezier
  Path _holdPath(Offset center, double r, int seed) {
    const n = 7;
    const angleStep = 2 * math.pi / n;
    // Pre-baked radius multipliers per vertex for organic shape
    final mults = [0.90, 0.75, 1.00, 0.80, 0.95, 0.70, 0.88];
    final radii  = List.generate(n, (i) => r * mults[(i + seed) % mults.length]);
    final pts    = List.generate(n, (i) {
      final angle = i * angleStep - math.pi / 2 + seed * 0.42;
      return Offset(center.dx + math.cos(angle) * radii[i],
                    center.dy + math.sin(angle) * radii[i]);
    });

    final path = Path()..moveTo(
      (pts[n-1].dx + pts[0].dx) / 2,
      (pts[n-1].dy + pts[0].dy) / 2,
    );
    for (int i = 0; i < n; i++) {
      final next = (i + 1) % n;
      final mid  = Offset((pts[i].dx + pts[next].dx) / 2,
                          (pts[i].dy + pts[next].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.mouse != mouse;
}

// ── Sliding tab indicator ─────────────────────────────────────────────────────
class _SlidingTabs extends StatefulWidget {
  const _SlidingTabs({
    required this.registerMode,
    required this.onLoginTap,
    required this.onRegisterTap,
  });
  final bool         registerMode;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  @override
  State<_SlidingTabs> createState() => _SlidingTabsState();
}

class _SlidingTabsState extends State<_SlidingTabs> {
  final _loginKey = GlobalKey();
  final _regKey   = GlobalKey();

  double   _indicatorLeft  = 0;
  double   _indicatorWidth = 0;
  bool     _measured       = false;
  Duration _animDuration   = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(snap: true));
  }

  @override
  void didUpdateWidget(_SlidingTabs old) {
    super.didUpdateWidget(old);
    if (old.registerMode != widget.registerMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure(snap: false));
    }
  }

  void _measure({required bool snap}) {
    final key    = widget.registerMode ? _regKey : _loginKey;
    final tabBox = key.currentContext?.findRenderObject() as RenderBox?;
    final myBox  = context.findRenderObject() as RenderBox?;
    if (tabBox == null || myBox == null) return;
    final local = myBox.globalToLocal(tabBox.localToGlobal(Offset.zero));
    setState(() {
      _indicatorLeft  = local.dx;
      _indicatorWidth = tabBox.size.width;
      _measured       = true;
      _animDuration   = snap ? Duration.zero : const Duration(milliseconds: 260);
    });
  }

  Widget _label({
    required Key key,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontFamily:    'Oswald',
          color:         selected ? _white : _muted,
          fontSize:      17,
          fontWeight:    selected ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _label(key: _loginKey, text: 'Log In',  selected: !widget.registerMode, onTap: widget.onLoginTap),
            const SizedBox(width: 28),
            _label(key: _regKey,   text: 'Sign Up', selected:  widget.registerMode, onTap: widget.onRegisterTap),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_measured)
                AnimatedPositioned(
                  duration: _animDuration,
                  curve: Curves.easeOutCubic,
                  left:   _indicatorLeft,
                  width:  _indicatorWidth,
                  top: 0,
                  height: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_orange, _orangeB]),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.80),
                          blurRadius: 8, spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Glow input field ──────────────────────────────────────────────────────────
class _GlowField extends StatefulWidget {
  const _GlowField({
    required this.controller,
    required this.label,
    this.obscureText    = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String                 label;
  final bool                   obscureText;
  final TextInputType?          keyboardType;
  final TextInputAction?        textInputAction;
  final ValueChanged<String>?   onSubmitted;
  final Widget?                 suffix;

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField> {
  late final FocusNode _focus;
  bool get _on => _focus.hasFocus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _on
            ? [BoxShadow(
                color: _orange.withValues(alpha: 0.22),
                blurRadius: 22,
                spreadRadius: 1,
              )]
            : null,
      ),
      child: TextField(
        focusNode:       _focus,
        controller:      widget.controller,
        obscureText:     widget.obscureText,
        keyboardType:    widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted:     widget.onSubmitted,
        style: const TextStyle(
          color: _white, fontSize: 15.5, fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText:  widget.label,
          labelStyle: TextStyle(
            color:    _on ? _orange.withValues(alpha: 0.85) : _muted,
            fontSize: 14.5,
          ),
          floatingLabelStyle: const TextStyle(
            color: _orange, fontSize: 12, fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled:    true,
          fillColor: _on
              ? _field.withValues(alpha: 1.0)
              : _field.withValues(alpha: 0.85),
          suffixIcon: widget.suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orange, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Press-scale button ────────────────────────────────────────────────────────
class _PressButton extends StatefulWidget {
  const _PressButton({required this.child, required this.onTap});
  final Widget        child;
  final VoidCallback? onTap;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _down = true),
      onTapUp:     (_) { setState(() => _down = false); widget.onTap?.call(); },
      onTapCancel: ()  => setState(() => _down = false),
      child: AnimatedScale(
        scale:    _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child:    widget.child,
      ),
    );
  }
}
