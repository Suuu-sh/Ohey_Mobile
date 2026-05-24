import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'nomo_pop_icon.dart';

enum NomoToastPlacement { top, bottom }

class NomoToastAccent extends InheritedTheme {
  const NomoToastAccent({super.key, required this.color, required super.child});

  final Color color;

  static Color? maybeOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<NomoToastAccent>();
    final widget = element?.widget;
    return widget is NomoToastAccent ? widget.color : null;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return NomoToastAccent(color: color, child: child);
  }

  @override
  bool updateShouldNotify(NomoToastAccent oldWidget) {
    return color != oldWidget.color;
  }
}

class NomoToast {
  const NomoToast._();

  static const defaultPlacement = NomoToastPlacement.bottom;
  static const defaultAccentColor = Color(0xFF7DDCFF);
  static const successAccentColor = Color(0xFF74E6A4);
  static const dangerAccentColor = Color(0xFFFF8BA8);
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    IconData icon = CupertinoIcons.bell_fill,
    Duration duration = const Duration(milliseconds: 2600),
    NomoToastPlacement placement = defaultPlacement,
    Color? accentColor,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final callerTopPadding = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final callerBottomPadding =
        MediaQuery.maybeOf(context)?.padding.bottom ?? 0;
    final overlayTopPadding =
        MediaQuery.maybeOf(overlay.context)?.padding.top ?? 0;
    final overlayBottomPadding =
        MediaQuery.maybeOf(overlay.context)?.padding.bottom ?? 0;
    final topPadding = math.max(callerTopPadding, overlayTopPadding);
    final bottomPadding = math.max(callerBottomPadding, overlayBottomPadding);
    final resolvedAccentColor = accentColorForIcon(
      icon,
      pageAccentColor: NomoToastAccent.maybeOf(context),
      overrideAccentColor: accentColor,
    );

    _timer?.cancel();
    _removeCurrentEntry();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NomoToastOverlay(
        message: message,
        icon: icon,
        topPadding: topPadding,
        bottomPadding: bottomPadding,
        placement: placement,
        accentColor: resolvedAccentColor,
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      if (_currentEntry == entry) {
        _removeCurrentEntry();
      }
    });
  }

  static void _removeCurrentEntry() {
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry == null || !entry.mounted) return;
    entry.remove();
  }

  static double topOffsetFor(double topPadding) {
    const safeAreaGap = 18.0;
    const minimumVisibleTop = 88.0;
    return math.max(topPadding + safeAreaGap, minimumVisibleTop);
  }

  static double bottomOffsetFor(double bottomPadding) {
    const tabBarTopClearance = 72.0;
    return bottomPadding + tabBarTopClearance;
  }

  static Color accentColorForIcon(
    IconData icon, {
    Color? pageAccentColor,
    Color? overrideAccentColor,
  }) {
    if (overrideAccentColor != null) {
      return overrideAccentColor;
    }
    if (icon == CupertinoIcons.checkmark_circle_fill) {
      return pageAccentColor ?? successAccentColor;
    }
    if (icon == CupertinoIcons.exclamationmark_triangle_fill) {
      return dangerAccentColor;
    }
    return pageAccentColor ?? defaultAccentColor;
  }
}

class _NomoToastOverlay extends StatefulWidget {
  const _NomoToastOverlay({
    required this.message,
    required this.icon,
    required this.topPadding,
    required this.bottomPadding,
    required this.placement,
    required this.accentColor,
  });

  final String message;
  final IconData icon;
  final double topPadding;
  final double bottomPadding;
  final NomoToastPlacement placement;
  final Color accentColor;

  @override
  State<_NomoToastOverlay> createState() => _NomoToastOverlayState();
}

class _NomoToastOverlayState extends State<_NomoToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _slide = Tween<Offset>(
      begin: widget.placement == NomoToastPlacement.bottom
          ? const Offset(0, 1.18)
          : const Offset(0, -1.18),
      end: Offset.zero,
    ).animate(curve);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;
    final toast = IgnorePointer(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF122335), Color(0xFF0A1724)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .13)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: .10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .32),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentColor.withValues(alpha: .30),
                      ),
                    ),
                    child: NomoGeneratedIcon(
                      widget.icon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.placement == NomoToastPlacement.bottom) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: NomoToast.bottomOffsetFor(widget.bottomPadding),
        child: toast,
      );
    }
    return Positioned(
      top: NomoToast.topOffsetFor(widget.topPadding),
      left: 16,
      right: 16,
      child: toast,
    );
  }
}
