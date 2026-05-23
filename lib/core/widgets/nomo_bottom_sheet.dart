import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'nomo_pop_icon.dart';

class NomoBottomSheetShell extends StatelessWidget {
  const NomoBottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.showHandle = false,
    this.topSafeArea = false,
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 14),
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 18),
    this.radius = 30,
    this.blurSigma = 16,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final bool showHandle;
  final bool topSafeArea;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return SafeArea(
      top: topSafeArea,
      child: Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: isWhite ? Colors.white : null,
                gradient: isWhite
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF172737), Color(0xFF0B1722)],
                      ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isWhite
                      ? const Color(0xFFE1E8F1)
                      : Colors.white.withValues(alpha: .12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isWhite ? .16 : .36),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHandle) ...[
                    const NomoBottomSheetHandle(),
                    const SizedBox(height: 18),
                  ],
                  if (title != null) ...[
                    Row(
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed:
                              onClose ?? () => Navigator.of(context).pop(),
                          icon: NomoGeneratedIcon(
                            CupertinoIcons.xmark,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NomoBottomSheetHandle extends StatelessWidget {
  const NomoBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFD7E0EA)
              : Colors.white.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
