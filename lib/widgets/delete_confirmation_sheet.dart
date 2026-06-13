import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';

class DeleteConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;

  const DeleteConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Delete Note',
    String message = 'This note will be permanently deleted. This action cannot be undone.',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DeleteConfirmationSheet(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kSurface = Color(0xFF1C1C21);
    const kBorder = Color(0xFF27272A);
    const kDangerBg = Color(0xFF7F1D1D);
    const kDangerFg = Color(0xFFF87171);
    const kTextPrimary = Color(0xFFFFFFFF);
    const kTextSecondary = Color(0xFFA1A1AA);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface.withAlpha(240),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [


            

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDangerBg.withAlpha(80),
                shape: BoxShape.circle,
                border: Border.all(color: kDangerBg, width: 2),
              ),
              child: const Icon(Iconsax.trash, color: kDangerFg, size: 28),
            ),
            const SizedBox(height: 16),
            

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: kBorder, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundColor: kTextPrimary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDangerBg,
                      foregroundColor: kDangerFg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
