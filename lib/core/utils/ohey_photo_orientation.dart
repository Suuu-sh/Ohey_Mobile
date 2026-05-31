import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

class OheyPhotoDimensions {
  const OheyPhotoDimensions({required this.width, required this.height});

  final int width;
  final int height;

  bool get isLandscape => width > height;
  bool get isSquare => width == height;
  bool get isSquareOrLandscape => width >= height;
}

Future<OheyPhotoDimensions> oheyReadPhotoDimensions(String path) async {
  final source = File(path);
  if (!await source.exists()) {
    throw StateError('写真ファイルが見つかりません。');
  }

  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final dimensions = OheyPhotoDimensions(
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return dimensions;
}

Future<bool> oheyIsLandscapePhoto(String path) async {
  final dimensions = await oheyReadPhotoDimensions(path);
  return dimensions.isLandscape;
}

Future<bool> oheyIsSquareOrLandscapePhoto(String path) async {
  final dimensions = await oheyReadPhotoDimensions(path);
  return dimensions.isSquareOrLandscape;
}

Future<String> oheyWriteSquarePhotoCopy(String path) async {
  return _oheyWriteCroppedPhotoCopy(
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
    errorMessage: 'ゆるぼを正方形にできませんでした。',
  );
}

Future<String> oheyWriteLandscapePhotoCopy(String path) async {
  final dimensions = await oheyReadPhotoDimensions(path);
  if (!dimensions.isLandscape) {
    throw StateError('16:9はカメラを横にして撮影してください。');
  }

  const targetAspectRatio = 16 / 9;
  return _oheyWriteCroppedPhotoCopy(
    path,
    prefix: 'landscape_16_9',
    sourceRectFor: (width, height) {
      final sourceAspectRatio = width / height;
      final cropWidth = sourceAspectRatio > targetAspectRatio
          ? height * targetAspectRatio
          : width;
      final cropHeight = sourceAspectRatio > targetAspectRatio
          ? height
          : width / targetAspectRatio;
      return ui.Rect.fromLTWH(
        (width - cropWidth) / 2,
        (height - cropHeight) / 2,
        cropWidth,
        cropHeight,
      );
    },
    errorMessage: 'ゆるぼを16:9にできませんでした。',
  );
}

Future<String> _oheyWriteCroppedPhotoCopy(
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
      '${Directory.systemTemp.path}/ohey_${prefix}_${DateTime.now().microsecondsSinceEpoch}.png';
  await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());
  image.dispose();
  output.dispose();
  picture.dispose();
  return outputPath;
}
