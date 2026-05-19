import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/nomo_avatar.dart';

class NomoAvatarView extends StatelessWidget {
  const NomoAvatarView({
    super.key,
    required this.avatar,
    this.size = 160,
    this.showBody = true,
  });

  final NomoAvatar avatar;
  final double size;
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NomoAvatarPainter(avatar: avatar, showBody: showBody),
      ),
    );
  }
}

class _NomoAvatarPainter extends CustomPainter {
  const _NomoAvatarPainter({required this.avatar, required this.showBody});

  final NomoAvatar avatar;
  final bool showBody;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 180;
    canvas.save();
    canvas.scale(scale);

    if (avatar.isAdmin) {
      _drawAdminMascot(canvas, showBody: showBody);
      canvas.restore();
      return;
    }

    final skin = NomoAvatar.skinColors[avatar.skin];
    final hair =
        NomoAvatar.hairColors[avatar.hair % NomoAvatar.hairColors.length];
    final shirt = NomoAvatar.shirtColors[avatar.shirt];
    final outline = Paint()
      ..color = const Color(0xFF1B2027).withValues(alpha: .18);
    final skinPaint = Paint()..color = skin;

    if (showBody) {
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 112, 76, 76),
        const Radius.circular(34),
      );
      canvas.drawRRect(body, Paint()..color = shirt);
    }

    canvas.drawOval(const Rect.fromLTWH(37, 70, 25, 20), skinPaint);
    canvas.drawOval(const Rect.fromLTWH(118, 70, 25, 20), skinPaint);

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(38, 38, 104, 92),
      const Radius.circular(30),
    );
    canvas.drawRRect(head.shift(const Offset(0, 2)), outline);
    canvas.drawRRect(head, skinPaint);

    _drawHair(canvas, hair);
    _drawEyes(canvas);
    _drawNose(canvas, skin);
    _drawMouth(canvas);
    _drawAccessory(canvas);

    canvas.restore();
  }

  void _drawAdminMascot(Canvas canvas, {required bool showBody}) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10103A), Color(0xFF1A123E), Color(0xFF2A103A)],
      ).createShader(const Rect.fromLTWH(14, 12, 152, 152));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 12, 152, 152),
        const Radius.circular(38),
      ),
      background,
    );

    final glow = Paint()
      ..color = const Color(0xFFFF40B7).withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(const Rect.fromLTWH(18, 44, 140, 118), glow);

    final bodyPath = Path()
      ..moveTo(14, 148)
      ..cubicTo(16, 96, 42, 58, 88, 54)
      ..cubicTo(132, 50, 160, 83, 162, 132)
      ..cubicTo(162, 148, 154, 160, 139, 164)
      ..lineTo(48, 166)
      ..cubicTo(28, 166, 14, 160, 14, 148)
      ..close();
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.42, -.55),
        radius: 1.1,
        colors: [Color(0xFFFF6ECC), Color(0xFFFF1AA8), Color(0xFFE9007D)],
      ).createShader(const Rect.fromLTWH(8, 48, 160, 126));
    canvas.drawPath(bodyPath, bodyPaint);

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(const Rect.fromLTWH(28, 60, 74, 30), shine);

    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB8FF44), Color(0xFF44D817)],
      ).createShader(const Rect.fromLTWH(83, 19, 48, 44));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(82, 42, 22, 30),
        const Radius.circular(12),
      ),
      stemPaint,
    );
    canvas.drawOval(const Rect.fromLTWH(80, 18, 58, 38), stemPaint);
    canvas.drawOval(
      const Rect.fromLTWH(86, 21, 42, 14),
      Paint()..color = Colors.white.withValues(alpha: .22),
    );

    final eyePaint = Paint()..color = const Color(0xFF111321);
    canvas.drawOval(const Rect.fromLTWH(44, 78, 34, 58), eyePaint);
    canvas.drawOval(const Rect.fromLTWH(103, 84, 32, 58), eyePaint);
    canvas.drawOval(
      const Rect.fromLTWH(56, 84, 12, 15),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      const Rect.fromLTWH(113, 91, 11, 14),
      Paint()..color = Colors.white,
    );

    final mouth = Path()
      ..moveTo(78, 128)
      ..cubicTo(84, 142, 107, 143, 116, 129)
      ..cubicTo(116, 122, 108, 122, 101, 124)
      ..cubicTo(91, 128, 86, 121, 80, 120)
      ..cubicTo(76, 121, 76, 125, 78, 128)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFF121025));
    canvas.drawOval(
      const Rect.fromLTWH(86, 134, 22, 10),
      Paint()..color = const Color(0xFFFF7CCB).withValues(alpha: .5),
    );

    final sparklePaint = Paint()..color = const Color(0xFFFF5DCB);
    final sparkle = Path()
      ..moveTo(150, 58)
      ..quadraticBezierTo(156, 72, 169, 78)
      ..quadraticBezierTo(156, 84, 150, 99)
      ..quadraticBezierTo(144, 84, 131, 78)
      ..quadraticBezierTo(144, 72, 150, 58)
      ..close();
    canvas.drawPath(
      sparkle.shift(const Offset(0, 1)),
      Paint()..color = const Color(0xFFFF5DCB).withValues(alpha: .25),
    );
    canvas.drawPath(sparkle, sparklePaint);
    canvas.drawPath(
      sparkle,
      Paint()
        ..color = Colors.white.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawHair(Canvas canvas, Color color) {
    final paint = Paint()..color = color;
    switch (avatar.hair) {
      case 0:
        return;
      case 1:
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(
            Offset(48 + i * 12, 40 + (i.isEven ? 0 : -5)),
            13,
            paint,
          );
        }
      case 2:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 28, 88, 34),
            const Radius.circular(28),
          ),
          paint,
        );
      case 3:
        canvas.drawPath(
          Path()
            ..moveTo(43, 49)
            ..quadraticBezierTo(86, 10, 135, 48)
            ..lineTo(132, 70)
            ..quadraticBezierTo(86, 40, 45, 70)
            ..close(),
          paint,
        );
      case 4:
        canvas.drawCircle(const Offset(90, 28), 20, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(48, 36, 84, 24),
            const Radius.circular(22),
          ),
          paint,
        );
      case 5:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 28, 88, 30),
            const Radius.circular(20),
          ),
          Paint()..color = const Color(0xFF21313E),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(62, 20, 56, 18),
            const Radius.circular(16),
          ),
          Paint()..color = const Color(0xFF2EA8FF),
        );
      case 6:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 36, 100, 68),
            const Radius.circular(28),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(48, 56, 84, 42),
            const Radius.circular(24),
          ),
          Paint()..color = NomoAvatar.skinColors[avatar.skin],
        );
      case 7:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(36, 32, 108, 108),
            const Radius.circular(34),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 50, 88, 76),
            const Radius.circular(28),
          ),
          Paint()..color = NomoAvatar.skinColors[avatar.skin],
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(34, 50, 30, 82),
            const Radius.circular(18),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(116, 50, 30, 82),
            const Radius.circular(18),
          ),
          paint,
        );
        canvas.drawCircle(const Offset(58, 34), 17, paint);
        canvas.drawCircle(const Offset(122, 34), 17, paint);
    }
  }

  void _drawEyes(Canvas canvas) {
    final white = Paint()..color = Colors.white;
    final dark = Paint()..color = const Color(0xFF24313A);
    switch (avatar.eyes) {
      case 1:
        final stroke = Paint()
          ..color = dark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
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
        for (final x in [70.0, 108.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 78), width: 24, height: 34),
            white,
          );
          canvas.drawCircle(Offset(x + 2, 82), 8, dark);
          canvas.drawCircle(Offset(x - 3, 75), 3, white);
        }
      case 3:
        final lash = Paint()
          ..color = dark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (final x in [70.0, 108.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 78), width: 26, height: 36),
            white,
          );
          canvas.drawCircle(Offset(x + 1, 82), 8, dark);
          canvas.drawLine(Offset(x - 14, 65), Offset(x - 20, 60), lash);
          canvas.drawLine(Offset(x + 14, 65), Offset(x + 20, 60), lash);
        }
      default:
        for (final x in [70.0, 108.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 78), width: 24, height: 34),
            white,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 2, 65, 10, 25),
              const Radius.circular(8),
            ),
            dark,
          );
        }
    }
  }

  void _drawNose(Canvas canvas, Color skin) {
    canvas.drawPath(
      Path()
        ..moveTo(90, 84)
        ..quadraticBezierTo(102, 102, 82, 102)
        ..quadraticBezierTo(86, 90, 90, 84),
      Paint()..color = Color.lerp(skin, Colors.black, .22)!,
    );
  }

  void _drawMouth(Canvas canvas) {
    final stroke = Paint()
      ..color = const Color(0xFF2A1715).withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    switch (avatar.mouth) {
      case 1:
        canvas.drawArc(
          const Rect.fromLTWH(70, 94, 38, 24),
          0,
          math.pi,
          false,
          stroke,
        );
      case 2:
        canvas.drawLine(const Offset(78, 106), const Offset(101, 106), stroke);
      default:
        canvas.drawArc(
          const Rect.fromLTWH(70, 88, 42, 28),
          .2,
          math.pi * .7,
          false,
          stroke,
        );
    }
  }

  void _drawAccessory(Canvas canvas) {
    if (avatar.accessory == 1) {
      final stroke = Paint()
        ..color = const Color(0xFF151D24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 66, 32, 28),
          const Radius.circular(10),
        ),
        stroke,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(94, 66, 32, 28),
          const Radius.circular(10),
        ),
        stroke,
      );
      canvas.drawLine(const Offset(86, 78), const Offset(94, 78), stroke);
    } else if (avatar.accessory == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 94, 56, 24),
          const Radius.circular(14),
        ),
        Paint()..color = Colors.white.withValues(alpha: .86),
      );
    } else if (avatar.accessory == 3) {
      final blush = Paint()
        ..color = const Color(0xFFFF7CA8).withValues(alpha: .62);
      canvas.drawCircle(const Offset(57, 95), 9, blush);
      canvas.drawCircle(const Offset(123, 95), 9, blush);
    }
  }

  @override
  bool shouldRepaint(covariant _NomoAvatarPainter oldDelegate) {
    return oldDelegate.avatar != avatar || oldDelegate.showBody != showBody;
  }
}
