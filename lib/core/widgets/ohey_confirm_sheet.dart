import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_bottom_sheet.dart';
import 'ohey_pop_icon.dart';

Future<bool?> showOheyConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'キャンセル',
  String confirmLabel = 'OK',
  bool destructive = false,
  IconData? icon,
  Color? accent,
}) {
  final sheetAccent =
      accent ?? (destructive ? AppColors.danger : AppColors.primaryAction);
  return showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => OheyConfirmSheet(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
      icon: icon,
      accent: sheetAccent,
    ),
  );
}

class OheyConfirmSheet extends StatelessWidget {
  const OheyConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.destructive,
    required this.accent,
    this.icon,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .62);
    final secondarySurface = isWhite
        ? AppColors.cFFF2F6FA
        : AppColors.white.withValues(alpha: .07);
    final secondaryForeground = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .72);

    return OheyBottomSheetShell(
      showBottomCloseButton: false,
      showHandle: true,
      maxHeightFactor: .72,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: OheyPopIcon(
              icon:
                  icon ??
                  (destructive
                      ? CupertinoIcons.trash_fill
                      : CupertinoIcons.question_circle_fill),
              color: accent,
              size: 64,
              iconSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Ohey3DButton.secondary(
                  label: cancelLabel,
                  icon: CupertinoIcons.xmark_circle_fill,
                  onTap: () => Navigator.of(context).pop(false),
                  height: 50,
                  radius: 21,
                  color: secondarySurface,
                  foregroundColor: secondaryForeground,
                  shadowColor: isWhite
                      ? AppColors.cFFD3DBE3
                      : AppColors.cFF243240.withValues(alpha: .88),
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  useGradient: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: destructive
                    ? Ohey3DButton.destructive(
                        label: confirmLabel,
                        icon: CupertinoIcons.trash_fill,
                        onTap: () => Navigator.of(context).pop(true),
                        height: 50,
                        radius: 21,
                        color: accent,
                        shadowColor: ohey3DShadowColorFor(accent),
                        fontSize: 13,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      )
                    : Ohey3DButton(
                        label: confirmLabel,
                        icon: CupertinoIcons.checkmark_circle_fill,
                        onTap: () => Navigator.of(context).pop(true),
                        height: 50,
                        radius: 21,
                        color: accent,
                        foregroundColor: AppColors.white,
                        shadowColor: ohey3DShadowColorFor(accent),
                        fontSize: 13,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
