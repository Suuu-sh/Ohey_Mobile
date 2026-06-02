import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Future<T?> showOheyBottomSheet<T>({
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
    backgroundColor: AppColors.transparent,
    barrierColor: barrierColor,
    builder: builder,
  );
}

class OheyBottomSheetShell extends StatelessWidget {
  const OheyBottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.showHandle = true,
    this.topSafeArea = false,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 18),
    this.radius = 30,
    this.blurSigma = 16,
    this.maxHeightFactor,
    this.followKeyboard = true,
    this.showBottomCloseButton = true,
    this.bottomCloseLabel = '閉じる',
    this.onBottomClose,
    this.bottomCloseHorizontalPadding = 0,
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
  final bool showBottomCloseButton;
  final String bottomCloseLabel;
  final VoidCallback? onBottomClose;
  final double bottomCloseHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
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
                  color: isWhite ? AppColors.white : AppColors.darkBackground,
                  borderRadius: sheetRadius,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(
                        alpha: isWhite ? .16 : .36,
                      ),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sheetChild = constraints.hasBoundedHeight
                        ? Flexible(fit: FlexFit.loose, child: child)
                        : child;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHandle) ...[
                          const SizedBox(height: 8),
                          const OheyBottomSheetHandle(),
                          const SizedBox(height: 16),
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
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        sheetChild,
                        if (showBottomCloseButton) ...[
                          const SizedBox(height: 16),
                          _OheyBottomSheetFooterButton(
                            label: bottomCloseLabel,
                            horizontalPadding: bottomCloseHorizontalPadding,
                            onTap:
                                onBottomClose ??
                                () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OheyBottomSheetFooterButton extends StatelessWidget {
  const _OheyBottomSheetFooterButton({
    required this.label,
    required this.onTap,
    required this.horizontalPadding,
  });

  final String label;
  final VoidCallback onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isWhite
                ? AppColors.cFFF2F4F6
                : AppColors.darkBackgroundBottom,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isWhite
                  ? AppColors.cFFD7DEE7
                  : AppColors.white.withValues(alpha: .10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isWhite ? .08 : .22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isWhite ? AppColors.cFF27313B : AppColors.cFFC08BFF,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
        ),
      ),
    );
  }
}

class OheyBottomSheetHandle extends StatelessWidget {
  const OheyBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: isWhite
              ? AppColors.cFFD7E0EA
              : AppColors.white.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class OheyCloseButton extends StatelessWidget {
  const OheyCloseButton({
    super.key,
    this.onTap,
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
