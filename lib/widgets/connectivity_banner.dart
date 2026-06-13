import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';

const _kPrimary = Color(0xFF5B6AF9);
const _kEmerald = Color(0xFF34D399);

class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool _showOnline = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final isSyncing = ref.watch(syncProvider);

    ref.listen<bool>(isOnlineProvider, (prev, next) {
      if (prev == false && next == true) {
        setState(() => _showOnline = true);
        _dismissTimer?.cancel();
        _dismissTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showOnline = false);
        });
      } else if (next == false) {
        _dismissTimer?.cancel();
        setState(() => _showOnline = false);
      }
    });

    final bool visible = !isOnline || _showOnline || isSyncing;
    final isOnlineState = isOnline;

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      child: visible
          ? Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                gradient: isOnlineState
                    ? const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF065F46)])
                    : const LinearGradient(
                        colors: [Color(0xFF1C1C21), Color(0xFF27272A)]),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnlineState ? Iconsax.wifi : Iconsax.wifi_square,
                    color: isOnlineState ? _kEmerald : const Color(0xFFA1A1AA),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnlineState
                        ? 'Back online · syncing your notes'
                        : "Offline · changes saved locally",
                    style: TextStyle(
                      color: isOnlineState
                          ? _kEmerald
                          : const Color(0xFFA1A1AA),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
