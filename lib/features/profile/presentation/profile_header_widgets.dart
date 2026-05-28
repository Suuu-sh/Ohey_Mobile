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
    return NomoPageHeader(
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
            child: NomoGeneratedIcon(
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
            child: NomoGeneratedIcon(
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

  final NomoAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final displayAvatar = avatar ?? NomoAvatar.defaultAvatar;
    if (NomoAvatar.usesMascotBackdrop(displayAvatar.background)) {
      return ExcludeSemantics(
        child: Image.asset(
          'assets/images/profile_mascot_backdrop_scene.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }

    final backgroundColors =
        NomoAvatar.backgroundGradients[displayAvatar.background %
            NomoAvatar.backgroundGradients.length];
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
          opacity: displayAvatar.background == NomoAvatar.dreamRoomBackground
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
        NomoPageHeader.horizontalPadding,
        4,
        NomoPageHeader.horizontalPadding,
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
  final NomoAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final joinedMonth = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    final displayAvatar = avatar ?? NomoAvatar.defaultAvatar;
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
              child: NomoAvatarView(avatar: displayAvatar, size: 156),
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
  final NomoAvatar? userAvatar;
  final String? currentUserId;
  final List<NomoDrinkInvite> reservations;
  final List<NomoDrinkInvite> incomingInvites;
  final ValueChanged<NomoDrinkInvite> onAccept;
  final ValueChanged<NomoDrinkInvite> onReject;

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
          NomoPopIcon(
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
  final NomoDrinkInvite invite;
  final String? currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final from = currentUserId == null
        ? invite.fromUser
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
          NomoPopIcon(
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

  final NomoAvatar? avatar;
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
        child: NomoAvatarView(avatar: avatar ?? NomoAvatar.defaultAvatar),
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
    required this.profileName,
    required this.logs,
    required this.photoLogs,
    required this.friendsCount,
    required this.onLogsTap,
    required this.onArchiveTap,
    required this.onAddFriendsTap,
  });

  final String profileName;
  final List<DrinkLog> logs;
  final List<DrinkLog> photoLogs;
  final int friendsCount;
  final VoidCallback onLogsTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    final joinedMonth = _profileJoinedMonth(DateTime.now());
    final recentLogs = logs.take(2).toList(growable: false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSummaryStats(
            friendsCount: friendsCount,
            logCount: logs.length,
          ),
          const SizedBox(height: 8),
          _ProfileFriendActionRow(onAddFriendsTap: onAddFriendsTap),
          const SizedBox(height: 8),
          _ProfileInfoCard(profileName: profileName, joinedMonth: joinedMonth),
          const SizedBox(height: 8),
          _ProfileRecentMemoriesCard(
            logs: recentLogs,
            photoLogCount: photoLogs.length,
            onLogsTap: onLogsTap,
            onArchiveTap: onArchiveTap,
            onAddFriendsTap: onAddFriendsTap,
          ),
        ],
      ),
    );
  }
}

String _profileJoinedMonth(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}';

class _ProfileSummaryStats extends StatelessWidget {
  const _ProfileSummaryStats({
    required this.friendsCount,
    required this.logCount,
  });

  final int friendsCount;
  final int logCount;

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
          const _ProfileStatsDivider(),
          Expanded(
            child: _ProfileSummaryStat(
              icon: CupertinoIcons.star_fill,
              iconColor: const Color(0xFFFFD84E),
              value: '$logCount',
              label: '思い出',
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

class _ProfileFriendActionRow extends StatelessWidget {
  const _ProfileFriendActionRow({required this.onAddFriendsTap});

  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Nomo3DButton(
      label: 'フレンズを追加',
      onTap: onAddFriendsTap,
      height: 48,
      radius: 24,
      color: AppColors.primaryAction,
      shadowColor: AppColors.primaryActionShadow,
      fontSize: 18,
      customIcon: const NomoPopIcon(
        icon: CupertinoIcons.person_2_fill,
        color: Colors.white,
        size: 32,
        iconSize: 18,
      ),
      trailing: const NomoGeneratedIcon(
        CupertinoIcons.chevron_forward,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.profileName,
    required this.joinedMonth,
  });

  final String profileName;
  final String joinedMonth;

  @override
  Widget build(BuildContext context) {
    return NomoThemedPanel(
      accentColor: _ProfileColors.pink,
      backgroundColor: AppColors.darkBackground,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      borderRadius: 24,
      borderAlpha: .28,
      glowAlpha: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.person_fill,
                color: Color(0xFFFF8AD1),
                size: 27,
                iconSize: 16,
              ),
              SizedBox(width: 7),
              Text(
                'プロフィール',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _ProfileInfoLine(
            icon: CupertinoIcons.smiley_fill,
            iconColor: const Color(0xFFFF8AD1),
            label: 'なまえ',
            value: profileName,
          ),
          const SizedBox(height: 5),
          _ProfileInfoLine(
            icon: CupertinoIcons.calendar,
            iconColor: const Color(0xFFC08BFF),
            label: '参加日',
            value: '$joinedMonth 参加',
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoLine extends StatelessWidget {
  const _ProfileInfoLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(12, 3, 10, 3),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .16),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: .20)),
            ),
            child: Center(
              child: NomoGeneratedIcon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
          ),
          const SizedBox(width: 7),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_forward,
            color: Colors.white.withValues(alpha: .65),
            size: 17,
          ),
        ],
      ),
    );
  }
}

