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
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../friends/presentation/add_nomi_tomo_screen.dart';
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
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final friendsCount = friendsAsync.asData?.value.length ?? 0;
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
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
                        onSettings: () => _showSettingsSheet(context, ref),
                      ),
                      const SizedBox(height: 14),
                      _SimpleHero(
                        isWhite: isWhite,
                        handle: user == null ? '@NOMO_USER' : '@${user.userId}',
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
                            child: _ProfileMoodCta(
                              status:
                                  user?.dailyStatus ??
                                  NomoDailyStatus.unselected,
                              onTap: () =>
                                  _showProfileStatusSheet(context, ref),
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
                              onAddFriend: () =>
                                  showMyQrDialog(context, user, ref),
                              onShowQr: () =>
                                  showMyQrDialog(context, user, ref),
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

  Future<void> copyLink(BuildContext dialogContext) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!dialogContext.mounted) return;
    NomoToast.show(dialogContext, 'リンクをコピーしました');
  }

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

  void scanQr(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const AddNomiTomoScreen(initialScan: true),
      ),
    );
  }

  Future<void> searchAndAddByUserId(
    BuildContext dialogContext,
    String rawUserId,
  ) async {
    final query = rawUserId.trim().replaceFirst(RegExp(r'^@'), '');
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
          .select('id, display_name, user_id')
          .eq('user_id', query)
          .maybeSingle();
      if (!dialogContext.mounted) return;
      if (row == null) {
        NomoToast.show(dialogContext, '@$query は見つかりませんでした');
        return;
      }

      final profile = Map<String, dynamic>.from(row);
      final friendId = profile['id'] as String;
      if (friendId == currentUser.id) {
        NomoToast.show(dialogContext, '自分自身は追加できません');
        return;
      }

      final ids = [currentUser.id, friendId]..sort();
      await Supabase.instance.client.from('friendships').upsert({
        'user_a_id': ids[0],
        'user_b_id': ids[1],
      }, onConflict: 'user_a_id,user_b_id');
      ref.invalidate(friendsProvider);
      if (!dialogContext.mounted) return;
      final displayName = (profile['display_name'] as String?) ?? '@$query';
      NomoToast.show(dialogContext, '$displayNameをフレンズに追加しました');
    } catch (e) {
      if (!dialogContext.mounted) return;
      NomoToast.show(dialogContext, '検索できませんでした: $e');
    }
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
          onCopy: () => copyLink(dialogContext),
          onCopyUserId: () => copyUserId(dialogContext),
          onSaveQr: () => saveQrImage(dialogContext),
          onScan: () => scanQr(dialogContext),
          onSearchUserId: (value) => searchAndAddByUserId(dialogContext, value),
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
  static const blue = Color(0xFF16A8FF);
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
  const _PageHeader({required this.isWhite, required this.onSettings});
  final bool isWhite;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final headerColor = isWhite ? Colors.white : const Color(0xFF31363B);
    return NomoPageHeader(
      title: 'マイページ',
      titleColor: headerColor,
      trailing: _ProfileSettingsButton(isWhite: isWhite, onTap: onSettings),
    );
  }
}

class _ProfileSettingsButton extends StatelessWidget {
  const _ProfileSettingsButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buttonColor = isWhite
        ? Colors.white.withValues(alpha: .09)
        : const Color(0xFFF7F9FB);
    final borderColor = isWhite
        ? Colors.white.withValues(alpha: .14)
        : const Color(0xFFD8DEE6);
    return Semantics(
      button: true,
      label: '設定',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: _ProfileColors.lime.withValues(
                  alpha: isWhite ? .16 : .10,
                ),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Center(
            child: NomoGeneratedIcon(
              CupertinoIcons.gear_alt,
              color: _ProfileColors.lime,
              size: 34,
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
    required this.handle,
    required this.avatar,
  });

  final bool isWhite;
  final String handle;
  final NomoAvatar? avatar;

  @override
  Widget build(BuildContext context) {
    final joinedYear = DateTime.now().year;
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$handle ・ $joinedYear年に参加',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isWhite
                          ? const Color(0xFF59636E)
                          : _ProfileColors.sub,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          _FlatStat(value: '$monthlyLogs', label: '今月'),
          const SizedBox(width: 34),
          _FlatStat(value: '$friends', label: 'フレンズ'),
          const SizedBox(width: 34),
          _FlatStat(value: '$streak', label: '連続'),
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
    required this.onAddFriend,
    required this.onShowQr,
  });

