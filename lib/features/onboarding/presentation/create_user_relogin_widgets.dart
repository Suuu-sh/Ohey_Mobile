part of 'create_user_dialog.dart';

class _ReLoginLoading extends StatelessWidget {
  const _ReLoginLoading();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ReLoginMascot(size: 112),
        const SizedBox(height: 24),
        CircularProgressIndicator(
          color: _authPink,
          backgroundColor: AppColors.white.withValues(alpha: .10),
        ),
      ],
    ),
  );
}

class _ReLoginMascot extends StatelessWidget {
  const _ReLoginMascot({this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.06,
    child: CustomPaint(painter: _ReLoginMascotPainter()),
  );
}

class _ReLoginMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Paint()..color = AppColors.cFFFF4FA3;
    final bodyDark = Paint()..color = AppColors.cFFE52B83;
    final bodyLight = Paint()..color = AppColors.cFFFF86C7;
    final eye = Paint()..color = AppColors.cFF101827;
    final white = Paint()..color = AppColors.white;
    final mouth = Paint()..color = AppColors.cFF251225;
    final tongue = Paint()..color = AppColors.cFFFF6AAE;
    final leaf = Paint()..color = AppColors.cFF84E817;
    final leafDark = Paint()..color = AppColors.cFF58C80A;
    final sparkle = Paint()..color = AppColors.cFFFF4FAB;

    void rotatedOval(
      Offset center,
      double width,
      double height,
      double radians,
      Paint paint,
    ) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(radians)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          paint,
        )
        ..restore();
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .86),
        width: w * .48,
        height: h * .075,
      ),
      Paint()..color = AppColors.cFFFF4FAB.withValues(alpha: .16),
    );

    rotatedOval(Offset(w * .34, h * .74), w * .22, h * .18, -.55, body);
    rotatedOval(Offset(w * .57, h * .77), w * .19, h * .22, -.12, body);
    rotatedOval(Offset(w * .22, h * .50), w * .20, h * .29, -.54, body);
    rotatedOval(Offset(w * .78, h * .56), w * .20, h * .25, .14, body);

    final bodyRect = Rect.fromCenter(
      center: Offset(w * .50, h * .54),
      width: w * .66,
      height: h * .58,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .38, h * .39),
        width: w * .30,
        height: h * .13,
      ),
      bodyLight..color = AppColors.cFFFF86C7.withValues(alpha: .36),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .58, h * .70),
        width: w * .30,
        height: h * .13,
      ),
      bodyDark..color = AppColors.cFFE52B83.withValues(alpha: .18),
    );

    final stem = Path()
      ..moveTo(w * .50, h * .26)
      ..cubicTo(w * .52, h * .20, w * .58, h * .21, w * .59, h * .29)
      ..cubicTo(w * .56, h * .31, w * .52, h * .31, w * .49, h * .29)
      ..close();
    canvas.drawPath(stem, leafDark);

    final leafPath = Path()
      ..moveTo(w * .52, h * .20)
      ..cubicTo(w * .58, h * .07, w * .83, h * .08, w * .83, h * .23)
      ..cubicTo(w * .81, h * .36, w * .60, h * .36, w * .52, h * .20)
      ..close();
    canvas.drawPath(leafPath, leaf);
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = AppColors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .012,
    );

    rotatedOval(Offset(w * .38, h * .48), w * .17, h * .27, .17, eye);
    rotatedOval(Offset(w * .60, h * .50), w * .17, h * .27, -.08, eye);
    canvas.drawCircle(Offset(w * .41, h * .42), w * .035, white);
    canvas.drawCircle(Offset(w * .62, h * .44), w * .035, white);

    final smile = Path()
      ..moveTo(w * .43, h * .61)
      ..cubicTo(w * .46, h * .70, w * .58, h * .70, w * .61, h * .61)
      ..cubicTo(w * .57, h * .64, w * .48, h * .64, w * .43, h * .61)
      ..close();
    canvas.drawPath(smile, mouth);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .52, h * .66),
        width: w * .11,
        height: h * .045,
      ),
      tongue,
    );

    final starCenter = Offset(w * .88, h * .33);
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? w * .08 : w * .028;
      final angle = -math.pi / 2 + i * math.pi / 4;
      final point = Offset(
        starCenter.dx + math.cos(angle) * radius,
        starCenter.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, sparkle);
    canvas.drawPath(
      star,
      Paint()
        ..color = AppColors.cFFFF9BD0
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .012,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReLoginAccountCard extends StatelessWidget {
  const _ReLoginAccountCard({
    required this.accounts,
    required this.onAccountTap,
    required this.onAddAccount,
    this.compact = false,
  });

  final List<OheyLastAccount> accounts;
  final ValueChanged<OheyLastAccount> onAccountTap;
  final VoidCallback onAddAccount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleAccounts = accounts
        .take(OheyLastAccountStore.maxAccounts)
        .toList(growable: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: OheyThemedPanel(
        accentColor: AppColors.white,
        backgroundColor: OheyThemedPanel.surfaceColor(isWhite: false),
        borderRadius: 20,
        borderAlpha: .20,
        borderWidth: 2,
        glowAlpha: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < visibleAccounts.length; index++) ...[
              _ReLoginAccountRow(
                account: visibleAccounts[index],
                compact: compact,
                onTap: () => onAccountTap(visibleAccounts[index]),
              ),
              Divider(height: 1, color: AppColors.white.withValues(alpha: .16)),
            ],
            InkWell(
              onTap: onAddAccount,
              child: Padding(
                padding: compact
                    ? const EdgeInsets.fromLTRB(18, 14, 18, 14)
                    : const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 46 : 52,
                      height: compact ? 46 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: .34),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: OheyGeneratedIcon(
                          CupertinoIcons.plus,
                          color: AppColors.white.withValues(alpha: .44),
                          size: compact ? 24 : 26,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 14 : 16),
                    Text(
                      '別のアカウントを追加',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: .44),
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReLoginAccountRow extends StatelessWidget {
  const _ReLoginAccountRow({
    required this.account,
    required this.onTap,
    required this.compact,
  });

  final OheyLastAccount account;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(18, 12, 16, 10)
          : const EdgeInsets.fromLTRB(20, 16, 18, 14),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.peach, AppColors.lavender],
              ),
            ),
            child: OheyAvatarView(
              avatar: account.avatar ?? OheyAvatar.defaultAvatar,
              size: compact ? 40 : 48,
            ),
          ),
          SizedBox(width: compact ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .36),
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: AppColors.white.withValues(alpha: .68),
            size: compact ? 25 : 28,
          ),
        ],
      ),
    ),
  );
}
