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
      if (avatar.isAdmin) {
        _drawAdminBody(canvas);
      }
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
    if (avatar.isAdmin) {
      _drawAdminCrown(canvas);
    }
    _drawEyes(canvas);
    _drawNose(canvas, skin);
    _drawMouth(canvas);
    _drawAccessory(canvas);
    if (avatar.isAdmin) {
      _drawAdminSparkles(canvas);
    }

    canvas.restore();
  }

  void _drawAdminBody(Canvas canvas) {
    final sash = Paint()..color = const Color(0xFFFFD25B);
    final outline = Paint()
      ..color = const Color(0xFF1B2027).withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(62, 126), const Offset(116, 176), outline);
    canvas.drawLine(
      const Offset(62, 126),
      const Offset(116, 176),
      Paint()
        ..color = sash.color
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(90, 146), 11, sash);
    canvas.drawCircle(
      const Offset(90, 146),
      5,
      Paint()..color = const Color(0xFF101820),
    );
  }

  void _drawAdminCrown(Canvas canvas) {
    final crown = Paint()..color = const Color(0xFFFFD25B);
    final shadow = Paint()
      ..color = const Color(0xFF1B2027).withValues(alpha: .14);
    final path = Path()
      ..moveTo(58, 36)
      ..lineTo(68, 16)
      ..lineTo(84, 34)
      ..lineTo(98, 14)
      ..lineTo(112, 34)
      ..lineTo(128, 16)
      ..lineTo(122, 42)
      ..quadraticBezierTo(90, 52, 58, 42)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 3)), shadow);
    canvas.drawPath(path, crown);
    canvas.drawCircle(const Offset(68, 16), 4, crown);
    canvas.drawCircle(const Offset(98, 14), 4, crown);
    canvas.drawCircle(const Offset(128, 16), 4, crown);
  }

  void _drawAdminSparkles(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF21E0C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final center in [const Offset(35, 44), const Offset(145, 58)]) {
      canvas.drawLine(center.translate(-7, 0), center.translate(7, 0), paint);
      canvas.drawLine(center.translate(0, -7), center.translate(0, 7), paint);
    }
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
