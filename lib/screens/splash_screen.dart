import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'notes_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Icon sequence ────────────────────────────────────────────────────────
  static const _icons = [
    Iconsax.note_text,
    Iconsax.edit_2,
    Iconsax.cloud_add,
    Iconsax.tick_circle,
  ];
  static const _labels = [
    'Capture ideas',
    'Edit anytime',
    'Sync everywhere',
    'Always in sync',
  ];
  static const _colors = [
    Color(0xFF5B6AF9),
    Color(0xFF818CF8),
    Color(0xFF34D399),
    Color(0xFF5B6AF9),
  ];

  int _step = 0;
  bool _showTitle = false;

  late final List<AnimationController> _iconCtrl;
  late final List<Animation<double>> _fadeAnim;
  late final List<Animation<double>> _scaleAnim;
  late final List<Animation<Offset>> _slideAnim;

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  late final AnimationController _sparkleCtrl;

  late final AnimationController _titleCtrl;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _iconCtrl = List.generate(
      _icons.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );
    _fadeAnim = _iconCtrl
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();
    _scaleAnim = _iconCtrl
        .map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();
    _slideAnim = _iconCtrl
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.elasticOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (int i = 0; i < _icons.length; i++) {
      if (!mounted) return;
      setState(() => _step = i);
      _iconCtrl[i].forward();
      await Future.delayed(const Duration(milliseconds: 750));
    }

    if (!mounted) return;
    setState(() => _showTitle = true);
    _titleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const NotesListScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _iconCtrl) c.dispose();
    _glowCtrl.dispose();
    _sparkleCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _colors[_step.clamp(0, _colors.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Background glow
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    activeColor.withOpacity(_glowAnim.value * 0.13),
                    const Color(0xFF0F0F13),
                  ],
                ),
              ),
            ),
          ),

          // Sparkle dots
          AnimatedBuilder(
            animation: _sparkleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _SparklePainter(_sparkleCtrl.value, activeColor),
              child: const SizedBox.expand(),
            ),
          ),

          // Centre content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon stage
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Orbit ring
                      AnimatedBuilder(
                        animation: _sparkleCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _OrbitPainter(
                            _sparkleCtrl.value,
                            activeColor,
                          ),
                          child: const SizedBox(width: 220, height: 220),
                        ),
                      ),

                      // Glow blob behind icon
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: activeColor
                                    .withOpacity(_glowAnim.value * 0.4),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Icons (stacked, previous ones fade out)
                      for (int i = 0; i <= _step && i < _icons.length; i++)
                        AnimatedBuilder(
                          animation: _iconCtrl[i],
                          builder: (_, __) {
                            final isCurrent = i == _step;
                            return Opacity(
                              opacity: isCurrent
                                  ? _fadeAnim[i].value
                                  : (1 - _fadeAnim[i].value)
                                      .clamp(0.0, 0.0), // ghost hidden
                              child: SlideTransition(
                                position: _slideAnim[i],
                                child: Transform.scale(
                                  scale: _scaleAnim[i].value,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1C1C21),
                                      border: Border.all(
                                        color: _colors[i].withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _icons[i],
                                      size: 46,
                                      color: _colors[i],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Animated label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _step < _labels.length ? _labels[_step] : '',
                    key: ValueKey(_step),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA1A1AA),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Step progress dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_icons.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:
                            i <= _step ? _colors[i] : const Color(0xFF27272A),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 52),

                // App name & tagline
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showTitle ? 1.0 : 0.0,
                  child: AnimatedBuilder(
                    animation: _titleCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _titleScale.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFF5B6AF9),
                                Color(0xFF818CF8),
                                Color(0xFF34D399),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Sync Notes',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your thoughts, always in sync',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA1A1AA),
                              letterSpacing: 0.3,
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
        ],
      ),
    );
  }
}

// ── Orbit ring painter ────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double t;
  final Color color;
  _OrbitPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 105.0;

    // Dashed orbit
    final dashPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r, dashPaint);

    // 6 orbiting dots
    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i / count + t) * 2 * math.pi;
      final dx = cx + r * math.cos(angle);
      final dy = cy + r * math.sin(angle);
      final phase = (i / count + t) % 1.0;
      final opacity = (0.3 + 0.7 * ((math.sin(phase * math.pi * 2) + 1) / 2))
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(dx, dy),
        i % 2 == 0 ? 4.5 : 2.5,
        Paint()..color = color.withOpacity(opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.color != color;
}

// ── Sparkle background painter ────────────────────────────────────────────────
class _SparklePainter extends CustomPainter {
  final double t;
  final Color color;
  _SparklePainter(this.t, this.color);

  static const _rel = [
    Offset(0.12, 0.10),
    Offset(0.88, 0.15),
    Offset(0.06, 0.52),
    Offset(0.94, 0.45),
    Offset(0.22, 0.88),
    Offset(0.80, 0.84),
    Offset(0.50, 0.05),
    Offset(0.62, 0.93),
    Offset(0.35, 0.30),
    Offset(0.72, 0.65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _rel.length; i++) {
      final phase = (t + i / _rel.length) % 1.0;
      final opacity = ((math.sin(phase * math.pi * 2) + 1) / 2) * 0.30;
      final r = (i % 3 == 0 ? 3.0 : i % 3 == 1 ? 2.0 : 1.5);
      canvas.drawCircle(
        Offset(_rel[i].dx * size.width, _rel[i].dy * size.height),
        r,
        Paint()..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t || old.color != color;
}
