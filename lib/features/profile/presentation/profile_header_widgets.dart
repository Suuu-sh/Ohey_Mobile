part of 'profile_screen.dart';

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isWhite,
    required this.canOpenAdmin,
    required this.onSettings,
    required this.onAdmin,
  });

  final bool isWhite;
  final bool canOpenAdmin;
  final VoidCallback onSettings;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    final headerColor = isWhite ? const Color(0xFF101820) : Colors.white;
    return OheyPageHeader(
      title: 'マイページ',
      titleColor: headerColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOpenAdmin) ...[
            _ProfileAdminButton(isWhite: isWhite, onTap: onAdmin),
            const SizedBox(width: 2),
          ],
          _ProfileSettingsButton(isWhite: isWhite, onTap: onSettings),
        ],
      ),
    );
  }
}

class _ProfileAdminButton extends StatelessWidget {
  const _ProfileAdminButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '管理画面',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: OheyGeneratedIcon(
              CupertinoIcons.lock_shield_fill,
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsButton extends StatelessWidget {
  const _ProfileSettingsButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '設定',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: OheyGeneratedIcon(
              CupertinoIcons.gear_alt,
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderBackdrop extends StatelessWidget {
  const _ProfileHeaderBackdrop({required this.avatar});

  final OheyAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final displayAvatar = avatar ?? OheyAvatar.defaultAvatar;
    final imageBackdropAsset = OheyAvatar.imageBackdropAsset(
      displayAvatar.background,
    );
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
        OheyAvatar.backgroundGradients[displayAvatar.background %
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
          opacity: displayAvatar.background == OheyAvatar.dreamRoomBackground
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
                Colors.white.withValues(alpha: .18),
                Colors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTopSheet extends StatelessWidget {
  const _ProfileTopSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        OheyPageHeader.horizontalPadding,
        4,
        OheyPageHeader.horizontalPadding,
        6,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: child,
    );
  }
}

class _SimpleHero extends StatelessWidget {
  const _SimpleHero({
    required this.isWhite,
    required this.name,
    required this.avatar,
  });

  final bool isWhite;
  final String name;
  final OheyAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final joinedMonth = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    final displayAvatar = avatar ?? OheyAvatar.defaultAvatar;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 166,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: OheyAvatarView(avatar: displayAvatar, size: 156),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
            color: AppColors.darkBackgroundBottom,
            child: Center(
              child: Text(
                '$name ・ $joinedMonth 参加',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .72),
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

class _ProfileReservationStrip extends StatelessWidget {
  const _ProfileReservationStrip({
    required this.isWhite,
    required this.userAvatar,
    required this.currentUserId,
    required this.reservations,
    required this.incomingInvites,
    required this.onAccept,
    required this.onReject,
  });

  final bool isWhite;
  final OheyAvatar? userAvatar;
  final String? currentUserId;
  final List<OheyInvite> reservations;
  final List<OheyInvite> incomingInvites;
  final ValueChanged<OheyInvite> onAccept;
  final ValueChanged<OheyInvite> onReject;

  @override
  Widget build(BuildContext context) {
    if (incomingInvites.isNotEmpty) {
      final invite = incomingInvites.first;
      return _IncomingInviteCard(
        isWhite: isWhite,
        invite: invite,
        currentUserId: currentUserId,
        onAccept: () => onAccept(invite),
        onReject: () => onReject(invite),
      );
    }
    if (reservations.isEmpty || currentUserId == null) {
      return const SizedBox.shrink();
    }

    final reservedFriends = reservations
        .map((invite) => invite.otherUser(currentUserId!))
        .toList(growable: false);
    final friendText = reservedFriends.isEmpty
        ? '予定が成立しています'
        : '${reservedFriends.first.name}${reservedFriends.length > 1 ? 'ほか${reservedFriends.length - 1}人' : ''}との予定があります';
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFFF6FFF2) : const Color(0xFF102614),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.success.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: isWhite ? .16 : .22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.checkmark_seal_fill,
            color: AppColors.success,
            size: 44,
            iconSize: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '今日の予定あり',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  friendText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF27313B) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  child: _ReservedAvatar(avatar: userAvatar, label: '自分'),
                ),
                for (var i = 0; i < reservedFriends.length.clamp(0, 2); i++)
                  Positioned(
                    left: 40 + i * 32,
                    child: _ReservedAvatar(
                      avatar: reservedFriends[i].avatar,
                      label: reservedFriends[i].name,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingInviteCard extends StatelessWidget {
  const _IncomingInviteCard({
    required this.isWhite,
    required this.invite,
    required this.currentUserId,
    required this.onAccept,
    required this.onReject,
  });

  final bool isWhite;
  final OheyInvite invite;
  final String? currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final from = currentUserId == null
        ? invite.inviter
        : invite.otherUser(currentUserId!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFFFFF5F1) : const Color(0xFF2B1714),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primaryAction.withValues(alpha: .44),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAction.withValues(
              alpha: isWhite ? .16 : .24,
            ),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.bell_fill,
            color: AppColors.primaryAction,
            size: 44,
            iconSize: 23,
          ),
          const SizedBox(width: 10),
          _ReservedAvatar(avatar: from.avatar, label: from.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '返信待ち',
                  style: TextStyle(
                    color: AppColors.primaryAction,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${from.name}からお誘い',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF27313B) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '返事すると今日の予定に追加されます',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF6D7884)
                        : Colors.white.withValues(alpha: .62),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InviteResponseButton(
            label: '参加',
            color: AppColors.primaryAction,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _InviteResponseButton(
            label: 'あとで',
            color: isWhite
                ? Colors.white.withValues(alpha: .86)
                : Colors.white.withValues(alpha: .10),
            textColor: isWhite
                ? const Color(0xFF637181)
                : Colors.white.withValues(alpha: .70),
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _ReservedAvatar extends StatelessWidget {
  const _ReservedAvatar({required this.avatar, required this.label});

  final OheyAvatar? avatar;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF12283A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: OheyAvatarView(avatar: avatar ?? OheyAvatar.defaultAvatar),
      ),
    ),
  );
}

class _InviteResponseButton extends StatelessWidget {
  const _InviteResponseButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = const Color(0xFF06111D),
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _ProfileActivityHome extends StatelessWidget {
  const _ProfileActivityHome({
    required this.friendsCount,
    required this.wishItems,
    required this.isWishLoading,
    required this.onEditProfileTap,
    required this.onCreateYuruboTap,
    required this.onOpenWishListTap,
    required this.onAddFriendsTap,
  });

  final int friendsCount;
  final List<WishItem> wishItems;
  final bool isWishLoading;
  final VoidCallback onEditProfileTap;
  final VoidCallback onCreateYuruboTap;
  final VoidCallback onOpenWishListTap;
  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProfileSummaryStats(friendsCount: friendsCount),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProfileEditActionRow(onTap: onEditProfileTap),
          ),
          const SizedBox(height: 12),
          _ProfileWishListSection(
            wishItems: wishItems,
            isLoading: isWishLoading,
            onOpenTap: onOpenWishListTap,
          ),
          const SizedBox(height: 12),
          const _ProfileArchiveTopGlowLine(),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileYuruboActionRow(onTap: onCreateYuruboTap),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileFriendActionRow(
                    onAddFriendsTap: onAddFriendsTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileWishListSection extends StatelessWidget {
  const _ProfileWishListSection({
    required this.wishItems,
    required this.isLoading,
    required this.onOpenTap,
  });

  final List<WishItem> wishItems;
  final bool isLoading;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = isLoading && wishItems.isEmpty
        ? '読み込み中'
        : '${wishItems.length}件';
    final preview = wishItems.take(3).map((wish) => wish.title).join('・');
    final subtitle = preview.isEmpty ? '追加するとここに表示されます' : preview;
    const accent = Color(0xFF39C7FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundBottom,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFC08BFF).withValues(alpha: .42),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            OheyPopIcon(
              icon: CupertinoIcons.list_bullet,
              color: _ProfileColors.sub,
              size: 34,
              iconSize: 18,
              showBubble: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$countLabelのやりたいこと',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ProfileColors.sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 62,
              child: Ohey3DButton(
                label: '見る',
                onTap: onOpenTap,
                height: 34,
                radius: 17,
                color: accent,
                foregroundColor: const Color(0xFF101820),
                shadowColor: const Color(0xFF1699D6),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryStats extends StatelessWidget {
  const _ProfileSummaryStats({required this.friendsCount});

  final int friendsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 11),
      decoration: const BoxDecoration(color: AppColors.darkBackground),
      child: Row(
        children: [
          const Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.house_fill,
              iconColor: Color(0xFFC08BFF),
              value: '1',
              label: 'ルーム',
            ),
          ),
          const _ProfileStatsDivider(),
          Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.person_2_fill,
              iconColor: const Color(0xFFFF9BD5),
              value: '$friendsCount',
              label: 'フレンズ',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsDivider extends StatelessWidget {
  const _ProfileStatsDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    color: Colors.white.withValues(alpha: .18),
  );
}

class _ProfileStatGlyph extends StatelessWidget {
  const _ProfileStatGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: 25,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: .30),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
        Shadow(
          color: color.withValues(alpha: .52),
          blurRadius: 10,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }
}

class _ProfileSummaryStat extends StatelessWidget {
  const _ProfileSummaryStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileStatGlyph(icon: icon, color: iconColor),
            const SizedBox(width: 7),
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -.9,
                height: .95,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
      ],
    );
  }
}

class _ProfileEditActionRow extends StatelessWidget {
  const _ProfileEditActionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButton(
      label: 'プロフィールを編集',
      onTap: onTap,
      height: 48,
      radius: 24,
      color: AppColors.primaryAction,
      foregroundColor: const Color(0xFF101820),
      shadowColor: AppColors.primaryActionShadow,
      fontSize: 18,
      customIcon: const OheyPopIcon(
        icon: CupertinoIcons.pencil,
        color: Color(0xFF101820),
        size: 32,
        iconSize: 18,
      ),
      trailing: const OheyGeneratedIcon(
        CupertinoIcons.chevron_forward,
        color: Color(0xFF101820),
        size: 22,
      ),
    );
  }
}

class _ProfileYuruboActionRow extends StatelessWidget {
  const _ProfileYuruboActionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 46,
      radius: 20,
      color: const Color(0xFFC08BFF),
      bottomColor: const Color(0xFF7F51C9),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: Colors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: const Color(0xFFC08BFF).withValues(alpha: .18),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          const OheyPopIcon(
            icon: CupertinoIcons.plus_bubble_fill,
            color: Color(0xFF101820),
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ゆるぼを追加',
              style: TextStyle(
                color: Color(0xFF101820),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: Color(0xFF101820),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileFriendActionRow extends StatelessWidget {
  const _ProfileFriendActionRow({required this.onAddFriendsTap});

  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButtonSurface(
      onTap: onAddFriendsTap,
      height: 46,
      radius: 20,
      color: const Color(0xFF9AF21A),
      bottomColor: const Color(0xFF5DC86C),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: Colors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: const Color(0xFF9AF21A).withValues(alpha: .18),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          const OheyPopIcon(
            icon: CupertinoIcons.person_2_fill,
            color: Color(0xFF101820),
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'フレンズを追加',
              style: TextStyle(
                color: Color(0xFF101820),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: Color(0xFF101820),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileArchiveTopGlowLine extends StatelessWidget {
  const _ProfileArchiveTopGlowLine();

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF75B5);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: pink.withValues(alpha: .72),
        boxShadow: [
          BoxShadow(
            color: pink.withValues(alpha: .34),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: pink.withValues(alpha: .24),
            blurRadius: 34,
            spreadRadius: 4,
            offset: const Offset(0, -7),
          ),
        ],
      ),
    );
  }
}

bool _isProfileDisplayablePhoto(Memory memory) =>
    _profileMemoryImageProvider(memory.photoAssetPath) != null;

ImageProvider<Object>? _profileMemoryImageProvider(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized.startsWith('ohey_memory_template_')) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }
  if (normalized.startsWith('/')) {
    final file = File(normalized);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }
  if (normalized.startsWith('assets/')) return AssetImage(normalized);
  return null;
}
