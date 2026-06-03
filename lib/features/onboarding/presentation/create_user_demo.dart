part of 'create_user_dialog.dart';

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: 'ゆるぼを見つける',
    subtitle: 'ホームには、フレンズが置いた「行きたい」「集まりたい」が投稿のように並びます。',
    kind: _DemoKind.feed,
  ),
  _DemoSlideData(
    step: '2 / 4',
    title: '参加したい時は申請',
    subtitle: '「参加する」を押すと、相手に参加申請が届きます。すぐ確定ではないので安心です。',
    kind: _DemoKind.request,
  ),
  _DemoSlideData(
    step: '3 / 4',
    title: '自分でも募集できる',
    subtitle: 'やりたいこと・場所・いつを入れて、フレンズにゆるく募集できます。',
    kind: _DemoKind.create,
  ),
  _DemoSlideData(
    step: '4 / 4',
    title: '申請は通知で確認',
    subtitle: '届いた申請を承認すると、参加者として予定に残ります。見送ることもできます。',
    kind: _DemoKind.notify,
  ),
];

enum _DemoKind { feed, request, create, notify }

class _DemoSlideData {
  const _DemoSlideData({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String step;
  final String title;
  final String subtitle;
  final _DemoKind kind;
}

class _DemoSlide extends StatelessWidget {
  const _DemoSlide({required this.slide});

  final _DemoSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cFF071038, AppColors.darkBackground],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DemoStepBadge(label: slide.step),
              const SizedBox(height: 12),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 31,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .68),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(child: _DemoPhoneStage(kind: slide.kind)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoStepBadge extends StatelessWidget {
  const _DemoStepBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cFFC08BFF.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cFFC08BFF.withValues(alpha: .38)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cFFC08BFF,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _DemoPhoneStage extends StatelessWidget {
  const _DemoPhoneStage({required this.kind});

  final _DemoKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cFF02092B,
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: AppColors.white.withValues(alpha: .10),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .36),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.2, -.9),
                    radius: 1.2,
                    colors: [
                      AppColors.cFFC08BFF.withValues(alpha: .16),
                      AppColors.darkBackground,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: _DemoStageContent(kind: kind),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoStageContent extends StatelessWidget {
  const _DemoStageContent({required this.kind});

  final _DemoKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _DemoKind.feed:
        return const _DemoFeedStep();
      case _DemoKind.request:
        return const _DemoRequestStep();
      case _DemoKind.create:
        return const _DemoCreateStep();
      case _DemoKind.notify:
        return const _DemoNotifyStep();
    }
  }
}

class _DemoFeedStep extends StatelessWidget {
  const _DemoFeedStep();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: const [
      _DemoMiniHeader(title: 'ゆるぼ', subtitle: 'フレンズの募集を見る'),
      SizedBox(height: 14),
      _DemoYuruboCard(
        name: 'youtan1223',
        title: '焼肉行きたい',
        meta: '今日 19:00 ・ 渋谷あたり',
        buttonLabel: '参加する',
        highlight: true,
      ),
      SizedBox(height: 10),
      _DemoYuruboCard(
        name: 'yisshiki391',
        title: 'カフェで作業',
        meta: 'いつでも ・ どこでも',
        buttonLabel: '見る',
      ),
    ],
  );
}

class _DemoRequestStep extends StatelessWidget {
  const _DemoRequestStep();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _DemoMiniHeader(title: '参加申請', subtitle: '相手の承認を待ちます'),
      const SizedBox(height: 14),
      const _DemoYuruboCard(
        name: 'youtan1223',
        title: '焼肉行きたい',
        meta: '今日 19:00 ・ 渋谷あたり',
        buttonLabel: '申請中',
        highlight: true,
      ),
      const SizedBox(height: 16),
      _DemoCallout(
        icon: CupertinoIcons.bell_fill,
        title: '押したら相手に通知',
        body: '承認されるまで「申請中」になります。',
        color: AppColors.cFF9AF21A,
      ),
    ],
  );
}

