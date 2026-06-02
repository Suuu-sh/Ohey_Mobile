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
    final headerColor = isWhite ? AppColors.cFF101820 : AppColors.white;
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
              color: isWhite ? AppColors.cFF101820 : AppColors.white,
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
              color: isWhite ? AppColors.cFF101820 : AppColors.white,
              size: 38,
            ),
          ),
        ),
      ),
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
        color: AppColors.transparent,
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
    return OheyProfileHeroBanner(
      avatar: avatar ?? OheyAvatar.defaultAvatar,
      label: '$name ・ $joinedMonth 参加',
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
        color: isWhite ? AppColors.cFFF6FFF2 : AppColors.cFF102614,
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
                    color: isWhite ? AppColors.cFF27313B : AppColors.white,
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
        color: isWhite ? AppColors.cFFFFF5F1 : AppColors.cFF2B1714,
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
                    color: isWhite ? AppColors.cFF27313B : AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '返事すると${invite.summary()}に参加します',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? AppColors.cFF6D7884
                        : AppColors.white.withValues(alpha: .62),
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
                ? AppColors.white.withValues(alpha: .86)
                : AppColors.white.withValues(alpha: .10),
            textColor: isWhite
                ? AppColors.cFF637181
                : AppColors.white.withValues(alpha: .70),
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
        color: AppColors.cFF12283A,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
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
    this.textColor = AppColors.cFF06111D,
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
    required this.joinedYurubos,
    required this.isYuruboLoading,
    required this.wishItems,
    required this.isWishLoading,
    required this.onCreateYuruboTap,
    required this.onOpenWishListTap,
    required this.onAddFriendsTap,
    required this.onChangeStatusTap,
  });

  final int friendsCount;
  final List<Yurubo> joinedYurubos;
  final bool isYuruboLoading;
  final List<WishItem> wishItems;
  final bool isWishLoading;
  final VoidCallback onCreateYuruboTap;
  final VoidCallback onOpenWishListTap;
  final VoidCallback onAddFriendsTap;
  final VoidCallback onChangeStatusTap;

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
          const SizedBox(height: 12),
          _ProfileTodayScheduleSection(
            joinedYurubos: joinedYurubos,
            isLoading: isYuruboLoading,
          ),
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
                  child: _ProfileStatusActionRow(onTap: onChangeStatusTap),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileWishListActionRow(
                    wishItems: wishItems,
                    isLoading: isWishLoading,
                    onTap: onOpenWishListTap,
                  ),
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

class _ProfileTodayScheduleSection extends StatelessWidget {
  const _ProfileTodayScheduleSection({
    required this.joinedYurubos,
    required this.isLoading,
  });

  final List<Yurubo> joinedYurubos;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final event = joinedYurubos.isEmpty ? null : joinedYurubos.first;
    const accent = AppColors.cFFFF75B5;
    final title = event == null
        ? (isLoading ? '読み込み中' : '本日の予定はありません')
        : event.title;
    final details = event == null
        ? ''
        : [event.timeLabel, event.placeText]
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join('・');
    final subtitle = details.isEmpty ? 'Oheyで参加した予定' : details;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundBottom,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: .58), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          '本日の予定',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (event != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: .08),
                          ),
                        ),
                        child: Text(
                          'Today · $subtitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ProfileColors.sub.withValues(alpha: .82),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _TodayScheduleParticipants(event: event, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayScheduleParticipants extends StatelessWidget {
  const _TodayScheduleParticipants({required this.event, required this.accent});

  final Yurubo? event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    if (event == null) {
      return OheyPopIcon(
        icon: CupertinoIcons.calendar_today,
        color: accent,
        size: 42,
        iconSize: 20,
        showBubble: false,
      );
    }

    final avatars = <OheyAvatar>[event.avatar];
    final seenUserIds = <String>{event.ownerUserId};
    for (final participant in event.participants) {
      if (seenUserIds.add(participant.userId)) {
        avatars.add(participant.avatar);
      }
    }

    final visibleAvatars = avatars.take(3).toList(growable: false);
    const avatarSize = 46.0;
    const overlap = 28.0;
    final width = avatarSize + (visibleAvatars.length - 1) * overlap;

    return SizedBox(
      width: width,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleAvatars.length; index++)
            Positioned(
              left: index * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkBackgroundBottom,
                  border: Border.all(
                    color: accent.withValues(alpha: .78),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .24),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: OheyAvatarView(
                  avatar: visibleAvatars[index],
                  size: avatarSize - 6,
                ),
              ),
            ),
        ],
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
              iconColor: AppColors.cFFC08BFF,
              value: '1',
              label: 'やりたいこと',
            ),
          ),
          const _ProfileStatsDivider(),
          Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.person_2_fill,
              iconColor: AppColors.cFFFF9BD5,
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
    color: AppColors.white.withValues(alpha: .18),
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
          color: AppColors.black.withValues(alpha: .30),
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
                color: AppColors.white,
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
            color: AppColors.white.withValues(alpha: .62),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
      ],
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
      color: AppColors.cFFC08BFF,
      bottomColor: AppColors.cFF7F51C9,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: AppColors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: AppColors.cFFC08BFF.withValues(alpha: .18),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.plus_bubble_fill,
            color: AppColors.cFF101820,
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ゆるぼを追加',
              style: TextStyle(
                color: AppColors.cFF101820,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: AppColors.cFF101820,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusActionRow extends StatelessWidget {
  const _ProfileStatusActionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 46,
      radius: 20,
      color: AppColors.cFFFF75B5,
      bottomColor: AppColors.cFFD4147C,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: AppColors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: AppColors.cFFFF75B5.withValues(alpha: .18),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          const OheyPopIcon(
            icon: CupertinoIcons.person_crop_circle_badge_checkmark,
            color: AppColors.cFF101820,
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ステータス変更',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.cFF101820,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: AppColors.cFF101820,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _ProfileWishListActionRow extends StatelessWidget {
  const _ProfileWishListActionRow({
    required this.wishItems,
    required this.isLoading,
    required this.onTap,
  });

  final List<WishItem> wishItems;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = isLoading && wishItems.isEmpty
        ? '読込中'
        : '${wishItems.length}件';
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 46,
      radius: 20,
      color: AppColors.cFF39C7FF,
      bottomColor: AppColors.cFF1699D6,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: AppColors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: AppColors.cFF39C7FF.withValues(alpha: .16),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          const OheyPopIcon(
            icon: CupertinoIcons.list_bullet,
            color: AppColors.cFF101820,
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'やりたいこと',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFF101820,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFF101820.withValues(alpha: .62),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: AppColors.cFF101820,
            size: 16,
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
      color: AppColors.cFF9AF21A,
      bottomColor: AppColors.cFF5DC86C,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: AppColors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: AppColors.cFF9AF21A.withValues(alpha: .18),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      child: Row(
        children: [
          const OheyPopIcon(
            icon: CupertinoIcons.person_2_fill,
            color: AppColors.cFF101820,
            size: 28,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'フレンズを追加',
              style: TextStyle(
                color: AppColors.cFF101820,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: AppColors.cFF101820,
            size: 18,
          ),
        ],
      ),
    );
  }
}