class _ProfileRecentMemoriesCard extends StatelessWidget {
  const _ProfileRecentMemoriesCard({
    required this.logs,
    required this.photoLogCount,
    required this.onLogsTap,
    required this.onArchiveTap,
    required this.onAddFriendsTap,
  });

  final List<DrinkLog> logs;
  final int photoLogCount;
  final VoidCallback onLogsTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    final firstLog = logs.isNotEmpty ? logs[0] : null;
    final secondLog = logs.length > 1 ? logs[1] : null;
    final openAll = photoLogCount > 0 ? onArchiveTap : onLogsTap;

    return NomoThemedPanel(
      accentColor: _ProfileColors.pink,
      backgroundColor: AppColors.darkBackground,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      borderRadius: 24,
      borderAlpha: .28,
      glowAlpha: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NomoPopIcon(
                icon: CupertinoIcons.sparkles,
                color: Color(0xFFFF75B5),
                size: 27,
                iconSize: 15,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '最近の思い出',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                    height: 1,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openAll,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'すべて見る',
                        style: TextStyle(
                          color: Color(0xFFFF86C8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 4),
                      NomoGeneratedIcon(
                        CupertinoIcons.chevron_forward,
                        color: Color(0xFFFF86C8),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ProfileMemoryPreviewTile(
                  log: firstLog,
                  fallbackTitle: 'はじめての思い出',
                  imageAlignment: Alignment.centerLeft,
                  onTap: firstLog == null ? onLogsTap : openAll,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileMemoryPreviewTile(
                  log: secondLog,
                  fallbackTitle: 'また遊ぼう',
                  imageAlignment: Alignment.centerRight,
                  onTap: secondLog == null ? onLogsTap : openAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ProfileMemoryHintCard(onTap: onAddFriendsTap),
        ],
      ),
    );
  }
}

class _ProfileMemoryPreviewTile extends StatelessWidget {
  const _ProfileMemoryPreviewTile({
    required this.log,
    required this.fallbackTitle,
    required this.imageAlignment,
    required this.onTap,
  });

  final DrinkLog? log;
  final String fallbackTitle;
  final Alignment imageAlignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = log == null ? fallbackTitle : _profileMemoryTitle(log!);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/profile_mascot_backdrop_scene.png',
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground.withValues(alpha: .08),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD84E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD84E).withValues(alpha: .30),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: NomoGeneratedIcon(
                        CupertinoIcons.star_fill,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMemoryHintCard extends StatelessWidget {
  const _ProfileMemoryHintCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Nomo3DButtonSurface(
      onTap: onTap,
      height: 48,
      radius: 22,
      color: AppColors.darkBackground,
      bottomColor: const Color(0xFF09131D),
      useGradient: false,
      padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
      borderColor: Colors.white.withValues(alpha: .12),
      outerShadows: const [],
      child: Row(
        children: [
          const NomoPopIcon(
            icon: CupertinoIcons.sparkles,
            color: Colors.white,
            size: 30,
            iconSize: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '思い出をふやそう',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                Text(
                  'フレンズと遊ぶとここに残るよ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_forward,
            color: Colors.white.withValues(alpha: .72),
            size: 17,
          ),
        ],
      ),
    );
  }
}

String _profileMemoryTitle(DrinkLog log) {
  final place = log.place.trim();
  if (place.isNotEmpty) return place;
  final memo = log.memo.trim();
  if (memo.isNotEmpty) return memo;
  return '思い出';
}
