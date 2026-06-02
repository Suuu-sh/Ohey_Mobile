import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_gender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_pop_icon.dart';

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({
    super.key,
    required this.initialAvatar,
    this.gender = OheyGender.unspecified,
  });

  final OheyAvatar initialAvatar;
  final OheyGender gender;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late OheyAvatar _avatar = widget.initialAvatar.normalizedForGender(
    widget.gender,
  );
  _AvatarTab _tab = _AvatarTab.face;

  bool get _hasChanges => _avatar.encode() != widget.initialAvatar.encode();

  Future<void> _handleDone() async {
    final result = await Navigator.of(context).push<OheyAvatar>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => AvatarBackgroundPickerScreen(initialAvatar: _avatar),
      ),
    );
    if (!mounted || result == null) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _handleClose() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final action = await showOheyBottomSheet<_UnsavedAvatarAction>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: .62),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleClose();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: _AvatarColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(onClose: _handleClose, onDone: _handleDone),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _AvatarPreviewStage(
                          avatar: _avatar,
                          onRandom: () => setState(
                            () => _avatar = OheyAvatar.random(
                              gender: widget.gender,
                            ),
                          ),
                        ),
                      ),
                      _TabBar(
                        selected: _tab,
                        onChanged: (tab) => setState(() => _tab = tab),
                      ),
                      Container(
                        height: 330,
                        decoration: const BoxDecoration(
                          color: _AvatarColors.background,
                          border: Border(
                            top: BorderSide(color: _AvatarColors.line),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
      ),
    );
  }
}

class AvatarBackgroundPickerScreen extends StatefulWidget {
  const AvatarBackgroundPickerScreen({super.key, required this.initialAvatar});

  final OheyAvatar initialAvatar;

  @override
  State<AvatarBackgroundPickerScreen> createState() =>
      _AvatarBackgroundPickerScreenState();
}

class _AvatarBackgroundPickerScreenState
    extends State<AvatarBackgroundPickerScreen> {
  late int _selected = widget.initialAvatar.background;

  @override
  Widget build(BuildContext context) {
    final avatar = widget.initialAvatar.copyWith(background: _selected);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _AvatarColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const OheyGeneratedIcon(
                        CupertinoIcons.chevron_left,
                        color: _AvatarColors.ink,
                        size: 34,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '背景を選ぶ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _AvatarColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                    ),
                    _SaveAvatarButton(
                      onTap: () => Navigator.of(context).pop(avatar),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'マイページのアバターカードに表示する背景です。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _AvatarColors.sub,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 230,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _AvatarColors.panel,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _AvatarColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: .28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _AvatarBackgroundPreview(avatar: avatar, large: true),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemCount: OheyAvatar.backgroundStyles.length,
                  itemBuilder: (context, index) => _AvatarBackgroundOption(
                    avatar: widget.initialAvatar.copyWith(background: index),
                    label: OheyAvatar.backgroundStyles[index],
                    selected: _selected == index,
                    onTap: () => setState(() => _selected = index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBackgroundOption extends StatelessWidget {
  const _AvatarBackgroundOption({
    required this.avatar,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final OheyAvatar avatar;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected ? _AvatarColors.accent : _AvatarColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? _AvatarColors.accent : _AvatarColors.line,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AvatarBackgroundPreview(avatar: avatar),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 8,
                top: 8,
                child: OheyPopIcon(
                  icon: CupertinoIcons.checkmark_alt,
                  color: _AvatarColors.accent,
                  size: 32,
                  iconSize: 18,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _AvatarBackgroundPreview extends StatelessWidget {
  const _AvatarBackgroundPreview({required this.avatar, this.large = false});

  final OheyAvatar avatar;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final imageBackdropAsset = OheyAvatar.imageBackdropAsset(avatar.background);
    if (imageBackdropAsset != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              imageBackdropAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Center(
            child: OheyAvatarView(avatar: avatar, size: large ? 190 : 96),
          ),
        ],
      );
    }

    final colors =
        OheyAvatar.backgroundGradients[avatar.background %
            OheyAvatar.backgroundGradients.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        Opacity(
          opacity: avatar.background == OheyAvatar.dreamRoomBackground
              ? .18
              : .10,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_header_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: .18),
                AppColors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
        Center(
          child: OheyAvatarView(avatar: avatar, size: large ? 190 : 96),
        ),
      ],
    );
  }
}

enum _UnsavedAvatarAction { save, discard, cancel }

class _AvatarPreviewStage extends StatelessWidget {
  const _AvatarPreviewStage({required this.avatar, required this.onRandom});

  final OheyAvatar avatar;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      color: _AvatarColors.panel,
      border: Border.all(color: _AvatarColors.line),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: .26),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 28,
          top: 24,
          child: _StageChip(icon: CupertinoIcons.sparkles, label: 'Preview'),
        ),
        Center(child: OheyAvatarView(avatar: avatar, size: 250)),
        Positioned(
          right: 18,
          top: 20,
          child: _RoundTool(
            icon: CupertinoIcons.shuffle,
            label: 'ランダム',
            onTap: onRandom,
          ),
        ),
      ],
    ),
  );
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.white.withValues(alpha: .10)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OheyGeneratedIcon(icon, color: _AvatarColors.accent, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _AvatarColors.sub,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
      ],
    ),
  );
}

