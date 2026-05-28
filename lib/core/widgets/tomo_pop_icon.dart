import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class TomoPopIcon extends StatelessWidget {
  const TomoPopIcon({
    super.key,
    required this.icon,
    this.size = 34,
    this.iconSize,
    this.color = const Color(0xFF9BFF00),
    this.foregroundColor,
    this.showBubble = true,
    this.shadow = true,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final Color color;
  final Color? foregroundColor;
  final bool showBubble;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? color;
    final glyphSize = showBubble ? size * .92 : (iconSize ?? size);
    return SizedBox(
      width: size,
      height: size,
      child: _CuteGlyph(icon: icon, color: fg, size: glyphSize),
    );
  }
}

class TomoGeneratedIcon extends StatelessWidget {
  const TomoGeneratedIcon(this.icon, {super.key, this.color, this.size});

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) => TomoPopIcon(
    icon: icon,
    color: color ?? IconTheme.of(context).color ?? Colors.white,
    size: size ?? IconTheme.of(context).size ?? 24,
    showBubble: false,
  );
}

class _CuteGlyph extends StatelessWidget {
  const _CuteGlyph({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final kind = _cuteGlyphKindFromIcon(icon);
    if (kind == null) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CuteGlyphPainter(
              kind: _CuteGlyphKind.spark,
              color: color,
            ),
          ),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CuteGlyphPainter(kind: kind, color: color),
        ),
      ),
    );
  }
}

enum _CuteGlyphKind {
  beverage,
  friends,
  friendAdd,
  flame,
  plane,
  smile,
  calendar,
  plus,
  xmark,
  chevronLeft,
  chevronRight,
  bell,
  heart,
  more,
  arrowCircle,
  gear,
  qr,
  atSign,
  lock,
  mail,
  pencil,
  camera,
  profile,
  moon,
  sun,
  refresh,
  play,
  logout,
  bolt,
  search,
  share,
  link,
  check,
  clock,
  photo,
  location,
  spark,
}

_CuteGlyphKind? _cuteGlyphKindFromIcon(IconData icon) {
  final code = icon.codePoint;
  if (code == Icons.local_bar_rounded.codePoint ||
      code == Icons.sports_bar_rounded.codePoint) {
    return _CuteGlyphKind.beverage;
  }
  if (code == CupertinoIcons.person_badge_plus_fill.codePoint ||
      code == CupertinoIcons.person_add_solid.codePoint) {
    return _CuteGlyphKind.friendAdd;
  }
  if (code == CupertinoIcons.person_2_fill.codePoint ||
      code == CupertinoIcons.person_2.codePoint) {
    return _CuteGlyphKind.friends;
  }
  if (code == CupertinoIcons.person_crop_circle.codePoint ||
      code == CupertinoIcons.person_crop_circle_fill.codePoint ||
      code == CupertinoIcons.person_crop_circle_badge_checkmark.codePoint ||
      code == CupertinoIcons.person_crop_square.codePoint ||
      code == CupertinoIcons.person_fill.codePoint) {
    return _CuteGlyphKind.profile;
  }
  if (code == CupertinoIcons.flame_fill.codePoint) {
    return _CuteGlyphKind.flame;
  }
  if (code == CupertinoIcons.bolt_fill.codePoint) return _CuteGlyphKind.bolt;
  if (code == CupertinoIcons.moon_stars_fill.codePoint ||
      code == CupertinoIcons.moon_fill.codePoint) {
    return _CuteGlyphKind.moon;
  }
  if (code == CupertinoIcons.sun_max_fill.codePoint) return _CuteGlyphKind.sun;
  if (code == CupertinoIcons.arrow_clockwise.codePoint ||
      code == CupertinoIcons.arrow_2_circlepath.codePoint ||
      code == CupertinoIcons.shuffle.codePoint) {
    return _CuteGlyphKind.refresh;
  }
  if (code == CupertinoIcons.play_circle_fill.codePoint) {
    return _CuteGlyphKind.play;
  }
  if (code == CupertinoIcons.square_arrow_right.codePoint) {
    return _CuteGlyphKind.logout;
  }
  if (code == CupertinoIcons.paperplane_fill.codePoint) {
    return _CuteGlyphKind.plane;
  }
  if (code == CupertinoIcons.smiley.codePoint) return _CuteGlyphKind.smile;
  if (code == Icons.calendar_month_rounded.codePoint ||
      code == CupertinoIcons.calendar.codePoint ||
      code == CupertinoIcons.calendar_today.codePoint) {
    return _CuteGlyphKind.calendar;
  }
  if (code == CupertinoIcons.plus.codePoint) return _CuteGlyphKind.plus;
  if (code == CupertinoIcons.xmark.codePoint) return _CuteGlyphKind.xmark;
  if (code == CupertinoIcons.bell.codePoint ||
      code == CupertinoIcons.bell_fill.codePoint) {
    return _CuteGlyphKind.bell;
  }
  if (code == CupertinoIcons.heart.codePoint ||
      code == CupertinoIcons.heart_fill.codePoint) {
    return _CuteGlyphKind.heart;
  }
  if (code == CupertinoIcons.ellipsis.codePoint) return _CuteGlyphKind.more;
  if (code == CupertinoIcons.arrow_right_circle_fill.codePoint ||
      code == CupertinoIcons.arrow_right_circle.codePoint) {
    return _CuteGlyphKind.arrowCircle;
  }
  if (code == CupertinoIcons.gear_alt.codePoint ||
      code == CupertinoIcons.gear.codePoint) {
    return _CuteGlyphKind.gear;
  }
  if (code == CupertinoIcons.qrcode_viewfinder.codePoint ||
      code == CupertinoIcons.qrcode.codePoint) {
    return _CuteGlyphKind.qr;
  }
  if (code == CupertinoIcons.at.codePoint) return _CuteGlyphKind.atSign;
  if (code == CupertinoIcons.lock.codePoint ||
      code == CupertinoIcons.lock_fill.codePoint ||
      code == CupertinoIcons.lock_shield_fill.codePoint) {
    return _CuteGlyphKind.lock;
  }
  if (code == CupertinoIcons.mail.codePoint ||
      code == CupertinoIcons.mail_solid.codePoint) {
    return _CuteGlyphKind.mail;
  }
  if (code == CupertinoIcons.pencil.codePoint) return _CuteGlyphKind.pencil;
  if (code == CupertinoIcons.camera.codePoint ||
      code == CupertinoIcons.camera_fill.codePoint) {
    return _CuteGlyphKind.camera;
  }
  if (code == CupertinoIcons.search.codePoint ||
      code == CupertinoIcons.eye.codePoint ||
      code == CupertinoIcons.eyeglasses.codePoint) {
    return _CuteGlyphKind.search;
  }
  if (code == CupertinoIcons.square_arrow_up.codePoint ||
      code == CupertinoIcons.arrow_down_to_line_alt.codePoint) {
    return _CuteGlyphKind.share;
  }
  if (code == CupertinoIcons.link.codePoint) return _CuteGlyphKind.link;
  if (code == CupertinoIcons.checkmark.codePoint ||
      code == CupertinoIcons.checkmark_alt.codePoint ||
      code == CupertinoIcons.checkmark_circle_fill.codePoint) {
    return _CuteGlyphKind.check;
  }
  if (code == CupertinoIcons.clock.codePoint ||
      code == CupertinoIcons.clock_fill.codePoint ||
      code == CupertinoIcons.hourglass.codePoint) {
    return _CuteGlyphKind.clock;
  }
  if (code == CupertinoIcons.photo_fill.codePoint ||
      code == CupertinoIcons.photo_fill_on_rectangle_fill.codePoint) {
    return _CuteGlyphKind.photo;
  }
  if (code == CupertinoIcons.location_fill.codePoint ||
      code == CupertinoIcons.location_solid.codePoint) {
    return _CuteGlyphKind.location;
  }
  if (code == CupertinoIcons.drop_fill.codePoint) {
    return _CuteGlyphKind.beverage;
  }
  if (code == CupertinoIcons.scissors.codePoint) return _CuteGlyphKind.pencil;
  if (code == CupertinoIcons.chevron_left.codePoint ||
      code == CupertinoIcons.arrow_left.codePoint) {
    return _CuteGlyphKind.chevronLeft;
  }
  if (code == CupertinoIcons.chevron_right.codePoint ||
      code == CupertinoIcons.chevron_forward.codePoint ||
      code == CupertinoIcons.arrow_right.codePoint) {
    return _CuteGlyphKind.chevronRight;
  }
  return null;
}

