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
    final headerColor = isWhite ? AppColors.cFF3C3C3C : AppColors.white;
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
              color: isWhite ? AppColors.cFF3C3C3C : AppColors.white,
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
              color: isWhite ? AppColors.cFF3C3C3C : AppColors.white,
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
        OheyPageHeader.topPadding,
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
    required this.currentProfileId,
    required this.reservations,
    required this.incomingInvites,
    required this.onAccept,
    required this.onReject,
  });

  final bool isWhite;
  final OheyAvatar? userAvatar;
  final String? currentProfileId;
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
        currentProfileId: currentProfileId,
        onAccept: () => onAccept(invite),
        onReject: () => onReject(invite),
      );
    }
    if (reservations.isEmpty || currentProfileId == null) {
      return const SizedBox.shrink();
    }

    final reservedFriends = reservations
        .map((invite) => invite.otherUser(currentProfileId!))
        .toList(growable: false);
    final friendText = reservedFriends.isEmpty
        ? '予定が成立しています'
        : '${reservedFriends.first.name}${reservedFriends.length > 1 ? 'ほか${reservedFriends.length - 1}人' : ''}との予定があります';
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF131F24,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.success.withValues(alpha: .42)),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  friendText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite ? AppColors.cFF2B3A41 : AppColors.white,
                    fontWeight: FontWeight.w700,
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
    required this.currentProfileId,
    required this.onAccept,
    required this.onReject,
  });

  final bool isWhite;
  final OheyInvite invite;
  final String? currentProfileId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final from = currentProfileId == null
        ? invite.inviter
        : invite.otherUser(currentProfileId!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF1A272D,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primaryAction.withValues(alpha: .44),
        ),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${from.name}からお誘い',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite ? AppColors.cFF2B3A41 : AppColors.white,
                    fontWeight: FontWeight.w700,
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
                        ? AppColors.cFF777777
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
                ? AppColors.cFF1899D6
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
        color: AppColors.cFF1A272D,
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
    this.textColor = AppColors.cFF131F24,
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
          fontWeight: FontWeight.w700,
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
    required this.isPlus,
    required this.onCreateYuruboTap,
    required this.onOpenYuruboTap,
    required this.onOpenWishListTap,
    required this.onAddFriendsTap,
    required this.onChangeStatusTap,
    required this.onPlusTap,
  });

  final int friendsCount;
  final List<Yurubo> joinedYurubos;
  final bool isYuruboLoading;
  final List<WishItem> wishItems;
  final bool isWishLoading;
  final bool isPlus;
  final VoidCallback onCreateYuruboTap;
  final VoidCallback? onOpenYuruboTap;
  final VoidCallback onOpenWishListTap;
  final VoidCallback onAddFriendsTap;
  final VoidCallback onChangeStatusTap;
  final VoidCallback onPlusTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProfileSummaryStats(
              wishItemsCount: wishItems.length,
              friendsCount: friendsCount,
            ),
          ),
          const SizedBox(height: 12),
          _ProfileTodayScheduleSection(
            joinedYurubos: joinedYurubos,
            isLoading: isYuruboLoading,
            isPlus: isPlus,
            onFindTap: onOpenYuruboTap ?? onCreateYuruboTap,
            onPlusTap: onPlusTap,
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
                  child: _ProfileFriendActionRow(
                    onAddFriendsTap: onAddFriendsTap,
                  ),
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
                  child: _ProfileStatusActionRow(onTap: onChangeStatusTap),
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
    required this.isPlus,
    required this.onFindTap,
    required this.onPlusTap,
  });

  final List<Yurubo> joinedYurubos;
  final bool isLoading;
  final bool isPlus;
  final VoidCallback onFindTap;
  final VoidCallback onPlusTap;

  @override
  Widget build(BuildContext context) {
    final event = joinedYurubos.isEmpty ? null : joinedYurubos.first;
    const accent = AppColors.cFFFF86C8;
    final showPlus = event == null && !isLoading && !isPlus;
    final title = event == null
        ? (isLoading ? '読み込み中' : (showPlus ? 'Ohey Plus' : '本日の予定はありません'))
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
        // Plus promo sits on the brand tint; a joined plan is a plain card.
        decoration: BoxDecoration(
          color: showPlus
              ? (OheyTone.of(context).isWhite
                    ? AppColors.brandTint
                    : AppColors.brand.withValues(alpha: .14))
              : OheyTone.of(context).page,
          borderRadius: BorderRadius.circular(20),
          border: oheyChunkyBorder(
            showPlus ? AppColors.cFFFFB8DD : OheyTone.of(context).edge,
          ),
        ),
        child: Stack(
          children: [
            Padding(
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
                            Text(
                              showPlus ? '広告を非表示' : '本日の予定',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: OheyTone.of(context).ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                          style: TextStyle(
                            color: OheyTone.of(context).muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                              color: OheyTone.of(context).field,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Today · $subtitle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ProfileColors.sub.withValues(
                                  alpha: .82,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (event == null)
                    SizedBox(
                      width: 82,
                      child: Ohey3DButton(
                        label: showPlus ? '詳細' : '探す',
                        onTap: isLoading
                            ? null
                            : (showPlus ? onPlusTap : onFindTap),
                        height: 42,
                        radius: 21,
                        color: AppColors.brand,
                        shadowColor: AppColors.brandLip,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        fontSize: 14,
                      ),
                    )
                  else
                    _TodayScheduleParticipants(event: event, accent: accent),
                ],
              ),
            ),
          ],
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
  const _ProfileSummaryStats({
    required this.wishItemsCount,
    required this.friendsCount,
  });

  final int wishItemsCount;
  final int friendsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 11),
      decoration: BoxDecoration(
        color: OheyTone.of(context).page,
        borderRadius: BorderRadius.circular(20),
        border: oheyChunkyBorder(OheyTone.of(context).edge),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.house_fill,
              iconColor: AppColors.cFFFF9600,
              value: '$wishItemsCount',
              label: 'やりたいこと',
            ),
          ),
          const _ProfileStatsDivider(),
          Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.person_2_fill,
              iconColor: AppColors.brand,
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
  Widget build(BuildContext context) =>
      Container(width: 2, height: 48, color: OheyTone.of(context).edge);
}

