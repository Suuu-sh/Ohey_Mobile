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
  const _ProfileHeaderBackdrop({required this.isWhite, required this.avatar});

  final bool isWhite;
  final NomoAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final displayAvatar = avatar ?? NomoAvatar.defaultAvatar;
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
          opacity: displayAvatar.background == 0 ? (isWhite ? .36 : .62) : .22,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_mascot_backdrop_scene.png',
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
                Colors.white.withValues(alpha: isWhite ? .22 : .08),
                Colors.white.withValues(alpha: isWhite ? .30 : .16),
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

class _ProfileMoodCta extends StatelessWidget {
  const _ProfileMoodCta({required this.status, required this.onTap});

  final NomoDailyStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = status == NomoDailyStatus.unselected
        ? CupertinoIcons.smiley
        : _statusIcon(status);

    return Nomo3DButtonSurface(
      onTap: onTap,
      height: 60,
      radius: 20,
      color: color,
      outerShadows: const <BoxShadow>[],
      padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
      child: Row(
        children: [
          _ProfileMoodCtaIcon(
            icon: icon,
            color: status == NomoDailyStatus.unselected ? Colors.white : color,
            muted: status == NomoDailyStatus.unselected,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status == NomoDailyStatus.unselected
                      ? 'ステータスを設定する'
                      : status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status == NomoDailyStatus.unselected
                      ? '未設定だと誘われにくいかも'
                      : 'フレンズが今日誘いやすくなります',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .70),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: -.1,
                  ),
                ),
              ],
            ),
          ),
          NomoPopIcon(
            icon: CupertinoIcons.chevron_right,
            color: Colors.white,
            foregroundColor: Colors.white,
            size: 28,
            iconSize: 24,
            showBubble: false,
            shadow: false,
          ),
        ],
      ),
    );
  }
}

class _ProfileMoodCtaIcon extends StatelessWidget {
  const _ProfileMoodCtaIcon({
    required this.icon,
    required this.color,
    required this.muted,
  });

  final IconData icon;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: muted
          ? Colors.white.withValues(alpha: .14)
          : Colors.white.withValues(alpha: .90),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: Colors.white.withValues(alpha: muted ? .18 : .34),
      ),
      boxShadow: muted
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
    ),
    child: Center(
      child: NomoPopIcon(
        icon: icon,
        color: color,
        size: 29,
        iconSize: 27,
        showBubble: false,
      ),
    ),
  );
}

class _ProfileActivityHome extends StatelessWidget {
  const _ProfileActivityHome({
    required this.isWhite,
    required this.logs,
    required this.photoLogs,
    required this.status,
    required this.onStatusTap,
    required this.onArchiveTap,
  });

