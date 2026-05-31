part of 'home_screen.dart';

class _FeedBackground extends ConsumerWidget {
  const _FeedBackground({required this.child});
  final Widget child;

  _FeedBackground copyWith({Widget? child}) =>
      _FeedBackground(child: child ?? this.child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWhite = ref.watch(oheyThemeModeProvider).isWhite;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
              : AppColors.darkBackgroundGradient,
        ),
      ),
      child: child,
    );
  }
}

class _FeedHeaderBackdropLayer extends StatelessWidget {
  const _FeedHeaderBackdropLayer({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final height = _feedHeaderScrollInset(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: IgnorePointer(
        child: ClipRect(
          child: OheySceneHeaderBackdrop(
            assetPath: 'assets/images/feed_header_scene_clear.png',
            fadeColor: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
            accentColor: _FeedColors.teal,
            imageTopOffset: 0,
            topShadeOpacity: 0,
            midShadeOpacity: 0,
            fadeStartOpacity: .18,
          ),
        ),
      ),
    );
  }
}

class _FeedHeaderControlsLayer extends StatelessWidget {
  const _FeedHeaderControlsLayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = OheyPageHeader.sceneBackdropHeight(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OheyPageHeader.horizontalPadding,
            OheyPageHeader.topPadding,
            OheyPageHeader.horizontalPadding,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}
