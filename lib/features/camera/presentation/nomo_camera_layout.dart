// ignore_for_file: invalid_use_of_protected_member

part of 'nomo_camera_screen.dart';

extension _NomoCameraLayout on _NomoCameraScreenState {
  Widget _buildCameraScreen(BuildContext context) {
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
