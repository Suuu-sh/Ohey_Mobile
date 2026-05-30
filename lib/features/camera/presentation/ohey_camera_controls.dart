part of 'ohey_camera_screen.dart';

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
                OheyGeneratedIcon(
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
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AlbumButton(onTap: onPickAlbum),
              const SizedBox(width: 4),
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
