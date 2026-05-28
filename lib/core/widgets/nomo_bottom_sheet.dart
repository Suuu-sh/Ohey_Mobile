import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nomo_pop_icon.dart';

Future<T?> showNomoBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = false,
  Color? barrierColor,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    constraints: BoxConstraints(
      minWidth: MediaQuery.sizeOf(context).width,
      maxWidth: MediaQuery.sizeOf(context).width,
    ),
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: builder,
  );
}

class NomoBottomSheetShell extends StatelessWidget {
  const NomoBottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.showHandle = false,
    this.topSafeArea = false,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 18),
    this.radius = 30,
    this.blurSigma = 16,
    this.maxHeightFactor,
    this.followKeyboard = true,
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
  final double? maxHeightFactor;
  final bool followKeyboard;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final maxHeight = maxHeightFactor == null
        ? null
        : MediaQuery.sizeOf(context).height * maxHeightFactor!;
    final bottomInset = followKeyboard
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final bottomSafePadding = MediaQuery.paddingOf(context).bottom;
    final direction = Directionality.of(context);
    final resolvedPadding = padding.resolve(direction);
    final resolvedMargin = margin.resolve(direction);
    final effectivePadding = resolvedPadding.add(
      EdgeInsets.only(bottom: bottomSafePadding),
    );
    final effectiveMargin = EdgeInsets.only(
      top: resolvedMargin.top,
      bottom: bottomInset,
    );
    final sheetRadius = BorderRadius.vertical(top: Radius.circular(radius));
    return SafeArea(
      top: topSafeArea,
      bottom: false,
      left: false,
      right: false,
      child: Padding(
        padding: effectiveMargin,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
          child: ClipRRect(
            borderRadius: sheetRadius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                padding: effectivePadding,
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : AppColors.darkBackground,
                  borderRadius: sheetRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isWhite ? .16 : .36,
                      ),
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
                          NomoCloseButton(
                            onTap: onClose ?? () => Navigator.of(context).pop(),
                            iconColor: ink,
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

class NomoCloseButton extends StatelessWidget {
  const NomoCloseButton({
    super.key,
    required this.onTap,
    this.enabled = true,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.semanticLabel = '閉じる',
  });

  final VoidCallback? onTap;
  final bool enabled;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final resolvedIconColor =
        iconColor ?? (isWhite ? const Color(0xFF101820) : Colors.white);
    final resolvedBackground =
        backgroundColor ??
        (isWhite
            ? const Color(0xFFF3F7FA)
            : Colors.white.withValues(alpha: .08));
    final resolvedBorder =
        borderColor ??
        (isWhite
            ? const Color(0xFFE0E7EE)
            : Colors.white.withValues(alpha: .10));

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: resolvedBackground,
              shape: BoxShape.circle,
              border: Border.all(color: resolvedBorder),
            ),
            child: Center(
              child: NomoGeneratedIcon(
                CupertinoIcons.xmark,
                color: resolvedIconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
