import 'package:flutter/material.dart';

import '../models/ohey_avatar.dart';
import '../theme/app_colors.dart';
import 'ohey_bottom_sheet.dart';
import 'ohey_page_header.dart';
import 'ohey_profile_hero_header.dart';

class OheyUserProfileSheet extends StatelessWidget {
  const OheyUserProfileSheet({
    super.key,
    required this.avatar,
    required this.label,
    required this.body,
    this.headerAction,
    this.bottomCloseHorizontalPadding = 18,
  });

  final OheyAvatar avatar;
  final String label;
  final Widget body;
  final Widget? headerAction;
  final double bottomCloseHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetContentHeight =
        media.size.height - media.padding.top - media.padding.bottom;

    return OheyBottomSheetShell(
      showHandle: true,
      bottomCloseHorizontalPadding: bottomCloseHorizontalPadding,
      padding: EdgeInsets.zero,
      radius: 0,
      maxHeightFactor: 1,
      followKeyboard: false,
      child: SizedBox(
        height: sheetContentHeight,
        child: ColoredBox(
          color: AppColors.darkBackgroundBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OheyUserProfileTopBackdrop(
                avatar: avatar,
                label: label,
                action: headerAction,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: body,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OheyUserProfileTopBackdrop extends StatelessWidget {
  const _OheyUserProfileTopBackdrop({
    required this.avatar,
    required this.label,
    this.action,
  });

  final OheyAvatar avatar;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final headerHeight = topPadding + 318;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OheyProfileHeaderBackdrop(avatar: avatar),
          if (action != null)
            Positioned(right: 20, top: topPadding + 46, child: action!),
          Padding(
            padding: EdgeInsets.fromLTRB(
              OheyPageHeader.horizontalPadding,
              topPadding + 4,
              OheyPageHeader.horizontalPadding,
              6,
            ),
            child: Column(
              children: [
                const Spacer(),
                OheyProfileHeroBanner(avatar: avatar, label: label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