class _UnsavedAvatarSheet extends StatelessWidget {
  const _UnsavedAvatarSheet();

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: OheyBottomSheetShell(
      showHandle: true,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      radius: 34,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OheyPopIcon(
                icon: CupertinoIcons.person_crop_circle_fill,
                color: AppColors.primaryAction,
                size: 48,
                iconSize: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '変更を保存しますか？',
                      style: TextStyle(
                        color: _AvatarColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '閉じる前に、アバターを残しておけるよ。',
                      style: TextStyle(
                        color: _AvatarColors.sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.white.withValues(alpha: .10)),
            ),
            child: const Row(
              children: [
                OheyGeneratedIcon(
                  CupertinoIcons.info_circle_fill,
                  color: AppColors.primaryAction,
                  size: 20,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '保存しない場合は、変更前のアバターに戻ります。',
                    style: TextStyle(
                      color: _AvatarColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Ohey3DButton(
            label: '保存して閉じる',
            color: AppColors.primaryAction,
            shadowColor: AppColors.primaryActionShadow,
            foregroundColor: AppColors.white,
            height: 52,
            radius: 22,
            fontSize: 15,
            onTap: () => Navigator.of(context).pop(_UnsavedAvatarAction.save),
          ),
          const SizedBox(height: 10),
          Ohey3DButton.secondary(
            label: '変更を戻す',
            color: _AvatarColors.card,
            foregroundColor: _AvatarColors.ink,
            shadowColor: _AvatarColors.panelShadow,
            height: 48,
            radius: 21,
            fontSize: 14,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedAvatarAction.discard),
          ),
          const SizedBox(height: 10),
          Ohey3DButton.secondary(
            label: '編集を続ける',
            color: AppColors.white.withValues(alpha: .055),
            foregroundColor: _AvatarColors.sub,
            shadowColor: _AvatarColors.panelShadow,
            height: 46,
            radius: 20,
            fontSize: 14,
            useGradient: false,
            onTap: () => Navigator.of(context).pop(_UnsavedAvatarAction.cancel),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onDone});

  final VoidCallback onClose;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
    child: Row(
      children: [
        const SizedBox(width: 48),
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
  Widget build(BuildContext context) => Ohey3DButtonSurface(
    onTap: onTap,
    height: 42,
    radius: 21,
    color: AppColors.primaryAction,
    bottomColor: AppColors.primaryActionShadow,
    padding: const EdgeInsets.fromLTRB(13, 0, 15, 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .24),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: OheyGeneratedIcon(
              CupertinoIcons.checkmark,
              color: AppColors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '保存',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: .1,
          ),
        ),
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
        color: AppColors.white.withValues(alpha: .08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OheyGeneratedIcon(icon, color: _AvatarColors.accent, size: 26),
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
      color: _AvatarColors.background,
      border: Border(top: BorderSide(color: _AvatarColors.line)),
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
              ? _AvatarColors.accent.withValues(alpha: .14)
              : AppColors.transparent,
          border: Border(
            bottom: BorderSide(
              color: active ? _AvatarColors.accent : AppColors.transparent,
              width: 3,
            ),
          ),
        ),
        child: OheyGeneratedIcon(
          icon,
          color: active ? _AvatarColors.accent : _AvatarColors.sub,
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
  final OheyAvatar avatar;
  final OheyGender gender;
  final ValueChanged<OheyAvatar> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _AvatarTab.face => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('肌の色'),
          _ColorRow(
            colors: OheyAvatar.skinColors,
            selected: avatar.skin,
            onTap: (i) => onChanged(avatar.copyWith(skin: i)),
          ),
          const SizedBox(height: 24),
          _Title('口'),
          _ChoiceGrid(
            count: OheyAvatar.mouthStyles.length,
            selected: avatar.mouth,
            label: (i) => OheyAvatar.mouthStyles[i],
            builder: (i) => OheyAvatarView(
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
            count: OheyAvatar.eyeStyles.length,
            selected: avatar.eyes,
            label: (i) => OheyAvatar.eyeStyles[i],
            builder: (i) => OheyAvatarView(
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
            indices: OheyAvatar.selectableHairIndicesForGender(gender),
            selected: avatar.hair,
            label: (i) => OheyAvatar.hairStyles[i],
            builder: (i) => OheyAvatarView(
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
            count: OheyAvatar.accessoryStyles.length,
            selected: avatar.accessory,
            label: (i) => OheyAvatar.accessoryStyles[i],
            builder: (i) => OheyAvatarView(
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
            colors: OheyAvatar.shirtColors,
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
                      ? _AvatarColors.accent
                      : _AvatarColors.line,
                  width: selected == i ? 2 : 1,
                ),
                boxShadow: [
                  if (selected == i)
                    BoxShadow(
                      color: _AvatarColors.accent.withValues(alpha: .20),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                ],
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
      color: selected ? _AvatarColors.selectedCard : _AvatarColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: selected ? _AvatarColors.accent : _AvatarColors.line,
        width: selected ? 2.5 : 1.2,
      ),
      boxShadow: [
        if (selected)
          BoxShadow(
            color: _AvatarColors.accent.withValues(alpha: .18),
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
                    color: _AvatarColors.panel,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _AvatarColors.line),
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
                color: _AvatarColors.accent,
                shape: BoxShape.circle,
              ),
              child: const OheyGeneratedIcon(
                CupertinoIcons.checkmark,
                color: AppColors.white,
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

  static const background = AppColors.darkBackground;
  static const panel = AppColors.cFF0D1A26;
  static const card = AppColors.cFF132231;
  static const selectedCard = AppColors.cFF1A2F42;
  static const panelShadow = AppColors.cFF08111A;
  static const line = AppColors.c1EFFFFFF;
  static const ink = AppColors.white;
  static const sub = AppColors.cFF8F9BAB;
  static const accent = AppColors.primaryAction;
}
