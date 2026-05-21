import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

class NomoPhotoDimensions {
  const NomoPhotoDimensions({required this.width, required this.height});

  final int width;
  final int height;

  bool get isLandscape => width > height;
  bool get isSquare => width == height;
  bool get isSquareOrLandscape => width >= height;
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

Future<bool> nomoIsSquareOrLandscapePhoto(String path) async {
  final dimensions = await nomoReadPhotoDimensions(path);
  return dimensions.isSquareOrLandscape;
}

Future<String> nomoWriteSquarePhotoCopy(String path) async {
  return _nomoWriteCroppedPhotoCopy(
    path,
    prefix: 'square',
    sourceRectFor: (width, height) {
      final side = math.min(width, height);
      return ui.Rect.fromLTWH(
        (width - side) / 2,
        (height - side) / 2,
        side,
        side,
      );
    },
    errorMessage: '写真を正方形にできませんでした。',
  );
}

Future<String> nomoWriteLandscapePhotoCopy(String path) async {
  final dimensions = await nomoReadPhotoDimensions(path);
  if (dimensions.isLandscape) return path;
  throw StateError('横長はカメラを横にして撮影してください。');
}

Future<String> _nomoWriteCroppedPhotoCopy(
  String path, {
  required String prefix,
  required ui.Rect Function(double width, double height) sourceRectFor,
  required String errorMessage,
}) async {
  final source = File(path);
  if (!await source.exists()) {
    throw StateError('写真ファイルが見つかりません。');
  }

  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final width = image.width.toDouble();
  final height = image.height.toDouble();
  final sourceRect = sourceRectFor(width, height);
  final targetRect = ui.Rect.fromLTWH(
    0,
    0,
    sourceRect.width,
    sourceRect.height,
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    sourceRect,
    targetRect,
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final output = await picture.toImage(
    sourceRect.width.round(),
    sourceRect.height.round(),
  );
  final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError(errorMessage);
  }

  final outputPath =
      '${Directory.systemTemp.path}/nomo_${prefix}_${DateTime.now().microsecondsSinceEpoch}.png';
  await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());
  image.dispose();
  output.dispose();
  picture.dispose();
  return outputPath;
}
