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
        NomoPageHeader.topPadding,
        NomoPageHeader.horizontalPadding,
        18,
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
            height: 196,
            child: Center(
              child: NomoAvatarView(avatar: displayAvatar, size: 194),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
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
        ? '飲み予定が成立しています'
        : '${reservedFriends.first.name}${reservedFriends.length > 1 ? 'ほか${reservedFriends.length - 1}人' : ''}との飲み予定があります';
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
                  '${from.name}から飲みのお誘い',
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
    required this.isWhite,
    required this.logs,
    required this.photoLogs,
    required this.friendsCount,
    required this.status,
    required this.onStatusTap,
    required this.onLogsTap,
    required this.onArchiveTap,
    required this.onAddFriendsTap,
  });

  final bool isWhite;
  final List<DrinkLog> logs;
  final List<DrinkLog> photoLogs;
  final int friendsCount;
  final NomoDailyStatus status;
  final VoidCallback onStatusTap;
  final VoidCallback onLogsTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onAddFriendsTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyLogs = logs.where((log) => log.isInMonth(now)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSummaryStats(
            friendsCount: friendsCount,
            logCount: logs.length,
          ),
          const SizedBox(height: 18),
          _ProfileFriendActionRow(onAddFriendsTap: onAddFriendsTap),
          const SizedBox(height: 46),
          _ProfileLearningStatus(
            status: status,
            monthlyLogCount: monthlyLogs.length,
            photoLogCount: photoLogs.length,
            onStatusTap: onStatusTap,
            onLogsTap: onLogsTap,
            onArchiveTap: onArchiveTap,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ProfileSummaryStats extends StatelessWidget {
  const _ProfileSummaryStats({
    required this.friendsCount,
    required this.logCount,
  });

  final int friendsCount;
  final int logCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _ProfileSummaryStat(
            icon: Icons.local_bar_rounded,
            value: '',
            label: 'コース',
            showIconOnly: true,
          ),
        ),
        Expanded(
          child: _ProfileSummaryStat(value: '$friendsCount', label: 'フレンズ'),
        ),
        Expanded(
          child: _ProfileSummaryStat(value: '$logCount', label: 'ログ回数'),
        ),
      ],
    );
  }
}

class _ProfileSummaryStat extends StatelessWidget {
  const _ProfileSummaryStat({
    required this.value,
    required this.label,
    this.icon,
    this.showIconOnly = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final bool showIconOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 38,
          child: Center(
            child: showIconOnly
                ? NomoPopIcon(
                    icon: icon ?? Icons.local_bar_rounded,
                    color: const Color(0xFF20DDBF),
                    size: 38,
                    iconSize: 21,
                  )
                : Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .48),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
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
    return Row(
      children: [
        Expanded(
          child: _ProfileOutlineButton(
            onTap: onAddFriendsTap,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NomoGeneratedIcon(
                  CupertinoIcons.person_badge_plus_fill,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  '友達を追加',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOutlineButton extends StatelessWidget {
  const _ProfileOutlineButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF53606B).withValues(alpha: .82),
            width: 2.4,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _ProfileLearningStatus extends StatelessWidget {
  const _ProfileLearningStatus({
    required this.status,
    required this.monthlyLogCount,
    required this.photoLogCount,
    required this.onStatusTap,
    required this.onLogsTap,
    required this.onArchiveTap,
  });

  final NomoDailyStatus status;
  final int monthlyLogCount;
  final int photoLogCount;
  final VoidCallback onStatusTap;
  final VoidCallback onLogsTap;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    final unset = status == NomoDailyStatus.unselected;
    final statusLabel = unset ? '未設定' : status.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学習状況',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .48),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _ProfileLearningItem(
                icon: CupertinoIcons.drop_fill,
                iconColor: Colors.white.withValues(alpha: .46),
                text: '$monthlyLogCount日',
                muted: true,
                onTap: onLogsTap,
              ),
            ),
            Expanded(
              child: _ProfileLearningItem(
                icon: CupertinoIcons.bolt_fill,
                iconColor: const Color(0xFFFFD60A),
                text: '${monthlyLogCount * 120} XP',
                onTap: onLogsTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _ProfileLearningItem(
                icon: unset ? CupertinoIcons.smiley : _statusIcon(status),
                iconColor: unset
                    ? const Color(0xFF28B9FF)
                    : _statusColor(status),
                text: statusLabel,
                onTap: onStatusTap,
              ),
            ),
            Expanded(
              child: _ProfileLearningItem(
                icon: CupertinoIcons.rosette,
                iconColor: const Color(0xFFFFD60A),
                text: '写真 $photoLogCount枚',
                onTap: onArchiveTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileLearningItem extends StatelessWidget {
  const _ProfileLearningItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NomoGeneratedIcon(icon, color: iconColor, size: 25),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: muted ? .52 : .92),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActivityCard extends StatelessWidget {
  const _ProfileActivityCard({
    required this.isWhite,
    required this.child,
    required this.height,
    this.borderRadius = 30,
    this.onTap,
  });

  final bool isWhite;
  final Widget child;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081724), Color(0xFF06111C)],
        ),
        border: Border.all(
          color: _ProfileColors.pink.withValues(alpha: isWhite ? .22 : .18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .08 : .20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _ProfileColors.pink.withValues(alpha: isWhite ? .05 : .08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
