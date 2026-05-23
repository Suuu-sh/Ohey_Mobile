part of 'profile_screen.dart';

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.canOpenAdmin,
    required this.onSettings,
    required this.onAdmin,
  });

  final bool canOpenAdmin;
  final VoidCallback onSettings;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    return NomoPageHeader(
      title: 'マイページ',
      titleColor: Colors.white,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOpenAdmin) ...[
            _ProfileAdminButton(onTap: onAdmin),
            const SizedBox(width: 2),
          ],
          _ProfileSettingsButton(onTap: onSettings),
        ],
      ),
    );
  }
}

class _ProfileAdminButton extends StatelessWidget {
  const _ProfileAdminButton({required this.onTap});

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
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsButton extends StatelessWidget {
  const _ProfileSettingsButton({required this.onTap});

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
              color: Colors.white,
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
        NomoPageHeader.horizontalPadding,
        NomoPageHeader.topPadding,
        NomoPageHeader.horizontalPadding,
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF03101E).withValues(alpha: .08),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFF06111D) : const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 196,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: isWhite ? .90 : .58,
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
                        colors: isWhite
                            ? [
                                const Color(0xFF101B28).withValues(alpha: .36),
                                const Color(0xFF06111D).withValues(alpha: .64),
                              ]
                            : [
                                const Color(0xFFFFFFFF).withValues(alpha: .22),
                                const Color(0xFFE7E4E0).withValues(alpha: .44),
                              ],
                      ),
                    ),
                  ),
                  Center(
                    child: NomoAvatarView(
                      avatar: avatar ?? NomoAvatar.defaultAvatar,
                      size: 194,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
            color: isWhite ? Colors.white : const Color(0xFF101D25),
            child: Center(
              child: Text(
                '$name ・ $joinedMonth 参加',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isWhite ? const Color(0xFF59636E) : _ProfileColors.sub,
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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF2F6FA)
            : Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE5EE)
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: isWhite
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _ReservedAvatar(avatar: userAvatar, label: '自分'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: _ProfileColors.lime,
              size: 22,
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < reservedFriends.length.clamp(0, 4); i++)
                  Positioned(
                    left: i * 34,
                    top: 10,
                    child: _ReservedAvatar(
                      avatar: reservedFriends[i].avatar,
                      label: reservedFriends[i].name,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '予約成立',
            style: TextStyle(
              color: isWhite ? const Color(0xFF27313B) : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
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
        color: isWhite ? const Color(0xFFF2F6FA) : const Color(0xFF102336),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE5EE)
              : _ProfileColors.lime.withValues(alpha: .22),
        ),
        boxShadow: isWhite
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _ReservedAvatar(avatar: from.avatar, label: from.name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${from.name}から飲み招待',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isWhite ? const Color(0xFF27313B) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          _InviteResponseButton(
            label: 'OK',
            color: _ProfileColors.lime,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _InviteResponseButton(
            label: 'あとで',
            color: isWhite
                ? const Color(0xFFE8EEF5)
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
            child: Text(
              status == NomoDailyStatus.unselected
                  ? '今日の気分を設定する'
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