  final bool isWhite;
  final List<DrinkLog> logs;
  final List<DrinkLog> photoLogs;
  final NomoDailyStatus status;
  final VoidCallback onStatusTap;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyLogs = logs.where((log) => log.isInMonth(now)).toList();
    final topFriends = _topProfileFriends(monthlyLogs);
    final recentLogs = logs.take(3).toList(growable: false);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 132),
      children: [
        Text(
          '飲み活動',
          style: TextStyle(
            color: isWhite ? const Color(0xFF17212B) : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                isWhite: isWhite,
                icon: CupertinoIcons.chart_bar_fill,
                color: AppColors.primaryAction,
                label: '今月の飲みログ',
                value: '${monthlyLogs.length}件',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatCard(
                isWhite: isWhite,
                icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                color: const Color(0xFFFF7AB8),
                label: '写真アーカイブ',
                value: '${photoLogs.length}枚',
                onTap: onArchiveTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileStatusHomeCard(
          isWhite: isWhite,
          status: status,
          onTap: onStatusTap,
        ),
        const SizedBox(height: 12),
        _ProfileTopFriendsCard(isWhite: isWhite, friends: topFriends),
        const SizedBox(height: 12),
        _ProfileRecentLogsCard(isWhite: isWhite, logs: recentLogs),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.isWhite,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final bool isWhite;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileActivityCard(
      isWhite: isWhite,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NomoPopIcon(icon: icon, color: color, size: 42, iconSize: 23),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isWhite ? const Color(0xFF17212B) : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isWhite
                  ? const Color(0xFF667381)
                  : Colors.white.withValues(alpha: .58),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusHomeCard extends StatelessWidget {
  const _ProfileStatusHomeCard({
    required this.isWhite,
    required this.status,
    required this.onTap,
  });

  final bool isWhite;
  final NomoDailyStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final unset = status == NomoDailyStatus.unselected;
    return _ProfileActivityCard(
      isWhite: isWhite,
      onTap: onTap,
      child: Row(
        children: [
          NomoPopIcon(
            icon: unset ? CupertinoIcons.smiley : _statusIcon(status),
            color: unset ? AppColors.primaryAction : color,
            size: 46,
            iconSize: 25,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unset ? 'ステータスを設定する' : status.label,
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF17212B) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unset
                      ? '未設定だと誘われにくいかも。今日誘いやすいかをフレンズに伝えましょう。'
                      : 'フレンズが今日誘いやすくなります。${status.description}',
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF667381)
                        : Colors.white.withValues(alpha: .58),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: isWhite
                ? const Color(0xFF98A3AF)
                : Colors.white.withValues(alpha: .44),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _ProfileTopFriendsCard extends StatelessWidget {
  const _ProfileTopFriendsCard({required this.isWhite, required this.friends});

  final bool isWhite;
  final List<_ProfileFriendCount> friends;

  @override
  Widget build(BuildContext context) {
    return _ProfileActivityCard(
      isWhite: isWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileActivitySectionTitle(
            isWhite: isWhite,
            title: 'よく飲むフレンズ',
            icon: CupertinoIcons.person_2_fill,
            color: AppColors.invite,
          ),
          const SizedBox(height: 12),
          if (friends.isEmpty)
            _ProfileActivityEmptyText(
              isWhite: isWhite,
              text: 'フレンズと飲みログを残すと、ここに表示されます。',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in friends)
                  _ProfileFriendChip(isWhite: isWhite, item: item),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileRecentLogsCard extends StatelessWidget {
  const _ProfileRecentLogsCard({required this.isWhite, required this.logs});

  final bool isWhite;
  final List<DrinkLog> logs;

  @override
  Widget build(BuildContext context) {
    return _ProfileActivityCard(
      isWhite: isWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileActivitySectionTitle(
            isWhite: isWhite,
            title: '最近の飲みログ',
            icon: CupertinoIcons.clock_fill,
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            _ProfileActivityEmptyText(
              isWhite: isWhite,
              text: '飲みログを残すと、最近の活動がここに並びます。',
            )
          else
            for (var i = 0; i < logs.length; i++) ...[
              _ProfileRecentLogRow(isWhite: isWhite, log: logs[i]),
              if (i != logs.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ProfileActivityCard extends StatelessWidget {
  const _ProfileActivityCard({
    required this.isWhite,
    required this.child,
    this.onTap,
  });

  final bool isWhite;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE0E6ED)
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: isWhite
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
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

class _ProfileActivitySectionTitle extends StatelessWidget {
  const _ProfileActivitySectionTitle({
    required this.isWhite,
    required this.title,
    required this.icon,
    required this.color,
  });

  final bool isWhite;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NomoGeneratedIcon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isWhite ? const Color(0xFF17212B) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileActivityEmptyText extends StatelessWidget {
  const _ProfileActivityEmptyText({required this.isWhite, required this.text});

  final bool isWhite;
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: isWhite
          ? const Color(0xFF667381)
          : Colors.white.withValues(alpha: .58),
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.4,
    ),
  );
}

class _ProfileFriendChip extends StatelessWidget {
  const _ProfileFriendChip({required this.isWhite, required this.item});

  final bool isWhite;
  final _ProfileFriendCount item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: isWhite
          ? const Color(0xFFF6F8FA)
          : Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: isWhite
            ? const Color(0xFFE0E6ED)
            : Colors.white.withValues(alpha: .10),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NomoAvatarView(
          avatar: item.friend.avatar ?? NomoAvatar.defaultAvatar,
          size: 24,
        ),
        const SizedBox(width: 7),
        Text(
          '${item.friend.name} ${item.count}回',
          style: TextStyle(
            color: isWhite ? const Color(0xFF17212B) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ProfileRecentLogRow extends StatelessWidget {
  const _ProfileRecentLogRow({required this.isWhite, required this.log});

  final bool isWhite;
  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final title = log.place.trim().isNotEmpty
        ? log.place.trim()
        : log.memo.trim().isNotEmpty
        ? log.memo.trim()
        : '飲みログ';
    final subtitle = log.friends.isEmpty
        ? _profileDateLabel(log.date)
        : log.friendNames;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryAction.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: NomoGeneratedIcon(
            (log.photoAssetPath ?? '').trim().isEmpty
                ? CupertinoIcons.doc_text_fill
                : CupertinoIcons.photo_fill,
            color: AppColors.primaryAction,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isWhite ? const Color(0xFF17212B) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isWhite
                      ? const Color(0xFF667381)
                      : Colors.white.withValues(alpha: .58),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          _profileShortDateLabel(log.date),
          style: TextStyle(
            color: isWhite
                ? const Color(0xFF98A3AF)
                : Colors.white.withValues(alpha: .44),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileFriendCount {
  const _ProfileFriendCount({required this.friend, required this.count});

  final NomoFriend friend;
  final int count;
}

List<_ProfileFriendCount> _topProfileFriends(List<DrinkLog> logs) {
  final counts = <String, ({NomoFriend friend, int count})>{};
  for (final log in logs) {
    for (final friend in log.friends) {
      final current = counts[friend.id];
      counts[friend.id] = (friend: friend, count: (current?.count ?? 0) + 1);
    }
  }
  final result = counts.values
      .map(
        (entry) =>
            _ProfileFriendCount(friend: entry.friend, count: entry.count),
      )
      .toList(growable: false);
  result.sort((a, b) => b.count.compareTo(a.count));
  return result.take(3).toList(growable: false);
}

String _profileDateLabel(DateTime date) =>
    '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _profileShortDateLabel(DateTime date) => '${date.month}/${date.day}';
