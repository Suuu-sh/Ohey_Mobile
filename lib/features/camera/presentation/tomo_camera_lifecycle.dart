// ignore_for_file: invalid_use_of_protected_member

part of 'tomo_camera_screen.dart';

extension _TomoCameraLifecycle on _TomoCameraScreenState {
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

  Future<void> _closeCamera([TomoCameraResult? result]) async {
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
}
