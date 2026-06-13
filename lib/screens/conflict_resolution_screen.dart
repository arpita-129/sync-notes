import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/services_provider.dart';
import '../providers/notes_provider.dart';

const _kBg = Color(0xFF0F0F13);
const _kSurface = Color(0xFF1C1C21);
const _kBorder = Color(0xFF27272A);
const _kPrimary = Color(0xFF5B6AF9);
const _kPrimaryLight = Color(0xFF818CF8);
const _kDanger = Color(0xFFF87171);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFFA1A1AA);

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  final Note note;
  const ConflictResolutionScreen({super.key, required this.note});

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [

          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      _kPrimary.withAlpha(
                          (_glowAnim.value * 20).round().clamp(0, 255)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),


          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConflictSparkle(_glowCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.arrow_left_2,
                            color: _kTextPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [_kDanger, Color(0xFFFCA5A5)],
                              ).createShader(b),
                              child: const Text(
                                'Resolve Conflict',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Text(
                              'Choose the version to keep',
                              style: TextStyle(
                                  fontSize: 12, color: _kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Iconsax.warning_2,
                          color: _kDanger.withAlpha(200), size: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 12),


                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          children: [

                            Positioned(
                              left: 0,
                              top: 8,
                              child: Container(
                                width: 36,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _kDanger.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _kDanger.withAlpha(100),
                                      width: 1.5),
                                ),
                                child: Icon(Iconsax.note_text,
                                    size: 18,
                                    color: _kDanger.withAlpha(180)),
                              ),
                            ),

                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 36,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _kPrimary.withAlpha(22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _kPrimary.withAlpha(120),
                                      width: 1.5),
                                ),
                                child: Icon(Iconsax.note_text,
                                    size: 18, color: _kPrimary),
                              ),
                            ),

                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7F1D1D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kSurface, width: 2),
                                ),
                                child: const Icon(Icons.priority_high,
                                    size: 10, color: _kDanger),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Two versions detected',
                            style: TextStyle(
                                color: _kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Select which version to keep.',
                            style: TextStyle(
                                color: _kTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 12),


                Expanded(
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: SingleChildScrollView(
                                  child: _buildPanel(ctx,
                                      isYours: true))),
                          const SizedBox(width: 4),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: _buildPanel(ctx,
                                      isYours: false))),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(children: [
                        _buildPanel(ctx, isYours: true),
                        const SizedBox(height: 4),
                        _buildPanel(ctx, isYours: false),
                        const SizedBox(height: 20),
                      ]),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context, {required bool isYours}) {
    final dateFormat = DateFormat('MMM dd, yyyy · h:mm a');
    final color = isYours ? _kPrimary : _kDanger;
    final title = isYours
        ? widget.note.title
        : (widget.note.conflictServerTitle ?? 'No Title');
    final body = isYours
        ? widget.note.body
        : (widget.note.conflictServerBody ?? 'No content');
    final updatedAt = isYours
        ? widget.note.updatedAt
        : widget.note.conflictServerUpdatedAt;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(120), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(
                  (_glowAnim.value * 40).round().clamp(0, 255)),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(color: color.withAlpha(150), blurRadius: 6)
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isYours ? 'YOUR VERSION' : 'SERVER VERSION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body.isNotEmpty ? body : 'No additional content',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextSecondary,
                      height: 1.6,
                    ),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Iconsax.calendar, size: 11,
                            color: color.withAlpha(160)),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(updatedAt).split(' · ')[0],
                          style: TextStyle(
                              color: color.withAlpha(160), fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Icon(Iconsax.clock, size: 11,
                            color: color.withAlpha(160)),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(updatedAt).split(' · ')[1],
                          style: TextStyle(
                              color: color.withAlpha(160), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action button — identical structure for both panels
                  isYours
                      ? _buildActionButton(
                          icon: Iconsax.tick_circle,
                          label: 'Keep Mine',
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: Colors.transparent,
                          glowColor: _kPrimary.withAlpha(80),
                          onTap: () async {
                            final s = ref.read(syncServiceProvider);
                            await s.resolveConflictKeepMine(widget.note);
                            ref.read(notesProvider.notifier).refresh();
                            if (context.mounted) Navigator.pop(context);
                          },
                        )
                      : _buildActionButton(
                          icon: Iconsax.refresh,
                          label: 'Use Server Version',
                          textColor: _kDanger,
                          iconColor: _kDanger,
                          gradient: null,
                          fillColor: _kDanger.withAlpha(18),
                          borderColor: _kDanger.withAlpha(160),
                          glowColor: Colors.transparent,
                          onTap: () async {
                            final s = ref.read(syncServiceProvider);
                            await s.resolveConflictUseServer(widget.note);
                            ref.read(notesProvider.notifier).refresh();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared button builder — guarantees identical height, padding, and
  /// border-radius for both "Keep Mine" and "Use Server Version".
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color iconColor,
    required LinearGradient? gradient,
    required Color borderColor,
    required Color glowColor,
    Color? fillColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient,
          color: gradient == null ? fillColor : null,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            if (glowColor != Colors.transparent)
              BoxShadow(
                color: glowColor,
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _ConflictSparkle extends CustomPainter {
  final double t;
  _ConflictSparkle(this.t);

  static const _rel = [
    Offset(0.05, 0.10), Offset(0.90, 0.08),
    Offset(0.08, 0.60), Offset(0.92, 0.55),
    Offset(0.50, 0.04),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _rel.length; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final opacity = ((math.sin(phase * math.pi * 2) + 1) / 2) * 0.18;
      final color = i % 2 == 0 ? _kPrimary : _kDanger;
      canvas.drawCircle(
        Offset(_rel[i].dx * size.width, _rel[i].dy * size.height),
        i % 2 == 0 ? 2.5 : 1.8,
        Paint()..color = color.withAlpha((opacity * 255).round().clamp(0, 255)),
      );
    }
  }

  @override
  bool shouldRepaint(_ConflictSparkle o) => o.t != t;
}
