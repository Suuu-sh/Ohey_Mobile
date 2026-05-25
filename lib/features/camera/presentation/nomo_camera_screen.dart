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
part 'nomo_camera_lifecycle.dart';
part 'nomo_camera_layout.dart';
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
  static const _avatarFilterName = 'Tomo AR Avatar';
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

  @override
  Widget build(BuildContext context) => _buildCameraScreen(context);
}
