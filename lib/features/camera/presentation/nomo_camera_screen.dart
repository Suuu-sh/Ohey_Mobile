import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';

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
  static const _filter = _NomoFilter(
    name: 'ANALOG NOMO',
    shortName: 'Analog',
    iconText: '4K',
    overlay: Color(0x33FFE0C2),
    vignette: Color(0x66030A10),
  );

  bool _isCapturing = false;
  bool _showStoryPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _CameraColors.shell,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: _CameraPreviewStage(
                  filter: _filter,
                  showStoryPreview: _showStoryPreview,
                  onClose: () => Navigator.of(context).maybePop(),
                  onFlash: () => _showSnack('フラッシュは準備中です。'),
                  onSettings: () => _showSnack('カメラ設定は準備中です。'),
                  onTool: (label) => _showSnack('$label は準備中です。'),
                  onBackToCamera: () =>
                      setState(() => _showStoryPreview = false),
                ),
              ),
            ),
            _InstagramFilterStrip(filter: _filter, onCapture: _capture),
            _BottomCameraBar(
              filter: _filter,
              isCapturing: _isCapturing,
              onCapture: _capture,
              onFlip: () => _showSnack('カメラ反転は準備中です。'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    if (!widget.returnPhoto) {
      setState(() => _showStoryPreview = true);
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;
      Navigator.of(
        context,
      ).pop(NomoCameraResult(path: picked.path, filterName: _filter.name));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showSnack(String message) {
    NomoToast.show(context, message);
  }
}

class _CameraPreviewStage extends StatelessWidget {
  const _CameraPreviewStage({
    required this.filter,
    required this.showStoryPreview,
    required this.onClose,
    required this.onFlash,
    required this.onSettings,
    required this.onTool,
    required this.onBackToCamera,
  });

  final _NomoFilter filter;
  final bool showStoryPreview;
  final VoidCallback onClose;
  final VoidCallback onFlash;
  final VoidCallback onSettings;
  final ValueChanged<String> onTool;
  final VoidCallback onBackToCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(34),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _AnalogPreview(filter: filter),
          if (showStoryPreview) _StoryPreviewOverlay(onClose: onBackToCamera),
          _TopCameraControls(
            onClose: onClose,
            onFlash: onFlash,
            onSettings: onSettings,
          ),
          Positioned(
            left: 26,
            top: 0,
            bottom: 0,
            child: Center(child: _SideToolRail(onTool: onTool)),
          ),
          if (!showStoryPreview)
            Center(
              child: Text(
                '飲みログを撮影',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 14,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalogPreview extends StatelessWidget {
  const _AnalogPreview({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141D23), Color(0xFF76818A), Color(0xFFE7D3C4)],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: const _PreviewPatternPainter()),
        ),
        Positioned.fill(child: ColoredBox(color: filter.overlay)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: .86,
                colors: [Colors.transparent, Color(0x9902090F)],
                stops: [.58, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: filter.vignette.withValues(alpha: .18)),
        ),
      ],
    );
  }
}

class _TopCameraControls extends StatelessWidget {
  const _TopCameraControls({
    required this.onClose,
    required this.onFlash,
    required this.onSettings,
  });

  final VoidCallback onClose;
  final VoidCallback onFlash;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      top: 22,
      child: Row(
        children: [
          _CameraIconButton(icon: CupertinoIcons.xmark, onTap: onClose),
          const Spacer(),
          _CameraIconButton(
            icon: CupertinoIcons.bolt_slash_fill,
            onTap: onFlash,
          ),
          const Spacer(),
          _CameraIconButton(icon: CupertinoIcons.gear_solid, onTap: onSettings),
        ],
      ),
    );
  }
}

class _SideToolRail extends StatelessWidget {
  const _SideToolRail({required this.onTool});

  final ValueChanged<String> onTool;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideToolText(label: 'Aa', onTap: () => onTool('テキスト')),
        const SizedBox(height: 24),
        _SideToolText(label: '∞', onTap: () => onTool('ループ')),
        const SizedBox(height: 24),
        _SideToolIcon(
          icon: CupertinoIcons.rectangle_split_3x1,
          onTap: () => onTool('レイアウト'),
        ),
        const SizedBox(height: 24),
        _SideToolIcon(
          icon: CupertinoIcons.smallcircle_fill_circle,
          onTap: () => onTool('撮影モード'),
        ),
      ],
    );
  }
}

