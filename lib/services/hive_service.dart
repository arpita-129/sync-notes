import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class HiveService {
  static const String _notesBoxName = 'notes';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    await Hive.openBox<Note>(_notesBoxName);
  }

  static Box<Note> get notesBox => Hive.box<Note>(_notesBoxName);
}
