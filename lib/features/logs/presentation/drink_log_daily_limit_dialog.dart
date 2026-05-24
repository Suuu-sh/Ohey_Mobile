import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../application/drink_log_daily_limit.dart';

Future<void> showDrinkLogDailyLimitDialog(BuildContext context, DateTime day) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '閉じる',
    barrierColor: Colors.black.withValues(alpha: .62),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _DrinkLogDailyLimitDialog(
        day: day,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _DrinkLogDailyLimitDialog extends StatelessWidget {
  const _DrinkLogDailyLimitDialog({required this.day, required this.onClose});

  final DateTime day;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final bodyColor = isWhite
        ? const Color(0xFF647284)
        : Colors.white.withValues(alpha: .70);
    final cardGradient = isWhite
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF2F7), Color(0xFFEAF8FF)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18293A), Color(0xFF0B1722)],
          );

    return Center(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isWhite
                      ? Colors.white.withValues(alpha: .82)
                      : Colors.white.withValues(alpha: .14),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isWhite ? .18 : .38),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: AppColors.primaryAction.withValues(alpha: .16),
                    blurRadius: 42,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -10,
                    top: -8,
                    child: _DialogBubble(color: Color(0xFFFFDDE8), size: 56),
                  ),
                  const Positioned(
                    left: -14,
                    bottom: 36,
                    child: _DialogBubble(color: Color(0xFFD9F0FF), size: 44),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryAction.withValues(
                                  alpha: isWhite ? .16 : .20,
                                ),
                              ),
                            ),
                            NomoPopIcon(
                              icon: CupertinoIcons.checkmark_seal_fill,
                              color: AppColors.primaryAction,
                              size: 62,
                              iconSize: 33,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.invite.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.invite.withValues(alpha: .28),
                            ),
                          ),
                          child: Text(
                            '1日1回のNomoルール',
                            style: TextStyle(
                              color: isWhite
                                  ? AppColors.inviteShadow
                                  : AppColors.invite,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        drinkLogDailyLimitAlertTitle(
                          day: day,
                          now: DateTime.now(),
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        drinkLogDailyLimitAlertMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DialogHint(isWhite: isWhite),
                      const SizedBox(height: 18),
                      Nomo3DButton(
                        label: 'OK',
                        icon: CupertinoIcons.heart_fill,
                        onTap: onClose,
                        height: 50,
                        radius: 22,
                        color: AppColors.invite,
                        shadowColor: AppColors.inviteShadow,
                        fontSize: 15,
                        useGradient: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHint extends StatelessWidget {
  const _DialogHint({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final color = isWhite
        ? const Color(0xFF52606B)
        : Colors.white.withValues(alpha: .70);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white.withValues(alpha: .72)
            : Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE4ECF4)
              : Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          NomoPopIcon(
            icon: CupertinoIcons.calendar_badge_plus,
            color: AppColors.info,
            size: 36,
            iconSize: 19,
            shadow: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'カレンダーから別の日を選ぶと、その日の思い出として残せます。',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogBubble extends StatelessWidget {
  const _DialogBubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .62),
        ),
      ),
    );
  }
}
