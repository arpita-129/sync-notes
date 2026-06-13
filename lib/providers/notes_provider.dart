import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/sync_status.dart';
import '../services/hive_service.dart';

class NotesNotifier extends Notifier<List<Note>> {
  @override
  List<Note> build() {
    return _loadNotes();
  }

  List<Note> _loadNotes() {
    final box = HiveService.notesBox;
    final allNotes = box.values.toList();
    return allNotes.where((note) => note.syncStatus != SyncStatus.pendingDelete).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void refresh() {
    state = _loadNotes();
  }

  Future<Note> addNote(String title, String body) async {
    final note = Note(
      localId: const Uuid().v4(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingCreate,
    );
    await HiveService.notesBox.put(note.localId, note);
    refresh();
    return note;
  }

  Future<void> updateNote(Note note, String title, String body) async {
    note.title = title;
    note.body = body;
    note.updatedAt = DateTime.now();
    if (note.syncStatus == SyncStatus.synced) {
      note.syncStatus = SyncStatus.pendingUpdate;
    }
    await HiveService.notesBox.put(note.localId, note);
    refresh();
  }

  Future<void> deleteNote(Note note) async {
    if (note.syncStatus == SyncStatus.pendingCreate) {
      await HiveService.notesBox.delete(note.localId);
    } else {
      note.syncStatus = SyncStatus.pendingDelete;
      await HiveService.notesBox.put(note.localId, note);
    }
    refresh();
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
