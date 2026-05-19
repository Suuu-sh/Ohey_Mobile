import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';

class NomoCameraResult {
  const NomoCameraResult({required this.path, required this.filterName});

  final String path;
  final String filterName;
}

class NomoCameraScreen extends ConsumerStatefulWidget {
  const NomoCameraScreen({super.key, this.returnPhoto = false});

  final bool returnPhoto;

  @override
  ConsumerState<NomoCameraScreen> createState() => _NomoCameraScreenState();
}

class _NomoCameraScreenState extends ConsumerState<NomoCameraScreen> {
  static const _plainFilterName = 'Original';
  static const _avatarFilterName = 'Nomo AR Avatar';

  CameraController? _cameraController;
  _ArAvatarCameraController? _arCameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _isInitializingCamera = true;
  late bool _useArAvatarFilter = _canUseArAvatarFilter;
  bool _showStoryPreview = false;
  bool _isClosing = false;

  bool get _canUseArAvatarFilter =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (_useArAvatarFilter) {
      _isInitializingCamera = false;
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _restorePortraitOrientation();
    _cameraController?.dispose();
    _arCameraController = null;
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
    final avatar =
        ref.watch(nomoUserProvider)?.avatar ?? NomoAvatar.defaultAvatar;

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
              useArAvatarFilter: _useArAvatarFilter,
              avatar: avatar,
              isInitializingCamera: _isInitializingCamera,
              onArViewCreated: _handleArViewCreated,
              onToggleFilter: _canUseArAvatarFilter
                  ? () => _setAvatarFilterEnabled(!_useArAvatarFilter)
                  : null,
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
    if (_useArAvatarFilter) {
      await _captureArAvatar();
      return;
    }

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

  Future<void> _captureArAvatar() async {
    final controller = _arCameraController;
    if (controller == null) {
      _showSnack('ARカメラの準備中です。');
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final path = await controller.capture();
      if (!mounted) return;
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(path: path, filterName: _avatarFilterName),
      );
    } on PlatformException catch (error) {
      if (mounted) _showSnack(error.message ?? 'AR写真を撮影できませんでした。');
    } catch (_) {
      if (mounted) _showSnack('AR写真を撮影できませんでした。');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_useArAvatarFilter) {
      _showSnack('Nomo ARアバターは前面カメラ専用です。');
      return;
    }
    if (_cameras.length < 2 || _isInitializingCamera) return;
    await _initializeCamera(cameraIndex: (_cameraIndex + 1) % _cameras.length);
  }

  void _handleArViewCreated(_ArAvatarCameraController controller) {
    _arCameraController = controller;
    unawaited(_fallbackToPlainCameraIfArUnsupported(controller));
  }

  Future<void> _fallbackToPlainCameraIfArUnsupported(
    _ArAvatarCameraController controller,
  ) async {
    final isSupported = await controller.isSupported();
    if (!mounted || controller != _arCameraController || !_useArAvatarFilter) {
      return;
    }
    if (isSupported) return;
    _showSnack('この端末ではARアバターを使えないため、通常カメラに切り替えます。');
    await _setAvatarFilterEnabled(false);
  }

  Future<void> _setAvatarFilterEnabled(bool enabled) async {
    if (!_canUseArAvatarFilter && enabled) return;
    if (_useArAvatarFilter == enabled) return;

    setState(() {
      _useArAvatarFilter = enabled;
      _showStoryPreview = false;
      _isInitializingCamera = !enabled;
    });

    if (enabled) {
      _arCameraController = null;
      final previous = _cameraController;
      _cameraController = null;
      await previous?.dispose();
      if (mounted) setState(() => _isInitializingCamera = false);
      return;
    }

    _arCameraController = null;
    await _initializeCamera();
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
    required this.useArAvatarFilter,
    required this.avatar,
    required this.isInitializingCamera,
    required this.onArViewCreated,
    required this.onToggleFilter,
    required this.onClose,
    required this.onBackToCamera,
  });

  final bool showStoryPreview;
  final CameraController? cameraController;
  final bool useArAvatarFilter;
  final NomoAvatar avatar;
  final bool isInitializingCamera;
  final ValueChanged<_ArAvatarCameraController> onArViewCreated;
  final VoidCallback? onToggleFilter;
  final VoidCallback onClose;
  final VoidCallback onBackToCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useArAvatarFilter)
            _ArAvatarCameraView(avatar: avatar, onCreated: onArViewCreated)
          else
            _LiveCameraBackground(
              controller: cameraController,
              isInitializing: isInitializingCamera,
            ),
          if (showStoryPreview) _StoryPreviewOverlay(onClose: onBackToCamera),
          _TopCameraControls(onClose: onClose),
          if (onToggleFilter != null)
            _FilterToggleButton(
              isAvatarFilterEnabled: useArAvatarFilter,
              onTap: onToggleFilter!,
            ),
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

class _ArAvatarCameraView extends StatefulWidget {
  const _ArAvatarCameraView({required this.avatar, required this.onCreated});

  final NomoAvatar avatar;
  final ValueChanged<_ArAvatarCameraController> onCreated;

  @override
  State<_ArAvatarCameraView> createState() => _ArAvatarCameraViewState();
}

class _ArAvatarCameraViewState extends State<_ArAvatarCameraView> {
  _ArAvatarCameraController? _controller;

  @override
  void didUpdateWidget(covariant _ArAvatarCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar.encode() != widget.avatar.encode()) {
      unawaited(_controller?.setAvatar(widget.avatar));
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'nomo/ar_avatar_camera',
      creationParams: {'avatar': _avatarPayload(widget.avatar)},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (viewId) {
        final controller = _ArAvatarCameraController(viewId);
        _controller = controller;
        widget.onCreated(controller);
      },
    );
  }
}

class _ArAvatarCameraController {
  _ArAvatarCameraController(int viewId)
    : _channel = MethodChannel('nomo/ar_avatar_camera_$viewId');

  final MethodChannel _channel;

  Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  Future<void> setAvatar(NomoAvatar avatar) {
    return _channel.invokeMethod<void>('setAvatar', _avatarPayload(avatar));
  }

  Future<String> capture() async {
    final path = await _channel.invokeMethod<String>('capture');
    if (path == null || path.trim().isEmpty) {
      throw PlatformException(
        code: 'empty_snapshot_path',
        message: 'AR写真を書き出せませんでした。',
      );
    }
    return path;
  }
}

Map<String, Object?> _avatarPayload(NomoAvatar avatar) => {
  'skin': avatar.skin,
  'hair': avatar.hair,
  'shirt': avatar.shirt,
  'eyes': avatar.eyes,
  'mouth': avatar.mouth,
  'accessory': avatar.accessory,
  'isAdmin': avatar.isAdmin,
};

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

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.isAvatarFilterEnabled,
    required this.onTap,
  });

  final bool isAvatarFilterEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: MediaQuery.paddingOf(context).top + 16,
      child: Semantics(
        button: true,
        label: isAvatarFilterEnabled ? '通常カメラに切り替え' : 'ARアバターフィルターに切り替え',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isAvatarFilterEnabled
                  ? const Color(0xFFFF4FA2).withValues(alpha: .92)
                  : Colors.black.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: .34)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NomoGeneratedIcon(
                  isAvatarFilterEnabled
                      ? CupertinoIcons.person_crop_circle_fill
                      : CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Text(
                  isAvatarFilterEnabled ? 'Nomo AR' : 'Original',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
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
