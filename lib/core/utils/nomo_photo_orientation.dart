import 'dart:io';
import 'dart:ui' as ui;

class NomoPhotoDimensions {
  const NomoPhotoDimensions({required this.width, required this.height});

  final int width;
  final int height;

  bool get isLandscape => width > height;
}

Future<NomoPhotoDimensions> nomoReadPhotoDimensions(String path) async {
  final source = File(path);
  if (!await source.exists()) {
    throw StateError('写真ファイルが見つかりません。');
  }

  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final dimensions = NomoPhotoDimensions(
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return dimensions;
}

Future<bool> nomoIsLandscapePhoto(String path) async {
  final dimensions = await nomoReadPhotoDimensions(path);
  return dimensions.isLandscape;
}
