// ignore_for_file: unused_element

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/backend_api_client.dart';
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
import '../../../core/widgets/nomo_exchange_components.dart';
import '../../admin/application/admin_controller.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../friends/presentation/add_nomi_tomo_screen.dart';
import '../../friends/data/friend_repository.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../onboarding/presentation/create_user_dialog.dart';
import 'avatar_builder_screen.dart';
import 'photo_archive_screen.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

part 'profile_header_widgets.dart';
part 'profile_preview_sheet.dart';
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
              child: const _ProfileHeaderBackdrop(),
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
                  Expanded(
                    child: ColoredBox(
                      color: bodyBackground,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ColoredBox(
                            color: bodyBackground,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                24,
                                18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (reservations.isNotEmpty ||
                                      incomingInvites.isNotEmpty) ...[
                                    _ProfileReservationStrip(
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
                                    const SizedBox(height: 12),
                                  ],
                                  _ProfileMoodCta(
                                    status:
                                        user?.dailyStatus ??
                                        NomoDailyStatus.unselected,
                                    onTap: () =>
                                        _showProfileStatusSheet(context, ref),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _ProfileActivityHome(
                              isWhite: bodyIsWhite,
                              logs: myLogs,
                              photoLogs: photoLogs,
                              status:
                                  user?.dailyStatus ??
                                  NomoDailyStatus.unselected,
                              onStatusTap: () =>
                                  _showProfileStatusSheet(context, ref),
                              onArchiveTap: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  fullscreenDialog: true,
                                  builder: (_) =>
                                      PhotoArchiveScreen(logs: photoLogs),
                                ),
                              ),
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

String _profileQrPayload(String userId) => 'nomo://friend/$userId';

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

String? _parseProfileFriendQrPayload(String raw) {
  final value = raw.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.scheme == 'nomo' && uri.host == 'friend') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return id?.isEmpty == false ? id : null;
  }
  if (RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(value)) return value;
  return null;
}

const _qrSaverChannel = MethodChannel('nomo/qr_saver');

Future<Uint8List> _createQrPngBytes(String payload) async {
  final painter = QrPainter(
    data: payload,
    version: QrVersions.auto,
    gapless: false,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF4B5056),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.circle,
      color: Color(0xFF4B5056),
    ),
  );
  final data = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('QR画像を生成できませんでした');
  }
  return data.buffer.asUint8List();
}

