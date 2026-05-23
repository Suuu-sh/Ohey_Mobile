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
part 'nomo_camera_actions.dart';

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
}
