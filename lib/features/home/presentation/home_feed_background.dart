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

class _FeedHeaderOverlay extends StatelessWidget {
  const _FeedHeaderOverlay({required this.child, required this.isWhite});

  final Widget child;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final height = NomoPageHeader.sceneBackdropHeight(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NomoSceneHeaderBackdrop(
                assetPath: 'assets/images/feed_header_scene.png',
                fadeColor: isWhite
                    ? Colors.white
                    : AppColors.darkBackgroundBottom,
                accentColor: _FeedColors.teal,
                topShadeOpacity: .12,
                fadeStartOpacity: .92,
              ),
              SafeArea(
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
            ],
          ),
        ),
      ),
    );
  }
}
