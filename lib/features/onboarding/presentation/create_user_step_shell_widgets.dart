part of 'create_user_dialog.dart';

class _FullScreenStep extends StatelessWidget {
  const _FullScreenStep({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _fixedAuthPage(
        constraints: constraints,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Center(child: child),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