class _CuteGlyphPainter extends CustomPainter {
  const _CuteGlyphPainter({required this.kind, required this.color});

  final _CuteGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * .12;

    switch (kind) {
      case _CuteGlyphKind.beverage:
        _drawBeverage(canvas, size, p, stroke);
      case _CuteGlyphKind.friends:
        _drawFriends(canvas, size, p);
      case _CuteGlyphKind.friendAdd:
        _drawFriendAdd(canvas, size, p);
      case _CuteGlyphKind.flame:
        _drawFlame(canvas, size, p);
      case _CuteGlyphKind.plane:
        _drawPlane(canvas, size, p);
      case _CuteGlyphKind.smile:
        _drawSmile(canvas, size, p, stroke);
      case _CuteGlyphKind.calendar:
        _drawCalendar(canvas, size, p);
      case _CuteGlyphKind.plus:
        _drawPlus(canvas, size, stroke);
      case _CuteGlyphKind.xmark:
        _drawX(canvas, size, stroke);
      case _CuteGlyphKind.chevronLeft:
        _drawChevron(canvas, size, stroke, pointsLeft: true);
      case _CuteGlyphKind.chevronRight:
        _drawChevron(canvas, size, stroke, pointsLeft: false);
      case _CuteGlyphKind.bell:
        _drawBell(canvas, size, p, stroke);
      case _CuteGlyphKind.heart:
        _drawHeart(canvas, size, p);
      case _CuteGlyphKind.more:
        _drawMore(canvas, size, p);
      case _CuteGlyphKind.arrowCircle:
        _drawArrowCircle(canvas, size, p, stroke);
      case _CuteGlyphKind.gear:
        _drawGear(canvas, size, p, stroke);
      case _CuteGlyphKind.qr:
        _drawQr(canvas, size, p, stroke);
      case _CuteGlyphKind.atSign:
        _drawAt(canvas, size, p, stroke);
      case _CuteGlyphKind.lock:
        _drawLock(canvas, size, p, stroke);
      case _CuteGlyphKind.mail:
        _drawMail(canvas, size, p, stroke);
      case _CuteGlyphKind.pencil:
        _drawPencil(canvas, size, p, stroke);
      case _CuteGlyphKind.camera:
        _drawCamera(canvas, size, p, stroke);
      case _CuteGlyphKind.profile:
        _drawProfile(canvas, size, p);
      case _CuteGlyphKind.moon:
        _drawMoon(canvas, size, p);
      case _CuteGlyphKind.sun:
        _drawSun(canvas, size, p);
      case _CuteGlyphKind.refresh:
        _drawRefresh(canvas, size, p);
      case _CuteGlyphKind.play:
        _drawPlay(canvas, size, p);
      case _CuteGlyphKind.logout:
        _drawLogout(canvas, size, p);
      case _CuteGlyphKind.bolt:
        _drawBolt(canvas, size, p);
      case _CuteGlyphKind.search:
        _drawSearch(canvas, size, p);
      case _CuteGlyphKind.share:
        _drawShare(canvas, size, p);
      case _CuteGlyphKind.link:
        _drawLink(canvas, size, p);
      case _CuteGlyphKind.check:
        _drawCheck(canvas, size, p, stroke);
      case _CuteGlyphKind.clock:
        _drawClock(canvas, size, p, stroke);
      case _CuteGlyphKind.photo:
        _drawPhoto(canvas, size, p, stroke);
      case _CuteGlyphKind.location:
        _drawLocation(canvas, size, p);
      case _CuteGlyphKind.spark:
        _drawSpark(canvas, size, p);
    }
  }

  void _drawBeverage(Canvas canvas, Size s, Paint p, Paint stroke) {
    final bowl = Path()
      ..moveTo(s.width * .16, s.height * .20)
      ..lineTo(s.width * .84, s.height * .20)
      ..lineTo(s.width * .54, s.height * .52)
      ..quadraticBezierTo(
        s.width * .50,
        s.height * .57,
        s.width * .46,
        s.height * .52,
      )
      ..close();
    canvas.drawPath(bowl, p);
    canvas.drawLine(
      Offset(s.width * .50, s.height * .52),
      Offset(s.width * .50, s.height * .78),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .32, s.height * .82),
      Offset(s.width * .68, s.height * .82),
      stroke,
    );
  }

  void _drawFriends(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66);
    final dark = Paint()..color = const Color(0xFF071927);
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: .96);
    final shine = Paint()..color = Colors.white.withValues(alpha: .82);
    final soft = Paint()..color = Colors.white.withValues(alpha: .32);
    final secondaryColor =
        Color.lerp(p.color, const Color(0xFF46C8FF), .26) ?? p.color;
    final secondary = Paint()..color = secondaryColor;
    final smile = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .045;

    Path buddy({
      required double x,
      required double y,
      required double scale,
      required bool front,
    }) {
      final w = s.width;
      final h = s.height;
      final path = Path()
        ..moveTo(w * (x + .09 * scale), h * (y + .31 * scale))
        ..cubicTo(
          w * (x + .02 * scale),
          h * (y + .17 * scale),
          w * (x + .13 * scale),
          h * (y + .04 * scale),
          w * (x + .26 * scale),
          h * (y + .07 * scale),
        )
        ..cubicTo(
          w * (x + .34 * scale),
          h * (y - .02 * scale),
          w * (x + .52 * scale),
          h * (y + .07 * scale),
          w * (x + .52 * scale),
          h * (y + .22 * scale),
        )
        ..cubicTo(
          w * (x + .64 * scale),
          h * (y + .30 * scale),
          w * (x + .56 * scale),
          h * (y + .51 * scale),
          w * (x + .39 * scale),
          h * (y + .51 * scale),
        )
        ..lineTo(w * (x + .24 * scale), h * (y + .51 * scale))
        ..cubicTo(
          w * (x + .09 * scale),
          h * (y + .51 * scale),
          w * (x - .01 * scale),
          h * (y + .40 * scale),
          w * (x + .09 * scale),
          h * (y + .31 * scale),
        )
        ..close();
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * (x + (front ? .14 : .11) * scale),
            h * (y + .48 * scale),
            w * (front ? .34 : .31) * scale,
            h * (front ? .28 : .25) * scale,
          ),
          Radius.circular(w * (front ? .18 : .16) * scale),
        ),
      );
      return path;
    }

    final back = buddy(x: .08, y: .18, scale: .92, front: false);
    final front = buddy(x: .35, y: .12, scale: 1.02, front: true);
    final shadowOffset = Offset(s.width * .045, s.height * .065);
    canvas.drawPath(back.shift(shadowOffset), shadow);
    canvas.drawPath(front.shift(shadowOffset), shadow);
    canvas.drawPath(back, secondary);
    canvas.drawPath(front, p);

    void face(double cx, double cy, double scale) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (cx - .055 * scale), s.height * cy),
          width: s.width * .070 * scale,
          height: s.height * .128 * scale,
        ),
        eyeWhite,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (cx + .085 * scale), s.height * cy),
          width: s.width * .070 * scale,
          height: s.height * .128 * scale,
        ),
        eyeWhite,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (cx - .040 * scale), s.height * cy),
          width: s.width * .026 * scale,
          height: s.height * .060 * scale,
        ),
        dark,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (cx + .070 * scale), s.height * cy),
          width: s.width * .026 * scale,
          height: s.height * .060 * scale,
        ),
        dark,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s.width * (cx + .018 * scale), s.height * (cy + .11)),
          width: s.width * .18 * scale,
          height: s.height * .11 * scale,
        ),
        .18,
        math.pi - .36,
        false,
        smile,
      );
    }

    face(.34, .42, .74);
    face(.62, .38, .88);
    canvas.drawCircle(
      Offset(s.width * .51, s.height * .24),
      s.width * .042,
      shine,
    );
    canvas.drawCircle(
      Offset(s.width * .22, s.height * .33),
      s.width * .035,
      soft,
    );
  }

  void _drawFriendAdd(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .68);
    final dark = Paint()..color = const Color(0xFF071927);
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: .96);
    final shine = Paint()..color = Colors.white.withValues(alpha: .82);
    final smile = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .052;
    final badgeCut = Paint()
      ..color = p.color.computeLuminance() > .76
          ? const Color(0xFF071927)
          : Colors.white;

    final body = Path()
      ..moveTo(s.width * .20, s.height * .46)
      ..cubicTo(
        s.width * .08,
        s.height * .30,
        s.width * .22,
        s.height * .12,
        s.width * .40,
        s.height * .16,
      )
      ..cubicTo(
        s.width * .48,
        s.height * .06,
        s.width * .67,
        s.height * .15,
        s.width * .66,
        s.height * .34,
      )
      ..cubicTo(
        s.width * .78,
        s.height * .43,
        s.width * .68,
        s.height * .62,
        s.width * .49,
        s.height * .61,
      )
      ..lineTo(s.width * .34, s.height * .61)
      ..cubicTo(
        s.width * .18,
        s.height * .61,
        s.width * .10,
        s.height * .52,
        s.width * .20,
        s.height * .46,
      )
      ..close()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * .25,
            s.height * .58,
            s.width * .36,
            s.height * .28,
          ),
          Radius.circular(s.width * .18),
        ),
      );

    canvas.drawPath(
      body.shift(Offset(s.width * .045, s.height * .065)),
      shadow,
    );
    canvas.drawPath(body, p);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .38, s.height * .39),
        width: s.width * .072,
        height: s.height * .130,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .53, s.height * .39),
        width: s.width * .072,
        height: s.height * .130,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .395, s.height * .39),
        width: s.width * .027,
        height: s.height * .062,
      ),
      dark,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .515, s.height * .39),
        width: s.width * .027,
        height: s.height * .062,
      ),
      dark,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s.width * .46, s.height * .51),
        width: s.width * .18,
        height: s.height * .10,
      ),
      .18,
      math.pi - .36,
      false,
      smile,
    );
    canvas.drawCircle(
      Offset(s.width * .32, s.height * .26),
      s.width * .04,
      shine,
    );
    canvas.drawCircle(Offset(s.width * .75, s.height * .27), s.width * .18, p);
    canvas.drawCircle(
      Offset(s.width * .75, s.height * .27),
      s.width * .135,
      Paint()..color = Colors.white.withValues(alpha: .16),
    );
    final plus = Paint()
      ..color = badgeCut.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .055;
    canvas.drawLine(
      Offset(s.width * .75, s.height * .18),
      Offset(s.width * .75, s.height * .36),
      plus,
    );
    canvas.drawLine(
      Offset(s.width * .66, s.height * .27),
      Offset(s.width * .84, s.height * .27),
      plus,
    );
  }

  void _drawFlame(Canvas canvas, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * .53, s.height * .08)
      ..cubicTo(
        s.width * .82,
        s.height * .32,
        s.width * .87,
        s.height * .58,
        s.width * .65,
        s.height * .82,
      )
      ..cubicTo(
        s.width * .51,
        s.height * .96,
        s.width * .26,
        s.height * .88,
        s.width * .22,
        s.height * .62,
      )
      ..cubicTo(
        s.width * .19,
        s.height * .42,
        s.width * .36,
        s.height * .33,
        s.width * .38,
        s.height * .18,
      )
      ..cubicTo(
        s.width * .47,
        s.height * .28,
        s.width * .52,
        s.height * .28,
        s.width * .53,
        s.height * .08,
      )
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawPlane(Canvas canvas, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * .11, s.height * .48)
      ..lineTo(s.width * .88, s.height * .14)
      ..lineTo(s.width * .67, s.height * .86)
      ..lineTo(s.width * .48, s.height * .61)
      ..lineTo(s.width * .28, s.height * .76)
      ..lineTo(s.width * .36, s.height * .55)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawSmile(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .50),
      s.width * .38,
      stroke,
    );
    canvas.drawCircle(Offset(s.width * .38, s.height * .42), s.width * .045, p);
    canvas.drawCircle(Offset(s.width * .62, s.height * .42), s.width * .045, p);
    final smile = Path()
      ..moveTo(s.width * .34, s.height * .57)
      ..quadraticBezierTo(
        s.width * .50,
        s.height * .72,
        s.width * .66,
        s.height * .57,
      );
    canvas.drawPath(smile, stroke);
  }

  void _drawCalendar(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .16,
          s.height * .20,
          s.width * .68,
          s.height * .64,
        ),
        Radius.circular(s.width * .14),
      ),
      p,
    );
    final cut = Paint()..color = Colors.black.withValues(alpha: .22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .25,
          s.height * .43,
          s.width * .50,
          s.height * .31,
        ),
        Radius.circular(s.width * .06),
      ),
      cut,
    );
    canvas.drawCircle(Offset(s.width * .36, s.height * .57), s.width * .045, p);
    canvas.drawCircle(Offset(s.width * .50, s.height * .57), s.width * .045, p);
    canvas.drawCircle(Offset(s.width * .64, s.height * .57), s.width * .045, p);
  }

  void _drawPlus(Canvas canvas, Size s, Paint stroke) {
    canvas.drawLine(
      Offset(s.width * .50, s.height * .22),
      Offset(s.width * .50, s.height * .78),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .22, s.height * .50),
      Offset(s.width * .78, s.height * .50),
      stroke,
    );
  }

  void _drawX(Canvas canvas, Size s, Paint stroke) {
    canvas.drawLine(
      Offset(s.width * .27, s.height * .27),
      Offset(s.width * .73, s.height * .73),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .73, s.height * .27),
      Offset(s.width * .27, s.height * .73),
      stroke,
    );
  }

  void _drawChevron(
    Canvas canvas,
    Size s,
    Paint stroke, {
    required bool pointsLeft,
  }) {
    final tipX = pointsLeft ? .36 : .64;
    final tailX = pointsLeft ? .62 : .38;
    canvas.drawLine(
      Offset(s.width * tailX, s.height * .25),
      Offset(s.width * tipX, s.height * .50),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * tipX, s.height * .50),
      Offset(s.width * tailX, s.height * .75),
      stroke,
    );
  }

  void _drawBell(Canvas canvas, Size s, Paint p, Paint stroke) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .68);
    final shine = Paint()..color = Colors.white.withValues(alpha: .72);
    final soft = Paint()..color = Colors.white.withValues(alpha: .26);
    final body = Path()
      ..moveTo(s.width * .24, s.height * .60)
      ..cubicTo(
        s.width * .20,
        s.height * .34,
        s.width * .34,
        s.height * .18,
        s.width * .51,
        s.height * .18,
      )
      ..cubicTo(
        s.width * .70,
        s.height * .18,
        s.width * .82,
        s.height * .35,
        s.width * .76,
        s.height * .60,
      )
      ..cubicTo(
        s.width * .84,
        s.height * .66,
        s.width * .78,
        s.height * .76,
        s.width * .62,
        s.height * .74,
      )
      ..lineTo(s.width * .38, s.height * .74)
      ..cubicTo(
        s.width * .22,
        s.height * .76,
        s.width * .16,
        s.height * .66,
        s.width * .24,
        s.height * .60,
      )
      ..close();
    canvas.drawPath(
      body.shift(Offset(s.width * .045, s.height * .065)),
      shadow,
    );
    canvas.drawPath(body, p);
    canvas.drawCircle(Offset(s.width * .50, s.height * .80), s.width * .085, p);
    canvas.drawCircle(
      Offset(s.width * .40, s.height * .34),
      s.width * .052,
      shine,
    );
    canvas.drawCircle(
      Offset(s.width * .32, s.height * .58),
      s.width * .034,
      soft,
    );
  }

  void _drawHeart(Canvas canvas, Size s, Paint p) {
    final shine = Paint()..color = Colors.white.withValues(alpha: .70);
    final heart = Path()
      ..moveTo(s.width * .50, s.height * .86)
      ..cubicTo(
        s.width * .25,
        s.height * .71,
        s.width * .08,
        s.height * .55,
        s.width * .16,
        s.height * .34,
      )
      ..cubicTo(
        s.width * .23,
        s.height * .15,
        s.width * .42,
        s.height * .17,
        s.width * .50,
        s.height * .34,
      )
      ..cubicTo(
        s.width * .59,
        s.height * .16,
        s.width * .80,
        s.height * .16,
        s.width * .86,
        s.height * .36,
      )
      ..cubicTo(
        s.width * .94,
        s.height * .60,
        s.width * .73,
        s.height * .74,
        s.width * .50,
        s.height * .86,
      )
      ..close();
    canvas.drawPath(
      heart.shift(Offset(s.width * .045, s.height * .065)),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .70),
    );
    canvas.drawPath(heart, p);
    canvas.drawCircle(
      Offset(s.width * .34, s.height * .34),
      s.width * .055,
      shine,
    );
    canvas.drawCircle(
      Offset(s.width * .44, s.height * .42),
      s.width * .033,
      shine,
    );
  }

  void _drawMore(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * .25, s.height * .50), s.width * .085, p);
    canvas.drawCircle(Offset(s.width * .50, s.height * .50), s.width * .085, p);
    canvas.drawCircle(Offset(s.width * .75, s.height * .50), s.width * .085, p);
  }

  void _drawArrowCircle(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .50),
      s.width * .42,
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .33, s.height * .50),
      Offset(s.width * .64, s.height * .50),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .54, s.height * .36),
      Offset(s.width * .66, s.height * .50),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .54, s.height * .64),
      Offset(s.width * .66, s.height * .50),
      stroke,
    );
  }

  void _drawGear(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.saveLayer(Offset.zero & s, Paint());
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        Offset(
          s.width * (.50 + .30 * math.cos(a)),
          s.height * (.50 + .30 * math.sin(a)),
        ),
        s.width * .11,
        p,
      );
    }
    canvas.drawCircle(Offset(s.width * .50, s.height * .50), s.width * .30, p);
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .50),
      s.width * .115,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  void _drawQr(Canvas canvas, Size s, Paint p, Paint stroke) {
    void corner(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * x,
            s.height * y,
            s.width * .22,
            s.width * .22,
          ),
          Radius.circular(s.width * .04),
        ),
        stroke,
      );
      canvas.drawCircle(
        Offset(s.width * (x + .11), s.height * (y + .11)),
        s.width * .04,
        p,
      );
    }

    corner(.16, .16);
    corner(.62, .16);
    corner(.16, .62);
    for (final o in [
      Offset(.54, .54),
      Offset(.68, .56),
      Offset(.56, .70),
      Offset(.76, .74),
    ]) {
      canvas.drawCircle(
        Offset(s.width * o.dx, s.height * o.dy),
        s.width * .04,
        p,
      );
    }
  }

  void _drawAt(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .50),
      s.width * .22,
      stroke,
    );
    canvas.drawCircle(Offset(s.width * .50, s.height * .50), s.width * .07, p);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(s.width * .50, s.height * .50),
        radius: s.width * .34,
      ),
      -1.2,
      5.1,
      false,
      stroke,
    );
  }

  void _drawLock(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawArc(
      Rect.fromLTWH(
        s.width * .30,
        s.height * .16,
        s.width * .40,
        s.height * .42,
      ),
      math.pi,
      math.pi,
      false,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .22,
          s.height * .42,
          s.width * .56,
          s.height * .40,
        ),
        Radius.circular(s.width * .10),
      ),
      p,
    );
  }

  void _drawMail(Canvas canvas, Size s, Paint p, Paint stroke) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * .14,
        s.height * .26,
        s.width * .72,
        s.height * .50,
      ),
      Radius.circular(s.width * .08),
    );
    canvas.drawRRect(r, stroke);
    canvas.drawLine(
      Offset(s.width * .18, s.height * .32),
      Offset(s.width * .50, s.height * .56),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .82, s.height * .32),
      Offset(s.width * .50, s.height * .56),
      stroke,
    );
  }

  void _drawPencil(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawLine(
      Offset(s.width * .28, s.height * .72),
      Offset(s.width * .70, s.height * .30),
      stroke,
    );
    canvas.drawCircle(Offset(s.width * .72, s.height * .28), s.width * .08, p);
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .22, s.height * .78)
        ..lineTo(s.width * .34, s.height * .72)
        ..lineTo(s.width * .28, s.height * .66)
        ..close(),
      p,
    );
  }

  void _drawCamera(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .16,
          s.height * .30,
          s.width * .68,
          s.height * .46,
        ),
        Radius.circular(s.width * .10),
      ),
      stroke,
    );
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .54),
      s.width * .14,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .28,
          s.height * .22,
          s.width * .22,
          s.height * .12,
        ),
        Radius.circular(s.width * .04),
      ),
      p,
    );
  }

  void _drawProfile(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66);
    final facePaint = Paint()..color = p.color;
    final eye = Paint()..color = const Color(0xFF06111D).withValues(alpha: .82);
    final shine = Paint()..color = Colors.white.withValues(alpha: .65);
    final blob = Path()
      ..moveTo(s.width * .28, s.height * .40)
      ..cubicTo(
        s.width * .20,
        s.height * .18,
        s.width * .46,
        s.height * .08,
        s.width * .62,
        s.height * .20,
      )
      ..cubicTo(
        s.width * .84,
        s.height * .18,
        s.width * .90,
        s.height * .44,
        s.width * .76,
        s.height * .58,
      )
      ..cubicTo(
        s.width * .83,
        s.height * .83,
        s.width * .50,
        s.height * .94,
        s.width * .32,
        s.height * .77,
      )
      ..cubicTo(
        s.width * .11,
        s.height * .78,
        s.width * .10,
        s.height * .49,
        s.width * .28,
        s.height * .40,
      )
      ..close();
    canvas.drawPath(
      blob.shift(Offset(s.width * .045, s.height * .065)),
      shadow,
    );
    canvas.drawPath(blob, facePaint);
    canvas.drawOval(
      Rect.fromLTWH(
        s.width * .34,
        s.height * .39,
        s.width * .10,
        s.height * .18,
      ),
      eye,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        s.width * .58,
        s.height * .39,
        s.width * .10,
        s.height * .18,
      ),
      eye,
    );
    final smile = Paint()
      ..color = eye.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .055;
    canvas.drawArc(
      Rect.fromLTWH(
        s.width * .38,
        s.height * .50,
        s.width * .28,
        s.height * .22,
      ),
      .20,
      math.pi - .40,
      false,
      smile,
    );
    canvas.drawCircle(
      Offset(s.width * .38, s.height * .29),
      s.width * .045,
      shine,
    );
  }

  void _drawMoon(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66);
    final moon = Path()
      ..moveTo(s.width * .68, s.height * .16)
      ..cubicTo(
        s.width * .36,
        s.height * .18,
        s.width * .20,
        s.height * .45,
        s.width * .34,
        s.height * .68,
      )
      ..cubicTo(
        s.width * .48,
        s.height * .91,
        s.width * .80,
        s.height * .87,
        s.width * .91,
        s.height * .62,
      )
      ..cubicTo(
        s.width * .67,
        s.height * .72,
        s.width * .45,
        s.height * .54,
        s.width * .52,
        s.height * .31,
      )
      ..cubicTo(
        s.width * .55,
        s.height * .23,
        s.width * .61,
        s.height * .18,
        s.width * .68,
        s.height * .16,
      )
      ..close();
    canvas.drawPath(moon.shift(Offset(s.width * .04, s.height * .06)), shadow);
    canvas.drawPath(moon, p);
    canvas.drawCircle(
      Offset(s.width * .33, s.height * .25),
      s.width * .035,
      Paint()..color = Colors.white.withValues(alpha: .76),
    );
    canvas.drawCircle(
      Offset(s.width * .78, s.height * .30),
      s.width * .025,
      Paint()..color = Colors.white.withValues(alpha: .62),
    );
  }

  void _drawSun(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .62);
    final center = Offset(s.width * .50, s.height * .50);
    canvas.drawCircle(
      center.translate(s.width * .04, s.height * .06),
      s.width * .25,
      shadow,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        Offset(
          s.width * (.50 + .36 * math.cos(a)),
          s.height * (.50 + .36 * math.sin(a)),
        ),
        s.width * .055,
        p,
      );
    }
    canvas.drawCircle(center, s.width * .25, p);
    canvas.drawCircle(
      Offset(s.width * .41, s.height * .39),
      s.width * .045,
      Paint()..color = Colors.white.withValues(alpha: .70),
    );
  }

  void _drawRefresh(Canvas canvas, Size s, Paint p) {
    final stroke = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .12;
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .13;
    final rect = Rect.fromCircle(
      center: Offset(s.width * .50, s.height * .50),
      radius: s.width * .31,
    );
    final off = Offset(s.width * .04, s.height * .06);
    canvas.drawArc(
      rect.shift(off),
      math.pi * .10,
      math.pi * 1.45,
      false,
      shadow,
    );
    canvas.drawArc(rect, math.pi * .10, math.pi * 1.45, false, stroke);
    final head = Path()
      ..moveTo(s.width * .76, s.height * .26)
      ..lineTo(s.width * .86, s.height * .45)
      ..lineTo(s.width * .65, s.height * .42)
      ..close();
    canvas.drawPath(
      head.shift(off),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .66),
    );
    canvas.drawPath(head, p);
  }

  void _drawPlay(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66);
    final blob = Path()
      ..moveTo(s.width * .50, s.height * .10)
      ..cubicTo(
        s.width * .78,
        s.height * .08,
        s.width * .93,
        s.height * .32,
        s.width * .84,
        s.height * .60,
      )
      ..cubicTo(
        s.width * .75,
        s.height * .90,
        s.width * .32,
        s.height * .91,
        s.width * .17,
        s.height * .63,
      )
      ..cubicTo(
        s.width * .03,
        s.height * .36,
        s.width * .21,
        s.height * .11,
        s.width * .50,
        s.height * .10,
      )
      ..close();
    final tri = Path()
      ..moveTo(s.width * .43, s.height * .34)
      ..lineTo(s.width * .68, s.height * .50)
      ..lineTo(s.width * .43, s.height * .66)
      ..close();
    canvas.drawPath(blob.shift(Offset(s.width * .04, s.height * .06)), shadow);
    canvas.drawPath(blob, p);
    canvas.drawPath(tri, Paint()..color = Colors.white.withValues(alpha: .86));
  }

  void _drawLogout(Canvas canvas, Size s, Paint p) {
    final stroke = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .11;
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .66)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .12;
    final off = Offset(s.width * .04, s.height * .06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .18,
          s.height * .24,
          s.width * .42,
          s.height * .52,
        ).shift(off),
        Radius.circular(s.width * .10),
      ),
      shadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .18,
          s.height * .24,
          s.width * .42,
          s.height * .52,
        ),
        Radius.circular(s.width * .10),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .45, s.height * .50) + off,
      Offset(s.width * .84, s.height * .50) + off,
      shadow,
    );
    canvas.drawLine(
      Offset(s.width * .70, s.height * .35) + off,
      Offset(s.width * .85, s.height * .50) + off,
      shadow,
    );
    canvas.drawLine(
      Offset(s.width * .70, s.height * .65) + off,
      Offset(s.width * .85, s.height * .50) + off,
      shadow,
    );
    canvas.drawLine(
      Offset(s.width * .45, s.height * .50),
      Offset(s.width * .84, s.height * .50),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .70, s.height * .35),
      Offset(s.width * .85, s.height * .50),
      stroke,
    );
    canvas.drawLine(
      Offset(s.width * .70, s.height * .65),
      Offset(s.width * .85, s.height * .50),
      stroke,
    );
  }

  void _drawBolt(Canvas canvas, Size s, Paint p) {
    final bolt = Path()
      ..moveTo(s.width * .56, s.height * .08)
      ..lineTo(s.width * .25, s.height * .52)
      ..lineTo(s.width * .48, s.height * .52)
      ..lineTo(s.width * .40, s.height * .92)
      ..lineTo(s.width * .76, s.height * .44)
      ..lineTo(s.width * .53, s.height * .44)
      ..close();
    canvas.drawPath(
      bolt.shift(Offset(s.width * .04, s.height * .06)),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .66),
    );
    canvas.drawPath(bolt, p);
    canvas.drawCircle(
      Offset(s.width * .48, s.height * .26),
      s.width * .035,
      Paint()..color = Colors.white.withValues(alpha: .65),
    );
  }

  void _drawSearch(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .15;
    final ring = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .16;
    final glass = Paint()..color = p.color.withValues(alpha: .22);
    final center = Offset(s.width * .43, s.height * .42);
    canvas.drawCircle(
      center.translate(s.width * .04, s.height * .06),
      s.width * .25,
      shadow,
    );
    canvas.drawLine(
      Offset(
        s.width * .62,
        s.height * .61,
      ).translate(s.width * .04, s.height * .06),
      Offset(
        s.width * .82,
        s.height * .81,
      ).translate(s.width * .04, s.height * .06),
      shadow,
    );
    canvas.drawCircle(center, s.width * .25, glass);
    canvas.drawCircle(center, s.width * .25, ring);
    canvas.drawLine(
      Offset(s.width * .62, s.height * .61),
      Offset(s.width * .82, s.height * .81),
      ring,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: s.width * .18),
      math.pi * .80,
      math.pi * .35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s.width * .055,
    );
  }

  void _drawShare(Canvas canvas, Size s, Paint p) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .68);
    final shine = Paint()..color = Colors.white.withValues(alpha: .70);
    final avatar = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(s.width * .39, s.height * .40),
          radius: s.width * .19,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * .18,
            s.height * .56,
            s.width * .46,
            s.height * .25,
          ),
          Radius.circular(s.width * .14),
        ),
      );
    canvas.drawPath(
      avatar.shift(Offset(s.width * .045, s.height * .06)),
      shadow,
    );
    canvas.drawPath(avatar, p);
    final arrow = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .105;
    final arrowShadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .11;
    final offset = Offset(s.width * .04, s.height * .06);
    canvas.drawLine(
      Offset(s.width * .70, s.height * .78) + offset,
      Offset(s.width * .70, s.height * .36) + offset,
      arrowShadow,
    );
    canvas.drawLine(
      Offset(s.width * .56, s.height * .50) + offset,
      Offset(s.width * .70, s.height * .34) + offset,
      arrowShadow,
    );
    canvas.drawLine(
      Offset(s.width * .84, s.height * .50) + offset,
      Offset(s.width * .70, s.height * .34) + offset,
      arrowShadow,
    );
    canvas.drawLine(
      Offset(s.width * .70, s.height * .78),
      Offset(s.width * .70, s.height * .36),
      arrow,
    );
    canvas.drawLine(
      Offset(s.width * .56, s.height * .50),
      Offset(s.width * .70, s.height * .34),
      arrow,
    );
    canvas.drawLine(
      Offset(s.width * .84, s.height * .50),
      Offset(s.width * .70, s.height * .34),
      arrow,
    );
    canvas.drawCircle(
      Offset(s.width * .31, s.height * .32),
      s.width * .04,
      shine,
    );
  }

  void _drawLink(Canvas canvas, Size s, Paint p) {
    final stroke = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .13;
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .68)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .14;
    void loop(Offset c, double angle, Paint paint) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s.width * .44,
            height: s.height * .24,
          ),
          Radius.circular(s.width * .12),
        ),
        paint,
      );
      canvas.restore();
    }

    final d = Offset(s.width * .04, s.height * .06);
    loop(Offset(s.width * .39, s.height * .57) + d, -.55, shadow);
    loop(Offset(s.width * .63, s.height * .43) + d, -.55, shadow);
    loop(Offset(s.width * .39, s.height * .57), -.55, stroke);
    loop(Offset(s.width * .63, s.height * .43), -.55, stroke);
  }

  void _drawCheck(Canvas canvas, Size s, Paint p, Paint stroke) {
    final blob = Path()
      ..moveTo(s.width * .50, s.height * .10)
      ..cubicTo(
        s.width * .78,
        s.height * .08,
        s.width * .94,
        s.height * .34,
        s.width * .82,
        s.height * .61,
      )
      ..cubicTo(
        s.width * .70,
        s.height * .90,
        s.width * .30,
        s.height * .91,
        s.width * .17,
        s.height * .62,
      )
      ..cubicTo(
        s.width * .04,
        s.height * .35,
        s.width * .22,
        s.height * .08,
        s.width * .50,
        s.height * .10,
      )
      ..close();
    canvas.drawPath(
      blob.shift(Offset(s.width * .04, s.height * .06)),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .65),
    );
    canvas.drawPath(blob, p);
    final mark = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width * .11;
    canvas.drawLine(
      Offset(s.width * .32, s.height * .50),
      Offset(s.width * .45, s.height * .64),
      mark,
    );
    canvas.drawLine(
      Offset(s.width * .45, s.height * .64),
      Offset(s.width * .70, s.height * .36),
      mark,
    );
  }

  void _drawClock(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawCircle(
      Offset(
        s.width * .52,
        s.height * .53,
      ).translate(s.width * .04, s.height * .06),
      s.width * .36,
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .64),
    );
    canvas.drawCircle(Offset(s.width * .50, s.height * .50), s.width * .36, p);
    final hand = Paint()
      ..color = Colors.white.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .09;
    canvas.drawLine(
      Offset(s.width * .50, s.height * .50),
      Offset(s.width * .50, s.height * .30),
      hand,
    );
    canvas.drawLine(
      Offset(s.width * .50, s.height * .50),
      Offset(s.width * .66, s.height * .58),
      hand,
    );
  }

  void _drawPhoto(Canvas canvas, Size s, Paint p, Paint stroke) {
    final shadow = Paint()
      ..color = const Color(0xFF06111D).withValues(alpha: .64);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * .14,
        s.height * .22,
        s.width * .72,
        s.height * .56,
      ),
      Radius.circular(s.width * .14),
    );
    canvas.drawRRect(body.shift(Offset(s.width * .04, s.height * .06)), shadow);
    canvas.drawRRect(body, p);
    final cut = Paint()..color = Colors.white.withValues(alpha: .78);
    canvas.drawCircle(
      Offset(s.width * .67, s.height * .38),
      s.width * .07,
      cut,
    );
    final hill = Path()
      ..moveTo(s.width * .22, s.height * .68)
      ..quadraticBezierTo(
        s.width * .39,
        s.height * .48,
        s.width * .52,
        s.height * .64,
      )
      ..quadraticBezierTo(
        s.width * .62,
        s.height * .54,
        s.width * .78,
        s.height * .70,
      )
      ..close();
    canvas.drawPath(
      hill,
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .35),
    );
  }

  void _drawLocation(Canvas canvas, Size s, Paint p) {
    final pin = Path()
      ..moveTo(s.width * .50, s.height * .88)
      ..cubicTo(
        s.width * .20,
        s.height * .58,
        s.width * .20,
        s.height * .25,
        s.width * .50,
        s.height * .18,
      )
      ..cubicTo(
        s.width * .80,
        s.height * .25,
        s.width * .80,
        s.height * .58,
        s.width * .50,
        s.height * .88,
      )
      ..close();
    canvas.drawPath(
      pin.shift(Offset(s.width * .04, s.height * .06)),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .64),
    );
    canvas.drawPath(pin, p);
    canvas.drawCircle(
      Offset(s.width * .50, s.height * .43),
      s.width * .09,
      Paint()..color = Colors.white.withValues(alpha: .78),
    );
  }

  void _drawSpark(Canvas canvas, Size s, Paint p) {
    final shine = Paint()..color = Colors.white.withValues(alpha: .72);
    final blob = Path()
      ..moveTo(s.width * .52, s.height * .12)
      ..cubicTo(
        s.width * .70,
        s.height * .14,
        s.width * .82,
        s.height * .27,
        s.width * .79,
        s.height * .44,
      )
      ..cubicTo(
        s.width * .94,
        s.height * .54,
        s.width * .84,
        s.height * .78,
        s.width * .63,
        s.height * .73,
      )
      ..cubicTo(
        s.width * .55,
        s.height * .91,
        s.width * .25,
        s.height * .82,
        s.width * .31,
        s.height * .60,
      )
      ..cubicTo(
        s.width * .10,
        s.height * .49,
        s.width * .22,
        s.height * .20,
        s.width * .45,
        s.height * .27,
      )
      ..cubicTo(
        s.width * .45,
        s.height * .19,
        s.width * .48,
        s.height * .14,
        s.width * .52,
        s.height * .12,
      )
      ..close();
    canvas.drawPath(
      blob.shift(Offset(s.width * .045, s.height * .065)),
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .72),
    );
    canvas.drawPath(blob, p);
    canvas.drawCircle(
      Offset(s.width * .43, s.height * .35),
      s.width * .05,
      shine,
    );
    canvas.drawCircle(
      Offset(s.width * .58, s.height * .31),
      s.width * .038,
      shine,
    );
    final ray = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .10;
    canvas.drawLine(
      Offset(s.width * .82, s.height * .18),
      Offset(s.width * .82, s.height * .39),
      ray,
    );
    canvas.drawLine(
      Offset(s.width * .94, s.height * .25),
      Offset(s.width * .94, s.height * .36),
      ray,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
