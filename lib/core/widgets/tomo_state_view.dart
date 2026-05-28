import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Compact loading/error/empty state block for panels and list sections.
///
/// Prefer [TomoEmptyState] for full-screen or illustration-rich empty pages.
class TomoStateView extends StatelessWidget {
  const TomoStateView.loading({
    super.key,
    this.message = '読み込み中...',
    this.compact = false,
  }) : icon = CupertinoIcons.hourglass,
       isLoading = true;

  const TomoStateView.error({
    super.key,
    required this.message,
    this.compact = false,
  }) : icon = CupertinoIcons.exclamationmark_triangle_fill,
       isLoading = false;

  const TomoStateView.empty({
    super.key,
    required this.message,
    this.compact = false,
  }) : icon = CupertinoIcons.tray,
       isLoading = false;

  final String message;
  final bool compact;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 46.0 : 72.0;
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const CupertinoActivityIndicator(color: Colors.white)
          else
            Icon(icon, color: Colors.white.withValues(alpha: .62), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
