import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/ohey_avatar.dart';
import 'ohey_3d_button.dart';
import 'ohey_avatar.dart';
import 'ohey_pop_icon.dart';

/// QR exchange display used by friend/profile exchange flows.
///
/// Keep this scoped to QR identity exchange; use generic cards or
/// [OheyActionTile] for non-exchange settings/actions.
class OheyQrDisplayCard extends StatelessWidget {
  const OheyQrDisplayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.handle,
    required this.payload,
    required this.avatar,
    required this.accentColor,
    this.cardColor,
    this.textColor = Colors.white,
    this.mutedTextColor,
    this.qrSize = 202,
    this.qrPadding = 14,
    this.loginRequiredMessage = 'ログインが必要です',
  });

  final String title;
  final String subtitle;
  final String handle;
  final String? payload;
  final OheyAvatar avatar;
  final Color accentColor;
  final Color? cardColor;
  final Color textColor;
  final Color? mutedTextColor;
  final double qrSize;
  final double qrPadding;
  final String loginRequiredMessage;

  @override
  Widget build(BuildContext context) {
    final muted = mutedTextColor ?? textColor.withValues(alpha: .50);
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accentColor.withValues(alpha: .28)),
              ),
              child: OheyAvatarView(avatar: avatar, size: 58),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            OheyPopIcon(icon: CupertinoIcons.qrcode, color: accentColor),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: qrSize,
          height: qrSize,
          padding: EdgeInsets.all(qrPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: .20),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: payload == null
              ? Center(child: Text(loginRequiredMessage))
              : QrImageView(data: payload!, version: QrVersions.auto),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: (cardColor ?? Colors.white).withValues(alpha: .07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: textColor.withValues(alpha: .08)),
          ),
          child: Text(
            handle,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Action card for the Ohey friend-exchange flow.
///
/// This is intentionally more branded than [OheyActionTile], which remains the
/// generic bottom-sheet/action-list tile.
class OheyExchangeActionCard extends StatelessWidget {
  const OheyExchangeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    required this.childBuilder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final Widget Function(BuildContext context, Widget child) childBuilder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: childBuilder(
        context,
        Row(
          children: [
            OheyPopIcon(icon: icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .50),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            OheyGeneratedIcon(
              CupertinoIcons.chevron_right,
              color: accent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for showing a found profile and a primary relationship action.
///
/// Use this for friend/profile search results; use feature-specific sheets for
/// complex forms or multi-step actions.
class OheyProfileResultSheet extends StatelessWidget {
  const OheyProfileResultSheet({
    super.key,
    required this.avatar,
    required this.displayName,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.backgroundColor,
    required this.accentColor,
    this.statusMessage,
    this.statusIcon,
    this.statusColor,
    this.onClose,
  });

  final OheyAvatar avatar;
  final String displayName;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final Color backgroundColor;
  final Color accentColor;
  final String? statusMessage;
  final IconData? statusIcon;
  final Color? statusColor;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const OheyGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: .35)),
              ),
              child: OheyAvatarView(avatar: avatar, size: 96),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .52),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  children: [
                    OheyPopIcon(
                      icon: statusIcon ?? CupertinoIcons.info_circle_fill,
                      color: statusColor ?? accentColor,
                      size: 38,
                      showBubble: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusMessage!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .74),
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Ohey3DButton(
              label: actionLabel,
              icon: actionIcon,
              onTap: onAction,
              height: 54,
              radius: 22,
              color: accentColor,
              foregroundColor: Colors.white,
              shadowColor: ohey3DShadowColorFor(
                accentColor,
                lightnessScale: .58,
              ),
              fontSize: 16,
            ),
          ],
        ),
      ),
    ),
  );
}
