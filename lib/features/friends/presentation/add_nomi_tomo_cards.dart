part of 'add_nomi_tomo_screen.dart';

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({
    required this.userId,
    required this.payload,
    required this.avatar,
  });

  final String? userId;
  final String payload;
  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) => _DarkCard(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    child: NomoQrDisplayCard(
      title: 'あなたのNomo QR',
      subtitle: '相手に見せて飲みとも交換',
      handle: '@${userId ?? '-'}',
      payload: userId == null ? null : payload,
      avatar: avatar,
      accentColor: _ExchangeColors.lime,
      cardColor: _ExchangeColors.card,
    ),
  );
}

class _ScanQrCard extends StatelessWidget {
  const _ScanQrCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => _ExchangeActionCard(
    icon: CupertinoIcons.qrcode_viewfinder,
    title: 'QRを読み取る',
    subtitle: 'カメラまたは画像から相手のNomo QRを読み取る',
    accent: _ExchangeColors.lime,
    onTap: onScan,
  );
}

class _UserIdSearchCard extends StatelessWidget {
  const _UserIdSearchCard({
    required this.controller,
    required this.busy,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => _DarkCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _PopBadge(
              icon: CupertinoIcons.at,
              color: _ExchangeColors.blue,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ユーザーIDで検索',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MiniPopButton(
              label: busy ? '検索中' : '探す',
              icon: busy ? CupertinoIcons.hourglass : CupertinoIcons.search,
              color: _ExchangeColors.blue,
              onTap: busy ? null : onSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DarkInput(
          controller: controller,
          hintText: '例: nomo_yuta_2026',
          onSubmitted: (_) => onSubmitted(),
        ),
      ],
    ),
  );
}

class _ExchangeActionCard extends StatelessWidget {
  const _ExchangeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NomoActionCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    accent: accent,
    onTap: onTap,
    childBuilder: (context, child) =>
        _DarkCard(padding: const EdgeInsets.all(16), child: child),
  );
}

class _UserSearchResultSheet extends StatelessWidget {
  const _UserSearchResultSheet({required this.profile, required this.onAdd});

  final NomoFriendProfile profile;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => NomoProfileResultSheet(
    avatar: profile.avatar,
    displayName: profile.displayName,
    subtitle: '@${profile.userId} を飲みともに追加しますか？',
    actionLabel: '飲みともに追加する',
    actionIcon: CupertinoIcons.person_badge_plus_fill,
    onAction: onAdd,
    backgroundColor: _ExchangeColors.card,
    accentColor: _ExchangeColors.teal,
  );
}

class _ExchangeHintCard extends StatelessWidget {
  const _ExchangeHintCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PopBadge(
          icon: CupertinoIcons.lock_shield_fill,
          color: _ExchangeColors.purple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '交換後に相手のアバターと名前がフレンズに表示されます。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
