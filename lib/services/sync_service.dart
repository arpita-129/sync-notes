import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/sync_status.dart';
import 'api_service.dart';
import 'hive_service.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

class SyncService {
  final ApiService _apiService;

  SyncService(this._apiService);

  Future<void> sync() async {
    final box = HiveService.notesBox;
    final notes = box.values.toList();

    // Synchronize local mutations (Create, Update, Delete) with the remote backend.
    for (var note in notes) {
      try {
        if (note.syncStatus == SyncStatus.pendingCreate) {
          final response = await _apiService.createNote(note.toJson());
          note.serverId = response['id'];
          note.syncStatus = SyncStatus.synced;
          note.lastSyncedAt = DateTime.now();
          await box.put(note.localId, note);
        } else if (note.syncStatus == SyncStatus.pendingDelete) {
          if (note.serverId == null) {
            await box.delete(note.localId);
          } else {
            await _apiService.deleteNote(note.serverId!);
            await box.delete(note.localId);
          }
        } else if (note.syncStatus == SyncStatus.pendingUpdate) {
          if (note.serverId == null) continue; // Should not happen

          // Fetch the remote state to detect potential concurrent modifications.
          final serverData = await _apiService.getNote(note.serverId!);
          final serverUpdatedAt = DateTime.parse(serverData['updatedAt']);

          if (note.lastSyncedAt != null && serverUpdatedAt.isAfter(note.lastSyncedAt!)) {
            note.syncStatus = SyncStatus.conflict;
            note.conflictServerTitle = serverData['title'];
            note.conflictServerBody = serverData['body'];
            note.conflictServerUpdatedAt = serverUpdatedAt;
            await box.put(note.localId, note);
          } else {
            await _apiService.updateNote(note.serverId!, note.toJson());
            note.syncStatus = SyncStatus.synced;
            note.lastSyncedAt = DateTime.now();
            await box.put(note.localId, note);
          }
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Reconcile 404 errors by pruning obsolete local tombstones.
          if (note.syncStatus == SyncStatus.pendingDelete || note.syncStatus == SyncStatus.pendingUpdate) {
            await box.delete(note.localId);
          }
        }
        debugPrint('DioError syncing note ${note.localId}: $e');
      } catch (e) {
        debugPrint('Error syncing note ${note.localId}: $e');
      }
    }

    // Ingest remote mutations and apply deltas to the local database.
    try {
      final serverNotesList = await _apiService.getNotes();
      for (var serverNoteData in serverNotesList) {
        final serverId = serverNoteData['id'];
        final serverTitle = serverNoteData['title'];
        final serverBody = serverNoteData['body'];
        final serverCreatedAt = DateTime.parse(serverNoteData['createdAt']);
        final serverUpdatedAt = DateTime.parse(serverNoteData['updatedAt']);

        final localNote = box.values.cast<Note?>().firstWhere(
              (n) => n?.serverId == serverId,
              orElse: () => null,
            );

        if (localNote == null) {
          final newNote = Note(
            localId: const Uuid().v4(),
            serverId: serverId,
            title: serverTitle,
            body: serverBody,
            createdAt: serverCreatedAt,
            updatedAt: serverUpdatedAt,
            lastSyncedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
          );
          await box.put(newNote.localId, newNote);
        } else if (localNote.syncStatus == SyncStatus.synced) {
          if (serverUpdatedAt.isAfter(localNote.updatedAt)) {
            localNote.title = serverTitle;
            localNote.body = serverBody;
            localNote.updatedAt = serverUpdatedAt;
            localNote.lastSyncedAt = DateTime.now();
            await box.put(localNote.localId, localNote);
          }
        }
      }
      
      // Identify notes that exist locally (with a serverId) but are missing from the server.
      // This means another client deleted the note remotely.
      final serverIds = serverNotesList.map((n) => n['id']).toSet();
      final allLocalNotes = box.values.toList();
      for (var localNote in allLocalNotes) {
        if (localNote.serverId != null && !serverIds.contains(localNote.serverId)) {
          // If it has a serverId but the server doesn't have it, it was deleted remotely.
          await box.delete(localNote.localId);
        }
      }
    } catch (e) {
      debugPrint('Error pulling remote changes: $e');
    }
  }

  Future<void> resolveConflictKeepMine(Note note) async {
    final box = HiveService.notesBox;
    try {
      await _apiService.updateNote(note.serverId!, note.toJson());
      note.syncStatus = SyncStatus.synced;
      note.lastSyncedAt = DateTime.now();
      note.conflictServerTitle = null;
      note.conflictServerBody = null;
      note.conflictServerUpdatedAt = null;
      await box.put(note.localId, note);
    } catch (e) {
      debugPrint('Error resolving conflict (keep mine): $e');
    }
  }

  Future<void> resolveConflictUseServer(Note note) async {
    final box = HiveService.notesBox;
    note.title = note.conflictServerTitle!;
    note.body = note.conflictServerBody!;
    note.updatedAt = note.conflictServerUpdatedAt!;
    note.syncStatus = SyncStatus.synced;
    note.lastSyncedAt = DateTime.now();
    note.conflictServerTitle = null;
    note.conflictServerBody = null;
    note.conflictServerUpdatedAt = null;
    await box.put(note.localId, note);
  }
}
