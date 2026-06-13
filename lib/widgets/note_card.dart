import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../models/note.dart';
import '../models/sync_status.dart';
import 'sync_status_badge.dart';

const _kSurface = Color(0xFF1C1C21);
const _kBorder = Color(0xFF27272A);
const _kPrimary = Color(0xFF5B6AF9);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFFA1A1AA);

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onConflictTap;
  final VoidCallback? onSyncTap;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.isGrid = false,
    required this.onTap,
    this.onLongPress,
    required this.onDelete,
    required this.onConflictTap,
    this.onSyncTap,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final hasConflict = widget.note.syncStatus == SyncStatus.conflict;
    final isPending = widget.note.syncStatus == SyncStatus.pendingCreate ||
        widget.note.syncStatus == SyncStatus.pendingUpdate ||
        widget.note.syncStatus == SyncStatus.pendingDelete;

    Color borderColor = widget.isSelected
        ? _kPrimary
        : (hasConflict ? Colors.redAccent.withAlpha(100) : _kBorder.withAlpha(100));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: widget.isGrid
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Reduced vertical spacing
        transform: Matrix4.translationValues(0, _isHovered && !widget.isGrid ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _kSurface.withAlpha(220),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: widget.isSelected ? 1.5 : 1.0),
          gradient: LinearGradient(
            colors: [
              _kSurface.withAlpha(240),
              _kSurface.withAlpha(180),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            if (_isHovered || widget.isSelected)
              BoxShadow(
                color: widget.isSelected ? _kPrimary.withAlpha(40) : Colors.black.withAlpha(60),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(16),
            splashColor: _kPrimary.withAlpha(20),
            highlightColor: _kPrimary.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title row ─────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.note.title.isNotEmpty ? widget.note.title : 'Untitled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary.withAlpha(240),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kPrimary,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        )
                      else if (!widget.isGrid)
                        SyncStatusBadge(
                          status: widget.note.syncStatus,
                          onConflictTap: widget.onConflictTap,
                          onSyncTap: widget.onSyncTap,
                        ),
                    ],
                  ),

                  if (widget.isGrid && !widget.isSelected) ...[
                    const SizedBox(height: 6),
                    SyncStatusBadge(
                      status: widget.note.syncStatus,
                      onConflictTap: widget.onConflictTap,
                      onSyncTap: widget.onSyncTap,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ── Body preview ──────────────────────────────────────────
                  Text(
                    widget.note.body.isNotEmpty ? widget.note.body : 'No additional text',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kTextSecondary.withAlpha(180),
                      height: 1.4,
                    ),
                    maxLines: widget.isGrid ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // ── Divider ────────────────────────────────────────────────
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kBorder.withAlpha(20),
                          _kBorder.withAlpha(80),
                          _kBorder.withAlpha(20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Timestamps ────────────────────────────────────────────
                  if (widget.isGrid)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _iconStamp(Iconsax.calendar_1, dateFormat.format(widget.note.updatedAt)),
                            const SizedBox(height: 2),
                            _iconStamp(Iconsax.clock, timeFormat.format(widget.note.updatedAt)),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _iconStamp(Iconsax.calendar_1, dateFormat.format(widget.note.updatedAt)),
                            const SizedBox(width: 12),
                            _iconStamp(Iconsax.clock, timeFormat.format(widget.note.updatedAt)),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconStamp(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kTextSecondary.withAlpha(160)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: _kTextSecondary.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      );
}