class _DemoCreateStep extends StatelessWidget {
  const _DemoCreateStep();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _DemoMiniHeader(title: 'ゆるぼ作成', subtitle: 'あとから編集・削除できます'),
      const SizedBox(height: 14),
      _DemoInput(label: 'やりたいこと', value: 'カフェ行きたい'),
      const SizedBox(height: 8),
      _DemoInput(label: '場所', value: '新宿'),
      const SizedBox(height: 8),
      _DemoInput(label: 'いつ', value: 'いつでも'),
      const Spacer(),
      Ohey3DButton(
        label: 'ゆるぼする',
        height: 46,
        radius: 22,
        color: AppColors.cFFC08BFF,
        foregroundColor: AppColors.cFF101820,
        shadowColor: AppColors.cFF7F51C9,
        onTap: () {},
      ),
    ],
  );
}

class _DemoNotifyStep extends StatelessWidget {
  const _DemoNotifyStep();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _DemoMiniHeader(title: '通知', subtitle: '未返信はアプリ起動時に表示'),
      const SizedBox(height: 18),
      OheyThemedPanel(
        backgroundColor: AppColors.darkBackgroundBottom,
        accentColor: AppColors.cFF9AF21A,
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                OheyPopIcon(
                  icon: CupertinoIcons.person_2_fill,
                  color: AppColors.cFFC08BFF,
                  size: 38,
                  iconSize: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '参加申請・参加者',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DemoRequestRow(),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _DemoCallout(
        icon: CupertinoIcons.checkmark_alt,
        title: '承認すると参加者に追加',
        body: '見送っても、あとから別のゆるぼを確認できます。',
        color: AppColors.cFF20B9FF,
      ),
    ],
  );
}

class _DemoMiniHeader extends StatelessWidget {
  const _DemoMiniHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const OheyPopIcon(
        icon: CupertinoIcons.sparkles,
        color: AppColors.cFFC08BFF,
        size: 42,
        iconSize: 22,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .58),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DemoYuruboCard extends StatelessWidget {
  const _DemoYuruboCard({
    required this.name,
    required this.title,
    required this.meta,
    required this.buttonLabel,
    this.highlight = false,
  });

  final String name;
  final String title;
  final String meta;
  final String buttonLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) => OheyThemedPanel(
    backgroundColor: AppColors.darkBackgroundBottom,
    accentColor: highlight ? AppColors.cFFC08BFF : AppColors.cFF20B9FF,
    borderRadius: 24,
    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
    child: Row(
      children: [
        const OheyPopIcon(
          icon: CupertinoIcons.person_fill,
          color: AppColors.cFFFF75B5,
          size: 44,
          iconSize: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .84),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .54),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Ohey3DButton(
            label: buttonLabel,
            height: 38,
            radius: 19,
            color: highlight ? AppColors.cFFC08BFF : AppColors.cFF20B9FF,
            foregroundColor: AppColors.cFF101820,
            shadowColor: highlight ? AppColors.cFF7F51C9 : AppColors.cFF0B78B7,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}

class _DemoCallout extends StatelessWidget {
  const _DemoCallout({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: color.withValues(alpha: .32)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .62),
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DemoInput extends StatelessWidget {
  const _DemoInput({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.white.withValues(alpha: .10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: .48),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DemoRequestRow extends StatelessWidget {
  const _DemoRequestRow();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    decoration: BoxDecoration(
      color: AppColors.cFF20B9FF.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.cFF20B9FF.withValues(alpha: .34)),
    ),
    child: Row(
      children: [
        const OheyPopIcon(
          icon: CupertinoIcons.person_fill,
          color: AppColors.cFFFF75B5,
          size: 38,
          iconSize: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'youtan1223',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '申請先: 焼肉行きたい',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.cFFC08BFF.withValues(alpha: .95),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 70,
          child: Ohey3DButton(
            label: '承認',
            height: 38,
            radius: 19,
            color: AppColors.cFF9AF21A,
            foregroundColor: AppColors.cFF101820,
            shadowColor: AppColors.cFF079078,
            fontSize: 13,
            onTap: () {},
          ),
        ),
      ],
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
                ? AppColors.cFFC08BFF
                : AppColors.white.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (i != count - 1) const SizedBox(width: 8),
      ],
    ],
  );
}
