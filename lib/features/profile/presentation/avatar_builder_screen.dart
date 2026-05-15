import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/models/nomo_avatar.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key, required this.initialAvatar});

  final NomoAvatar initialAvatar;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late NomoAvatar _avatar = widget.initialAvatar;
  _AvatarTab _tab = _AvatarTab.face;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AvatarColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onClose: () => Navigator.of(context).pop(),
              onDone: () => Navigator.of(context).pop(_avatar),
              onRandom: () => setState(() => _avatar = NomoAvatar.random()),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _AvatarColors.previewA,
                            _AvatarColors.previewB,
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          NomoAvatarView(avatar: _avatar, size: 250),
                          Positioned(
                            right: 28,
                            top: 70,
                            child: _RoundTool(
                              icon: CupertinoIcons.shuffle,
                              label: 'ランダム',
                              onTap: () =>
                                  setState(() => _avatar = NomoAvatar.random()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _TabBar(
                    selected: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  SizedBox(
                    height: 330,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: _OptionsPanel(
                        tab: _tab,
                        avatar: _avatar,
                        onChanged: (avatar) => setState(() => _avatar = avatar),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.onDone,
    required this.onRandom,
  });

  final VoidCallback onClose;
  final VoidCallback onDone;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
    child: Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const NomoGeneratedIcon(
            CupertinoIcons.xmark,
            color: _AvatarColors.ink,
            size: 34,
          ),
        ),
        const Expanded(
          child: Text(
            'アバターを作成する',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AvatarColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
        ),
        TextButton(onPressed: onDone, child: const Text('保存')),
      ],
    ),
  );
}

class _RoundTool extends StatelessWidget {
  const _RoundTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .86),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: _AvatarColors.ink, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _AvatarColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

