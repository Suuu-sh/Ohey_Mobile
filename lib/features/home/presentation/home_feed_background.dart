part of 'home_screen.dart';

class _FeedBackground extends ConsumerWidget {
  const _FeedBackground({required this.child});
  final Widget child;

  _FeedBackground copyWith({Widget? child}) =>
      _FeedBackground(child: child ?? this.child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
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
          child: NomoSceneHeaderBackdrop(
            assetPath: 'assets/images/feed_header_scene.png',
            fadeColor: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
            accentColor: _FeedColors.teal,
            topShadeOpacity: .04,
            midShadeOpacity: .01,
            fadeStartOpacity: .56,
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
    final height = NomoPageHeader.sceneBackdropHeight(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NomoPageHeader.horizontalPadding,
            NomoPageHeader.topPadding,
            NomoPageHeader.horizontalPadding,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}
