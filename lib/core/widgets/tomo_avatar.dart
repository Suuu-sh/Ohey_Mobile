import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tomo_avatar.dart';

class TomoAvatarView extends StatelessWidget {
  const TomoAvatarView({
    super.key,
    required this.avatar,
    this.size = 160,
    this.showBody = true,
  });

  final TomoAvatar avatar;
  final double size;
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    if (avatar.isAdmin) {
      return ClipOval(
        child: Image.asset(
          'assets/images/admin_tomo_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TomoAvatarPainter(avatar: avatar, showBody: showBody),
      ),
    );
  }
}

class _TomoAvatarPainter extends CustomPainter {
  const _TomoAvatarPainter({required this.avatar, required this.showBody});

  static const double _canvasSize = 180;

  final TomoAvatar avatar;
  final bool showBody;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _canvasSize;
    canvas.save();
    canvas.translate(
      (size.width - _canvasSize * scale) / 2,
      (size.height - _canvasSize * scale) / 2,
    );
    canvas.scale(scale);

    final skin = TomoAvatar.skinColors[avatar.skin];
    final hair =
        TomoAvatar.hairColors[avatar.hair % TomoAvatar.hairColors.length];
    final shirt = TomoAvatar.shirtColors[avatar.shirt];

    _drawHairBack(canvas, hair);
    if (showBody) _drawBody(canvas, skin, shirt);
    _drawEars(canvas, skin);
    _drawHead(canvas, skin);

    _drawHairFront(canvas, hair, shirt);
    _drawEyes(canvas);
    _drawNose(canvas, skin);
    _drawMouth(canvas);
    _drawAccessory(canvas);

