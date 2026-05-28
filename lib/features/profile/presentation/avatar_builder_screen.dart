import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
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

  Future<void> _handleDone() async {
    final result = await Navigator.of(context).push<NomoAvatar>(
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

    final action = await showNomoBottomSheet<_UnsavedAvatarAction>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .62),
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
        statusBarColor: Colors.transparent,
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
                            () => _avatar = NomoAvatar.random(
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

  final NomoAvatar initialAvatar;

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
        statusBarColor: Colors.transparent,
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
                      icon: const NomoGeneratedIcon(
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
                      color: Colors.black.withValues(alpha: .28),
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
                  itemCount: NomoAvatar.backgroundStyles.length,
                  itemBuilder: (context, index) => _AvatarBackgroundOption(
                    avatar: widget.initialAvatar.copyWith(background: index),
                    label: NomoAvatar.backgroundStyles[index],
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

  final NomoAvatar avatar;
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
            color: Colors.black.withValues(alpha: .24),
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
                  color: Colors.black.withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
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
                child: NomoPopIcon(
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

  final NomoAvatar avatar;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (NomoAvatar.usesMascotBackdrop(avatar.background)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_mascot_backdrop_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Center(
            child: NomoAvatarView(avatar: avatar, size: large ? 190 : 96),
          ),
        ],
      );
    }

    final colors =
        NomoAvatar.backgroundGradients[avatar.background %
            NomoAvatar.backgroundGradients.length];
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
          opacity: avatar.background == NomoAvatar.dreamRoomBackground
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
                Colors.white.withValues(alpha: .18),
                Colors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
        Center(
          child: NomoAvatarView(avatar: avatar, size: large ? 190 : 96),
        ),
      ],
    );
  }
}

enum _UnsavedAvatarAction { save, discard, cancel }

class _AvatarPreviewStage extends StatelessWidget {
  const _AvatarPreviewStage({required this.avatar, required this.onRandom});

  final NomoAvatar avatar;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_AvatarColors.panel, _AvatarColors.background],
      ),
      border: Border.all(color: _AvatarColors.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .26),
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
          left: -56,
          top: 46,
          child: _GlowOrb(
            size: 170,
            color: AppColors.invite.withValues(alpha: .22),
          ),
        ),
        Positioned(
          right: -50,
          bottom: -40,
          child: _GlowOrb(
            size: 190,
            color: AppColors.primaryAction.withValues(alpha: .20),
          ),
        ),
        Positioned(
          left: 28,
          top: 24,
          child: _StageChip(icon: CupertinoIcons.sparkles, label: 'Preview'),
        ),
        Center(
          child: Container(
            width: 268,
            height: 268,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .14),
                  Colors.white.withValues(alpha: .04),
                  Colors.transparent,
                ],
                stops: const [0, .54, 1],
              ),
            ),
            child: Center(child: NomoAvatarView(avatar: avatar, size: 250)),
          ),
        ),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NomoGeneratedIcon(icon, color: _AvatarColors.accent, size: 16),
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
    child: NomoBottomSheetShell(
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
              const NomoPopIcon(
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
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: const Row(
              children: [
                NomoGeneratedIcon(
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
          Nomo3DButton(
            label: '保存して閉じる',
            icon: CupertinoIcons.check_mark_circled_solid,
            color: AppColors.primaryAction,
            shadowColor: AppColors.primaryActionShadow,
            foregroundColor: Colors.white,
            height: 52,
            radius: 22,
            fontSize: 15,
            onTap: () => Navigator.of(context).pop(_UnsavedAvatarAction.save),
          ),
          const SizedBox(height: 10),
          Nomo3DButton.secondary(
            label: '変更を戻す',
            icon: CupertinoIcons.arrow_uturn_left,
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
          Nomo3DButton.secondary(
            label: '編集を続ける',
            icon: CupertinoIcons.pencil,
            color: Colors.white.withValues(alpha: .055),
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
  Widget build(BuildContext context) => Nomo3DButtonSurface(
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
            color: Colors.white.withValues(alpha: .24),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: NomoGeneratedIcon(
              CupertinoIcons.checkmark,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '保存',
          style: TextStyle(
            color: Colors.white,
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
        color: Colors.white.withValues(alpha: .08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: _AvatarColors.accent, size: 26),
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
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: active ? _AvatarColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: NomoGeneratedIcon(
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

  static const background = AppColors.darkBackground;
  static const panel = Color(0xFF0D1A26);
  static const card = Color(0xFF132231);
  static const selectedCard = Color(0xFF1A2F42);
  static const panelShadow = Color(0xFF08111A);
  static const line = Color(0x1EFFFFFF);
  static const ink = Colors.white;
  static const sub = Color(0xFF8F9BAB);
  static const accent = AppColors.primaryAction;
}
