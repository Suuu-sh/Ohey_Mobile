// ignore_for_file: unused_element

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../friends/presentation/add_nomi_tomo_screen.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../onboarding/presentation/create_user_dialog.dart';
import 'avatar_builder_screen.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final currentAuthUserId = Supabase.instance.client.auth.currentUser?.id;
    final reservationsAsync = ref.watch(todayReservationsProvider);
    final incomingInvitesAsync = ref.watch(incomingDrinkInvitesProvider);
    final reservations =
        reservationsAsync.asData?.value ?? const <NomoDrinkInvite>[];
    final incomingInvites =
        incomingInvitesAsync.asData?.value ?? const <NomoDrinkInvite>[];
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final friendsCount = friendsAsync.asData?.value.length ?? 0;
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    final canOpenAdmin =
        Supabase.instance.client.auth.currentUser?.email?.toLowerCase() ==
        'yisshiki39@gmail.com';
    final monthlyLogs = logs
        .where((log) => log.isInMonth(DateTime.now()))
        .toList();
    final streak = _currentStreak(logs);
    final topBackground = isWhite
        ? const Color(0xFF06111D)
        : const Color(0xFFF4F2EE);
    final bodyBackground = isWhite ? Colors.white : const Color(0xFF0B1420);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isWhite ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: topBackground),
      child: Scaffold(
        backgroundColor: bodyBackground,
        body: ColoredBox(
          color: topBackground,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ProfileTopSheet(
                  isWhite: isWhite,
                  child: Column(
                    children: [
                      _PageHeader(
                        isWhite: isWhite,
                        canOpenAdmin: canOpenAdmin,
                        onSettings: () => _showSettingsSheet(context, ref),
                        onAdmin: () => _openAdminScreen(context),
                      ),
                      const SizedBox(height: 14),
                      _SimpleHero(
                        isWhite: isWhite,
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
                          color: isWhite
                              ? Colors.white
                              : const Color(0xFF0B1420),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (reservations.isNotEmpty ||
                                    incomingInvites.isNotEmpty) ...[
                                  _ProfileReservationStrip(
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 106),
                            child: _ProfileDashboard(
                              isWhite: isWhite,
                              monthlyLogs: monthlyLogs.length,
                              friends: friendsCount,
                              streak: streak,
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
        ),
      ),
    );
  }
}

String _profileQrPayload(String userId) => 'nomo://friend/$userId';

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

Future<bool> _isAlreadyFriend(String currentUserId, String friendId) async {
  final rows = await Supabase.instance.client
      .from('friendships')
      .select('id')
      .or(
        'and(user_a_id.eq.$currentUserId,user_b_id.eq.$friendId),and(user_a_id.eq.$friendId,user_b_id.eq.$currentUserId)',
      )
      .limit(1);
  return rows.isNotEmpty;
}

enum _FriendRequestState { none, outgoing, incoming }

Future<_FriendRequestState> _friendRequestState(
  String currentUserId,
  String friendId,
) async {
  final rows = await Supabase.instance.client
      .from('friend_requests')
      .select('from_user_id,to_user_id')
      .eq('status', 'pending')
      .or(
        'and(from_user_id.eq.$currentUserId,to_user_id.eq.$friendId),and(from_user_id.eq.$friendId,to_user_id.eq.$currentUserId)',
      )
      .limit(1);
  if (rows.isEmpty) return _FriendRequestState.none;
  final row = Map<String, dynamic>.from(rows.first as Map);
  return row['from_user_id'] == currentUserId
      ? _FriendRequestState.outgoing
      : _FriendRequestState.incoming;
}

class _NomoSearchProfile {
  const _NomoSearchProfile({
    required this.id,
    required this.displayName,
    required this.userId,
    this.avatar,
  });

  factory _NomoSearchProfile.fromRow(Map<String, dynamic> row) {
    return _NomoSearchProfile(
      id: row['id'] as String,
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? (row['display_name'] as String).trim()
          : 'Nomo friend',
      userId: (row['user_id'] as String?) ?? '',
      avatar: NomoAvatar.decode(row['avatar_url'] as String?),
    );
  }

  final String id;
  final String displayName;
  final String userId;
  final NomoAvatar? avatar;
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
    _NomoSearchProfile profile,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      NomoToast.show(sheetContext, 'フレンズ申請にはログインが必要です');
      return;
    }
    if (profile.id == currentUser.id) {
      NomoToast.show(sheetContext, '自分自身には申請できません');
      return;
    }

    try {
      await Supabase.instance.client.from('friend_requests').insert({
        'from_user_id': currentUser.id,
        'to_user_id': profile.id,
        'status': 'pending',
      });
      if (!sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      if (!context.mounted) return;
      NomoToast.show(context, '${profile.displayName}にフレンズ申請を送りました');
    } on PostgrestException catch (e) {
      if (!sheetContext.mounted) return;
      if (e.code == '23505') {
        NomoToast.show(sheetContext, 'すでに申請済みです');
      } else {
        NomoToast.show(sheetContext, '申請を送れませんでした: ${e.message}');
      }
    } catch (e) {
      if (!sheetContext.mounted) return;
      NomoToast.show(sheetContext, '申請を送れませんでした: $e');
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

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      NomoToast.show(dialogContext, '友達追加にはログインが必要です');
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name, user_id, avatar_url')
          .eq('user_id', query)
          .maybeSingle();
      if (!dialogContext.mounted) return;
      if (row == null) {
        NomoToast.show(dialogContext, '@$query は見つかりませんでした');
        return;
      }

      final profile = _NomoSearchProfile.fromRow(
        Map<String, dynamic>.from(row),
      );
      if (profile.id == currentUser.id) {
        NomoToast.show(dialogContext, '自分自身は追加できません');
        return;
      }

      final alreadyFriend = await _isAlreadyFriend(currentUser.id, profile.id);
      final requestState = alreadyFriend
          ? _FriendRequestState.none
          : await _friendRequestState(currentUser.id, profile.id);
      if (!dialogContext.mounted) return;
      await showModalBottomSheet<void>(
        context: dialogContext,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .62),
        builder: (sheetContext) => _NomoProfilePreviewSheet(
          profile: profile,
          alreadyFriend: alreadyFriend,
          requestState: requestState,
          onRequest: () => sendFriendRequest(sheetContext, profile),
        ),
      );
    } catch (e) {
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, '検索できませんでした: $e');
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
      NomoToast.show(dialogContext, 'Nomoの友達QRではありません');
      return;
    }
    await searchAndShowProfileByUserId(dialogContext, userId);
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .74),
    builder: (dialogContext) => MediaQuery(
      data: MediaQuery.of(
        dialogContext,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
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

int _currentStreak(List<DrinkLog> logs) {
  if (logs.isEmpty) return 0;
  final days =
      logs
          .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  var streak = 0;
  var cursor = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  for (final day in days) {
    if (day == cursor) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (day.isBefore(cursor)) {
      break;
    }
  }
  return streak;
}

class _ProfileColors {
  const _ProfileColors._();
  static const panel = Color(0xFF0A1B2A);
  static const line = Color(0x1EFFFFFF);
  static const sub = Color(0xFF8F9BAB);
  static const lime = Color(0xFF9AF21A);
  static const pink = Color(0xFFFF5EA8);
}

Color _statusColor(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.canDrinkToday => _ProfileColors.lime,
  NomoDailyStatus.lightDrink => const Color(0xFF58D6FF),
  NomoDailyStatus.wantDrinkHard => const Color(0xFFFFC857),
  NomoDailyStatus.nonAlcohol => const Color(0xFF5DEBD3),
  NomoDailyStatus.liverRest => _ProfileColors.pink,
  NomoDailyStatus.waitingInvite => const Color(0xFFC08BFF),
  NomoDailyStatus.hasPlans => const Color(0xFFB8C1CD),
  NomoDailyStatus.unselected => _ProfileColors.sub,
};

IconData _statusIcon(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.canDrinkToday => CupertinoIcons.checkmark_circle_fill,
  NomoDailyStatus.lightDrink => CupertinoIcons.clock_fill,
  NomoDailyStatus.wantDrinkHard => Icons.local_bar_rounded,
  NomoDailyStatus.nonAlcohol => CupertinoIcons.drop_fill,
  NomoDailyStatus.liverRest => CupertinoIcons.moon_fill,
  NomoDailyStatus.waitingInvite => CupertinoIcons.bell_fill,
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
    NomoToast.show(context, accept ? '飲み予約が成立しました。' : '招待を見送りました。');
  } catch (error) {
    if (!context.mounted) return;
    NomoToast.show(context, '返信できませんでした: $error');
  }
}

const _selectableDailyStatuses = <NomoDailyStatus>[
  NomoDailyStatus.canDrinkToday,
  NomoDailyStatus.lightDrink,
  NomoDailyStatus.wantDrinkHard,
  NomoDailyStatus.nonAlcohol,
  NomoDailyStatus.liverRest,
  NomoDailyStatus.waitingInvite,
  NomoDailyStatus.hasPlans,
];

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isWhite,
    required this.canOpenAdmin,
    required this.onSettings,
    required this.onAdmin,
  });

  final bool isWhite;
  final bool canOpenAdmin;
  final VoidCallback onSettings;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    final headerColor = isWhite ? Colors.white : const Color(0xFF31363B);
    return NomoPageHeader(
      title: 'マイページ',
      titleColor: headerColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOpenAdmin) ...[
            _ProfileAdminButton(isWhite: isWhite, onTap: onAdmin),
            const SizedBox(width: 2),
          ],
          _ProfileSettingsButton(isWhite: isWhite, onTap: onSettings),
        ],
      ),
    );
  }
}

