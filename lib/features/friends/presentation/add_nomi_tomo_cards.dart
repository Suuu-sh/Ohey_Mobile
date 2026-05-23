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
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _ExchangeColors.teal.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _ExchangeColors.teal.withValues(alpha: .28),
                ),
              ),
              child: NomoAvatarView(avatar: avatar, size: 58),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたのNomo QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '相手に見せて飲みとも交換',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .48),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const _PopBadge(
              icon: CupertinoIcons.qrcode,
              color: _ExchangeColors.lime,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: 202,
          height: 202,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _ExchangeColors.lime.withValues(alpha: .20),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: userId == null
              ? const Center(child: Text('ログインが必要です'))
              : QrImageView(data: payload, version: QrVersions.auto),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Text(
            '@${userId ?? '-'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _DarkCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _PopBadge(icon: icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .50),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: accent,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

class _UserSearchResultSheet extends StatelessWidget {
  const _UserSearchResultSheet({required this.profile, required this.onAdd});

  final NomoFriendProfile profile;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: _ExchangeColors.card,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _ExchangeColors.teal.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ExchangeColors.teal.withValues(alpha: .35),
                ),
              ),
              child: NomoAvatarView(avatar: profile.avatar, size: 96),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${profile.userId} を飲みともに追加しますか？',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .52),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _BigPopButton(
              label: '飲みともに追加する',
              icon: CupertinoIcons.person_badge_plus_fill,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    ),
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
