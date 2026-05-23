import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nomo_photo_orientation.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';

part 'nomo_camera_modes.dart';
part 'nomo_camera_preview.dart';
part 'nomo_camera_controls.dart';
part 'nomo_camera_shared_widgets.dart';

const _landscapeCameraControlsWidth = 132.0;

class NomoCameraResult {
  const NomoCameraResult({required this.path, required this.filterName});

  final String path;
  final String filterName;
}

class NomoCameraScreen extends ConsumerStatefulWidget {
  const NomoCameraScreen({super.key});

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
    final padding = MediaQuery.paddingOf(context);

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
            ),
            if (_selectedFraming == _CameraFraming.landscape)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: _landscapeCameraControlsWidth + padding.right,
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
