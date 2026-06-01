import 'package:flutter/material.dart';

import '../models/ohey_avatar.dart';
import '../theme/app_colors.dart';
import 'ohey_avatar.dart';

class OheyProfileHeaderBackdrop extends StatelessWidget {
  const OheyProfileHeaderBackdrop({super.key, required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final imageBackdropAsset = OheyAvatar.imageBackdropAsset(avatar.background);
    if (imageBackdropAsset != null) {
      return ExcludeSemantics(
        child: Image.asset(
          imageBackdropAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }

    final backgroundColors =
        OheyAvatar.backgroundGradients[avatar.background %
            OheyAvatar.backgroundGradients.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors,
            ),
          ),
        ),
        Opacity(
          opacity: avatar.background == OheyAvatar.dreamRoomBackground
              ? .18
              : .10,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_header_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: .18),
                AppColors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
      ],
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
            color: AppColors.darkBackgroundBottom,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: .72),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
