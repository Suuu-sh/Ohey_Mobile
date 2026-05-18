import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

class NomoCameraResult {
  const NomoCameraResult({required this.path, required this.filterName});

  final String path;
  final String filterName;
}

class NomoCameraScreen extends StatefulWidget {
  const NomoCameraScreen({super.key, this.returnPhoto = false});

  final bool returnPhoto;

  @override
  State<NomoCameraScreen> createState() => _NomoCameraScreenState();
}

class _NomoCameraScreenState extends State<NomoCameraScreen> {
  int _selectedFilterIndex = 0;
  bool _showShareCard = false;

  static const _filters = [
    _NomoFilter(
      name: 'Nomo',
      emoji: '✨',
      gradient: [Color(0xFFFFF6E8), Color(0xFFEFF6FF)],
      overlay: Color(0x00FFFFFF),
    ),
    _NomoFilter(
      name: 'Pastel',
      emoji: '🌸',
      gradient: [Color(0xFFFFEAF1), Color(0xFFEAF5FF)],
      overlay: Color(0x33FFFFFF),
    ),
    _NomoFilter(
      name: 'Cheers',
      emoji: '🍺',
      gradient: [Color(0xFFFFE8B8), Color(0xFFFFF7E5)],
      overlay: Color(0x22F5B84B),
    ),
    _NomoFilter(
      name: 'Night',
      emoji: '🌙',
      gradient: [Color(0xFF101A43), Color(0xFF6A78B7)],
      overlay: Color(0x33202B62),
    ),
    _NomoFilter(
      name: 'Milky',
      emoji: '🫧',
      gradient: [Color(0xFFF9FBFF), Color(0xFFFFEEF4)],
      overlay: Color(0x55FFFFFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = _filters[_selectedFilterIndex];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF101B28),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              sliver: SliverList.list(
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _showShareCard
                        ? _InstagramShareCard(
                            key: ValueKey('share_${filter.name}'),
                            filter: filter,
                            onClose: () =>
                                setState(() => _showShareCard = false),
                          )
                        : _CameraPreviewCard(
                            key: ValueKey('camera_${filter.name}'),
                            filter: filter,
                          ),
                  ),
                  const SizedBox(height: 18),
                  _FilterPicker(
                    filters: _filters,
                    selectedIndex: _selectedFilterIndex,
                    onChanged: (index) =>
                        setState(() => _selectedFilterIndex = index),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _RoundToolButton(
                        icon: CupertinoIcons.sparkles,
                        label: 'スタンプ',
                        onTap: () => _showSnack('Nomoステッカーを追加しました。'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _captureOrPreviewShare,
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: .18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const NomoGeneratedIcon(
                                  CupertinoIcons.camera_fill,
                                  color: Colors.white,
                                  size: 23,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.returnPhoto ? 'フィルターで撮る' : '撮ってシェア',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RoundToolButton(
                        icon: CupertinoIcons.arrow_2_circlepath,
                        label: '反転',
                        onTap: () => _showSnack('カメラ反転は準備中です。'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ShareActions(onSnack: _showSnack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureOrPreviewShare() async {
    final filter = _filters[_selectedFilterIndex];
    if (!widget.returnPhoto) {
      setState(() => _showShareCard = true);
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    Navigator.of(
      context,
    ).pop(NomoCameraResult(path: picked.path, filterName: filter.name));
  }

  void _showSnack(String message) {
    NomoToast.show(context, message);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const NomoGeneratedIcon(
            CupertinoIcons.chevron_left,
            color: AppColors.navy,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const NomoGeneratedIcon(
            CupertinoIcons.ellipsis,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard({super.key, required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    final isNight = filter.name == 'Night';
    final ink = isNight ? Colors.white : AppColors.navy;

    return AspectRatio(
      aspectRatio: 3 / 4.25,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .10),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: filter.gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BokehPainter(isNight: isNight)),
            ),
            Positioned.fill(child: ColoredBox(color: filter.overlay)),
            Positioned(
              left: 22,
              top: 22,
              child: _GlassChip(
                icon: CupertinoIcons.camera_fill,
                label: filter.name,
                dark: isNight,
              ),
            ),
            Positioned(
              right: 20,
              top: 22,
              child: _GlassChip(
                icon: CupertinoIcons.sparkles,
                label: 'Story',
                dark: isNight,
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 32,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isNight ? .18 : .74,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '今日の乾杯  ·  Nomo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '今月の飲みログ',
                    style: TextStyle(
                      color: ink.withValues(alpha: .72),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '3',
                        style: TextStyle(
                          color: ink,
                          fontSize: 58,
                          height: .92,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          '回',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 132,
              child: const NomoAvatarView(
                avatar: NomoAvatar.defaultAvatar,
                size: 132,
              ),
            ),
            const Positioned(
              left: 48,
              top: 118,
              child: _Sparkle(color: AppColors.beer),
            ),
            const Positioned(
              right: 70,
              top: 112,
              child: _Sparkle(color: AppColors.sky),
            ),
            const Positioned(
              left: 78,
              top: 238,
              child: _Sparkle(color: AppColors.peach),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramShareCard extends StatelessWidget {
  const _InstagramShareCard({
    super.key,
    required this.filter,
    required this.onClose,
  });

  final _NomoFilter filter;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isNight = filter.name == 'Night';
    final ink = isNight ? Colors.white : AppColors.navy;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 9 / 14,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: filter.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BokehPainter(isNight: isNight)),
                ),
                Positioned.fill(child: ColoredBox(color: filter.overlay)),
                Positioned(
                  top: 34,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Nomo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  top: 102,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        '今月の飲み回数',
                        style: TextStyle(
                          color: ink.withValues(alpha: .78),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '3',
                            style: TextStyle(
                              color: ink,
                              fontSize: 86,
                              height: .88,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6, bottom: 10),
                            child: Text(
                              '回',
                              style: TextStyle(
                                color: ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 72,
                  child: const NomoAvatarView(
                    avatar: NomoAvatar.defaultAvatar,
                    size: 176,
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isNight ? .18 : .66,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Nomoで今日の乾杯をシェア',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const Positioned(
                  left: 44,
                  top: 176,
                  child: _Sparkle(color: AppColors.sky),
                ),
                const Positioned(
                  right: 50,
                  top: 170,
                  child: _Sparkle(color: AppColors.beer),
                ),
                const Positioned(
                  left: 78,
                  bottom: 238,
                  child: _Sparkle(color: AppColors.peach),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onClose,
          icon: const NomoGeneratedIcon(CupertinoIcons.camera),
          label: const Text('カメラに戻る'),
        ),
      ],
    );
  }
}

class _FilterPicker extends StatelessWidget {
  const _FilterPicker({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_NomoFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 82,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppColors.navy : AppColors.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: filter.gradient),
                    ),
                    child: Text(
                      filter.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filter.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.navy : AppColors.mutedInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShareActions extends StatelessWidget {
  const _ShareActions({required this.onSnack});

  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ShareAction(
            icon: CupertinoIcons.arrow_down_to_line_alt,
            label: '保存',
            onTap: () => onSnack('シェア画像を保存しました。'),
          ),
          _ShareAction.brand(
            label: 'Instagram',
            colors: const [
              Color(0xFFFEDA75),
              Color(0xFFD62976),
              Color(0xFF4F5BD5),
            ],
            onTap: () => onSnack('Instagramストーリーへ共有する準備をしました。'),
          ),
          _ShareAction(
            icon: CupertinoIcons.xmark,
            label: 'X',
            onTap: () => onSnack('Xへ共有する準備をしました。'),
          ),
          _ShareAction.brand(
            label: 'LINE',
            colors: const [Color(0xFF06C755), Color(0xFF06C755)],
            onTap: () => onSnack('LINEへ共有する準備をしました。'),
          ),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : colors = null;
  const _ShareAction.brand({
    required this.label,
    required this.colors,
    required this.onTap,
  }) : icon = null;

  final IconData? icon;
  final String label;
  final List<Color>? colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors == null ? null : LinearGradient(colors: colors!),
              color: colors == null ? AppColors.softGray : null,
            ),
            child: icon == null
                ? Text(
                    label == 'Instagram' ? '◎' : '💬',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  )
                : NomoGeneratedIcon(icon!, color: AppColors.navy, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundToolButton extends StatelessWidget {
  const _RoundToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: NomoGeneratedIcon(icon, color: AppColors.navy),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? .18 : .62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          NomoGeneratedIcon(
            icon,
            size: 16,
            color: dark ? Colors.white : AppColors.navy,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      NomoGeneratedIcon(CupertinoIcons.sparkles, color: color, size: 18);
}

class _BokehPainter extends CustomPainter {
  const _BokehPainter({required this.isNight});

  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final spots = [
      (Offset(size.width * .22, size.height * .22), size.width * .18),
      (Offset(size.width * .78, size.height * .28), size.width * .14),
      (Offset(size.width * .34, size.height * .54), size.width * .22),
      (Offset(size.width * .72, size.height * .62), size.width * .20),
    ];
    for (final spot in spots) {
      paint.color = (isNight ? Colors.white : AppColors.beer).withValues(
        alpha: isNight ? .08 : .12,
      );
      canvas.drawCircle(spot.$1, spot.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter oldDelegate) =>
      oldDelegate.isNight != isNight;
}

class _NomoFilter {
  const _NomoFilter({
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.overlay,
  });

  final String name;
  final String emoji;
  final List<Color> gradient;
  final Color overlay;
}
