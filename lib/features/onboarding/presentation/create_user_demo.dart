part of 'create_user_dialog.dart';

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: '友達と会うきっかけを\n気軽につくれる',
    subtitle: 'Oheyは、ゆるい募集から友達と会う予定をつくるアプリです。',
    kind: _DemoKind.hero,
    assetName: 'assets/images/onboarding_demo_hero.png',
  ),
  _DemoSlideData(
    step: '2 / 4',
    title: 'まずは自分の\nアバターを作ろう',
    subtitle: 'プロフィールができると、ゆるぼもフレンズ追加も自分らしく始められます。',
    kind: _DemoKind.profile,
    assetName: 'assets/images/onboarding_demo_profile.png',
  ),
  _DemoSlideData(
    step: '3 / 4',
    title: 'オンボーディング後は\nゆるぼしてみよう',
    subtitle: 'ご飯・作業・サウナなど、軽い誘いを置いてみよう。',
    kind: _DemoKind.log,
    assetName: 'assets/images/onboarding_demo_log.png',
  ),
  _DemoSlideData(
    step: '4 / 4',
    title: 'フレンズとつながると\nもっと楽しくなる',
    subtitle: 'QRやIDでつながって、ゆるぼに反応したり、また遊ぶきっかけを作れます。',
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
  Widget build(BuildContext context) => Image.asset(
    slide.assetName,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
    alignment: Alignment.center,
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
                ? AppColors.cFF12C9A4
                : AppColors.white.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (i != count - 1) const SizedBox(width: 8),
      ],
    ],
  );
}