class _InstagramFilterStrip extends StatelessWidget {
  const _InstagramFilterStrip({required this.filter, required this.onCapture});

  final _NomoFilter filter;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -66),
      child: SizedBox(
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 28,
              bottom: 16,
              child: _TinyGalleryPreview(filter: filter),
            ),
            Center(
              child: GestureDetector(
                onTap: onCapture,
                child: _FilterCaptureBubble(filter: filter),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 16,
              child: _TinyFilterPreview(filter: filter),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCameraBar extends StatelessWidget {
  const _BottomCameraBar({
    required this.filter,
    required this.isCapturing,
    required this.onCapture,
    required this.onFlip,
  });

  final _NomoFilter filter;
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -46),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Row(
          children: [
            _RecentShotThumb(filter: filter),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onCapture,
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F353D),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const NomoGeneratedIcon(
                        CupertinoIcons.bookmark,
                        color: Colors.white70,
                        size: 24,
                      ),
                      const Spacer(),
                      if (isCapturing)
                        const CupertinoActivityIndicator(color: Colors.white)
                      else
                        Text(
                          filter.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .6,
                          ),
                        ),
                      const Spacer(),
                      const NomoGeneratedIcon(
                        CupertinoIcons.xmark_circle,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _FlipCameraButton(onTap: onFlip),
          ],
        ),
      ),
    );
  }
}

class _StoryPreviewOverlay extends StatelessWidget {
  const _StoryPreviewOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28)),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Story Preview',
                  style: TextStyle(
                    color: Color(0xFF101820),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ANALOG NOMOで撮影した雰囲気をここで確認できます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF66717D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF101820),
                  onPressed: onClose,
                  child: const Text(
                    'カメラに戻る',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _FilterCaptureBubble extends StatelessWidget {
  const _FilterCaptureBubble({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .95),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2B33), Color(0xFFF0CDB8)],
          ),
        ),
        child: Center(
          child: Text(
            filter.shortName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyGalleryPreview extends StatelessWidget {
  const _TinyGalleryPreview({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF111820), Color(0xFFD4C0AE)],
        ),
      ),
      child: Center(
        child: Text(
          filter.iconText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TinyFilterPreview extends StatelessWidget {
  const _TinyFilterPreview({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .18),
        border: Border.all(color: Colors.white70, width: 2),
      ),
      child: const NomoGeneratedIcon(
        CupertinoIcons.sparkles,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _RecentShotThumb extends StatelessWidget {
  const _RecentShotThumb({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white70, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF111820), Color(0xFFCDB7A6)],
        ),
      ),
      child: Center(
        child: Text(
          filter.iconText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2F353D),
        ),
        child: const NomoGeneratedIcon(
          CupertinoIcons.arrow_2_circlepath,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Center(
          child: NomoGeneratedIcon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _SideToolText extends StatelessWidget {
  const _SideToolText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 38,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideToolIcon extends StatelessWidget {
  const _SideToolIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 38,
        child: Center(
          child: NomoGeneratedIcon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _PreviewPatternPainter extends CustomPainter {
  const _PreviewPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: .18);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFE0C2).withValues(alpha: .10);

    canvas.drawCircle(
      Offset(size.width * .78, size.height * .18),
      size.width * .28,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * .22, size.height * .82),
      size.width * .32,
      glow,
    );

    const step = 54.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), step * .64, line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPatternPainter oldDelegate) => false;
}

class _NomoFilter {
  const _NomoFilter({
    required this.name,
    required this.shortName,
    required this.iconText,
    required this.overlay,
    required this.vignette,
  });

  final String name;
  final String shortName;
  final String iconText;
  final Color overlay;
  final Color vignette;
}

class _CameraColors {
  const _CameraColors._();

  static const shell = Color(0xFF050B10);
}