class _ProfileAdminButton extends StatelessWidget {
  const _ProfileAdminButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '管理画面',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: NomoGeneratedIcon(
              CupertinoIcons.lock_shield_fill,
              color: isWhite ? Colors.white : Colors.black,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsButton extends StatelessWidget {
  const _ProfileSettingsButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '設定',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: NomoGeneratedIcon(
              CupertinoIcons.gear_alt,
              color: isWhite ? Colors.white : Colors.black,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTopSheet extends StatelessWidget {
  const _ProfileTopSheet({required this.child, required this.isWhite});

  final Widget child;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        NomoPageHeader.horizontalPadding,
        NomoPageHeader.topPadding,
        NomoPageHeader.horizontalPadding,
        18,
      ),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFF06111D) : const Color(0xFFF4F2EE),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: child,
    );
  }
}

class _SimpleHero extends StatelessWidget {
  const _SimpleHero({
    required this.isWhite,
    required this.name,
    required this.avatar,
  });

  final bool isWhite;
  final String name;
  final NomoAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final joinedMonth = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFF06111D) : const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isWhite
                    ? const [Color(0xFF101B28), Color(0xFF06111D)]
                    : const [Color(0xFFF3F1EE), Color(0xFFE7E4E0)],
              ),
            ),
            child: SizedBox(
              height: 196,
              child: Center(
                child: NomoAvatarView(
                  avatar: avatar ?? NomoAvatar.defaultAvatar,
                  size: 194,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
            color: isWhite ? Colors.white : const Color(0xFF101D25),
            child: Center(
              child: Text(
                '$name ・ $joinedMonth 参加',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isWhite ? const Color(0xFF59636E) : _ProfileColors.sub,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReservationStrip extends StatelessWidget {
  const _ProfileReservationStrip({
    required this.userAvatar,
    required this.currentUserId,
    required this.reservations,
    required this.incomingInvites,
    required this.onAccept,
    required this.onReject,
  });

  final NomoAvatar? userAvatar;
  final String? currentUserId;
  final List<NomoDrinkInvite> reservations;
  final List<NomoDrinkInvite> incomingInvites;
  final ValueChanged<NomoDrinkInvite> onAccept;
  final ValueChanged<NomoDrinkInvite> onReject;

  @override
  Widget build(BuildContext context) {
    if (incomingInvites.isNotEmpty) {
      final invite = incomingInvites.first;
      return _IncomingInviteCard(
        invite: invite,
        currentUserId: currentUserId,
        onAccept: () => onAccept(invite),
        onReject: () => onReject(invite),
      );
    }
    if (reservations.isEmpty || currentUserId == null) {
      return const SizedBox.shrink();
    }

    final reservedFriends = reservations
        .map((invite) => invite.otherUser(currentUserId!))
        .toList(growable: false);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          _ReservedAvatar(avatar: userAvatar, label: '自分'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: _ProfileColors.lime,
              size: 22,
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < reservedFriends.length.clamp(0, 4); i++)
                  Positioned(
                    left: i * 34,
                    top: 10,
                    child: _ReservedAvatar(
                      avatar: reservedFriends[i].avatar,
                      label: reservedFriends[i].name,
                    ),
                  ),
              ],
            ),
          ),
          const Text(
            '予約成立',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingInviteCard extends StatelessWidget {
  const _IncomingInviteCard({
    required this.invite,
    required this.currentUserId,
    required this.onAccept,
    required this.onReject,
  });

  final NomoDrinkInvite invite;
  final String? currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final from = currentUserId == null
        ? invite.fromUser
        : invite.otherUser(currentUserId!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102336),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileColors.lime.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          _ReservedAvatar(avatar: from.avatar, label: from.name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${from.name}から飲み招待',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          _InviteResponseButton(
            label: 'OK',
            color: _ProfileColors.lime,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _InviteResponseButton(
            label: 'あとで',
            color: Colors.white.withValues(alpha: .10),
            textColor: Colors.white.withValues(alpha: .70),
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _ReservedAvatar extends StatelessWidget {
  const _ReservedAvatar({required this.avatar, required this.label});

  final NomoAvatar? avatar;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF12283A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: NomoAvatarView(avatar: avatar ?? NomoAvatar.defaultAvatar),
      ),
    ),
  );
}

class _InviteResponseButton extends StatelessWidget {
  const _InviteResponseButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = const Color(0xFF06111D),
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _ProfileMoodCta extends StatelessWidget {
  const _ProfileMoodCta({required this.status, required this.onTap});

  final NomoDailyStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final darkColor = Color.lerp(color, Colors.black, .22)!;
    final icon = status == NomoDailyStatus.unselected
        ? CupertinoIcons.smiley
        : _statusIcon(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .16)!, color],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .30),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: darkColor,
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _ProfileMoodCtaIcon(
              icon: icon,
              color: status == NomoDailyStatus.unselected
                  ? Colors.white
                  : color,
              muted: status == NomoDailyStatus.unselected,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                status == NomoDailyStatus.unselected
                    ? '今日の気分を設定する'
                    : status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -.2,
                ),
              ),
            ),
            NomoPopIcon(
              icon: CupertinoIcons.chevron_right,
              color: Colors.white,
              foregroundColor: Colors.white,
              size: 28,
              iconSize: 24,
              showBubble: false,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMoodCtaIcon extends StatelessWidget {
  const _ProfileMoodCtaIcon({
    required this.icon,
    required this.color,
    required this.muted,
  });

  final IconData icon;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: muted
          ? Colors.white.withValues(alpha: .14)
          : Colors.white.withValues(alpha: .90),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: Colors.white.withValues(alpha: muted ? .18 : .34),
      ),
      boxShadow: muted
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
    ),
    child: Center(
      child: NomoPopIcon(
        icon: icon,
        color: color,
        size: 29,
        iconSize: 27,
        showBubble: false,
      ),
    ),
  );
}

class _ProfileSocialSection extends StatelessWidget {
  const _ProfileSocialSection({
    required this.monthlyLogs,
    required this.friends,
    required this.streak,
  });

  final int monthlyLogs;
  final int friends;
  final int streak;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const _LeagueBadge(
            icon: Icons.local_bar_rounded,
            label: 'コース',
            color: _ProfileColors.lime,
            isWhite: false,
          ),
          const Spacer(),
          _FlatStat(value: '$monthlyLogs', label: '今月', isWhite: false),
          const SizedBox(width: 34),
          _FlatStat(value: '$friends', label: 'フレンズ', isWhite: false),
          const SizedBox(width: 34),
          _FlatStat(value: '$streak', label: '連続', isWhite: false),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const NomoGeneratedIcon(
                CupertinoIcons.person_badge_plus_fill,
                size: 20,
              ),
              label: const Text('友達を追加'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .22)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: .22)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
            child: const NomoGeneratedIcon(
              CupertinoIcons.qrcode_viewfinder,
              size: 25,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ProfileDashboard extends StatelessWidget {
  const _ProfileDashboard({
    required this.isWhite,
    required this.monthlyLogs,
    required this.friends,
    required this.streak,
  });

  final bool isWhite;
  final int monthlyLogs;
  final int friends;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                isWhite: isWhite,
                value: '$friends',
                label: '友達',
                icon: CupertinoIcons.person_2_fill,
                accent: _ProfileColors.lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                isWhite: isWhite,
                value: '$monthlyLogs',
                label: '今月',
                icon: CupertinoIcons.calendar,
                accent: const Color(0xFF49D7FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                isWhite: isWhite,
                value: '$streak',
                label: '連続',
                icon: CupertinoIcons.flame_fill,
                accent: const Color(0xFFFFB74A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.isWhite,
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final bool isWhite;
  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: isWhite
          ? const Color(0xFFF6F8FA)
          : Colors.white.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isWhite
            ? const Color(0xFFE4E9EF)
            : Colors.white.withValues(alpha: .08),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NomoPopIcon(
              icon: icon,
              color: accent,
              foregroundColor: accent,
              size: 23,
              iconSize: 20,
              showBubble: false,
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: isWhite ? const Color(0xFF101A24) : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          label,
          style: TextStyle(
            color: isWhite ? const Color(0xFF6F7A86) : _ProfileColors.sub,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _NomoProfilePreviewSheet extends StatefulWidget {
  const _NomoProfilePreviewSheet({
    required this.profile,
    required this.alreadyFriend,
    required this.requestState,
    required this.onRequest,
  });

  final _NomoSearchProfile profile;
  final bool alreadyFriend;
  final _FriendRequestState requestState;
  final Future<void> Function() onRequest;

  @override
  State<_NomoProfilePreviewSheet> createState() =>
      _NomoProfilePreviewSheetState();
}

class _NomoProfilePreviewSheetState extends State<_NomoProfilePreviewSheet> {
  bool _busy = false;

  bool get _canRequest =>
      !widget.alreadyFriend && widget.requestState == _FriendRequestState.none;

  String get _statusMessage {
    if (widget.alreadyFriend) {
      return 'すでにフレンズです。飲みログに一緒に残せます。';
    }
    return switch (widget.requestState) {
      _FriendRequestState.outgoing => 'フレンズ申請を送信済みです。相手の承認を待っています。',
      _FriendRequestState.incoming => 'この人からフレンズ申請が届いています。承認するとフレンズになります。',
      _FriendRequestState.none => 'フレンズ申請を送って、承認されたら飲みログや予約でつながれます。',
    };
  }

  String get _buttonLabel {
    if (widget.alreadyFriend) return 'フレンズです';
    return switch (widget.requestState) {
      _FriendRequestState.outgoing => '申請済み',
      _FriendRequestState.incoming => '申請が届いています',
      _FriendRequestState.none => 'フレンズ申請を送る',
    };
  }

  IconData get _statusIcon {
    if (widget.alreadyFriend) return CupertinoIcons.checkmark_seal_fill;
    return switch (widget.requestState) {
      _FriendRequestState.none => CupertinoIcons.paperplane_fill,
      _FriendRequestState.outgoing => CupertinoIcons.clock_fill,
      _FriendRequestState.incoming =>
        CupertinoIcons.person_crop_circle_badge_checkmark,
    };
  }

  Color get _statusColor {
    if (widget.alreadyFriend) return const Color(0xFF9AF21A);
    return switch (widget.requestState) {
      _FriendRequestState.none => const Color(0xFF22D7C5),
      _FriendRequestState.outgoing => const Color(0xFFFFD166),
      _FriendRequestState.incoming => const Color(0xFFC08BFF),
    };
  }

  Future<void> _sendRequest() async {
    if (_busy || !_canRequest) return;
    setState(() => _busy = true);
    try {
      await widget.onRequest();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF071622),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    shape: BoxShape.circle,
                  ),
                  child: const NomoGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 156,
                  height: 156,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF22D7C5), Color(0xFFFFD166)],
                    ),
                  ),
                ),
                Container(
                  width: 146,
                  height: 146,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: ClipOval(
                    child: NomoAvatarView(
                      avatar: widget.profile.avatar ?? NomoAvatar.defaultAvatar,
                      size: 126,
                    ),
                  ),
                ),
                const Positioned(
                  right: 16,
                  top: 18,
                  child: NomoGeneratedIcon(
                    CupertinoIcons.sparkles,
                    color: Color(0xFFFFD166),
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: .10)),
              ),
              child: Text(
                '@${widget.profile.userId}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .68),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Row(
                children: [
                  NomoPopIcon(
                    icon: _statusIcon,
                    color: _statusColor,
                    size: 38,
                    showBubble: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Nomo3DButton(
              label: _buttonLabel,
              icon: _canRequest ? CupertinoIcons.paperplane_fill : _statusIcon,
              onTap: _canRequest ? _sendRequest : null,
              isLoading: _busy,
              enabled: _canRequest,
              height: 54,
              radius: 22,
              color: _canRequest ? const Color(0xFF22D7C5) : _statusColor,
              shadowColor: _canRequest
                  ? const Color(0xFF109F91)
                  : _statusColor.withValues(alpha: .62),
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({
    required this.name,
    required this.handle,
    required this.avatar,
    required this.payload,
    required this.onClose,
    required this.onCopyUserId,
    required this.onSaveQr,
    required this.onScan,
    required this.onSearchUserId,
  });

  final String name;
  final String handle;
  final NomoAvatar? avatar;
  final String payload;
  final VoidCallback onClose;
  final VoidCallback onCopyUserId;
  final VoidCallback onSaveQr;
  final VoidCallback onScan;
  final Future<void> Function(String value) onSearchUserId;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const titleColor = Color(0xFF33373C);
    const subColor = Color(0xFF7D858E);
    const qrColor = Color(0xFF4B5056);
    const logoBg = Color(0xFFF4F2EE);
    const logoBorder = Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Color(0xFF4B5056),
                      size: 30,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: subColor,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 284,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: qrColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: qrColor,
                ),
              ),
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: logoBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: logoBorder, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: NomoAvatarView(
                    avatar: avatar ?? NomoAvatar.defaultAvatar,
                    size: 78,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'nomo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF22D7C5),
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QrActionButton(
                icon: CupertinoIcons.arrow_down_to_line_alt,
                label: 'QR保存',
                color: const Color(0xFF22D7C5),
                onTap: onSaveQr,
              ),
              _QrActionButton(
                icon: CupertinoIcons.qrcode_viewfinder,
                label: 'QR読取',
                color: const Color(0xFFB188FF),
                onTap: onScan,
              ),
              _QrActionButton(
                icon: CupertinoIcons.at,
                label: 'IDコピー',
                color: const Color(0xFFFF8A3D),
                onTap: onCopyUserId,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _QrIdSearchInput(onSearch: onSearchUserId),
        ],
      ),
    );
  }
}

class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color.lerp(color, Colors.white, .88)!],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3E4E6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 12,
                    top: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  NomoPopIcon(
                    icon: icon,
                    color: color,
                    size: 39,
                    showBubble: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9BA1A8),
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrIdSearchInput extends StatefulWidget {
  const _QrIdSearchInput({required this.onSearch});

  final Future<void> Function(String value) onSearch;

  @override
  State<_QrIdSearchInput> createState() => _QrIdSearchInputState();
}

