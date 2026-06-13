import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/delete_confirmation_sheet.dart';
import 'package:iconsax/iconsax.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/connectivity_provider.dart';

const _kBg = Color(0xFF0F0F13);
const _kSurface = Color(0xFF1C1C21);
const _kBorder = Color(0xFF27272A);
const _kPrimary = Color(0xFF5B6AF9);
const _kPrimaryLight = Color(0xFF818CF8);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFFA1A1AA);

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _hasChanges = false;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleCtrl = TextEditingController(text: _currentNote?.title ?? '');
    _bodyCtrl = TextEditingController(text: _currentNote?.body ?? '');

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _titleCtrl.addListener(_checkChanges);
    _bodyCtrl.addListener(_checkChanges);
    WidgetsBinding.instance.addObserver(this);
  }

  void _checkChanges() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final hasText = title.isNotEmpty || body.isNotEmpty;
    
    bool changed = false;
    if (_currentNote == null) {
      changed = hasText;
    } else {
      changed = hasText && (title != _currentNote!.title || body != _currentNote!.body);
    }

    if (_hasChanges != changed) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _autoSaveBackground();
    }
  }

  Future<void> _autoSaveBackground() async {
    if (!_hasChanges) return;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    if (_currentNote == null) {
      final newNote = await ref.read(notesProvider.notifier).addNote(title, body);
      if (mounted) {
        _currentNote = newNote;
        _hasChanges = false;
      }
    } else {
      await ref.read(notesProvider.notifier).updateNote(_currentNote!, title, body);
      if (mounted) _hasChanges = false;
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (_currentNote == null) {
      final newNote = await ref.read(notesProvider.notifier).addNote(title, body);
      _currentNote = newNote;
    } else {
      await ref.read(notesProvider.notifier).updateNote(_currentNote!, title, body);
    }
    
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      ref.read(syncProvider.notifier).syncNow();
    }
    
    if (mounted) {
      setState(() => _hasChanges = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _delete() async {
    await ref.read(notesProvider.notifier).deleteNote(widget.note!);
    // Flush deletion event to the backend synchronously.
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      ref.read(syncProvider.notifier).syncNow();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _currentNote == null;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _save();
      },
      child: Scaffold(
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
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [
                      _kPrimary.withAlpha(
                          (_glowAnim.value * 25).round().clamp(0, 255)),
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
              painter: _EditorSparklePainter(_glowCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.arrow_left_2,
                            color: _kTextPrimary),
                        onPressed: () async {
                          if (_hasChanges) {
                            await _save();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          isNew ? 'New Note' : 'Edit Note',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      if (!isNew)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F1D1D).withAlpha(120),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFF87171).withAlpha(40)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _showDeleteDialog(),
                                child: const Icon(Iconsax.trash,
                                    color: Color(0xFFF87171), size: 18),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: _hasChanges
                                ? const LinearGradient(
                                    colors: [_kPrimary, _kPrimaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _hasChanges ? null : _kSurface,
                            border: _hasChanges
                                ? null
                                : Border.all(
                                    color: _kPrimary.withAlpha(50)),
                            boxShadow: _hasChanges
                                ? [
                                    BoxShadow(
                                      color: _kPrimary.withAlpha(
                                          (_glowAnim.value * 120)
                                              .round()
                                              .clamp(0, 255)),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _hasChanges ? _save : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.tick_circle,
                                      size: 16,
                                      color: _hasChanges
                                          ? Colors.white
                                          : _kPrimary.withAlpha(160),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Done',
                                      style: TextStyle(
                                        color: _hasChanges
                                            ? Colors.white
                                            : _kPrimary.withAlpha(160),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: 0.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note title...',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _kTextSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _kPrimary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),


                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: TextField(
                      controller: _bodyCtrl,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _kTextPrimary,
                        height: 1.7,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: _kTextSecondary,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteDialog() async {
    final result = await DeleteConfirmationSheet.show(context);
    if (result == true) {
      _delete();
    }
  }
}


class _EditorSparklePainter extends CustomPainter {
  final double t;
  _EditorSparklePainter(this.t);
  static const _rel = [
    Offset(0.05, 0.15), Offset(0.92, 0.20), Offset(0.08, 0.80),
    Offset(0.88, 0.75), Offset(0.50, 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _rel.length; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final opacity = ((math.sin(phase * math.pi * 2) + 1) / 2) * 0.15;
      canvas.drawCircle(
        Offset(_rel[i].dx * size.width, _rel[i].dy * size.height),
        i % 2 == 0 ? 2.5 : 1.5,
        Paint()
          ..color = _kPrimary.withAlpha((opacity * 255).round().clamp(0, 255)),
      );
    }
  }

  @override
  bool shouldRepaint(_EditorSparklePainter o) => o.t != t;
}
