# Sync Notes

A local-first note-taking application built with Flutter. Sync Notes is designed to provide a reliable offline experience with background synchronization and conflict resolution when switching between offline and online states.

## Overview

Sync Notes is built as a technical demonstration of handling distributed state across a local client and a remote backend. The application prioritizes local writes—meaning users can create, edit, delete, and manage notes entirely offline—while a background synchronization engine ensures eventual consistency with the server once connectivity is restored.

## Key Features

- **Core Note Management**: Create, edit, delete, and view all notes. The application stores the note's title and body entirely offline without requiring an internet connection.
- **Dedicated Search Experience**: Find notes using a dedicated, full-screen search interface. Features real-time filtering to quickly locate content without clutter.
- **Sync Status Indicators**: Every note displays a clear visual indicator of its current synchronization state (`Synced`, `Pending Sync`, or `Conflict`), ensuring users always know if their data is safely backed up.
- **Background Synchronization**: Automatically detects internet connectivity changes. The system queues local operations while offline, pushes pending changes to the server when online, and pulls the latest note updates to maintain consistency.
- **Conflict Resolution**: Detects when a note has been modified both locally and on the server. Provides a side-by-side UI allowing the user to manually resolve the conflict.

## Synchronization & Offline Strategy

### Local State Management

The app utilizes `Hive` for synchronous local data persistence. Every note maintains internal metadata tracking its synchronization state, distinguishing between notes that are fully synced, pending creation, pending updates, or flagged for deletion.

### Synchronization Flow

1. **Mutation**: When a user modifies a note, the local database is updated immediately, and the note is marked as requiring synchronization.
2. **Reconciliation**: The `SyncService` queries the backend for the source of truth.
3. **Delta Application**:
   - Newly created local notes are pushed to the server.
   - Updated local notes are synchronized with the backend.
   - Notes flagged for deletion trigger a remote deletion request. If the server indicates the note is already gone, the app safely prunes the local tombstone.
4. **Ingestion**: Server-side modifications that are newer than local versions are ingested and overwrite local data unless a conflict is detected.

### Conflict Resolution Strategy

When the synchronization engine detects that a note has been modified both locally and remotely since the last sync, it halts automatic merging to prevent data loss.

- The note is flagged as conflicted.
- The user is presented with a specialized **Conflict Resolution Screen**.
- The UI displays a side-by-side comparison of the "Local Version" and the "Server Version".
- The user explicitly chooses which version to keep, and the `SyncService` forces the chosen state across both environments.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Local Persistence**: Hive (`hive`, `hive_flutter`)
- **Networking**: Dio
- **Connectivity & Utility**: `connectivity_plus` for network state, `uuid` for unique ID generation.

## Setup Instructions

1. **Prerequisites**: Ensure you have Flutter SDK `^3.12.0` installed.
2. **Clone the repository**:
   ```bash
   git clone https://github.com/arpita-129/sync-notes.git
   cd sync-notes
   ```
3. **Pre-compiled APK**: A production-ready Android APK is available inside the repository at `release_apk/sync_notes.apk`.
4. **Install dependencies**:
   ```bash
   flutter pub get
   ```
5. **Code Generation**: The project uses Riverpod generator. Run the build runner to generate the necessary provider files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
6. **Run the application**:
   ```bash
   flutter run
   ```

## Project Structure

```text
lib/
├── models/          # Data classes and Hive type adapters (Note model)
├── providers/       # Riverpod state notifiers (NotesProvider, SyncProvider)
├── screens/         # UI Views (NotesListScreen, NoteEditorScreen, ConflictScreen)
├── services/        # Core business logic (HiveService, SyncService)
├── widgets/         # Reusable UI components (NoteCard, DeleteBottomSheet)
└── main.dart        # Entry point and theme configuration
```

## Architectural Decisions

- **Riverpod for State**: Chosen for its compile-time safety and decoupled dependency injection, making the `SyncService` easily accessible across the widget tree.
- **Hive over SQLite**: Opted for Hive's key-value synchronous reads/writes to enable immediate UI updates during offline operations.
- **Soft Deletion Locally**: Deleted notes are kept as tombstones (`pendingDelete`) rather than being purged immediately. This guarantees that offline deletes are correctly propagated to the backend when connectivity returns.
