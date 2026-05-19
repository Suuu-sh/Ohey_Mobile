import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/utils/nomo_photo_orientation.dart';

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

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _isInitializingCamera = true;
  bool _showStoryPreview = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCamera();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera({int? cameraIndex}) async {
    setState(() => _isInitializingCamera = true);
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _cameraController = null;
          _isInitializingCamera = false;
        });
        return;
      }

      final nextIndex =
          cameraIndex ??
          cameras.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );
      final resolvedIndex = nextIndex < 0 ? 0 : nextIndex % cameras.length;
      final previous = _cameraController;
      _cameraController = null;
      await previous?.dispose();

      final controller = CameraController(
        cameras[resolvedIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.lockCaptureOrientation(
          DeviceOrientation.landscapeLeft,
        );
      } on CameraException {
        // Capture is still validated after shooting/selection.
      }
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameras = cameras;
        _cameraIndex = resolvedIndex;
        _cameraController = controller;
        _isInitializingCamera = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _isInitializingCamera = false);
      _showSnack(_cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isInitializingCamera = false);
      _showSnack('カメラを起動できませんでした。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _CameraColors.shell,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreviewStage(
            filter: _filter,
            showStoryPreview: _showStoryPreview,
            onClose: () => Navigator.of(context).maybePop(),
            cameraController: _cameraController,
            isInitializingCamera: _isInitializingCamera,
            onBackToCamera: () => setState(() => _showStoryPreview = false),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomCameraBar(
                    filter: _filter,
                    isCapturing: _isCapturing,
                    onPickAlbum: _pickFromAlbum,
                    onCapture: _capture,
                    onFlip: _flipCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showSnack('カメラの準備中です。');
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final shot = await controller.takePicture();
      if (!mounted) return;
      if (!await _ensureLandscapePhoto(shot.path) || !mounted) return;
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      Navigator.of(
        context,
      ).pop(NomoCameraResult(path: shot.path, filterName: _filter.name));
    } on CameraException catch (error) {
      if (mounted) _showSnack(_cameraErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isInitializingCamera) return;
    await _initializeCamera(cameraIndex: (_cameraIndex + 1) % _cameras.length);
  }

  Future<void> _pickFromAlbum() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;
      if (!await _ensureLandscapePhoto(picked.path) || !mounted) return;
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      Navigator.of(
        context,
      ).pop(NomoCameraResult(path: picked.path, filterName: _filter.name));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<bool> _ensureLandscapePhoto(String path) async {
    try {
      final isLandscape = await nomoIsLandscapePhoto(path);
      if (isLandscape) return true;
      if (mounted) {
        _showSnack('横向き写真のみ投稿できます。端末を横にして撮影してください。');
      }
      return false;
    } catch (_) {
      if (mounted) _showSnack('写真を読み込めませんでした。');
      return false;
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'カメラへのアクセスを許可してください。';
      default:
        return 'カメラを起動できませんでした。';
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
    required this.cameraController,
    required this.isInitializingCamera,
    required this.onClose,
    required this.onBackToCamera,
  });

  final _NomoFilter filter;
  final bool showStoryPreview;
  final CameraController? cameraController;
  final bool isInitializingCamera;
  final VoidCallback onClose;
  final VoidCallback onBackToCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LiveCameraBackground(
            controller: cameraController,
            isInitializing: isInitializingCamera,
            filter: filter,
          ),
          if (showStoryPreview) _StoryPreviewOverlay(onClose: onBackToCamera),
          _TopCameraControls(onClose: onClose),
        ],
      ),
    );
  }
}

class _LiveCameraBackground extends StatelessWidget {
  const _LiveCameraBackground({
    required this.controller,
    required this.isInitializing,
    required this.filter,
  });

  final CameraController? controller;
  final bool isInitializing;
  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final isReady = camera != null && camera.value.isInitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isReady)
          _CoverCameraPreview(controller: camera)
        else
          _CameraUnavailablePlaceholder(isInitializing: isInitializing),
        Positioned.fill(child: ColoredBox(color: filter.overlay)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: .88,
                colors: [Colors.transparent, Color(0xB002090F)],
                stops: [.55, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) return CameraPreview(controller);
        final previewAspect = previewSize.height / previewSize.width;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / previewAspect,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraUnavailablePlaceholder extends StatelessWidget {
  const _CameraUnavailablePlaceholder({required this.isInitializing});

  final bool isInitializing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF060B10), Color(0xFF1C2833)],
        ),
      ),
      child: Center(
        child: isInitializing
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text(
                'カメラを利用できません',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _TopCameraControls extends StatelessWidget {
  const _TopCameraControls({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      top: MediaQuery.paddingOf(context).top + 16,
      child: _CameraIconButton(
        icon: CupertinoIcons.chevron_left,
        semanticLabel: '戻る',
        onTap: onClose,
      ),
    );
  }
}

class _BottomCameraBar extends StatelessWidget {
  const _BottomCameraBar({
    required this.filter,
    required this.isCapturing,
    required this.onPickAlbum,
    required this.onCapture,
    required this.onFlip,
  });

  final _NomoFilter filter;
  final bool isCapturing;
  final VoidCallback onPickAlbum;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterSelectPill(filter: filter),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AlbumButton(onTap: onPickAlbum),
              GestureDetector(
                onTap: onCapture,
                child: _FilterCaptureBubble(
                  filter: filter,
                  isCapturing: isCapturing,
                ),
              ),
              _FlipCameraButton(onTap: onFlip),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSelectPill extends StatelessWidget {
  const _FilterSelectPill({required this.filter});

  final _NomoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NomoGeneratedIcon(
            CupertinoIcons.slider_horizontal_3,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            filter.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumButton extends StatelessWidget {
  const _AlbumButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoundCameraButton(
      semanticLabel: 'アルバムを開く',
      onTap: onTap,
      child: const NomoPopIcon(
        icon: CupertinoIcons.photo_fill,
        color: Color(0xFFFF8BC0),
        size: 34,
        showBubble: false,
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
  const _FilterCaptureBubble({required this.filter, required this.isCapturing});

  final _NomoFilter filter;
  final bool isCapturing;

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
          child: isCapturing
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
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

class _FlipCameraButton extends StatelessWidget {
  const _FlipCameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoundCameraButton(
      semanticLabel: 'カメラ反転',
      onTap: onTap,
      child: const NomoGeneratedIcon(
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
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
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
            child: NomoGeneratedIcon(
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
