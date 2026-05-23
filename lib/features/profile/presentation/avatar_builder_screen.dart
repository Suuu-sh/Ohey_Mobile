import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({
    super.key,
    required this.initialAvatar,
    this.gender = NomoGender.unspecified,
  });

  final NomoAvatar initialAvatar;
  final NomoGender gender;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late NomoAvatar _avatar = widget.initialAvatar.normalizedForGender(
    widget.gender,
  );
  _AvatarTab _tab = _AvatarTab.face;

  bool get _hasChanges => _avatar.encode() != widget.initialAvatar.encode();

  Future<void> _handleClose() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final action = await showCupertinoModalPopup<_UnsavedAvatarAction>(
      context: context,
      builder: (context) => const _UnsavedAvatarSheet(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _UnsavedAvatarAction.save:
        Navigator.of(context).pop(_avatar);
      case _UnsavedAvatarAction.discard:
        Navigator.of(context).pop();
      case _UnsavedAvatarAction.cancel:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _AvatarColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                onClose: _handleClose,
                onDone: () => Navigator.of(context).pop(_avatar),
                onRandom: () => setState(
                  () => _avatar = NomoAvatar.random(gender: widget.gender),
                ),
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
                                onTap: () => setState(
                                  () => _avatar = NomoAvatar.random(
                                    gender: widget.gender,
                                  ),
                                ),
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
                          gender: widget.gender,
                          onChanged: (avatar) =>
                              setState(() => _avatar = avatar),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _UnsavedAvatarAction { save, discard, cancel }

class _UnsavedAvatarSheet extends StatelessWidget {
  const _UnsavedAvatarSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'アバターの変更を保存する？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AvatarColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '保存せずに閉じると、変更前のアバターに戻ります。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AvatarColors.dim,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _UnsavedAvatarButton(
            label: '保存して閉じる',
            icon: CupertinoIcons.check_mark_circled_solid,
            color: _AvatarColors.coral,
            textColor: Colors.white,
            onTap: () => Navigator.of(context).pop(_UnsavedAvatarAction.save),
          ),
          const SizedBox(height: 10),
          _UnsavedAvatarButton(
            label: '変更を戻す',
            icon: CupertinoIcons.arrow_uturn_left,
            color: const Color(0xFFFFF2F7),
            textColor: _AvatarColors.coral,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedAvatarAction.discard),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedAvatarAction.cancel),
            child: const Text(
              '編集を続ける',
              style: TextStyle(
                color: _AvatarColors.dim,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnsavedAvatarButton extends StatelessWidget {
  const _UnsavedAvatarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: textColor, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
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
        _SaveAvatarButton(onTap: onDone),
      ],
    ),
  );
}

class _SaveAvatarButton extends StatelessWidget {
  const _SaveAvatarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21E0C2), Color(0xFF12C9A4)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .86),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12C9A4).withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          const BoxShadow(
            color: Color(0xFF079078),
            blurRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .24),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: NomoGeneratedIcon(
                CupertinoIcons.checkmark,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '保存',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
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
    required this.gender,
    required this.onChanged,
  });

  final _AvatarTab tab;
  final NomoAvatar avatar;
  final NomoGender gender;
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
            indices: NomoAvatar.selectableHairIndicesForGender(gender),
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
    required this.selected,
    required this.label,
    required this.builder,
    required this.onTap,
    this.count,
    this.indices,
  });

  final int? count;
  final List<int>? indices;
  final int selected;
  final String Function(int) label;
  final Widget Function(int) builder;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = indices ?? [for (var i = 0; i < (count ?? 0); i++) i];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .86,
      ),
      itemBuilder: (context, itemIndex) {
        final i = items[itemIndex];
        return GestureDetector(
          onTap: () => onTap(i),
          child: _ChoiceTile(
            selected: selected == i,
            label: label(i),
            preview: builder(i),
          ),
        );
      },
    );
  }
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
