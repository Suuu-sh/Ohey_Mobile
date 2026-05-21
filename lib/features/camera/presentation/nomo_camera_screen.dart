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
import '../../../core/utils/nomo_photo_orientation.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';

const _landscapeCameraControlsWidth = 132.0;

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
  static const _naturalFilterName = 'Natural';

  CameraController? _cameraController;
  _ArAvatarCameraController? _arCameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _isInitializingCamera = true;
  late _CameraFilter _selectedFilter = _canUseArFilters
      ? _CameraFilter.avatar
      : _CameraFilter.original;
  _CameraFraming _selectedFraming = _CameraFraming.square;
  bool _showStoryPreview = false;
  bool _isClosing = false;

  bool get _canUseArFilters =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    unawaited(_applyOrientationForFraming(_selectedFraming));
    if (_selectedFilter.usesArFaceTracking) {
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

  Future<void> _applyOrientationForFraming(_CameraFraming framing) async {
    await SystemChrome.setPreferredOrientations(
      framing == _CameraFraming.square
          ? const [DeviceOrientation.portraitUp]
          : const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    await _configureCaptureOrientation(controller, framing);
  }

  Future<void> _configureCaptureOrientation(
    CameraController controller,
    _CameraFraming framing,
  ) async {
    try {
      if (framing == _CameraFraming.square) {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        return;
      }
      await controller.unlockCaptureOrientation();
    } on CameraException {
      // Keep the camera usable even if capture orientation locking fails.
    }
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
      await _configureCaptureOrientation(controller, _selectedFraming);
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
              selectedFilter: _selectedFilter,
              selectedFraming: _selectedFraming,
              avatar: avatar,
              isInitializingCamera: _isInitializingCamera,
              onArViewCreated: _handleArViewCreated,
              onToggleFilter:
                  _canUseArFilters && _selectedFraming.allowsArFilters
                  ? _selectNextFilter
                  : null,
              onBackToCamera: () => setState(() => _showStoryPreview = false),
            ),
            if (_selectedFraming == _CameraFraming.landscape)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: _landscapeCameraControlsWidth,
                child: SafeArea(
                  left: false,
                  child: _LandscapeCameraControls(
                    isCapturing: _isCapturing,
                    selectedFraming: _selectedFraming,
                    onFramingChanged: _setFraming,
                    onPickAlbum: _pickFromAlbum,
                    onCapture: _capture,
                    onFlip: _flipCamera,
                  ),
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _BottomCameraControls(
                    isCapturing: _isCapturing,
                    selectedFraming: _selectedFraming,
                    onFramingChanged: _setFraming,
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
    if (_selectedFilter.usesArFaceTracking) {
      await _captureArFilter();
      return;
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showSnack('カメラの準備中です。');
      return;
    }

    final canCapture = await _prepareForCapture(controller);
    if (!canCapture) return;

    setState(() => _isCapturing = true);
    try {
      final shot = await controller.takePicture();
      if (!mounted) return;
      final outputPath = await _photoPathForSelectedFraming(shot.path);
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(path: outputPath, filterName: _plainFilterName),
      );
    } on CameraException catch (error) {
      if (mounted) _showSnack(_cameraErrorMessage(error));
    } on StateError catch (error) {
      if (mounted) _showSnack(error.message);
    } catch (_) {
      if (mounted) _showSnack('写真を処理できませんでした。');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _captureArFilter() async {
    final controller = _arCameraController;
    if (controller == null) {
      _showSnack('ARカメラの準備中です。');
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final path = await controller.capture();
      if (!mounted) return;
      final outputPath = await _photoPathForSelectedFraming(path);
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(
          path: outputPath,
          filterName: _selectedFilter.resultName,
        ),
      );
    } on PlatformException catch (error) {
      if (mounted) _showSnack(error.message ?? 'AR写真を撮影できませんでした。');
    } on StateError catch (error) {
      if (mounted) _showSnack(error.message);
    } catch (_) {
      if (mounted) _showSnack('AR写真を撮影できませんでした。');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<bool> _prepareForCapture(CameraController controller) async {
    if (_selectedFraming != _CameraFraming.landscape) return true;
    final orientation = _currentLandscapeOrientation(controller);
    if (orientation == null) {
      _showSnack('16:9はカメラを横にして撮影してください。');
      return false;
    }
    try {
      await controller.lockCaptureOrientation(orientation);
    } on CameraException {
      // If locking fails, the raw photo validation still prevents portrait posts.
    }
    return true;
  }

  DeviceOrientation? _currentLandscapeOrientation(CameraController controller) {
    final deviceOrientation = controller.value.deviceOrientation;
    if (deviceOrientation == DeviceOrientation.landscapeLeft ||
        deviceOrientation == DeviceOrientation.landscapeRight) {
      return deviceOrientation;
    }
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return DeviceOrientation.landscapeLeft;
    }
    return null;
  }

  Future<void> _setFraming(_CameraFraming framing) async {
    if (_selectedFraming == framing || _isCapturing) return;
    await HapticFeedback.selectionClick();
    setState(() => _selectedFraming = framing);
    await _applyOrientationForFraming(framing);
    if (framing == _CameraFraming.landscape &&
        _selectedFilter.usesArFaceTracking) {
      await _setFilter(_CameraFilter.original);
    }
  }

  Future<String> _photoPathForSelectedFraming(String path) async {
    return switch (_selectedFraming) {
      _CameraFraming.square => nomoWriteSquarePhotoCopy(path),
      _CameraFraming.landscape => nomoWriteLandscapePhotoCopy(path),
    };
  }

  Future<void> _flipCamera() async {
    if (_selectedFilter.usesArFaceTracking) {
      _showSnack('${_selectedFilter.label}は前面カメラ専用です。');
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
    if (!mounted ||
        controller != _arCameraController ||
        !_selectedFilter.usesArFaceTracking) {
      return;
    }
    if (isSupported) return;
    _showSnack('この端末ではARフィルターを使えないため、通常カメラに切り替えます。');
    await _setFilter(_CameraFilter.original);
  }

  Future<void> _selectNextFilter() async {
    final next = switch (_selectedFilter) {
      _CameraFilter.avatar => _CameraFilter.natural,
      _CameraFilter.natural => _CameraFilter.original,
      _CameraFilter.original => _CameraFilter.avatar,
    };
    await _setFilter(next);
  }

  Future<void> _setFilter(_CameraFilter filter) async {
    if (!_canUseArFilters && filter.usesArFaceTracking) return;
    if (filter.usesArFaceTracking && !_selectedFraming.allowsArFilters) {
      await _setFraming(_CameraFraming.square);
    }
    if (_selectedFilter == filter) return;

    final wasUsingAr = _selectedFilter.usesArFaceTracking;
    final willUseAr = filter.usesArFaceTracking;

    setState(() {
      _selectedFilter = filter;
      _showStoryPreview = false;
      _isInitializingCamera = !willUseAr;
    });

    if (willUseAr && wasUsingAr) {
      await _arCameraController?.setFilterMode(filter);
      return;
    }

    if (willUseAr) {
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
      final outputPath = await _photoPathFromAlbum(picked.path);
      if (outputPath == null || !mounted) return;
      if (!widget.returnPhoto) {
        setState(() => _showStoryPreview = true);
        return;
      }
      await _closeCamera(
        NomoCameraResult(path: outputPath, filterName: _plainFilterName),
      );
    } catch (_) {
      if (mounted) _showSnack('写真を読み込めませんでした。');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<String?> _photoPathFromAlbum(String path) async {
    if (_selectedFraming == _CameraFraming.square) {
      return nomoWriteSquarePhotoCopy(path);
    }
    final dimensions = await nomoReadPhotoDimensions(path);
    if (dimensions.isLandscape) return nomoWriteLandscapePhotoCopy(path);
    _showSnack('16:9は横向きの写真を選んでください。');
    return null;
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

enum _CameraFilter {
  original,
  avatar,
  natural;

  bool get usesArFaceTracking => this != original;

  String get modeName => switch (this) {
    original => 'original',
    avatar => 'avatar',
    natural => 'natural',
  };

  String get label => switch (this) {
    original => 'Original',
    avatar => 'Nomo AR',
    natural => 'Natural',
  };

  String get resultName => switch (this) {
    original => _NomoCameraScreenState._plainFilterName,
    avatar => _NomoCameraScreenState._avatarFilterName,
    natural => _NomoCameraScreenState._naturalFilterName,
  };

  IconData get icon => switch (this) {
    original => CupertinoIcons.sparkles,
    avatar => CupertinoIcons.person_crop_circle_fill,
    natural => CupertinoIcons.wand_stars,
  };

  Color get buttonColor => switch (this) {
    original => Colors.black.withValues(alpha: .42),
    avatar => const Color(0xFFFF4FA2).withValues(alpha: .92),
    natural => const Color(0xFF47C9B6).withValues(alpha: .92),
  };
}

enum _CameraFraming {
  square,
  landscape;

  bool get allowsArFilters => this == square;

  String get label => switch (this) {
    square => '1:1',
    landscape => '16:9',
  };

  String get description => switch (this) {
    square => '縦撮り',
    landscape => '横撮り',
  };

  double get frameAspectRatio => switch (this) {
    square => 1,
    landscape => 16 / 9,
  };

  String get semanticLabel => switch (this) {
    square => '縦撮り 1対1',
    landscape => '横撮り 16対9',
  };
}

class _CameraPreviewStage extends StatelessWidget {
  const _CameraPreviewStage({
    required this.showStoryPreview,
    required this.cameraController,
    required this.selectedFilter,
    required this.selectedFraming,
    required this.avatar,
    required this.isInitializingCamera,
    required this.onArViewCreated,
    required this.onToggleFilter,
    required this.onClose,
    required this.onBackToCamera,
  });

  final bool showStoryPreview;
  final CameraController? cameraController;
  final _CameraFilter selectedFilter;
  final _CameraFraming selectedFraming;
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
          if (selectedFilter.usesArFaceTracking)
            _ArAvatarCameraView(
              avatar: avatar,
              filter: selectedFilter,
              onCreated: onArViewCreated,
            )
          else
            _LiveCameraBackground(
              controller: cameraController,
              isInitializing: isInitializingCamera,
            ),
          _CameraFrameMask(
            framing: selectedFraming,
            aspectRatio: selectedFraming.frameAspectRatio,
            label: selectedFraming.label,
          ),
          if (showStoryPreview) _StoryPreviewOverlay(onClose: onBackToCamera),
          _TopCameraControls(onClose: onClose),
          if (onToggleFilter != null)
            _FilterToggleButton(
              selectedFilter: selectedFilter,
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
  const _ArAvatarCameraView({
    required this.avatar,
    required this.filter,
    required this.onCreated,
  });

  final NomoAvatar avatar;
  final _CameraFilter filter;
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
    if (oldWidget.filter != widget.filter) {
      unawaited(_controller?.setFilterMode(widget.filter));
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'nomo/ar_avatar_camera',
      creationParams: {
        'avatar': _avatarPayload(widget.avatar),
        'filterMode': widget.filter.modeName,
      },
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

  Future<void> setFilterMode(_CameraFilter filter) {
    return _channel.invokeMethod<void>('setFilterMode', filter.modeName);
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

class _CameraFrameMask extends StatelessWidget {
  const _CameraFrameMask({
    required this.framing,
    required this.aspectRatio,
    required this.label,
  });

  final _CameraFraming framing;
  final double aspectRatio;
  final String label;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useLandscapeLayout =
              framing == _CameraFraming.landscape &&
              constraints.maxWidth > constraints.maxHeight;
          final topReserve = padding.top + (useLandscapeLayout ? 10 : 86);
          final bottomReserve =
              padding.bottom + (useLandscapeLayout ? 10 : 196);
          final sideReserve = useLandscapeLayout
              ? _landscapeCameraControlsWidth + padding.right + 8
              : 0.0;
          final horizontalInset = useLandscapeLayout ? 12.0 : 44.0;
          final frameAreaWidth = constraints.maxWidth - sideReserve;
          final maxWidth = frameAreaWidth - horizontalInset;
          final maxHeight = constraints.maxHeight - topReserve - bottomReserve;
          var frameWidth = maxWidth;
          var frameHeight = frameWidth / aspectRatio;
          if (frameHeight > maxHeight) {
            frameHeight = maxHeight;
            frameWidth = frameHeight * aspectRatio;
          }
          if (frameWidth <= 0 || frameHeight <= 0) {
            return const SizedBox.shrink();
          }
          final left = useLandscapeLayout
              ? (frameAreaWidth - frameWidth) / 2
              : (constraints.maxWidth - frameWidth) / 2;
          final availableTop = topReserve + (maxHeight - frameHeight) / 2;
          final top = availableTop < topReserve ? topReserve : availableTop;
          final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CameraFrameMaskPainter(rect)),
              Positioned(
                left: rect.left + 14,
                top: rect.top + 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .46),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraFrameMaskPainter extends CustomPainter {
  const _CameraFrameMaskPainter(this.frameRect);

  final Rect frameRect;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(frameRect, const Radius.circular(28));
    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: .38),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .88),
    );
  }

  @override
  bool shouldRepaint(covariant _CameraFrameMaskPainter oldDelegate) {
    return oldDelegate.frameRect != frameRect;
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
    required this.selectedFilter,
    required this.onTap,
  });

  final _CameraFilter selectedFilter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: MediaQuery.paddingOf(context).top + 16,
      child: Semantics(
        button: true,
        label: 'フィルター切り替え: ${selectedFilter.label}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: selectedFilter.buttonColor,
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
                  selectedFilter.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Text(
                  selectedFilter.label,
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
    required this.selectedFraming,
    required this.onFramingChanged,
    required this.onPickAlbum,
    required this.onCapture,
    required this.onFlip,
  });

  final bool isCapturing;
  final _CameraFraming selectedFraming;
  final ValueChanged<_CameraFraming> onFramingChanged;
  final VoidCallback onPickAlbum;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FramingModeSelector(
            selectedFraming: selectedFraming,
            onChanged: onFramingChanged,
          ),
          const SizedBox(height: 16),
          Row(
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
        ],
      ),
    );
  }
}

class _LandscapeCameraControls extends StatelessWidget {
  const _LandscapeCameraControls({
    required this.isCapturing,
    required this.selectedFraming,
    required this.onFramingChanged,
    required this.onPickAlbum,
    required this.onCapture,
    required this.onFlip,
  });

  final bool isCapturing;
  final _CameraFraming selectedFraming;
  final ValueChanged<_CameraFraming> onFramingChanged;
  final VoidCallback onPickAlbum;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FramingModeSelector(
            selectedFraming: selectedFraming,
            onChanged: onFramingChanged,
            axis: Axis.vertical,
          ),
          GestureDetector(
            onTap: onCapture,
            child: _PlainCaptureButton(isCapturing: isCapturing),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AlbumButton(onTap: onPickAlbum),
              _FlipCameraButton(onTap: onFlip),
            ],
          ),
        ],
      ),
    );
  }
}

class _FramingModeSelector extends StatelessWidget {
  const _FramingModeSelector({
    required this.selectedFraming,
    required this.onChanged,
    this.axis = Axis.horizontal,
  });

  final _CameraFraming selectedFraming;
  final ValueChanged<_CameraFraming> onChanged;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .44),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Flex(
          direction: axis,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final framing in _CameraFraming.values) ...[
              _FramingModeChip(
                framing: framing,
                isSelected: framing == selectedFraming,
                compact: isVertical,
                onTap: () => onChanged(framing),
              ),
              if (isVertical && framing != _CameraFraming.values.last)
                const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _FramingModeChip extends StatelessWidget {
  const _FramingModeChip({
    required this.framing,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final _CameraFraming framing;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? const Color(0xFF051015) : Colors.white;
    return Semantics(
      button: true,
      selected: isSelected,
      label: framing.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minWidth: compact ? 74 : 86),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF28F0E0) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                framing.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                framing.description,
                style: TextStyle(
                  color: foreground.withValues(alpha: isSelected ? .72 : .66),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ),
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
