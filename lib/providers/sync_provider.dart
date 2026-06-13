import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services_provider.dart';
import 'notes_provider.dart';

class SyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(() => syncNow());
    return false;
  }

  Future<void> syncNow() async {
    state = true;
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.sync();
      ref.read(notesProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      state = false;
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, bool>(SyncNotifier.new);
