import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'nomo_pop_icon.dart';

class NomoToast {
  const NomoToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    IconData icon = CupertinoIcons.bell_fill,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _timer?.cancel();
    _currentEntry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NomoToastOverlay(message: message, icon: icon),
    );
    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      if (_currentEntry == entry) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}

class _NomoToastOverlay extends StatefulWidget {
  const _NomoToastOverlay({required this.message, required this.icon});

  final String message;
  final IconData icon;

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
      begin: const Offset(0, -1.18),
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
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F2230).withValues(alpha: .97),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFB5FF00).withValues(alpha: .26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB5FF00).withValues(alpha: .16),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .26),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
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
                        color: const Color(0xFFB5FF00),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: NomoGeneratedIcon(
                        widget.icon,
                        color: const Color(0xFF0B1420),
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
      ),
    );
  }
}
