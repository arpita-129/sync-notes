import 'package:hive/hive.dart';
import 'sync_status.dart';

class Note {
  String localId;
  String? serverId;
  String title;
  String body;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastSyncedAt;
  SyncStatus syncStatus;
  
  String? conflictServerTitle;
  String? conflictServerBody;
  DateTime? conflictServerUpdatedAt;

  Note({
    required this.localId,
    this.serverId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.conflictServerTitle,
    this.conflictServerBody,
    this.conflictServerUpdatedAt,
  });

  Note copyWith({
    String? localId,
    String? serverId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    String? conflictServerTitle,
    String? conflictServerBody,
    DateTime? conflictServerUpdatedAt,
  }) {
    return Note(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      conflictServerTitle: conflictServerTitle ?? this.conflictServerTitle,
      conflictServerBody: conflictServerBody ?? this.conflictServerBody,
      conflictServerUpdatedAt: conflictServerUpdatedAt ?? this.conflictServerUpdatedAt,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      localId: '', // placeholder, shouldn't be parsed directly as local Note
      serverId: json['id'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    return Note(
      localId: reader.readString(),
      serverId: reader.read() as String?,
      title: reader.readString(),
      body: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastSyncedAt: reader.read() != null ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      syncStatus: SyncStatus.values[reader.readInt()],
      conflictServerTitle: reader.read() as String?,
      conflictServerBody: reader.read() as String?,
      conflictServerUpdatedAt: reader.read() != null ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.localId);
    writer.write(obj.serverId);
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    if (obj.lastSyncedAt != null) {
      writer.write(true);
      writer.writeInt(obj.lastSyncedAt!.millisecondsSinceEpoch);
    } else {
      writer.write(null);
    }
    writer.writeInt(obj.syncStatus.index);
    writer.write(obj.conflictServerTitle);
    writer.write(obj.conflictServerBody);
    if (obj.conflictServerUpdatedAt != null) {
      writer.write(true);
      writer.writeInt(obj.conflictServerUpdatedAt!.millisecondsSinceEpoch);
    } else {
      writer.write(null);
    }
  }
}
