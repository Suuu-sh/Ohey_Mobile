part of 'tomo_camera_screen.dart';

class _AlbumButton extends StatelessWidget {
  const _AlbumButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoundCameraButton(
      semanticLabel: 'アルバムを開く',
      onTap: onTap,
      child: const TomoPopIcon(
        icon: CupertinoIcons.photo_fill,
        color: Colors.white,
        size: 34,
        showBubble: false,
      ),
    );
  }
}

class _PlainCaptureButton extends StatelessWidget {
  const _PlainCaptureButton({required this.isCapturing});

  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        color: Colors.white.withValues(alpha: .12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: isCapturing
              ? const CupertinoActivityIndicator(color: Colors.black)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FlipCameraButton extends StatelessWidget {
  const _FlipCameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoundCameraButton(
      semanticLabel: 'カメラ反転',
      onTap: onTap,
      child: const TomoGeneratedIcon(
        CupertinoIcons.arrow_2_circlepath,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _RoundCameraButton extends StatelessWidget {
  const _RoundCameraButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: .42),
            border: Border.all(color: Colors.white.withValues(alpha: .32)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .34),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: TomoGeneratedIcon(
              icon,
              color: Colors.white,
              size: icon == CupertinoIcons.chevron_left ? 30 : 27,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraColors {
  const _CameraColors._();

  static const shell = AppColors.darkBackground;
}
