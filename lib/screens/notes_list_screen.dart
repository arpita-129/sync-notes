import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/notes_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/note_card.dart';
import '../models/sync_status.dart';
import '../models/note.dart';
import 'note_editor_screen.dart';
import '../screens/conflict_resolution_screen.dart';
import '../widgets/delete_confirmation_sheet.dart';
import 'note_search_screen.dart';

enum SortOption { timeCreated, timeEdited, titleAlphabetical }

const _kBgTop = Color(0xFF15151A);
const _kBgBottom = Color(0xFF0A0A0E);
const _kSurface = Color(0xFF1C1C21);
const _kSurfaceLighter = Color(0xFF27272D);
const _kBorder = Color(0xFF2A2A35);
const _kPrimary = Color(0xFF5B6AF9);
const _kPrimaryLight = Color(0xFF818CF8);
const _kTextPrimary = Color(0xFFF4F4F5);
const _kTextSecondary = Color(0xFFA1A1AA);
const _kDanger = Color(0xFFF87171);
const _kWarning = Color(0xFFFBBF24);
const _kSuccess = Color(0xFF34D399);

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;
  bool _isGridView = false;
  SortOption _sortOption = SortOption.timeEdited;
  String _searchQuery = '';

  final FocusNode _searchFocusNode = FocusNode();

  AnimationController? _glowCtrl;
  AnimationController? _sparkleCtrl;
  Animation<double>? _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl?.dispose();
    _sparkleCtrl?.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) => setState(() {
        if (_selectedNoteIds.contains(id)) {
          _selectedNoteIds.remove(id);
        } else {
          _selectedNoteIds.add(id);
        }
      });

  void _selectAll(List<String> allIds) =>
      setState(() => _selectedNoteIds.addAll(allIds));

  void _clearSelection() => setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });

  Future<void> _deleteSelectedNotes() async {
    final result = await DeleteConfirmationSheet.show(
      context,
      title: 'Delete ${_selectedNoteIds.length} Notes',
      message: 'These notes will be permanently deleted. This action cannot be undone.',
    );
    if (result != true) return;

    final notes = ref.read(notesProvider);
    for (var id in _selectedNoteIds) {
      final idx = notes.indexWhere((n) => n.localId == id);
      if (idx != -1) ref.read(notesProvider.notifier).deleteNote(notes[idx]);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final isSyncing = ref.watch(syncProvider);
    
    ref.listen(isOnlineProvider, (prev, next) {
      if (prev == false && next == true) {
        ref.read(syncProvider.notifier).syncNow();
      }
    });

    final notes = ref.watch(notesProvider);

    var filtered = notes.toList();

    filtered.sort((a, b) {
      if (_sortOption == SortOption.timeCreated) {
        return b.createdAt.compareTo(a.createdAt);
      } else if (_sortOption == SortOption.titleAlphabetical) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    final allIds = filtered.map((e) => e.localId).toList();

    return Scaffold(
      backgroundColor: _kBgBottom,
      appBar: _isSelectionMode ? _buildSelectionAppBar(allIds) : null,
      body: GestureDetector(
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [

          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [_kBgTop, _kBgBottom],
                center: Alignment(-0.5, -0.8),
                radius: 1.5,
              ),
            ),
          ),

          if (_sparkleCtrl != null && !_isSelectionMode)
            AnimatedBuilder(
              animation: _sparkleCtrl!,
              builder: (_, __) => CustomPaint(
                painter: _SparklesPainter(_sparkleCtrl!.value),
                child: const SizedBox.expand(),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                if (!_isSelectionMode) _buildPremiumHeader(isOnline, notes),
                if (!_isSelectionMode && notes.isNotEmpty) _buildSummaryCard(notes),
                if (!_isSelectionMode && notes.isNotEmpty) _buildUnifiedSearchSection(),
                if (_isSelectionMode) const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(syncProvider.notifier).syncNow();
                    },
                    color: _kPrimary,
                    backgroundColor: _kSurface,
                    child: _buildBodyContent(notes, filtered, isSyncing),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: (!_isSelectionMode && notes.isEmpty)
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, _fadeRoute(const NoteEditorScreen())),
              backgroundColor: _kPrimary,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Iconsax.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: (_isSelectionMode || notes.isEmpty) ? null : _buildModernBottomNav(notes),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(List<String> allIds) {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(Iconsax.close_square, color: _kTextSecondary),
          ),
          const SizedBox(width: 16),
          Text('${_selectedNoteIds.length} selected',
              style: const TextStyle(fontSize: 16, color: _kTextPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        if (_selectedNoteIds.isNotEmpty)
          IconButton(
            icon: const Icon(Iconsax.trash, color: _kDanger, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _deleteSelectedNotes,
          ),
        TextButton(
          onPressed: () {
            if (_selectedNoteIds.length == allIds.length) {
              setState(() => _selectedNoteIds.clear());
            } else {
              _selectAll(allIds);
            }
          },
          child: Text(
            _selectedNoteIds.length == allIds.length && allIds.isNotEmpty
                ? 'Deselect all'
                : 'Select all',
            style: const TextStyle(
                color: _kPrimaryLight, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPremiumHeader(bool isOnline, List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                'Good morning, Alex 👋',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Workspace',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kSurfaceLighter.withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? _kSuccess : _kTextSecondary,
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [BoxShadow(color: _kSuccess.withAlpha(100), blurRadius: 4)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      notes.isEmpty
                          ? (isOnline ? 'Online' : 'Offline')
                          : (isOnline ? 'Online • Up to date' : 'Offline • Pending sync'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOnline ? _kTextPrimary.withAlpha(200) : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kPrimary.withAlpha(80), width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Note> notes) {
    int synced = notes.where((n) => n.syncStatus == SyncStatus.synced).length;
    int pending = notes.where((n) => n.syncStatus == SyncStatus.pendingCreate || n.syncStatus == SyncStatus.pendingUpdate || n.syncStatus == SyncStatus.pendingDelete).length;
    int conflicts = notes.where((n) => n.syncStatus == SyncStatus.conflict).length;

    // Adjust visual emphasis based on synchronization anomalies.
    final hasIssues = conflicts > 0 || pending > 0;
    final issueColor = conflicts > 0 ? _kDanger : _kWarning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasIssues ? issueColor.withAlpha(80) : _kBorder.withAlpha(150),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            _kSurfaceLighter.withAlpha(180),
            _kSurface.withAlpha(240),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (hasIssues)
            BoxShadow(
              color: issueColor.withAlpha(30),
              blurRadius: 20,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPremiumStatCol(Iconsax.folder_2, notes.length, 'Total', _kPrimaryLight),
          _buildPremiumStatCol(Iconsax.cloud_plus, synced, 'Synced', _kSuccess),
          _buildPremiumStatCol(Iconsax.arrow_swap, pending, 'Pending', pending > 0 ? _kWarning : _kTextSecondary),
          _buildPremiumStatCol(Iconsax.warning_2, conflicts, 'Conflicts', conflicts > 0 ? _kDanger : _kTextSecondary),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCol(IconData icon, int count, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: count > 0 ? Colors.white : _kTextSecondary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: count > 0 ? _kTextSecondary.withAlpha(220) : _kTextSecondary.withAlpha(120),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(context, _fadeRoute(const NoteSearchScreen()));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Iconsax.search_normal_1, color: _kTextSecondary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search your thoughts...',
                          style: TextStyle(color: _kTextSecondary.withAlpha(150), fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'Sort Options',
                    color: _kSurfaceLighter,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _kBorder),
                    ),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Icon(Iconsax.sort, color: _kTextSecondary, size: 20),
                    ),
                    itemBuilder: (_) => [
                      _menuItem('edit', Iconsax.edit_2, 'Select / Edit'),
                      _menuItem('sort_created', Iconsax.calendar_1, 'Sort by created', isSelected: _sortOption == SortOption.timeCreated),
                      _menuItem('sort_edited', Iconsax.clock, 'Sort by edited', isSelected: _sortOption == SortOption.timeEdited),
                      _menuItem('sort_title', Iconsax.text, 'Sort by title (A-Z)', isSelected: _sortOption == SortOption.titleAlphabetical),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          setState(() => _isSelectionMode = true);
                        case 'sort_created':
                          setState(() => _sortOption = SortOption.timeCreated);
                        case 'sort_edited':
                          setState(() => _sortOption = SortOption.timeEdited);
                        case 'sort_title':
                          setState(() => _sortOption = SortOption.titleAlphabetical);
                      }
                    },
                  ),
                ),
                Container(width: 1.5, height: 24, color: _kBorder),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(_isGridView ? Iconsax.row_vertical : Iconsax.grid_2, color: _kTextSecondary, size: 20),
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

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool isSelected = false}) =>
      PopupMenuItem(
        value: value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: isSelected ? _kPrimary : _kPrimaryLight, size: 18),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: isSelected ? _kPrimary : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            if (isSelected) const Icon(Iconsax.tick_circle, color: _kPrimary, size: 18),
          ],
        ),
      );

  Widget _buildModernBottomNav(List<Note> notes) {
    final fabBuilder = AnimatedBuilder(
      animation: _glowAnim ?? const AlwaysStoppedAnimation(0.5),
      builder: (_, __) {
        final glow = _glowAnim?.value ?? 0.5;
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kPrimary, _kPrimaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withAlpha((glow * 140).round().clamp(0, 255)),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(context, _fadeRoute(const NoteEditorScreen())),
              child: const Icon(Iconsax.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: _kSurface.withAlpha(240),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _kBorder.withAlpha(120), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: notes.isEmpty
                      ? [const SizedBox(width: 64)] // Just space for the center CTA
                      : [
                          _buildSlimNavItem(Iconsax.document, true),
                          _buildSlimNavItem(Iconsax.search_normal_1, false, onTap: () {
                            Navigator.push(context, _fadeRoute(const NoteSearchScreen()));
                          }),
                          const SizedBox(width: 64),
                          _buildSlimNavItem(Iconsax.refresh, false, onTap: () {
                            ref.read(syncProvider.notifier).syncNow();
                          }),
                          _buildSlimNavItem(Iconsax.setting_2, false),
                        ],
                ),
              ),
              Positioned(
                top: -16,
                child: fabBuilder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlimNavItem(IconData icon, bool isActive, {VoidCallback? onTap}) {
    final color = isActive ? _kPrimaryLight : _kTextSecondary.withAlpha(150);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(List<Note> notes, List<Note> filtered, bool isSyncing) {
    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            AnimatedBuilder(
              animation: _glowAnim ?? const AlwaysStoppedAnimation(0.5),
              builder: (_, __) {
                final glow = _glowAnim?.value ?? 0.5;
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPrimary.withAlpha((glow * 40).round().clamp(0, 255)),
                            width: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPrimary.withAlpha((glow * 15).round().clamp(0, 255)),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withAlpha((glow * 60).round().clamp(0, 255)),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Iconsax.note_21,
                        size: 48,
                        color: _kPrimaryLight,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              notes.isEmpty ? 'Your workspace is empty' : 'No results found',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),
            Text(
              notes.isEmpty
                  ? 'Create a new note to start capturing\nyour ideas offline.'
                  : 'Try adjusting your search query.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.5),
            ),

          ],
        ),
        ),
      );
    }

    if (_isGridView) {
      const spacing = 12.0;
      const padding = 20.0;
      
      final leftColumn = <Widget>[];
      final rightColumn = <Widget>[];
      
      for (int i = 0; i < filtered.length; i++) {
        final note = filtered[i];
        final sel = _selectedNoteIds.contains(note.localId);
        final card = _buildCard(context, note, sel, isSyncing, isGrid: true);
        
        if (i % 2 == 0) {
          leftColumn.add(card);
          leftColumn.add(const SizedBox(height: spacing));
        } else {
          rightColumn.add(card);
          rightColumn.add(const SizedBox(height: spacing));
        }
      }
      
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: padding, right: padding, top: 4, bottom: 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: leftColumn,
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rightColumn,
              ),
            ),
          ],
        ),
      );
    }


    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final note = filtered[i];
        final sel = _selectedNoteIds.contains(note.localId);
        return Dismissible(
          key: Key(note.localId),
          direction: _isSelectionMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), _kDanger]),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Iconsax.trash, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await DeleteConfirmationSheet.show(context);
          },
          onDismissed: (_) =>
              ref.read(notesProvider.notifier).deleteNote(note),
          child: _buildCard(ctx, note, sel, isSyncing, isGrid: false),
        );
      },
    );
  }

  Widget _buildCard(BuildContext ctx, dynamic note, bool isSelected, bool isSyncing,
      {required bool isGrid}) {
    final isPending = note.syncStatus != SyncStatus.synced;
    
    return ShimmerOverlay(
      isSyncing: isSyncing && isPending,
      child: NoteCard(
      note: note,
      isSelected: isSelected,
      isGrid: isGrid,
      onLongPress: () => setState(() {
        _isSelectionMode = true;
        _toggleSelection(note.localId);
      }),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(note.localId);
        } else {
          Navigator.push(ctx, _fadeRoute(NoteEditorScreen(note: note)));
        }
      },
      onDelete: () {},
      onConflictTap: note.syncStatus == SyncStatus.conflict && !_isSelectionMode
          ? () => Navigator.push(
              ctx, _fadeRoute(ConflictResolutionScreen(note: note)))
          : () {},
      onSyncTap: () {
        if (!_isSelectionMode) ref.read(syncProvider.notifier).syncNow();
      },
    ),
    );
  }
}

PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

class _SparklesPainter extends CustomPainter {
  final double t;
  _SparklesPainter(this.t);

  static const _rel = [
    Offset(0.1, 0.15), Offset(0.85, 0.20), Offset(0.15, 0.45),
    Offset(0.9, 0.50), Offset(0.08, 0.82), Offset(0.92, 0.78),
    Offset(0.40, 0.05), Offset(0.70, 0.90),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _rel.length; i++) {
      final phase = (t + i / _rel.length) % 1.0;
      final opacity = ((math.sin(phase * math.pi * 2) + 1) / 2) * 0.15; // Very faint
      canvas.drawCircle(
        Offset(_rel[i].dx * size.width, _rel[i].dy * size.height),
        i % 2 == 0 ? 2.5 : 1.5,
        Paint()
          ..color = const Color(0xFF818CF8)
              .withAlpha((opacity * 255).round().clamp(0, 255)),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter o) => o.t != t;
}

class ShimmerOverlay extends StatefulWidget {
  final bool isSyncing;
  final Widget child;

  const ShimmerOverlay({super.key, required this.isSyncing, required this.child});

  @override
  State<ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<ShimmerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.isSyncing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(ShimmerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !oldWidget.isSyncing) {
      _ctrl.repeat();
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(80),
                Colors.white.withAlpha(0),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(slidePercent: _ctrl.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
