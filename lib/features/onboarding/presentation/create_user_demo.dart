part of 'create_user_dialog.dart';

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: '写真1枚で、今日が\n友達との思い出になる',
    subtitle: 'Tomoは、写真・場所・一緒にいたフレンズをかわいく残すアプリです。',
    kind: _DemoKind.hero,
    chips: ['撮る', '残る', 'また誘える'],
  ),
  _DemoSlideData(
    step: '2 / 4',
    title: 'まずは自分の\nアバターを作ろう',
    subtitle: 'プロフィールができると、投稿もフレンズ追加も自分らしく始められます。',
    kind: _DemoKind.profile,
    chips: ['30秒で作成', 'あとから変更OK'],
  ),
  _DemoSlideData(
    step: '3 / 4',
    title: 'オンボーディング後は\n1枚投稿してみよう',
    subtitle: '今日の写真にひと言だけ。最初の思い出を飾ろう。',
    kind: _DemoKind.log,
    chips: ['写真 + ひと言', '場所も残せる'],
  ),
  _DemoSlideData(
    step: '4 / 4',
    title: 'フレンズとつながると\nもっと楽しくなる',
    subtitle: 'QRやIDでつながって、投稿に反応したり、また遊ぶきっかけを作れます。',
    kind: _DemoKind.friends,
    chips: ['反応', '思い出共有', 'また誘う'],
  ),
];

enum _DemoKind { hero, profile, log, friends }

class _DemoSlideData {
  const _DemoSlideData({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.chips = const <String>[],
  });

  final String step;
  final String title;
  final String subtitle;
  final _DemoKind kind;
  final List<String> chips;
}

class _DemoSlide extends StatelessWidget {
  const _DemoSlide({required this.slide});

  final _DemoSlideData slide;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.darkBackgroundGradient,
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.step,
          style: const TextStyle(
            color: Color(0xFF12C9A4),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.25,
            letterSpacing: -.9,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          slide.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.6,
          ),
        ),
        if (slide.chips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in slide.chips) _DemoValueChip(label: chip),
            ],
          ),
        ],
        const Spacer(),
        _DemoVisual(kind: slide.kind),
      ],
    ),
  );
}

class _DemoVisual extends StatelessWidget {
  const _DemoVisual({required this.kind});

  final _DemoKind kind;

  @override
  Widget build(BuildContext context) => switch (kind) {
    _DemoKind.hero => const _HeroDemoVisual(),
    _DemoKind.profile => const _ProfileDemoVisual(),
    _DemoKind.log => const _LogDemoVisual(),
    _DemoKind.friends => const _FriendsDemoVisual(),
  };
}

class _HeroDemoVisual extends StatelessWidget {
  const _HeroDemoVisual();

  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 190,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const Positioned(
          left: 30,
          bottom: 8,
          child: TomoAvatarView(avatar: TomoAvatar.defaultAvatar, size: 132),
        ),
        const Positioned(
          right: 20,
          top: 18,
          child: TomoPopIcon(
            icon: CupertinoIcons.sparkles,
            color: Color(0xFFFFC857),
            size: 42,
          ),
        ),
        const Positioned(
          left: -14,
          top: 48,
          child: TomoPopIcon(
            icon: CupertinoIcons.calendar,
            color: Color(0xFF16A8FF),
            size: 48,
          ),
        ),
      ],
    ),
  );
}

class _ProfileDemoVisual extends StatelessWidget {
  const _ProfileDemoVisual();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        const TomoAvatarView(avatar: TomoAvatar.defaultAvatar, size: 86),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  TomoPopIcon(icon: CupertinoIcons.person_fill, size: 34),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '@tomo_friend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
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

class _LogDemoVisual extends StatelessWidget {
  const _LogDemoVisual();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: const Column(
      children: [
        _DemoRow(icon: CupertinoIcons.camera_fill, label: '最初の投稿', value: '1枚'),
        SizedBox(height: 14),
        _DemoRow(
          icon: CupertinoIcons.person_2_fill,
          label: '一緒にいたフレンズ',
          value: 'タグ',
        ),
        SizedBox(height: 14),
        _DemoRow(icon: CupertinoIcons.calendar, label: 'ホームに表示', value: 'すぐ'),
      ],
    ),
  );
}

class _FriendsDemoVisual extends StatelessWidget {
  const _FriendsDemoVisual();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TomoAvatarView(avatar: TomoAvatar.defaultAvatar, size: 86),
          const SizedBox(width: 12),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFC08BFF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: TomoPopIcon(
                icon: CupertinoIcons.heart_fill,
                color: Colors.white,
                foregroundColor: Colors.white,
                showBubble: false,
                size: 42,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF12C9A4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'フレンズを追加する',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'QRコードで交換',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _DemoValueChip extends StatelessWidget {
  const _DemoValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TomoPopIcon(icon: icon, color: const Color(0xFF12C9A4), size: 42),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _DemoDots extends StatelessWidget {
  const _DemoDots({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: i == selectedIndex ? 18 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: i == selectedIndex
                ? const Color(0xFF12C9A4)
                : Colors.white.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (i != count - 1) const SizedBox(width: 8),
      ],
    ],
  );
}
