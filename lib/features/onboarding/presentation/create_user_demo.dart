part of 'create_user_dialog.dart';

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: '写真1枚で、今日が\n友達との思い出になる',
    subtitle: 'Oheyは、写真・場所・一緒にいたフレンズをかわいく残すアプリです。',
    kind: _DemoKind.hero,
    assetName: 'assets/images/onboarding_demo_hero.png',
  ),
  _DemoSlideData(
    step: '2 / 4',
    title: 'まずは自分の\nアバターを作ろう',
    subtitle: 'プロフィールができると、投稿もフレンズ追加も自分らしく始められます。',
    kind: _DemoKind.profile,
    assetName: 'assets/images/onboarding_demo_profile.png',
  ),
  _DemoSlideData(
    step: '3 / 4',
    title: 'オンボーディング後は\n1枚投稿してみよう',
    subtitle: '今日の写真にひと言だけ。最初の思い出を飾ろう。',
    kind: _DemoKind.log,
    assetName: 'assets/images/onboarding_demo_log.png',
  ),
  _DemoSlideData(
    step: '4 / 4',
    title: 'フレンズとつながると\nもっと楽しくなる',
    subtitle: 'QRやIDでつながって、投稿に反応したり、また遊ぶきっかけを作れます。',
    kind: _DemoKind.friends,
    assetName: 'assets/images/onboarding_demo_friends.png',
  ),
];

enum _DemoKind { hero, profile, log, friends }

class _DemoSlideData {
  const _DemoSlideData({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.assetName,
  });

  final String step;
  final String title;
  final String subtitle;
  final _DemoKind kind;
  final String assetName;
}

class _DemoSlide extends StatelessWidget {
  const _DemoSlide({required this.slide});

  final _DemoSlideData slide;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Image.asset(
      slide.assetName,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
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
