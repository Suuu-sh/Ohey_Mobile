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
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final effectivePadding = resolvedPadding.add(
      EdgeInsets.only(bottom: bottomSafePadding),
    );
    final sheetRadius = BorderRadius.vertical(top: Radius.circular(radius));
    return SafeArea(
      top: topSafeArea,
      bottom: false,
      child: Padding(
        padding: margin.add(EdgeInsets.only(bottom: bottomInset)),
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
                  border: Border.all(
                    color: isWhite
                        ? const Color(0xFFE1E8F1)
                        : Colors.white.withValues(alpha: .12),
                    width: 1.2,
                  ),
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
