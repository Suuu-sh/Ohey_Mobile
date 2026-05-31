part of 'ohey_camera_screen.dart';

class _CameraPreviewStage extends StatelessWidget {
  const _CameraPreviewStage({
    required this.cameraController,
    required this.selectedFilter,
    required this.selectedFraming,
    required this.avatar,
    required this.isInitializingCamera,
    required this.onArViewCreated,
    required this.onToggleFilter,
    required this.onClose,
  });

  final CameraController? cameraController;
  final _CameraFilter selectedFilter;
  final _CameraFraming selectedFraming;
  final OheyAvatar avatar;
  final bool isInitializingCamera;
  final ValueChanged<_ArAvatarCameraController> onArViewCreated;
  final VoidCallback? onToggleFilter;
  final VoidCallback onClose;

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
              framing: selectedFraming,
            ),
          _CameraFrameMask(
            framing: selectedFraming,
            aspectRatio: selectedFraming.frameAspectRatio,
            label: selectedFraming.label,
          ),
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
    required this.framing,
  });

  final CameraController? controller;
  final bool isInitializing;
  final _CameraFraming framing;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final isReady = camera != null && camera.value.isInitialized;
    if (!isReady) {
      return _CameraUnavailablePlaceholder(isInitializing: isInitializing);
    }
    return _PlainCameraPreview(
      controller: camera,
      fillAspectRatio: framing == _CameraFraming.landscape
          ? framing.frameAspectRatio
          : null,
    );
  }
}

class _PlainCameraPreview extends StatelessWidget {
  const _PlainCameraPreview({
    required this.controller,
    required this.fillAspectRatio,
  });

  final CameraController controller;
  final double? fillAspectRatio;

  @override
  Widget build(BuildContext context) {
    final fillAspectRatio = this.fillAspectRatio;
    if (fillAspectRatio == null) {
      // Use the plugin's default preview widget directly for non-wide modes so
      // the existing square/portrait framing keeps its current behavior.
      return Center(child: CameraPreview(controller));
    }

    // In 16:9 landscape mode the camera plugin can report a portrait preview
    // aspect while the app shell is landscape, which leaves only a narrow
    // vertical strip of live camera inside the wide frame. Size the preview as
    // a landscape surface and cover the full stage so everything inside the
    // bracket frame is live camera.
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width / fillAspectRatio;
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(controller),
            ),
          );
        },
      ),
    );
  }
}

class _ArAvatarCameraView extends StatefulWidget {
  const _ArAvatarCameraView({
    required this.avatar,
    required this.filter,
    required this.onCreated,
  });

  final OheyAvatar avatar;
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
      viewType: 'ohey/ar_avatar_camera',
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
    : _channel = MethodChannel('ohey/ar_avatar_camera_$viewId');

  final MethodChannel _channel;

  Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  Future<void> setAvatar(OheyAvatar avatar) {
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
        message: 'ARゆるぼを書き出せませんでした。',
      );
    }
    return path;
  }
}

Map<String, Object?> _avatarPayload(OheyAvatar avatar) => {
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
          final topReserve = useLandscapeLayout ? 0.0 : padding.top + 86;
          final bottomReserve = useLandscapeLayout ? 0.0 : padding.bottom + 196;
          final sideReserve = useLandscapeLayout
              ? _landscapeCameraControlsWidth
              : 0.0;
          const horizontalInset = 0.0;
          final frameAreaWidth = constraints.maxWidth - sideReserve;
          final maxWidth = frameAreaWidth - horizontalInset;
          final maxHeight = constraints.maxHeight - topReserve - bottomReserve;
          final desiredLandscapeHeight = constraints.maxHeight;
          final desiredLandscapeWidth = desiredLandscapeHeight * aspectRatio;
          var frameWidth = useLandscapeLayout
              ? desiredLandscapeWidth
              : maxWidth;
          var frameHeight = useLandscapeLayout
              ? desiredLandscapeHeight
              : frameWidth / aspectRatio;
          if (frameWidth > maxWidth) {
            frameWidth = maxWidth;
            frameHeight = frameWidth / aspectRatio;
          } else if (frameHeight > maxHeight) {
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
              CustomPaint(
                painter: _CameraFrameMaskPainter(
                  rect,
                  isLandscape: useLandscapeLayout,
                ),
              ),
              if (useLandscapeLayout)
                _LandscapeFrameBadge(rect: rect)
              else
                Positioned(
                  left: rect.left + 14,
                  top: rect.top + 14,
                  child: _FrameLabelPill(label: label),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraFrameMaskPainter extends CustomPainter {
  const _CameraFrameMaskPainter(this.frameRect, {required this.isLandscape});

  final Rect frameRect;
  final bool isLandscape;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(isLandscape ? 34 : 28);
    final frame = RRect.fromRectAndRadius(frameRect, radius);
    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: isLandscape ? .30 : .38),
    );
    if (!isLandscape) {
      canvas.drawRRect(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: .88),
      );
      return;
    }

    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: .20),
    );

    final cornerLength = (math.min(frameRect.width, frameRect.height) * .10)
        .clamp(34.0, 64.0);
    final inset = 16.0;
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF28F0E0).withValues(alpha: .96);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF28F0E0).withValues(alpha: .16);

    void drawCorner(Paint paint, bool left, bool top) {
      final x = left ? frameRect.left + inset : frameRect.right - inset;
      final y = top ? frameRect.top + inset : frameRect.bottom - inset;
      final horizontalEnd = left ? x + cornerLength : x - cornerLength;
      final verticalEnd = top ? y + cornerLength : y - cornerLength;
      canvas.drawLine(Offset(x, y), Offset(horizontalEnd, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, verticalEnd), paint);
    }

    for (final paint in [glowPaint, cornerPaint]) {
      drawCorner(paint, true, true);
      drawCorner(paint, false, true);
      drawCorner(paint, true, false);
      drawCorner(paint, false, false);
    }
  }

  @override
  bool shouldRepaint(covariant _CameraFrameMaskPainter oldDelegate) {
    return oldDelegate.frameRect != frameRect ||
        oldDelegate.isLandscape != isLandscape;
  }
}

class _FrameLabelPill extends StatelessWidget {
  const _FrameLabelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .46),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .32)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  );
}

class _LandscapeFrameBadge extends StatelessWidget {
  const _LandscapeFrameBadge({required this.rect});

  final Rect rect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left + 18,
      top: rect.top + 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .34),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF28F0E0).withValues(alpha: .58),
                width: 1.2,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(12, 7, 13, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OheyGeneratedIcon(
                    CupertinoIcons.crop,
                    color: Color(0xFF28F0E0),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '16:9 WIDE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
