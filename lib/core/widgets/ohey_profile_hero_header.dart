import 'package:flutter/material.dart';

import '../models/ohey_avatar.dart';
import '../theme/app_colors.dart';
import 'ohey_avatar.dart';
import 'ohey_themed_panel.dart';

/// Flat band behind a profile avatar, tinted by the user's background style.
class OheyProfileHeaderBackdrop extends StatelessWidget {
  const OheyProfileHeaderBackdrop({super.key, required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: OheyAvatar.backgroundColor(avatar.background));
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: oheyChunkyBorder(AppColors.chunkyBorderLight),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.cFF3C3C3C,
              fontWeight: FontWeight.w900,
              letterSpacing: -.2,
            ),
          ),
        ),
      ],
    );
  }
}