enum _AvatarTab { face, eyes, hair, accessory, shirt }

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});

  final _AvatarTab selected;
  final ValueChanged<_AvatarTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    decoration: const BoxDecoration(
      color: _AvatarColors.cream,
      border: Border(top: BorderSide(color: Color(0x110A1520))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _TabIcon(
          tab: _AvatarTab.face,
          selected: selected,
          icon: CupertinoIcons.person_crop_circle,
          onChanged: onChanged,
        ),
        _TabIcon(
          tab: _AvatarTab.eyes,
          selected: selected,
          icon: CupertinoIcons.eye,
          onChanged: onChanged,
        ),
        _TabIcon(
          tab: _AvatarTab.hair,
          selected: selected,
          icon: CupertinoIcons.scissors,
          onChanged: onChanged,
        ),
        _TabIcon(
          tab: _AvatarTab.accessory,
          selected: selected,
          icon: CupertinoIcons.eyeglasses,
          onChanged: onChanged,
        ),
        _TabIcon(
          tab: _AvatarTab.shirt,
          selected: selected,
          icon: CupertinoIcons.person_crop_square,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.tab,
    required this.selected,
    required this.icon,
    required this.onChanged,
  });

  final _AvatarTab tab;
  final _AvatarTab selected;
  final IconData icon;
  final ValueChanged<_AvatarTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = selected == tab;
    return GestureDetector(
      onTap: () => onChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: active
              ? _AvatarColors.coral.withValues(alpha: .16)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: active ? _AvatarColors.coral : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: NomoGeneratedIcon(
          icon,
          color: active ? _AvatarColors.coral : _AvatarColors.dim,
          size: 34,
        ),
      ),
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
    required this.tab,
    required this.avatar,
    required this.onChanged,
  });

  final _AvatarTab tab;
  final NomoAvatar avatar;
  final ValueChanged<NomoAvatar> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _AvatarTab.face => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('肌の色'),
          _ColorRow(
            colors: NomoAvatar.skinColors,
            selected: avatar.skin,
            onTap: (i) => onChanged(avatar.copyWith(skin: i)),
          ),
          const SizedBox(height: 24),
          _Title('口'),
          _ChoiceGrid(
            count: NomoAvatar.mouthStyles.length,
            selected: avatar.mouth,
            label: (i) => NomoAvatar.mouthStyles[i],
            builder: (i) => NomoAvatarView(
              avatar: avatar.copyWith(mouth: i),
              showBody: false,
            ),
            onTap: (i) => onChanged(avatar.copyWith(mouth: i)),
          ),
        ],
      ),
      _AvatarTab.eyes => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('目'),
          _ChoiceGrid(
            count: NomoAvatar.eyeStyles.length,
            selected: avatar.eyes,
            label: (i) => NomoAvatar.eyeStyles[i],
            builder: (i) => NomoAvatarView(
              avatar: avatar.copyWith(eyes: i),
              showBody: false,
            ),
            onTap: (i) => onChanged(avatar.copyWith(eyes: i)),
          ),
        ],
      ),
      _AvatarTab.hair => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('髪型'),
          _ChoiceGrid(
            count: NomoAvatar.hairStyles.length,
            selected: avatar.hair,
            label: (i) => NomoAvatar.hairStyles[i],
            builder: (i) => NomoAvatarView(
              avatar: avatar.copyWith(hair: i),
              showBody: false,
            ),
            onTap: (i) => onChanged(avatar.copyWith(hair: i)),
          ),
        ],
      ),
      _AvatarTab.accessory => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('アクセサリー'),
          _ChoiceGrid(
            count: NomoAvatar.accessoryStyles.length,
            selected: avatar.accessory,
            label: (i) => NomoAvatar.accessoryStyles[i],
            builder: (i) => NomoAvatarView(
              avatar: avatar.copyWith(accessory: i),
              showBody: false,
            ),
            onTap: (i) => onChanged(avatar.copyWith(accessory: i)),
          ),
        ],
      ),
      _AvatarTab.shirt => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('服の色'),
          _ColorRow(
            colors: NomoAvatar.shirtColors,
            selected: avatar.shirt,
            onTap: (i) => onChanged(avatar.copyWith(shirt: i)),
          ),
        ],
      ),
    };
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: _AvatarColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      children: [
        for (var i = 0; i < colors.length; i++) ...[
          GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 66,
              height: 66,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _AvatarColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected == i
                      ? _AvatarColors.coral
                      : _AvatarColors.line,
                  width: selected == i ? 2 : 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.count,
    required this.selected,
    required this.label,
    required this.builder,
    required this.onTap,
  });

  final int count;
  final int selected;
  final String Function(int) label;
  final Widget Function(int) builder;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: count,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: .86,
    ),
    itemBuilder: (context, i) => GestureDetector(
      onTap: () => onTap(i),
      child: _ChoiceTile(
        selected: selected == i,
        label: label(i),
        preview: builder(i),
      ),
    ),
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.label,
    required this.preview,
  });

  final bool selected;
  final String label;
  final Widget preview;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOutCubic,
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFFFF2F7) : _AvatarColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: selected ? _AvatarColors.coral : _AvatarColors.line,
        width: selected ? 2.5 : 1.2,
      ),
      boxShadow: [
        if (selected)
          BoxShadow(
            color: _AvatarColors.coral.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
      ],
    ),
    child: Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(width: 120, height: 120, child: preview),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AvatarColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (selected)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: _AvatarColors.coral,
                shape: BoxShape.circle,
              ),
              child: const NomoGeneratedIcon(
                CupertinoIcons.checkmark,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    ),
  );
}

class _AvatarColors {
  const _AvatarColors._();

  static const cream = Color(0xFFFFFBF4);
  static const previewA = Color(0xFFFFF1DF);
  static const previewB = Color(0xFFE8F7F8);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFEADFD6);
  static const dim = Color(0xFFB6A9A0);
  static const ink = Color(0xFF182333);
  static const coral = Color(0xFFFF8FB2);
}
