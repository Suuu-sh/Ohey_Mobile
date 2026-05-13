import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../../core/widgets/nomo_primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/soft_card.dart';

class AddNomiTomoScreen extends StatefulWidget {
  const AddNomiTomoScreen({super.key});

  @override
  State<AddNomiTomoScreen> createState() => _AddNomiTomoScreenState();
}

class _AddNomiTomoScreenState extends State<AddNomiTomoScreen> {
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '飲み友交換',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                color: AppColors.navy,
                              ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(CupertinoIcons.xmark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'QRコードかユーザーIDでつながろう。キャラクターは相手が選んだアイコンで表示されます。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _MyQrCard(),
                  const SizedBox(height: 20),
                  const _ScanQrCard(),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'ユーザーIDで検索'),
                  TextField(
                    controller: _userIdController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: '例: nomo_yuta_2026',
                      prefixIcon: Icon(CupertinoIcons.at),
                    ),
                    onSubmitted: (_) => _searchByUserId(context),
                  ),
                  const SizedBox(height: 14),
                  NomoPrimaryButton(
                    label: 'ユーザーIDで探す',
                    icon: CupertinoIcons.search,
                    onPressed: () => _searchByUserId(context),
                  ),
                  const SizedBox(height: 24),
                  const _ExchangeHintCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchByUserId(BuildContext context) {
    final id = _userIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザーIDを入力してください。')));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _UserSearchResultSheet(userId: id),
    );
  }
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEAF2FF), AppColors.surface],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const NomoCharacter(
                pose: NomoCharacterPose.iconSmile,
                width: 58,
                height: 58,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたのQR',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '相手に見せて飲み友交換',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR共有は準備中です（ダミー）。')),
                ),
                icon: const Icon(CupertinoIcons.share, color: AppColors.navy),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: 196,
            height: 196,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.line),
            ),
            child: const _DummyQr(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ID: nomo_yuta_2026',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanQrCard extends StatelessWidget {
  const _ScanQrCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExchangeActionCard(
            icon: CupertinoIcons.qrcode_viewfinder,
            title: 'QRを読み取る',
            subtitle: 'カメラで交換',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('QR読み取りは準備中です（ダミー）。'))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ExchangeActionCard(
            icon: CupertinoIcons.person_2_fill,
            title: '近くの人',
            subtitle: '近距離交換',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('近距離交換は準備中です（ダミー）。'))),
          ),
        ),
      ],
    );
  }
}

class _ExchangeActionCard extends StatelessWidget {
  const _ExchangeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .05),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.navy, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchResultSheet extends StatelessWidget {
  const _UserSearchResultSheet({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NomoCharacter(
            pose: NomoCharacterPose.iconWink,
            width: 88,
            height: 88,
          ),
          const SizedBox(height: 8),
          Text(
            userId,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'このユーザーに飲み友申請を送りますか？',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          NomoPrimaryButton(
            label: '飲み友申請を送る（ダミー）',
            icon: CupertinoIcons.paperplane_fill,
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$userId に飲み友申請を送りました（ダミー）。')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExchangeHintCard extends StatelessWidget {
  const _ExchangeHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.lock_shield, color: AppColors.mutedInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '交換後に相手のキャラクターアイコンと名前が友達リストに表示されます。実保存はSupabase連携時に追加予定です。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DummyQr extends StatelessWidget {
  const _DummyQr();

  @override
  Widget build(BuildContext context) {
    const pattern = [
      [1, 1, 1, 0, 1, 0, 0, 1, 1],
      [1, 0, 1, 0, 0, 1, 0, 0, 1],
      [1, 1, 1, 1, 0, 1, 1, 0, 0],
      [0, 0, 1, 0, 1, 0, 1, 1, 1],
      [1, 0, 0, 1, 1, 1, 0, 1, 0],
      [0, 1, 1, 0, 0, 1, 1, 0, 1],
      [1, 0, 1, 1, 0, 0, 1, 1, 1],
      [0, 1, 0, 0, 1, 1, 0, 0, 1],
      [1, 1, 0, 1, 0, 1, 1, 1, 0],
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 81,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),
      itemBuilder: (context, index) {
        final y = index ~/ 9;
        final x = index % 9;
        final filled = pattern[y][x] == 1;
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: filled ? AppColors.navy : AppColors.softGray,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
