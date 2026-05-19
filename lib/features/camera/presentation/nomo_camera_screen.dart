import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
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
  static const _plainFilterName = 'Original';

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _isInitializingCamera = true;
  bool _showStoryPreview = false;
  bool _isClosing = false;

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
    _restorePortraitOrientation();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _restorePortraitOrientation() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _closeCamera([NomoCameraResult? result]) async {
    if (_isClosing) return;
    _isClosing = true;
    await _restorePortraitOrientation();
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(result);
    }
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
        // Keep the plain camera usable even if capture orientation locking fails.
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeCamera();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _CameraColors.shell,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewStage(
              showStoryPreview: _showStoryPreview,
              onClose: _closeCamera,
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
                child: _BottomCameraControls(
                  isCapturing: _isCapturing,
                  onPickAlbum: _pickFromAlbum,
                  onCapture: _capture,
                  onFlip: _flipCamera,
                ),
              ),
            ),
          ],
        ),
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
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(path: shot.path, filterName: _plainFilterName),
      );
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
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(path: picked.path, filterName: _plainFilterName),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
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
    required this.showStoryPreview,
    required this.cameraController,
    required this.isInitializingCamera,
    required this.onClose,
    required this.onBackToCamera,
  });

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
  });

  final CameraController? controller;
  final bool isInitializing;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final isReady = camera != null && camera.value.isInitialized;
    if (!isReady) {
      return _CameraUnavailablePlaceholder(isInitializing: isInitializing);
    }
    return _PlainCameraPreview(controller: camera);
  }
}

class _PlainCameraPreview extends StatelessWidget {
  const _PlainCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // Use the plugin's default preview widget directly so the preview is not
    // stretched, cropped, or tinted by Nomo-specific filters.
    return Center(child: CameraPreview(controller));
  }
}

class _CameraUnavailablePlaceholder extends StatelessWidget {
  const _CameraUnavailablePlaceholder({required this.isInitializing});

  final bool isInitializing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
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

class _BottomCameraControls extends StatelessWidget {
  const _BottomCameraControls({
    required this.isCapturing,
    required this.onPickAlbum,
    required this.onCapture,
    required this.onFlip,
  });

  final bool isCapturing;
  final VoidCallback onPickAlbum;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AlbumButton(onTap: onPickAlbum),
          GestureDetector(
            onTap: onCapture,
            child: _PlainCaptureButton(isCapturing: isCapturing),
          ),
          _FlipCameraButton(onTap: onFlip),
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
        color: Colors.white,
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
                  '撮影しました',
                  style: TextStyle(
                    color: Color(0xFF101820),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'フィルターなしの通常カメラで撮影しています。',
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

class _CameraColors {
  const _CameraColors._();

  static const shell = Color(0xFF050B10);
}
