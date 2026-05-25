// ignore_for_file: unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/widgets/nomo_themed_panel.dart';
import '../../admin/application/admin_controller.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../friends/presentation/friend_add_sheet.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../onboarding/presentation/create_user_dialog.dart';
import 'avatar_builder_screen.dart';
import 'photo_archive_screen.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

part 'profile_header_widgets.dart';
part 'profile_memory_widgets.dart';
part 'profile_status_sheet.dart';
part 'profile_settings_sheet.dart';
part 'profile_form_helpers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(nomoUserProvider);
    final currentAuthUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final currentAuthUserId = currentAuthUser?.id;
    final reservationsAsync = ref.watch(todayReservationsProvider);
    final incomingInvitesAsync = ref.watch(incomingDrinkInvitesProvider);
    final reservations =
        reservationsAsync.asData?.value ?? const <NomoDrinkInvite>[];
    final incomingInvites =
        incomingInvitesAsync.asData?.value ?? const <NomoDrinkInvite>[];
    final logs =
        ref.watch(drinkLogControllerProvider).asData?.value ??
        const <DrinkLog>[];
    final myLogs = _myProfileLogs(logs, currentAuthUserId);
    final photoLogs = _photoArchiveLogs(logs, currentAuthUserId);
    final friends =
        ref.watch(friendsProvider).asData?.value ?? const <NomoFriend>[];
    const headerIsWhite = true;
    const bodyIsWhite = false;
    final hasAdminEmail = NomoAvatar.isAdminEmail(currentAuthUser?.email);
    final hasAdminAccess = ref
        .watch(adminAccessProvider)
        .maybeWhen(data: (allowed) => allowed, orElse: () => false);
    final canOpenAdmin = hasAdminEmail || hasAdminAccess;
    const bodyBackground = AppColors.darkBackgroundBottom;
    final headerBackgroundHeight = MediaQuery.paddingOf(context).top + 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: bodyBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: bodyBackground),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerBackgroundHeight,
              child: _ProfileHeaderBackdrop(avatar: user?.avatar),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ProfileTopSheet(
                    child: Column(
                      children: [
                        _PageHeader(
                          isWhite: headerIsWhite,
                          canOpenAdmin: canOpenAdmin,
                          onSettings: () => _showSettingsSheet(context, ref),
                          onAdmin: () => _openAdminScreen(context),
                        ),
                        const SizedBox(height: 14),
                        _SimpleHero(
                          isWhite: headerIsWhite,
                          name: user?.name ?? 'ユーザー名',
                          avatar: user?.avatar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ColoredBox(
                      color: bodyBackground,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (reservations.isNotEmpty ||
                              incomingInvites.isNotEmpty)
                            ColoredBox(
                              color: bodyBackground,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  24,
                                  18,
                                ),
                                child: _ProfileReservationStrip(
                                  isWhite: bodyIsWhite,
                                  userAvatar: user?.avatar,
                                  currentUserId: currentAuthUserId,
                                  reservations: reservations,
                                  incomingInvites: incomingInvites,
                                  onAccept: (invite) => _respondDrinkInvite(
                                    context,
                                    ref,
                                    invite,
                                    accept: true,
                                  ),
                                  onReject: (invite) => _respondDrinkInvite(
                                    context,
                                    ref,
                                    invite,
                                    accept: false,
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: _ProfileActivityHome(
                              isWhite: bodyIsWhite,
                              logs: myLogs,
                              photoLogs: photoLogs,
                              friendsCount: friends.length,
                              status:
                                  user?.dailyStatus ??
                                  NomoDailyStatus.unselected,
                              onStatusTap: () =>
                                  _showProfileStatusSheet(context, ref),
                              onLogsTap: () => NomoToast.show(
                                context,
                                'カレンダーを見てみてね。',
                                icon: CupertinoIcons.calendar,
                              ),
                              onArchiveTap: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  fullscreenDialog: true,
                                  builder: (_) =>
                                      PhotoArchiveScreen(logs: photoLogs),
                                ),
                              ),
                              onAddFriendsTap: () =>
                                  showFriendAddSheet(context, ref),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isMyUserLog(DrinkLog log, String? currentUserId) {
  if (log.isOfficial) return false;
  if (currentUserId == null || currentUserId.isEmpty) return true;
  if (log.ownerUserId.isEmpty) return true;
  return log.ownerUserId == currentUserId;
}

List<DrinkLog> _myProfileLogs(List<DrinkLog> logs, String? currentAuthUserId) =>
    logs
        .where((log) => _isMyUserLog(log, currentAuthUserId))
        .toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));

List<DrinkLog> _photoArchiveLogs(
  List<DrinkLog> logs,
  String? currentAuthUserId,
) => logs
    .where((log) => _isMyUserLog(log, currentAuthUserId))
    .where((log) => (log.photoAssetPath ?? '').trim().isNotEmpty)
    .toList(growable: false);

Future<void> _showProfileStatusSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected =
      ref.read(nomoUserProvider)?.dailyStatus ?? NomoDailyStatus.unselected;
  await showNomoBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SheetShell(
      title: '今日のステータス',
      child: _ProfileStatusSheetContent(selected: selected, ref: ref),
    ),
  );
}

class _ProfileColors {
  const _ProfileColors._();
  static const line = Color(0x1EFFFFFF);
  static const sub = Color(0xFF8F9BAB);
  static const lime = Color(0xFF9AF21A);
  static const pink = Color(0xFFFF5EA8);
}

Color _statusColor(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.canDrinkToday => _ProfileColors.lime,
  NomoDailyStatus.nonAlcohol => const Color(0xFF5DEBD3),
  NomoDailyStatus.liverRest => _ProfileColors.pink,
  NomoDailyStatus.hasPlans => const Color(0xFFB8C1CD),
  NomoDailyStatus.unselected => _ProfileColors.sub,
};

IconData _statusIcon(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.canDrinkToday => CupertinoIcons.checkmark_circle_fill,
  NomoDailyStatus.nonAlcohol => CupertinoIcons.drop_fill,
  NomoDailyStatus.liverRest => CupertinoIcons.moon_fill,
  NomoDailyStatus.hasPlans => CupertinoIcons.calendar_today,
  NomoDailyStatus.unselected => CupertinoIcons.circle,
};

Future<void> _respondDrinkInvite(
  BuildContext context,
  WidgetRef ref,
  NomoDrinkInvite invite, {
  required bool accept,
}) async {
  try {
    final controller = ref.read(drinkInviteControllerProvider);
    if (accept) {
      await controller.accept(invite.id);
    } else {
      await controller.reject(invite.id);
    }
    if (!context.mounted) return;
    NomoToast.show(context, accept ? '飲み予定が成立しました。' : '招待を見送りました。');
  } catch (error) {
    if (!context.mounted) return;
    NomoToast.show(context, '返信できなかったよ。あとでもう一度試してね');
  }
}

const _selectableDailyStatuses = <NomoDailyStatus>[
  NomoDailyStatus.canDrinkToday,
  NomoDailyStatus.nonAlcohol,
  NomoDailyStatus.liverRest,
  NomoDailyStatus.hasPlans,
];