  final bool isWhite;
  final int monthlyLogs;
  final int friends;
  final int streak;
  final VoidCallback onAddFriend;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isWhite
                ? Colors.white.withValues(alpha: .78)
                : Colors.white.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isWhite
                  ? const Color(0xFFE1E6EC)
                  : Colors.white.withValues(alpha: .08),
            ),
            boxShadow: isWhite
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LeagueBadge(
                    icon: CupertinoIcons.person_2_fill,
                    label: 'フレンズ',
                    color: _ProfileColors.lime,
                    isWhite: isWhite,
                  ),
                  const Spacer(),
                  _FlatStat(value: '$friends', label: '友達', isWhite: isWhite),
                  const SizedBox(width: 24),
                  _FlatStat(
                    value: '$monthlyLogs',
                    label: '今月',
                    isWhite: isWhite,
                  ),
                  const SizedBox(width: 24),
                  _FlatStat(value: '$streak', label: '連続', isWhite: isWhite),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DashboardButton(
                      isWhite: isWhite,
                      icon: CupertinoIcons.person_badge_plus_fill,
                      label: '友達を追加',
                      onTap: onAddFriend,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconDashboardButton(
                    isWhite: isWhite,
                    icon: CupertinoIcons.qrcode_viewfinder,
                    onTap: onShowQr,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton({
    required this.isWhite,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isWhite;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF7F9FB)
            : Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFD8DEE6)
              : Colors.white.withValues(alpha: .16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoPopIcon(
            icon: icon,
            color: _ProfileColors.lime,
            size: 30,
            showBubble: false,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isWhite ? const Color(0xFF27313B) : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _IconDashboardButton extends StatelessWidget {
  const _IconDashboardButton({
    required this.isWhite,
    required this.icon,
    required this.onTap,
  });

  final bool isWhite;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 56,
      height: 46,
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF7F9FB)
            : Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFD8DEE6)
              : Colors.white.withValues(alpha: .16),
        ),
      ),
      child: Center(
        child: NomoPopIcon(
          icon: icon,
          color: _ProfileColors.blue,
          size: 34,
          showBubble: false,
        ),
      ),
    ),
  );
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({
    required this.name,
    required this.handle,
    required this.avatar,
    required this.payload,
    required this.onClose,
    required this.onCopy,
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
  final VoidCallback onCopy;
  final VoidCallback onCopyUserId;
  final VoidCallback onSaveQr;
  final VoidCallback onScan;
  final Future<void> Function(String value) onSearchUserId;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final cardColor = isWhite ? Colors.white : const Color(0xFF08131A);
    final titleColor = isWhite ? const Color(0xFF33373C) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7D858E)
        : const Color(0xFF9AA7B7);
    final qrColor = isWhite ? const Color(0xFF4B5056) : const Color(0xFFEAF1F6);
    final logoBg = isWhite ? const Color(0xFFF4F2EE) : const Color(0xFF14212B);
    final logoBorder = isWhite ? Colors.white : const Color(0xFF243240);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isWhite
              ? Colors.transparent
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .28 : .46),
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
                icon: CupertinoIcons.link,
                label: 'リンクコピー',
                color: const Color(0xFF4A7DFF),
                onTap: onCopy,
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
    final isWhite = Theme.of(context).brightness == Brightness.light;
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
                  colors: isWhite
                      ? [Colors.white, Color.lerp(color, Colors.white, .88)!]
                      : [const Color(0xFF172637), const Color(0xFF101B28)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWhite
                      ? const Color(0xFFE3E4E6)
                      : Colors.white.withValues(alpha: .10),
                  width: 2,
                ),
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
                color: isWhite
                    ? const Color(0xFF9BA1A8)
                    : const Color(0xFF9AA7B7),
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
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFFF5F7F8) : const Color(0xFF14212B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE1E4E7)
              : Colors.white.withValues(alpha: .10),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          NomoGeneratedIcon(
            CupertinoIcons.at,
            color: isWhite ? const Color(0xFF4B5056) : Colors.white,
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
                hintStyle: TextStyle(
                  color: isWhite
                      ? const Color(0xFF9BA1A8)
                      : const Color(0xFF9AA7B7),
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: TextStyle(
                color: isWhite ? const Color(0xFF33373C) : Colors.white,
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
                            : (latest.memo.isNotEmpty
                                  ? latest.memo
                                  : latest.friendNames),
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
                                : '未記録',
                          ),
                          const _Tag('思い出'),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  latest == null ? '未記録' : _relativeTime(latest.date),
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
  var avatar = user?.avatar ?? NomoAvatar.defaultAvatar;
  var saving = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => _SheetShell(
        title: 'プロフィール編集',
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                                builder: (_) =>
                                    AvatarBuilderScreen(initialAvatar: avatar),
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
                onTap: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => error = '表示名を入力してください。');
                    return;
                  }
                  setState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await ref
                        .read(nomoUserProvider.notifier)
                        .updateProfile(name: name, avatar: avatar);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                    if (context.mounted) {
                      _showSnack(context, 'プロフィールを更新しました。');
                    }
                  } catch (e) {
                    setState(() {
                      saving = false;
                      error = '保存できませんでした: $e';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  controller.dispose();
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
                label: '名前・アバターを編集',
                onTap: () async {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (!context.mounted) return;
                  await _showEditProfileSheet(context, ref, user);
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.arrow_clockwise,
                label: 'プロフィールを再読み込み',
                onTap: () async {
                  try {
                    await ref
                        .read(nomoUserProvider.notifier)
                        .loadFromSupabaseProfile();
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                    if (context.mounted) {
                      _showSnack(context, 'プロフィールを再読み込みしました。');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showSnack(context, '再読み込みできませんでした: $e');
                    }
                  }
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
          const SizedBox(height: 16),
          Text(
            'メモ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            log.memo.isEmpty ? 'メモはありません。' : log.memo,
            style: const TextStyle(
              color: _ProfileColors.sub,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

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
                  onPressed: () => Navigator.of(context).pop(),
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
