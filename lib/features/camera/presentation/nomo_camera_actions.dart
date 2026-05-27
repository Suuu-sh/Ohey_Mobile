// ignore_for_file: invalid_use_of_protected_member

part of 'nomo_camera_screen.dart';

extension _NomoCameraScreenActions on _NomoCameraScreenState {
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
        NomoCameraResult(
          path: outputPath,
          filterName: _NomoCameraScreenState._plainFilterName,
        ),
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
      _CameraFilter.avatar => _CameraFilter.original,
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
        NomoCameraResult(
          path: outputPath,
          filterName: _NomoCameraScreenState._plainFilterName,
        ),
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