Future<void> showMyQrDialog(
  BuildContext context,
  NomoUser? user,
  WidgetRef ref,
) async {
  if (user == null) {
    NomoToast.show(context, 'プロフィール作成後にQRを表示できます。');
    return;
  }

  final payload = _profileQrPayload(user.userId);
  final name = user.name.trim().isEmpty ? 'nomo_user' : user.name.trim();

  Future<void> copyUserId(BuildContext dialogContext) async {
    await Clipboard.setData(ClipboardData(text: user.userId));
    if (!dialogContext.mounted) return;
    NomoToast.show(dialogContext, 'ユーザーIDをコピーしました');
  }

  Future<void> saveQrImage(BuildContext dialogContext) async {
    try {
      final pngBytes = await _createQrPngBytes(payload);
      await _qrSaverChannel.invokeMethod<void>('savePngToPhotos', pngBytes);
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, 'QR画像を保存しました');
    } on PlatformException catch (error) {
      if (!dialogContext.mounted) return;
      final message = error.code == 'permission_denied'
          ? '写真への保存が許可されていません'
          : 'QR画像を保存できませんでした';
      NomoToast.show(dialogContext, message);
    } on MissingPluginException {
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, 'この端末ではQR保存に未対応です');
    } catch (_) {
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, 'QR画像を保存できませんでした');
    }
  }

  Future<void> sendFriendRequest(
    BuildContext sheetContext,
    NomoFriendProfile profile,
  ) async {
    final repository = ref.read(friendRepositoryProvider);
    final currentUserId = repository.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      NomoToast.show(sheetContext, 'フレンズ申請にはログインが必要です');
      return;
    }
    if (profile.id == currentUserId) {
      NomoToast.show(sheetContext, '自分自身には申請できません');
      return;
    }

    try {
      await repository.sendFriendRequest(profile.id);
      if (!sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      if (!context.mounted) return;
      NomoToast.show(context, '${profile.displayName}にフレンズ申請を送りました');
    } on BackendApiException catch (e) {
      if (!sheetContext.mounted) return;
      if (e.statusCode == 409) {
        NomoToast.show(sheetContext, 'すでに申請済みです');
      } else {
        NomoToast.show(sheetContext, '申請を送れなかったよ。あとでもう一度試してね');
      }
    } catch (e) {
      if (!sheetContext.mounted) return;
      NomoToast.show(sheetContext, '申請を送れなかったよ。あとでもう一度試してね');
    }
  }

  Future<void> searchAndShowProfileByUserId(
    BuildContext dialogContext,
    String rawUserId,
  ) async {
    final query = rawUserId.trim();
    if (query.isEmpty) {
      NomoToast.show(dialogContext, 'ユーザーIDを入力してください');
      return;
    }

    final repository = ref.read(friendRepositoryProvider);
    final currentUserId = repository.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      NomoToast.show(dialogContext, 'フレンズ追加にはログインが必要です');
      return;
    }

    try {
      final profile = await repository.findProfileByUserId(query);
      if (!dialogContext.mounted) return;
      if (profile == null) {
        NomoToast.show(dialogContext, '@$query は見つかりませんでした');
        return;
      }
      if (profile.id == currentUserId) {
        NomoToast.show(dialogContext, '自分自身は追加できません');
        return;
      }

      final relationship = await repository.relationshipStatus(profile.id);
      if (!dialogContext.mounted) return;
      await showModalBottomSheet<void>(
        context: dialogContext,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .62),
        builder: (sheetContext) => _NomoProfilePreviewSheet(
          profile: profile,
          alreadyFriend: relationship.alreadyFriend,
          requestState: relationship.requestState,
          onRequest: () => sendFriendRequest(sheetContext, profile),
        ),
      );
    } on BackendApiException catch (e) {
      if (!dialogContext.mounted) return;
      if (e.statusCode == 404) {
        NomoToast.show(dialogContext, '@$query は見つかりませんでした');
      } else {
        NomoToast.show(dialogContext, '検索できなかったよ。あとでもう一度試してね');
      }
    } catch (e) {
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, '検索できなかったよ。あとでもう一度試してね');
    }
  }

  Future<void> scanQr(BuildContext dialogContext) async {
    final payload = await Navigator.of(dialogContext).push<String>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NomiTomoQrScannerScreen(),
      ),
    );
    if (!dialogContext.mounted || payload == null) return;
    final userId = _parseProfileFriendQrPayload(payload);
    if (userId == null) {
      NomoToast.show(dialogContext, 'NomoのフレンズQRではありません');
      return;
    }
    await searchAndShowProfileByUserId(dialogContext, userId);
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .74),
    builder: (dialogContext) {
      final mediaQuery = MediaQuery.of(dialogContext);
      final maxDialogHeight =
          (mediaQuery.size.height -
                  mediaQuery.viewInsets.bottom -
                  mediaQuery.padding.vertical -
                  48)
              .clamp(360.0, mediaQuery.size.height)
              .toDouble();

      return MediaQuery(
        data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1)),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: _MyQrCard(
              name: name,
              handle: '@${user.userId}',
              avatar: user.avatar,
              payload: payload,
              onClose: () => Navigator.of(dialogContext).pop(),
              onCopyUserId: () => copyUserId(dialogContext),
              onSaveQr: () => saveQrImage(dialogContext),
              onScan: () => scanQr(dialogContext),
              onSearchUserId: (value) =>
                  searchAndShowProfileByUserId(dialogContext, value),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showProfileStatusSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected =
      ref.read(nomoUserProvider)?.dailyStatus ?? NomoDailyStatus.unselected;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