    canvas.restore();
  }

  Color _lighten(Color color, double amount) =>
      Color.lerp(color, Colors.white, amount)!;

  Color _darken(Color color, double amount) =>
      Color.lerp(color, Colors.black, amount)!;

  Paint _verticalGradient(Rect rect, Color color, {double top = .12}) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(color, top), color, _darken(color, .14)],
          stops: const [0, .52, 1],
        ).createShader(rect);

  Paint _skinGradient(Rect rect, Color skin) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(skin, .16), skin, _darken(skin, .11)],
          stops: const [0, .54, 1],
        ).createShader(rect);

  void _drawBody(Canvas canvas, Color skin, Color shirt) {
    final neckRect = Rect.fromLTWH(75, 104, 30, 43);
    final neck = RRect.fromRectAndRadius(neckRect, const Radius.circular(12));
    canvas.drawRRect(
      neck.shift(const Offset(0, 2)),
      Paint()..color = _darken(skin, .18).withValues(alpha: .42),
    );
    canvas.drawRRect(neck, _skinGradient(neckRect, skin));

    final shoulders = Path()
      ..moveTo(50, 180)
      ..cubicTo(54, 151, 66, 128, 81, 121)
      ..quadraticBezierTo(90, 131, 99, 121)
      ..cubicTo(114, 128, 126, 151, 130, 180)
      ..close();
    canvas.drawShadow(shoulders, Colors.black.withValues(alpha: .24), 7, true);
    canvas.drawPath(
      shoulders,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(shirt, .16), shirt, _darken(shirt, .13)],
          stops: const [0, .58, 1],
        ).createShader(const Rect.fromLTWH(50, 120, 80, 60)),
    );

    final shirtRim = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(64, 137)
        ..quadraticBezierTo(77, 126, 90, 135)
        ..quadraticBezierTo(103, 126, 116, 137),
      shirtRim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(81, 121)
        ..quadraticBezierTo(90, 131, 99, 121)
        ..lineTo(90, 149)
        ..close(),
      Paint()..color = _darken(shirt, .10).withValues(alpha: .28),
    );
  }

  void _drawEars(Canvas canvas, Color skin) {
    const leftEar = Rect.fromLTWH(31, 74, 28, 26);
    const rightEar = Rect.fromLTWH(121, 74, 28, 26);
    for (final ear in [leftEar, rightEar]) {
      canvas.drawOval(
        ear.shift(const Offset(0, 2)),
        Paint()..color = Colors.black.withValues(alpha: .10),
      );
      canvas.drawOval(ear, _skinGradient(ear, skin));
      final inner = Rect.fromCenter(
        center: ear.center.translate(ear.left < 90 ? 2 : -2, 1),
        width: 12,
        height: 14,
      );
      canvas.drawOval(
        inner,
        Paint()..color = _darken(skin, .16).withValues(alpha: .28),
      );
    }
  }

  void _drawHead(Canvas canvas, Color skin) {
    const headRect = Rect.fromLTWH(38, 34, 104, 102);
    final head = RRect.fromRectAndRadius(headRect, const Radius.circular(32));
    canvas.drawShadow(
      Path()..addRRect(head),
      Colors.black.withValues(alpha: .20),
      9,
      true,
    );
    canvas.drawRRect(
      head.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: .06),
    );
    canvas.drawRRect(head, _skinGradient(headRect, skin));

    canvas.drawRRect(
      head,
      Paint()
        ..color = Colors.white.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 40, 42, 72),
        const Radius.circular(24),
      ),
      Paint()..color = Colors.white.withValues(alpha: .10),
    );
    canvas.drawOval(
      const Rect.fromLTWH(56, 113, 68, 18),
      Paint()..color = _darken(skin, .18).withValues(alpha: .12),
    );
  }

  void _drawHairBack(Canvas canvas, Color color) {
    final paint = _verticalGradient(
      const Rect.fromLTWH(30, 24, 120, 132),
      color,
      top: .08,
    );
    switch (avatar.hair) {
      case 4:
        canvas.drawCircle(const Offset(90, 27), 22, paint);
        canvas.drawCircle(
          const Offset(90, 27),
          13,
          Paint()..color = _lighten(color, .12).withValues(alpha: .65),
        );
      case 6:
        final bob = RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 30, 112, 118),
          const Radius.circular(39),
        );
        canvas.drawShadow(
          Path()..addRRect(bob),
          Colors.black.withValues(alpha: .18),
          7,
          true,
        );
        canvas.drawRRect(bob, paint);
      case 7:
        final long = Path()
          ..moveTo(38, 47)
          ..cubicTo(38, 24, 62, 20, 90, 20)
          ..cubicTo(118, 20, 142, 24, 142, 47)
          ..lineTo(153, 150)
          ..quadraticBezierTo(122, 162, 90, 152)
          ..quadraticBezierTo(58, 162, 27, 150)
          ..close();
        canvas.drawShadow(long, Colors.black.withValues(alpha: .22), 8, true);
        canvas.drawPath(long, paint);
      case 8:
        for (final side in [-1.0, 1.0]) {
          final tail = Path()
            ..moveTo(90 + side * 45, 58)
            ..cubicTo(
              90 + side * 74,
              70,
              90 + side * 78,
              114,
              90 + side * 54,
              139,
            )
            ..cubicTo(
              90 + side * 28,
              122,
              90 + side * 32,
              78,
              90 + side * 45,
              58,
            )
            ..close();
          canvas.drawShadow(tail, Colors.black.withValues(alpha: .18), 6, true);
          canvas.drawPath(tail, paint);
          canvas.drawCircle(
            Offset(90 + side * 46, 67),
            7,
            Paint()..color = const Color(0xFFFF8FB2),
          );
        }
      case 9:
        for (final side in [-1.0, 1.0]) {
          final wave = Path()
            ..moveTo(90 + side * 37, 60)
            ..cubicTo(
              90 + side * 58,
              70,
              90 + side * 54,
              103,
              90 + side * 39,
              124,
            )
            ..cubicTo(
              90 + side * 25,
              110,
              90 + side * 27,
              75,
              90 + side * 37,
              60,
            )
            ..close();
          canvas.drawPath(wave, paint);
        }
      case 11:
        final ponytail = Path()
          ..moveTo(126, 52)
          ..cubicTo(164, 58, 166, 108, 132, 132)
          ..cubicTo(114, 115, 119, 75, 126, 52)
          ..close();
        canvas.drawShadow(
          ponytail,
          Colors.black.withValues(alpha: .18),
          6,
          true,
        );
        canvas.drawPath(ponytail, paint);
        canvas.drawCircle(
          const Offset(126, 62),
          7,
          Paint()..color = const Color(0xFFFF8FB2),
        );
      default:
        return;
    }
  }

  void _drawHairFront(Canvas canvas, Color color, Color shirt) {
    final paint = _verticalGradient(
      const Rect.fromLTWH(34, 20, 112, 68),
      color,
      top: .15,
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    switch (avatar.hair) {
      case 0:
        return;
      case 1:
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(
            Offset(48 + i * 12, 39 + (i.isEven ? 1 : -5)),
            i.isEven ? 13.5 : 12,
            paint,
          );
        }
        for (final point in const [
          Offset(55, 34),
          Offset(83, 28),
          Offset(113, 34),
        ]) {
          canvas.drawCircle(
            point,
            4.2,
            Paint()..color = Colors.white.withValues(alpha: .22),
          );
        }
        canvas.drawCircle(const Offset(42, 61), 10, paint);
        canvas.drawCircle(const Offset(138, 61), 10, paint);
      case 2:
        final short = Path()
          ..moveTo(43, 58)
          ..cubicTo(47, 32, 68, 23, 94, 24)
          ..cubicTo(118, 25, 134, 37, 138, 58)
          ..quadraticBezierTo(121, 48, 105, 55)
          ..quadraticBezierTo(84, 38, 62, 58)
          ..quadraticBezierTo(52, 53, 43, 58)
          ..close();
        canvas.drawPath(short, paint);
        canvas.drawPath(
          Path()
            ..moveTo(64, 43)
            ..quadraticBezierTo(82, 34, 105, 43),
          shine,
        );
      case 3:
        final side = Path()
          ..moveTo(40, 61)
          ..cubicTo(49, 27, 83, 15, 120, 33)
          ..quadraticBezierTo(143, 44, 139, 69)
          ..cubicTo(120, 54, 100, 50, 77, 59)
          ..quadraticBezierTo(60, 66, 43, 75)
          ..close();
        canvas.drawPath(side, paint);
        canvas.drawPath(
          Path()
            ..moveTo(76, 37)
            ..cubicTo(94, 30, 115, 36, 127, 48),
          shine,
        );
      case 4:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 35, 88, 31),
            const Radius.circular(24),
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(62, 47)
            ..quadraticBezierTo(88, 32, 119, 46),
          shine,
        );
      case 5:
        final capColor = shirt;
        final brimColor = _darken(capColor, .12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(45, 29, 90, 37),
            const Radius.circular(24),
          ),
          _verticalGradient(
            const Rect.fromLTWH(45, 29, 90, 37),
            capColor,
            top: .18,
          ),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(57, 54, 66, 18),
            const Radius.circular(13),
          ),
          Paint()..color = brimColor,
        );
        canvas.drawCircle(
          const Offset(90, 30),
          4.4,
          Paint()..color = _lighten(capColor, .22),
        );
        canvas.drawPath(
          Path()
            ..moveTo(90, 34)
            ..lineTo(90, 62),
          Paint()
            ..color = Colors.white.withValues(alpha: .24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      case 6:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 35, 94, 37),
            const Radius.circular(28),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 61, 20, 64),
            const Radius.circular(14),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(117, 61, 20, 64),
            const Radius.circular(14),
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(61, 48)
            ..quadraticBezierTo(90, 35, 121, 49),
          shine,
        );
      case 7:
        canvas.drawPath(
          Path()
            ..moveTo(43, 64)
            ..cubicTo(47, 34, 69, 25, 91, 25)
            ..cubicTo(116, 25, 136, 35, 139, 64)
            ..quadraticBezierTo(122, 52, 103, 59)
            ..quadraticBezierTo(86, 42, 66, 61)
            ..quadraticBezierTo(54, 55, 43, 64)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(61, 43)
            ..cubicTo(79, 33, 105, 34, 124, 47),
          shine,
        );
      case 9:
        canvas.drawPath(
          Path()
            ..moveTo(42, 62)
            ..cubicTo(48, 31, 72, 22, 91, 24)
            ..cubicTo(116, 26, 136, 40, 138, 64)
            ..quadraticBezierTo(122, 51, 106, 59)
            ..quadraticBezierTo(96, 44, 83, 59)
            ..quadraticBezierTo(68, 49, 52, 66)
            ..close(),
          paint,
        );
        for (final curl in const [
          Rect.fromLTWH(44, 63, 19, 29),
          Rect.fromLTWH(117, 62, 19, 30),
        ]) {
          canvas.drawArc(
            curl,
            math.pi * .38,
            math.pi * 1.15,
            false,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(62, 44)
            ..cubicTo(78, 35, 106, 36, 124, 49),
          shine,
        );
      case 10:
        final mash = Path()
          ..moveTo(42, 63)
          ..cubicTo(42, 34, 64, 23, 89, 23)
          ..cubicTo(119, 23, 139, 36, 139, 64)
          ..quadraticBezierTo(130, 66, 121, 62)
          ..quadraticBezierTo(112, 69, 102, 61)
          ..quadraticBezierTo(91, 70, 80, 60)
          ..quadraticBezierTo(68, 69, 58, 61)
          ..quadraticBezierTo(49, 66, 42, 63)
          ..close();
        canvas.drawPath(mash, paint);
        canvas.drawPath(
          Path()
            ..moveTo(60, 42)
            ..quadraticBezierTo(90, 30, 121, 44),
          shine,
        );
      case 11:
        canvas.drawPath(
          Path()
            ..moveTo(43, 62)
            ..cubicTo(48, 32, 70, 24, 91, 24)
            ..cubicTo(114, 24, 135, 35, 139, 62)
            ..quadraticBezierTo(122, 55, 107, 60)
            ..quadraticBezierTo(91, 45, 73, 61)
            ..quadraticBezierTo(59, 56, 43, 62)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(66, 42)
            ..cubicTo(86, 33, 109, 35, 126, 49),
          shine,
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(45, 34, 90, 34),
            const Radius.circular(24),
          ),
          paint,
        );
        canvas.drawCircle(const Offset(56, 44), 16, paint);
        canvas.drawCircle(const Offset(124, 44), 16, paint);
        canvas.drawPath(
          Path()
            ..moveTo(63, 47)
            ..quadraticBezierTo(90, 32, 117, 47),
          shine,
        );
    }
  }

  void _drawEyes(Canvas canvas) {
    final white = Paint()..color = Colors.white;
    final darkColor = const Color(0xFF24313A);

    void eyeShadow(Rect rect) => canvas.drawOval(
      rect.shift(const Offset(0, 1.4)),
      Paint()..color = Colors.black.withValues(alpha: .10),
    );

    void glossyEye({
      required double x,
      double width = 25,
      double height = 34,
      double pupilDx = 2,
      bool roundPupil = false,
      Color? accent,
    }) {
      final rect = Rect.fromCenter(
        center: Offset(x, 78),
        width: width,
        height: height,
      );
      eyeShadow(rect);
      canvas.drawOval(rect, white);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + pupilDx, 81),
          width: roundPupil ? 15 : 11,
          height: roundPupil ? 17 : 25,
        ),
        Paint()..color = accent ?? darkColor,
      );
      canvas.drawCircle(
        Offset(x - 4 + pupilDx * .25, 72),
        3.3,
        Paint()..color = Colors.white.withValues(alpha: .92),
      );
      canvas.drawArc(
        rect.inflate(1.2),
        math.pi * 1.04,
        math.pi * .92,
        false,
        Paint()
          ..color = darkColor.withValues(alpha: .14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    switch (avatar.eyes) {
      case 1:
        final stroke = Paint()
          ..color = darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (final x in [70.0, 110.0]) {
          canvas.drawArc(
            Rect.fromCenter(center: Offset(x, 78), width: 26, height: 16),
            .12,
            math.pi - .24,
            false,
            Paint()
              ..color = Colors.white.withValues(alpha: .60)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawArc(
          const Rect.fromLTWH(60, 72, 24, 16),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(98, 72, 24, 16),
          math.pi,
          math.pi,
          false,
          stroke,
        );
      case 2:
        for (final x in [70.0, 109.0]) {
          glossyEye(
            x: x,
            width: 26,
            height: 36,
            roundPupil: true,
            accent: const Color(0xFF23303C),
          );
          final sparkle = Paint()..color = const Color(0xFFFFD25B);
          canvas.drawPath(
            Path()
              ..moveTo(x + 9, 68)
              ..lineTo(x + 12, 73)
              ..lineTo(x + 17, 76)
              ..lineTo(x + 12, 79)
              ..lineTo(x + 9, 84)
              ..lineTo(x + 6, 79)
              ..lineTo(x + 1, 76)
              ..lineTo(x + 6, 73)
              ..close(),
            sparkle,
          );
        }
      case 3:
        final lash = Paint()
          ..color = darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (final x in [70.0, 109.0]) {
          glossyEye(
            x: x,
            width: 27,
            height: 37,
            roundPupil: true,
            accent: const Color(0xFF202A34),
          );
          canvas.drawLine(Offset(x - 13, 65), Offset(x - 19, 61), lash);
          canvas.drawLine(Offset(x + 13, 65), Offset(x + 19, 61), lash);
        }
      case 4:
        glossyEye(x: 69, width: 26, height: 36, roundPupil: true);
        final winkStroke = Paint()
          ..color = darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          const Rect.fromLTWH(98, 75, 25, 14),
          .2,
          math.pi - .4,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: .66)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawArc(
          const Rect.fromLTWH(98, 73, 25, 16),
          .08,
          math.pi - .16,
          false,
          winkStroke,
        );
      case 5:
        for (final x in [70.0, 109.0]) {
          glossyEye(
            x: x,
            width: 27,
            height: 32,
            pupilDx: x < 90 ? 1 : -1,
            roundPupil: true,
            accent: const Color(0xFF253443),
          );
          canvas.drawArc(
            Rect.fromCenter(center: Offset(x, 68), width: 29, height: 14),
            .15,
            math.pi - .30,
            false,
            Paint()
              ..color = darkColor.withValues(alpha: .62)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
      case 6:
        final sleepy = Paint()
          ..color = darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (final x in [70.0, 109.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, 79), width: 27, height: 14),
              const Radius.circular(9),
            ),
            Paint()..color = Colors.white.withValues(alpha: .76),
          );
          canvas.drawLine(Offset(x - 11, 80), Offset(x + 11, 78), sleepy);
          canvas.drawCircle(
            Offset(x + 3, 81),
            3.4,
            Paint()..color = darkColor.withValues(alpha: .82),
          );
        }
      default:
        glossyEye(x: 70);
        glossyEye(x: 109);
    }
  }

  void _drawNose(Canvas canvas, Color skin) {
    final noseShadow = Paint()
      ..color = _darken(skin, .24).withValues(alpha: .55);
    final nose = Path()
      ..moveTo(90, 84)
      ..cubicTo(98, 94, 99, 103, 89, 106)
      ..cubicTo(83, 104, 84, 96, 90, 84)
      ..close();
    canvas.drawPath(nose, noseShadow);
    canvas.drawPath(
      Path()
        ..moveTo(88, 88)
        ..quadraticBezierTo(92, 96, 88, 101),
      Paint()
        ..color = Colors.white.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawMouth(Canvas canvas) {
    final darkMouth = const Color(0xFF2A1715);
    final stroke = Paint()
      ..color = darkMouth.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    switch (avatar.mouth) {
      case 1:
        final mouth = RRect.fromRectAndRadius(
          const Rect.fromLTWH(73, 101, 34, 20),
          const Radius.circular(13),
        );
        canvas.drawRRect(
          mouth,
          Paint()..color = darkMouth.withValues(alpha: .82),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(78, 101, 24, 8),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.white.withValues(alpha: .92),
        );
        canvas.drawOval(
          const Rect.fromLTWH(83, 112, 15, 7),
          Paint()..color = const Color(0xFFFF6F8F).withValues(alpha: .72),
        );
      case 2:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(78, 105, 25, 7),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFFC94E5D).withValues(alpha: .82),
        );
        canvas.drawCircle(
          const Offset(99, 107),
          2.2,
          Paint()..color = Colors.white.withValues(alpha: .60),
        );
      case 3:
        canvas.drawOval(
          const Rect.fromLTWH(80, 101, 20, 24),
          Paint()..color = darkMouth.withValues(alpha: .82),
        );
        canvas.drawOval(
          const Rect.fromLTWH(85, 106, 10, 12),
          Paint()..color = const Color(0xFFFF8FA6).withValues(alpha: .72),
        );
        canvas.drawOval(
          const Rect.fromLTWH(84, 103, 7, 4),
          Paint()..color = Colors.white.withValues(alpha: .50),
        );
      case 4:
        final smile = Path()
          ..moveTo(75, 103)
          ..cubicTo(83, 111, 97, 112, 106, 103);
        canvas.drawPath(
          smile,
          Paint()
            ..color = darkMouth.withValues(alpha: .58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.7
            ..strokeCap = StrokeCap.round,
        );
        for (final point in const [Offset(71, 101), Offset(110, 101)]) {
          canvas.drawCircle(
            point,
            2.2,
            Paint()..color = darkMouth.withValues(alpha: .22),
          );
        }
      case 5:
        canvas.drawPath(
          Path()
            ..moveTo(78, 106)
            ..quadraticBezierTo(90, 101, 102, 106)
            ..quadraticBezierTo(90, 112, 78, 106)
            ..close(),
          Paint()..color = const Color(0xFFC94E5D).withValues(alpha: .82),
        );
        canvas.drawLine(
          const Offset(82, 106),
          const Offset(98, 106),
          Paint()
            ..color = Colors.white.withValues(alpha: .26)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      default:
        final path = Path()
          ..moveTo(72, 101)
          ..cubicTo(80, 113, 95, 117, 108, 104);
        canvas.drawPath(
          path.shift(const Offset(0, 1.2)),
          Paint()
            ..color = Colors.white.withValues(alpha: .28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(path, stroke);
        canvas.drawCircle(
          const Offset(74, 101),
          2.2,
          Paint()..color = darkMouth.withValues(alpha: .34),
        );
    }
  }

  void _drawAccessory(Canvas canvas) {
    if (avatar.accessory == 1) {
      final stroke = Paint()
        ..color = const Color(0xFF151D24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeJoin = StrokeJoin.round;
      for (final rect in const [
        Rect.fromLTWH(53, 66, 33, 29),
        Rect.fromLTWH(94, 66, 33, 29),
      ]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(11)),
          Paint()..color = Colors.white.withValues(alpha: .18),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(11)),
          stroke,
        );
        canvas.drawLine(
          rect.topLeft + const Offset(8, 6),
          rect.topLeft + const Offset(18, 2),
          Paint()
            ..color = Colors.white.withValues(alpha: .72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(const Offset(86, 79), const Offset(94, 79), stroke);
    } else if (avatar.accessory == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(60, 94, 60, 27),
          const Radius.circular(15),
        ),
        Paint()..color = Colors.white.withValues(alpha: .90),
      );
      for (final y in [101.0, 108.0, 115.0]) {
        canvas.drawLine(
          Offset(66, y),
          Offset(114, y),
          Paint()
            ..color = const Color(0xFF8EA0AD).withValues(alpha: .24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(
        const Offset(60, 103),
        const Offset(49, 96),
        Paint()
          ..color = Colors.white.withValues(alpha: .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawLine(
        const Offset(120, 103),
        const Offset(131, 96),
        Paint()
          ..color = Colors.white.withValues(alpha: .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    } else if (avatar.accessory == 3) {
      final blush = Paint()
        ..color = const Color(0xFFFF7CA8).withValues(alpha: .62);
      canvas.drawOval(const Rect.fromLTWH(49, 93, 20, 12), blush);
      canvas.drawOval(const Rect.fromLTWH(111, 93, 20, 12), blush);
      canvas.drawOval(
        const Rect.fromLTWH(53, 94, 8, 4),
        Paint()..color = Colors.white.withValues(alpha: .24),
      );
      canvas.drawOval(
        const Rect.fromLTWH(115, 94, 8, 4),
        Paint()..color = Colors.white.withValues(alpha: .24),
      );
    } else if (avatar.accessory == 4) {
      final freckle = Paint()
        ..color = const Color(0xFF5C2B22).withValues(alpha: .34);
      for (final point in const [
        Offset(57, 94),
        Offset(64, 98),
        Offset(70, 93),
        Offset(110, 94),
        Offset(117, 98),
        Offset(123, 93),
      ]) {
        canvas.drawCircle(point, 1.8, freckle);
      }
    } else if (avatar.accessory == 5) {
      canvas.drawCircle(
        const Offset(116, 101),
        2.7,
        Paint()..color = const Color(0xFF2A1715).withValues(alpha: .74),
      );
      canvas.drawCircle(
        const Offset(115.3, 100.2),
        .8,
        Paint()..color = Colors.white.withValues(alpha: .55),
      );
    } else if (avatar.accessory == 6) {
      final frame = Paint()
        ..color = const Color(0xFF25313E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        const Rect.fromLTWH(44, 34, 92, 76),
        math.pi * 1.12,
        math.pi * .76,
        false,
        frame,
      );
      for (final cup in const [
        Rect.fromLTWH(37, 73, 18, 32),
        Rect.fromLTWH(125, 73, 18, 32),
      ]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(cup, const Radius.circular(9)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5869FF), Color(0xFF21E0C2)],
            ).createShader(cup),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cup.deflate(4), const Radius.circular(6)),
          Paint()..color = const Color(0xFF101820).withValues(alpha: .28),
        );
      }
    } else if (avatar.accessory == 7) {
      final pinPaint = Paint()
        ..color = const Color(0xFFFFD25B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(51, 53), const Offset(72, 44), pinPaint);
      canvas.drawLine(
        const Offset(54, 60),
        const Offset(75, 51),
        Paint()
          ..color = const Color(0xFFFF8FB2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        const Offset(72, 44),
        3.3,
        Paint()..color = Colors.white.withValues(alpha: .82),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TomoAvatarPainter oldDelegate) {
    return oldDelegate.avatar != avatar || oldDelegate.showBody != showBody;
  }
}
