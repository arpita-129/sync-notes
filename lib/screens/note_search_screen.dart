import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/notes_provider.dart';
import '../providers/sync_provider.dart';
import '../models/sync_status.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

const _kBgBottom = Color(0xFF0A0A0E);
const _kSurface = Color(0xFF1C1C21);
const _kBorder = Color(0xFF2A2A35);
const _kTextPrimary = Color(0xFFF4F4F5);
const _kTextSecondary = Color(0xFFA1A1AA);
const _kPrimaryLight = Color(0xFF818CF8);

class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final isSyncing = ref.watch(syncProvider);

    var filtered = notes.where((n) {
      if (_searchQuery.isEmpty) return false; // Show nothing or all? Usually search screens show nothing or history until typed. Let's show all by default like home, or if empty, show "Type to search"
      return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.body.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by latest edited by default for search results
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: _kBgBottom,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildInitialState()
                  : _buildBodyContent(filtered, isSyncing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2, color: _kTextPrimary),
            onPressed: () {
              _searchFocusNode.unfocus();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: _kTextSecondary.withAlpha(150), fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 12),
                    child: Icon(Iconsax.search_normal_1, color: _kTextSecondary, size: 18),
                  ),
                  prefixIconConstraints: const BoxConstraints(minHeight: 48),
                  suffixIconConstraints: const BoxConstraints(maxHeight: 48, maxWidth: 48),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle, color: _kTextSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _searchFocusNode.requestFocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.search_normal_1, size: 48, color: _kTextSecondary.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            'Type to search your thoughts',
            style: TextStyle(fontSize: 16, color: _kTextSecondary.withAlpha(150)),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(List<Note> filtered, bool isSyncing) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.note_21, size: 48, color: _kPrimaryLight),
            const SizedBox(height: 24),
            const Text(
              'No results found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kTextPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search query.',
              style: TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 4, bottom: 40),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final note = filtered[i];
        return _buildCard(ctx, note, isSyncing);
      },
    );
  }

  Widget _buildCard(BuildContext ctx, dynamic note, bool isSyncing) {
    return NoteCard(
      note: note,
      isSelected: false,
      isGrid: false,
      onLongPress: () {},
      onTap: () {
        _searchFocusNode.unfocus();
        Navigator.push(ctx, _fadeRoute(NoteEditorScreen(note: note)));
      },
      onDelete: () {},
      onConflictTap: () {},
      onSyncTap: () {},
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