class _QrIdSearchInputState extends State<_QrIdSearchInput> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSearch(_controller.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E4E8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          NomoGeneratedIcon(
            CupertinoIcons.at,
            color: Color(0xFF5F6872),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'ユーザーIDで検索',
                hintStyle: const TextStyle(
                  color: Color(0xFF8D97A2),
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF202832),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: _busy ? null : _submit,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF22D7C5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D7C5).withValues(alpha: .25),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _busy ? '検索中' : '検索',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isWhite,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      NomoPopIcon(icon: icon, color: color, size: 30, showBubble: false),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isWhite ? const Color(0xFF7B8590) : _ProfileColors.sub,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _FlatStat extends StatelessWidget {
  const _FlatStat({
    required this.value,
    required this.label,
    this.isWhite = false,
  });

  final String value;
  final String label;
  final bool isWhite;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isWhite ? const Color(0xFF27313B) : Colors.white,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _ProfileColors.sub,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.isWhite,
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
    required this.value,
  });

  final bool isWhite;
  final IconData icon;
  final Color color;
  final Color background;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          background.withValues(alpha: .20),
          background.withValues(alpha: isWhite ? .11 : .08),
          isWhite
              ? Colors.white.withValues(alpha: .78)
              : Colors.white.withValues(alpha: .035),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: background.withValues(alpha: .24)),
      boxShadow: [
        BoxShadow(
          color: background.withValues(alpha: .10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: NomoPopIcon(
            icon: icon,
            color: color,
            size: 24,
            showBubble: false,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isWhite ? const Color(0xFF737F8B) : _ProfileColors.sub,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isWhite
                      ? const Color(0xFF27313B)
                      : Colors.white.withValues(alpha: .92),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecentMemory extends StatelessWidget {
  const _RecentMemory({
    required this.logs,
    required this.onViewAll,
    required this.onOpenLatest,
  });
  final List<DrinkLog> logs;
  final VoidCallback onViewAll;
  final VoidCallback onOpenLatest;

  @override
  Widget build(BuildContext context) {
    final latest = logs.isEmpty ? null : logs.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '最近の思い出',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'すべて見る',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _ProfileColors.lime,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const NomoGeneratedIcon(
              CupertinoIcons.chevron_forward,
              color: _ProfileColors.lime,
              size: 17,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onOpenLatest,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _ProfileColors.panel.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _ProfileColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 122,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF102D55), Color(0xFF5B1F29)],
                    ),
                  ),
                  child: const NomoGeneratedIcon(
                    CupertinoIcons.photo_fill_on_rectangle_fill,
                    color: _ProfileColors.lime,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest?.place ?? 'まだ思い出がありません',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        latest == null
                            ? '飲みログを追加するとここに表示されます'
                            : latest.memo.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ProfileColors.sub,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Tag(
                            latest?.place.isNotEmpty == true
                                ? latest!.place
                                : '場所未設定',
                          ),
                          const _Tag('思い出'),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  latest == null ? '飲みログなし' : _relativeTime(latest.date),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _ProfileColors.sub,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const NomoGeneratedIcon(
                  CupertinoIcons.chevron_forward,
                  color: _ProfileColors.sub,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white.withValues(alpha: .72),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

Future<void> _showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  NomoUser? user,
) async {
  final controller = TextEditingController(text: user?.name ?? '');
  final userIdController = TextEditingController(text: user?.userId ?? '');
  final userController = ref.read(nomoUserProvider.notifier);
  final initialName = user?.name ?? '';
  final initialUserId = user?.userId ?? '';
  final initialAvatar = user?.avatar ?? NomoAvatar.defaultAvatar;
  var avatar = user?.avatar ?? NomoAvatar.defaultAvatar;
  var saving = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetBuildContext, setState) {
        Future<void> saveProfile() async {
          final name = controller.text.trim();
          final userId = userIdController.text.trim();
          if (name.isEmpty) {
            setState(() => error = '表示名を入力してください。');
            return;
          }
          if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(userId)) {
            setState(() => error = 'ユーザーIDは半角英数字と_で3〜24文字にしてください。');
            return;
          }
          setState(() {
            saving = true;
            error = null;
          });
          try {
            await userController.updateProfile(
              name: name,
              userId: userId,
              avatar: avatar,
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              _showSnack(context, 'プロフィールを更新しました。');
            }
          } catch (e) {
            if (!sheetContext.mounted) return;
            setState(() {
              saving = false;
              error = '保存できませんでした: $e';
            });
          }
        }

        bool hasChanges() =>
            controller.text.trim() != initialName.trim() ||
            userIdController.text.trim() != initialUserId.trim() ||
            avatar.encode() != initialAvatar.encode();

        Future<void> requestClose() async {
          if (saving) return;
          if (!hasChanges()) {
            Navigator.of(sheetContext).pop();
            return;
          }

          final action = await showCupertinoModalPopup<_UnsavedProfileAction>(
            context: sheetContext,
            builder: (context) => const _UnsavedProfileSheet(),
          );
          if (!sheetContext.mounted || action == null) return;
          switch (action) {
            case _UnsavedProfileAction.save:
              await saveProfile();
            case _UnsavedProfileAction.discard:
              Navigator.of(sheetContext).pop();
            case _UnsavedProfileAction.cancel:
              break;
          }
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) requestClose();
          },
          child: _SheetShell(
            title: 'プロフィール編集',
            onClose: requestClose,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetBuildContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _darkInputDecoration('表示名'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userIdController,
                    enabled: !saving,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _darkInputDecoration('ユーザーID').copyWith(
                      prefixText: '@',
                      prefixStyle: const TextStyle(
                        color: _ProfileColors.sub,
                        fontWeight: FontWeight.w900,
                      ),
                      helperText: '半角英数字と_で3〜24文字',
                      helperStyle: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AvatarEditCard(
                    avatar: avatar,
                    onTap: saving
                        ? null
                        : () async {
                            final result = await Navigator.of(context)
                                .push<NomoAvatar>(
                                  CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => AvatarBuilderScreen(
                                      initialAvatar: avatar,
                                    ),
                                  ),
                                );
                            if (result != null) {
                              setState(() => avatar = result);
                            }
                          },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: _ProfileColors.pink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SheetPrimaryButton(
                    label: '保存する',
                    busy: saving,
                    onTap: saveProfile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  controller.dispose();
  userIdController.dispose();
}

enum _UnsavedProfileAction { save, discard, cancel }

class _UnsavedProfileSheet extends StatelessWidget {
  const _UnsavedProfileSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF071622),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ProfileColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'プロフィールの変更を保存する？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '保存せずに閉じると、変更前のプロフィールに戻ります。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _UnsavedProfileButton(
            label: '保存して閉じる',
            icon: CupertinoIcons.check_mark_circled_solid,
            color: const Color(0xFF20D0B4),
            textColor: Colors.white,
            onTap: () => Navigator.of(context).pop(_UnsavedProfileAction.save),
          ),
          const SizedBox(height: 10),
          _UnsavedProfileButton(
            label: '変更を戻す',
            icon: CupertinoIcons.arrow_uturn_left,
            color: Colors.white.withValues(alpha: .07),
            textColor: Colors.white,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.discard),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.cancel),
            child: const Text(
              '編集を続ける',
              style: TextStyle(
                color: _ProfileColors.sub,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnsavedProfileButton extends StatelessWidget {
  const _UnsavedProfileButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: textColor, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _openAdminScreen(BuildContext context) async {
  await Navigator.of(context).push<void>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AdminScreen(),
    ),
  );
}

Future<void> _showSettingsSheet(BuildContext context, WidgetRef ref) async {
  final user = ref.read(nomoUserProvider);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(nomoThemeModeProvider);
        return _SheetShell(
          title: '設定',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsTile(
                icon: themeMode.isWhite
                    ? CupertinoIcons.moon_stars_fill
                    : CupertinoIcons.sun_max_fill,
                label: themeMode.isWhite ? 'ダークモードに切り替え' : 'ホワイトモードに切り替え',
                onTap: () {
                  ref
                      .read(nomoThemeModeProvider.notifier)
                      .setMode(
                        themeMode.isWhite
                            ? NomoThemeMode.dark
                            : NomoThemeMode.white,
                      );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.person_crop_circle,
                label: 'プロフィールを編集',
                onTap: () async {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (!context.mounted) return;
                  await _showEditProfileSheet(context, ref, user);
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.play_circle_fill,
                label: 'はじめてのデモを見る',
                onTap: () async {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push<void>(
                    CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const NomoDemoScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.square_arrow_right,
                label: 'ログアウト',
                destructive: true,
                onTap: () async {
                  try {
                    await ref.read(nomoUserProvider.notifier).signOut();
                  } catch (e) {
                    if (context.mounted) {
                      _showSnack(context, 'ログアウト処理を完了しました。再度ログインしてください。');
                    }
                  } finally {
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _showMemoriesSheet(BuildContext context, List<DrinkLog> logs) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SheetShell(
      title: 'すべての思い出',
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .55,
        child: logs.isEmpty
            ? const Center(
                child: Text(
                  'まだ思い出がありません。',
                  style: TextStyle(
                    color: _ProfileColors.sub,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _MemoryRow(
                  log: logs[index],
                  onTap: () => _showMemoryDetail(context, logs[index]),
                ),
              ),
      ),
    ),
  );
}

void _showMemoryDetail(BuildContext context, DrinkLog? log) {
  if (log == null) {
    _showSnack(context, 'まだ表示できる思い出がありません。');
    return;
  }
  final comment = log.memo.trim();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _SheetShell(
      title: log.place.isEmpty ? '思い出' : log.place,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemoryRow(log: log, onTap: () {}),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'コメント',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                color: _ProfileColors.sub,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child, this.onClose});
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : const Color(0xFF071622),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isWhite ? const Color(0xFFDDE4EA) : _ProfileColors.line,
          ),
          boxShadow: isWhite
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                  icon: NomoGeneratedIcon(CupertinoIcons.xmark, color: ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileStatusSheetContent extends StatefulWidget {
  const _ProfileStatusSheetContent({required this.selected, required this.ref});

  final NomoDailyStatus selected;
  final WidgetRef ref;

  @override
  State<_ProfileStatusSheetContent> createState() =>
      _ProfileStatusSheetContentState();
}

class _ProfileStatusSheetContentState
    extends State<_ProfileStatusSheetContent> {
  NomoDailyStatus? _savingStatus;

  Future<void> _selectStatus(NomoDailyStatus status) async {
    if (_savingStatus != null) return;
    final navigator = Navigator.of(context);
    setState(() => _savingStatus = status);
    try {
      await widget.ref
          .read(nomoUserProvider.notifier)
          .updateDailyStatus(status);
      if (navigator.mounted) navigator.pop();
      if (mounted) NomoToast.show(context, 'ステータスを「${status.label}」にしました。');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingStatus = null);
      NomoToast.show(context, '設定できませんでした: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final status in _selectableDailyStatuses) ...[
        _ProfileStatusOption(
          status: status,
          selected: status == widget.selected,
          saving: _savingStatus == status,
          disabled: _savingStatus != null,
          onTap: () => _selectStatus(status),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _ProfileStatusOption extends StatelessWidget {
  const _ProfileStatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
    this.saving = false,
    this.disabled = false,
  });

  final NomoDailyStatus status;
  final bool selected;
  final VoidCallback onTap;
  final bool saving;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .16)
              : (isWhite
                    ? const Color(0xFFF6F8FA)
                    : Colors.white.withValues(alpha: .055)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? color
                : (isWhite
                      ? const Color(0xFFDDE4EA)
                      : Colors.white.withValues(alpha: .10)),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: _statusIcon(status), color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isWhite
                          ? const Color(0xFF687481)
                          : _ProfileColors.sub,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (saving)
              CupertinoActivityIndicator(color: color)
            else
              NomoGeneratedIcon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: selected ? color : ink.withValues(alpha: .22),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarEditCard extends StatelessWidget {
  const _AvatarEditCard({required this.avatar, required this.onTap});

  final NomoAvatar avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF6F8FA)
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite ? const Color(0xFFDDE4EA) : _ProfileColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF223544), Color(0xFF101B28)],
                ),
              ),
              child: NomoAvatarView(avatar: avatar, size: 82),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自分のアバター',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '肌・髪型・服・表情をカスタム',
                    style: TextStyle(
                      color: isWhite
                          ? const Color(0xFF687481)
                          : Colors.white.withValues(alpha: .58),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const NomoGeneratedIcon(
              CupertinoIcons.chevron_forward,
              color: _ProfileColors.lime,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF6F8FA)
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isWhite ? const Color(0xFFDDE4EA) : _ProfileColors.line,
          ),
        ),
        child: Row(
          children: [
            NomoGeneratedIcon(
              icon,
              color: destructive ? _ProfileColors.pink : ink,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: destructive ? _ProfileColors.pink : ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const NomoGeneratedIcon(
              CupertinoIcons.chevron_forward,
              color: _ProfileColors.sub,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF12C9A4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: .16),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF079078),
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: busy
          ? const CupertinoActivityIndicator(color: Colors.white)
          : Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
    ),
  );
}

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({required this.log, required this.onTap});
  final DrinkLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfileColors.line),
      ),
      child: Row(
        children: [
          const NomoGeneratedIcon(
            CupertinoIcons.photo_fill,
            color: _ProfileColors.lime,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.place.isEmpty ? '場所未設定' : log.place,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.friendNames.isEmpty
                      ? _dateLabel(log.date)
                      : log.friendNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileColors.sub,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _relativeTime(log.date),
            style: const TextStyle(
              color: _ProfileColors.sub,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _darkInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: Colors.white.withValues(alpha: .45),
    fontWeight: FontWeight.w800,
  ),
  filled: true,
  fillColor: Colors.white.withValues(alpha: .06),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _ProfileColors.line),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _ProfileColors.line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _ProfileColors.lime),
  ),
);

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) {
    return '今';
  }
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  return _dateLabel(date);
}

String _dateLabel(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

void _showSnack(BuildContext context, String message) {
  NomoToast.show(context, message);
}
