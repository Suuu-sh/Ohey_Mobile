import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/nomo_avatar.dart';
import '../models/nomo_friend.dart';
import '../theme/app_colors.dart';
import 'nomo_3d_button.dart';
import 'nomo_avatar.dart';
import 'nomo_invite_success_burst.dart';
import 'nomo_themed_panel.dart';

class NomoFriendUserBlock extends StatelessWidget {
  const NomoFriendUserBlock({
    super.key,
    required this.friend,
    required this.statusLabel,
    required this.statusReason,
    required this.statusColor,
    required this.statusEnabled,
    required this.fallbackAvatar,
    this.onFavoriteToggle,
    this.onInvite,
    this.onTap,
    this.showFavorite = false,
    this.showInvite = false,
    this.compact = false,
  });

  final NomoFriend friend;
  final String statusLabel;
  final String statusReason;
  final Color statusColor;
  final bool statusEnabled;
  final NomoAvatar fallbackAvatar;
  final VoidCallback? onFavoriteToggle;
  final FutureOr<void> Function()? onInvite;
  final VoidCallback? onTap;
  final bool showFavorite;
  final bool showInvite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final accent = statusEnabled ? statusColor : const Color(0xFF2B3441);
    final ink = statusEnabled
        ? (isWhite ? const Color(0xFF101820) : Colors.white)
        : (isWhite ? const Color(0xFF667381) : const Color(0xFF8792A3));
    final avatarSize = compact ? 52.0 : 62.0;

    final block = ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 88 : 98),
      child: NomoThemedPanel(
        padding: EdgeInsets.fromLTRB(
          14,
          compact ? 9 : 10,
          14,
          compact ? 9 : 10,
        ),
        accentColor: accent,
        backgroundColor: isWhite
            ? Colors.white
            : AppColors.darkBackgroundBottom,
        borderRadius: 20,
        borderAlpha: statusEnabled
            ? (isWhite ? .34 : .42)
            : (isWhite ? .20 : .24),
        glowAlpha: statusEnabled
            ? (isWhite ? .09 : .18)
            : (isWhite ? .035 : .06),
        glowBlur: 24,
        glowOffset: const Offset(0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FriendBlockAvatarBubble(
              avatar: friend.avatar ?? fallbackAvatar,
              accent: accent,
              size: avatarSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          friend.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 18 : 20,
                            letterSpacing: -.4,
                          ),
                        ),
                      ),
                      if (showFavorite) ...[
                        const SizedBox(width: 9),
                        _FavoriteStarButton(
                          isFavorite: friend.isFavorite,
                          isWhite: isWhite,
                          onTap: onFavoriteToggle,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  _StatusPill(
                    label: statusLabel,
                    accent: accent,
                    enabled: statusEnabled,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 7),
                    Text(
                      statusReason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isWhite
                            ? const Color(0xFF667381)
                            : Colors.white.withValues(alpha: .62),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showInvite) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: NomoInviteSuccessBurst(
                  builder: (context, runWithBurst) => Nomo3DButton(
                    label: '誘う',
                    icon: CupertinoIcons.paperplane_fill,
                    onTap: statusEnabled ? () => runWithBurst(onInvite) : null,
                    enabled: statusEnabled,
                    height: 36,
                    radius: 18,
                    color: accent,
                    foregroundColor: statusEnabled
                        ? const Color(0xFF071320)
                        : const Color(0xFF738092),
                    shadowColor: statusEnabled
                        ? Color.lerp(accent, Colors.black, .32)
                        : const Color(0xFF111923),
                    disabledColor: const Color(0xFF2B3441),
                    disabledOpacity: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return block;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: block,
    );
  }
}

class _FriendBlockAvatarBubble extends StatelessWidget {
  const _FriendBlockAvatarBubble({
    required this.avatar,
    required this.accent,
    required this.size,
  });

  final NomoAvatar avatar;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: isWhite ? .22 : .30),
        border: Border.all(
          color: isWhite
              ? Colors.white.withValues(alpha: .86)
              : const Color(0xFF072130),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .10 : .24),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _FriendAvatarBubbleBackground(avatar: avatar),
            Center(
              child: Transform.translate(
                offset: const Offset(0, 5),
                child: NomoAvatarView(
                  avatar: avatar,
                  size: size - 6,
                  showBody: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatarBubbleBackground extends StatelessWidget {
  const _FriendAvatarBubbleBackground({required this.avatar});

  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final colors =
        NomoAvatar.backgroundGradients[avatar.background %
            NomoAvatar.backgroundGradients.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.accent,
    required this.enabled,
  });

  final String label;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: enabled ? .22 : .38),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: enabled ? accent : const Color(0xFF738092),
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    ),
  );
}

class _FavoriteStarButton extends StatelessWidget {
  const _FavoriteStarButton({
    required this.isFavorite,
    required this.isWhite,
    required this.onTap,
  });

  final bool isFavorite;
  final bool isWhite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Icon(
            isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
            color: isFavorite
                ? const Color(0xFFFFC700)
                : (isWhite ? const Color(0xFF8C9CAB) : const Color(0xFF8792A3)),
            size: 22,
          ),
        ),
      ),
    ),
  );
}