class _ProfileStatGlyph extends StatelessWidget {
  const _ProfileStatGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color, size: 25);
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
              style: TextStyle(
                color: OheyTone.of(context).ink,
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
            color: OheyTone.of(context).muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
      color: OheyTone.of(context).page,
      bottomColor: OheyTone.of(context).edge,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: OheyTone.of(context).edge,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ゆるぼ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OheyTone.of(context).ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: AppColors.brand,
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
      color: OheyTone.of(context).page,
      bottomColor: OheyTone.of(context).edge,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: OheyTone.of(context).edge,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '今日の予定',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OheyTone.of(context).ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: AppColors.brand,
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
      color: OheyTone.of(context).page,
      bottomColor: OheyTone.of(context).edge,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: OheyTone.of(context).edge,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'やりたいこと',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: OheyTone.of(context).ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                    color: OheyTone.of(context).ink.withValues(alpha: .62),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: AppColors.brand,
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
      color: OheyTone.of(context).page,
      bottomColor: OheyTone.of(context).edge,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: OheyTone.of(context).edge,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'フレンズを追加',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OheyTone.of(context).ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.plus,
            color: AppColors.brand,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileOheyPlusPurchaseSheet extends ConsumerStatefulWidget {
  const _ProfileOheyPlusPurchaseSheet();

  @override
  ConsumerState<_ProfileOheyPlusPurchaseSheet> createState() =>
      _ProfileOheyPlusPurchaseSheetState();
}

class _ProfileOheyPlusPurchaseSheetState
    extends ConsumerState<_ProfileOheyPlusPurchaseSheet> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final offeringAsync = ref.watch(oheyPlusOfferingProvider);
    final isPlusActive = ref.watch(oheyPlusActiveProvider);
    final service = ref.watch(oheyPlusServiceProvider);
    final offering = offeringAsync.asData?.value;
    final package = service.preferredPackage(offering);
    final product = package?.storeProduct;
    final priceLabel = product?.priceString.trim();
    final subscriptionPeriodLabel = oheySubscriptionPeriodLabel(
      product?.subscriptionPeriod,
    );
    final isRevenueCatReady = OheyRevenueCatConfig.isConfigured;
    final hasPrice = priceLabel?.isNotEmpty == true;
    final canPurchase =
        isRevenueCatReady &&
        !isPlusActive &&
        package != null &&
        hasPrice &&
        subscriptionPeriodLabel != null;

    final tone = OheyTone.of(context);
    final String? statusMessage;
    if (!isRevenueCatReady) {
      // The API-key hint is for developers only; users get a plain message.
      statusMessage = kDebugMode
          ? 'RevenueCat APIキー未設定（OHEY_REVENUECAT_IOS_API_KEY）'
          : '現在購入を受け付けていません';
    } else if (offeringAsync.isLoading) {
      statusMessage = 'プランを読み込み中...';
    } else if (offeringAsync.hasError || package == null) {
      statusMessage = 'プランを取得できませんでした。時間をおいて試してください。';
    } else if (!hasPrice || subscriptionPeriodLabel == null) {
      statusMessage = 'プランの価格・契約期間を確認できませんでした。時間をおいて試してください。';
    } else {
      statusMessage = null;
    }

    return OheyBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      radius: 30,
      showHandle: false,
      bottomCloseLabel: '閉じる',
      blurSigma: 0,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PlusHero(),
            const SizedBox(height: 18),
            _PlusPlanCard(
              isActive: isPlusActive,
              planTitle: product?.title.trim().isNotEmpty == true
                  ? product!.title
                  : 'Ohey Plus',
              priceLabel: priceLabel,
              subscriptionPeriodLabel: subscriptionPeriodLabel,
            ),
            const SizedBox(height: 14),
            _PlusCompareTable(tone: tone),
            if (priceLabel?.isNotEmpty == true &&
                subscriptionPeriodLabel != null) ...[
              const SizedBox(height: 12),
              Text(
                '購入確認時にApple Accountへ請求され、$subscriptionPeriodLabelに${priceLabel}で自動更新されます。次回の請求を止めるには、更新日前にApple Accountのサブスクリプション設定から解約してください。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tone.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],
            if (statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tone.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Ohey3DButton(
              label: isPlusActive
                  ? 'Plus利用中'
                  : _isPurchasing
                  ? '購入中...'
                  : 'Plusをはじめる',
              icon: isPlusActive ? CupertinoIcons.checkmark_seal_fill : null,
              onTap: canPurchase && !_isPurchasing
                  ? () => _purchase(package)
                  : null,
              disabledColor: tone.edge,
              height: 54,
              fontSize: 16,
            ),
            const SizedBox(height: 6),
            Center(
              child: CupertinoButton(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: _isRestoring ? null : _restore,
                child: Text(
                  _isRestoring ? '復元中...' : '購入を復元',
                  style: TextStyle(
                    color: tone.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () =>
                      _openOheyPlusLegalUrl(context, _oheyTermsUrl),
                  child: Text(
                    'Ohey利用規約',
                    style: TextStyle(
                      color: tone.muted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () =>
                      _openOheyPlusLegalUrl(context, _appleStandardEulaUrl),
                  child: Text(
                    'Apple標準EULA',
                    style: TextStyle(
                      color: tone.muted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text('・', style: TextStyle(color: tone.muted, fontSize: 12)),
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () =>
                      _openOheyPlusLegalUrl(context, _oheyPrivacyUrl),
                  child: Text(
                    'プライバシーポリシー',
                    style: TextStyle(
                      color: tone.muted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
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

  Future<void> _purchase(rc.Package package) async {
    setState(() => _isPurchasing = true);
    try {
      final info = await ref.read(oheyPlusServiceProvider).purchase(package);
      if (!mounted) return;
      if (OheyPlusService.hasPlusEntitlement(info)) {
        OheyToast.show(context, 'Ohey Plusが有効になりました');
        Navigator.of(context).pop();
      } else {
        OheyToast.show(context, '購入状態を確認できませんでした。少し待ってから復元を試してください。');
      }
    } catch (error) {
      if (!mounted) return;
      if (ref.read(oheyPlusServiceProvider).isCancellation(error)) return;
      OheyToast.show(context, '購入を開始できませんでした。あとでもう一度試してください。');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    try {
      final info = await ref.read(oheyPlusServiceProvider).restore();
      if (!mounted) return;
      if (OheyPlusService.hasPlusEntitlement(info)) {
        OheyToast.show(context, '購入を復元しました');
        Navigator.of(context).pop();
      } else {
        OheyToast.show(context, '復元できるOhey Plus購入が見つかりませんでした');
      }
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(context, '購入を復元できませんでした。あとでもう一度試してください。');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }
}

Future<void> _openOheyPlusLegalUrl(BuildContext context, String url) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (opened || !context.mounted) return;
  } catch (_) {
    if (!context.mounted) return;
  }
  OheyToast.show(context, 'ページを開けませんでした。時間をおいて試してください。');
}

const _appleStandardEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Brand-color band with the Plus mark, like a subscription page header.
class _PlusHero extends StatelessWidget {
  const _PlusHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(22),
        border: const Border(
          bottom: BorderSide(color: AppColors.brandLip, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OHEY PLUS',
                  style: TextStyle(
                    color: AppColors.cFFFFE3F0,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '広告なしで、\nもっとゆるく。',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: const Border(
                bottom: BorderSide(color: AppColors.brandLip, width: 4),
              ),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: AppColors.brand,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

/// The single plan, with a ribbon the way pricing cards mark a pick.
class _PlusPlanCard extends StatelessWidget {
  const _PlusPlanCard({
    required this.isActive,
    required this.planTitle,
    required this.priceLabel,
    required this.subscriptionPeriodLabel,
  });

  final bool isActive;
  final String planTitle;
  final String? priceLabel;
  final String? subscriptionPeriodLabel;

  @override
  Widget build(BuildContext context) {
    final tone = OheyTone.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tone.page,
        borderRadius: BorderRadius.circular(20),
        border: oheyChunkyBorder(AppColors.brand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.brand,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              isActive ? '利用中' : 'おすすめ',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tone.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ゆるぼ一覧の広告をすべて非表示',
                        style: TextStyle(
                          color: tone.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (priceLabel?.isNotEmpty == true)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceLabel!,
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (subscriptionPeriodLabel != null)
                        Text(
                          '/ $subscriptionPeriodLabel',
                          style: TextStyle(
                            color: tone.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Free vs Plus, listing only what actually differs today.
class _PlusCompareTable extends StatelessWidget {
  const _PlusCompareTable({required this.tone});

  final OheyTone tone;

  @override
  Widget build(BuildContext context) {
    Widget head(String label, {Color? color}) => SizedBox(
      width: 60,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? tone.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    Widget mark(bool on) => SizedBox(
      width: 60,
      child: Icon(
        on ? CupertinoIcons.checkmark_alt : CupertinoIcons.minus,
        color: on ? AppColors.brand : tone.faint,
        size: 20,
      ),
    );
    Widget row(String label, bool free, bool plus) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: tone.ink,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          mark(free),
          mark(plus),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      decoration: BoxDecoration(
        color: tone.page,
        borderRadius: BorderRadius.circular(20),
        border: oheyChunkyBorder(tone.edge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              head('無料'),
              head('Plus', color: AppColors.brand),
            ],
          ),
          row('ゆるぼ・フレンズ・カレンダー', true, true),
          Divider(height: 1, thickness: 2, color: tone.edge),
          row('広告なし', false, true),
        ],
      ),
    );
  }
}
