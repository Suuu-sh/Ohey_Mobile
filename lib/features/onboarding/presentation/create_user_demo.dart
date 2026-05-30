part of 'create_user_dialog.dart';

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: '写真1枚で、今日が\n友達との思い出になる',
    subtitle: 'Oheyは、写真・場所・一緒にいたフレンズをかわいく残すアプリです。',
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
    _DemoKind.hero => const _GeneratedDemoVisual(
      assetName: 'assets/images/onboarding_demo_hero.png',
    ),
    _DemoKind.profile => const _GeneratedDemoVisual(
      assetName: 'assets/images/onboarding_demo_profile.png',
    ),
    _DemoKind.log => const _GeneratedDemoVisual(
      assetName: 'assets/images/onboarding_demo_log.png',
    ),
    _DemoKind.friends => const _GeneratedDemoVisual(
      assetName: 'assets/images/onboarding_demo_friends.png',
    ),
  };
}

class _GeneratedDemoVisual extends StatelessWidget {
  const _GeneratedDemoVisual({required this.assetName});

  final String assetName;

  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF12C9A4).withValues(alpha: .16),
          blurRadius: 34,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.asset(
        assetName,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    ),
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
