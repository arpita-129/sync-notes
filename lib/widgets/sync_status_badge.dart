import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/sync_status.dart';

const _kEmerald = Color(0xFF34D399);
const _kDanger = Color(0xFFF87171);
const _kAmber = Color(0xFFFBBF24);
const _kTextSecondary = Color(0xFFA1A1AA);

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onConflictTap;
  final VoidCallback? onSyncTap;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.onConflictTap,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    Color fg;
    List<Color> bgGradient;
    IconData icon;
    String label;
    VoidCallback? onTap;

    switch (status) {
      case SyncStatus.synced:
        fg = _kEmerald;
        bgGradient = [const Color(0xFF064E3B), const Color(0xFF065F46)];
        icon = Iconsax.tick_circle;
        label = 'Synced';
        onTap = null;
        break;
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
        fg = _kAmber;
        bgGradient = [const Color(0xFF78350F), const Color(0xFF92400E)];
        icon = Iconsax.clock;
        label = 'Pending';
        onTap = onSyncTap;
        break;
      case SyncStatus.pendingDelete:
        fg = _kTextSecondary;
        bgGradient = [const Color(0xFF27272A), const Color(0xFF3F3F46)];
        icon = Iconsax.trash;
        label = 'Deleting';
        onTap = null;
        break;
      case SyncStatus.conflict:
        fg = _kDanger;
        bgGradient = [const Color(0xFF7F1D1D), const Color(0xFF991B1B)];
        icon = Iconsax.warning_2;
        label = 'Conflict';
        onTap = onConflictTap;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: Container(
          key: ValueKey(status),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: bgGradient),
            border: Border.all(color: fg.withAlpha(60), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 11),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
