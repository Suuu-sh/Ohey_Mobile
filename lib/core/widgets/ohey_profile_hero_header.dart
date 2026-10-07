import 'package:flutter/material.dart';

import '../models/ohey_avatar.dart';
import '../theme/ohey_tone.dart';
import 'ohey_avatar.dart';
import 'ohey_themed_panel.dart';

/// Flat band behind a profile avatar, tinted by the user's background style.
class OheyProfileHeaderBackdrop extends StatelessWidget {
  const OheyProfileHeaderBackdrop({super.key, required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final tint = OheyAvatar.backgroundColor(avatar.background);
    final tone = OheyTone.of(context);
    // In dark mode the tint is laid thinly over the page so it stays dim.
    return ColoredBox(
      color: tone.isWhite
          ? tint
          : Color.alphaBlend(tint.withValues(alpha: .16), tone.page),
    );
  }
}

class OheyProfileHeroBanner extends StatelessWidget {
  const OheyProfileHeroBanner({
    super.key,
    required this.avatar,
    required this.label,
    this.avatarStageHeight = 190,
    this.avatarSize = 156,
  });

  final OheyAvatar avatar;
  final String label;
  final double avatarStageHeight;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: avatarStageHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: OheyAvatarView(avatar: avatar, size: avatarSize),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: OheyTone.of(context).page,
            borderRadius: BorderRadius.circular(18),
            border: oheyChunkyBorder(OheyTone.of(context).edge),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: OheyTone.of(context).ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -.2,
            ),
          ),
        ),
      ],
    );
  }
}
