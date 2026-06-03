import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend_request_status.dart';
import '../../../core/models/ohey_invite.dart';
import '../../../core/models/ohey_visibility.dart';
import '../../../core/models/wish_item.dart';
import '../../../core/models/yurubo.dart';
import '../../../core/models/ohey_gender.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/models/ohey_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_action_tile.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_daily_status_3d_option.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_empty_state.dart';
import '../../../core/widgets/ohey_page_header.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../../admin/application/admin_controller.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../friends/application/invite_controller.dart';
import '../../friends/data/friend_repository.dart';
import '../../friends/presentation/friend_add_sheet.dart';
import '../../memories/application/memory_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../yurubos/application/yurubo_controller.dart';
import '../../yurubos/data/yurubo_repository.dart';
import '../../wish_items/application/wish_item_controller.dart';
import '../../wish_items/data/wish_item_repository.dart';
import '../../onboarding/presentation/create_user_dialog.dart';
import '../data/user_safety_repository.dart';
import 'avatar_builder_screen.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_profile_hero_header.dart';

part 'profile_header_widgets.dart';
part 'profile_memory_widgets.dart';
part 'profile_status_sheet.dart';
part 'profile_settings_sheet.dart';
part 'profile_form_helpers.dart';
part 'profile_wish_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.onOpenYurubo});

  final VoidCallback? onOpenYurubo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(oheyUserProvider);
    final currentAuthUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final currentAuthUserId = currentAuthUser?.id;
    final reservationsAsync = ref.watch(todayReservationsProvider);
    final incomingInvitesAsync = ref.watch(incomingInvitesProvider);
    final reservations =
        reservationsAsync.asData?.value ?? const <OheyInvite>[];
    final incomingInvites =
        incomingInvitesAsync.asData?.value ?? const <OheyInvite>[];
    final wishItemsAsync = ref.watch(wishItemControllerProvider);
    final wishItems = wishItemsAsync.asData?.value ?? const <WishItem>[];
    final yurubosAsync = ref.watch(yuruboControllerProvider);
    final today = _dateOnly(DateTime.now());
    final joinedYurubos = (yurubosAsync.asData?.value ?? const <Yurubo>[])
        .where((yurubo) => yurubo.reactedByMe && yurubo.startsAt != null)
        .where((yurubo) => _dateOnly(yurubo.startsAt!) == today)
        .toList(growable: false);
    final friends =
        ref.watch(friendsProvider).asData?.value ?? const <OheyFriend>[];
    const headerIsWhite = true;
    const bodyIsWhite = false;
    final hasAdminEmail = OheyAvatar.isAdminEmail(currentAuthUser?.email);
    final hasAdminAccess = ref
        .watch(adminAccessProvider)
        .maybeWhen(data: (allowed) => allowed, orElse: () => false);
    final canOpenAdmin = hasAdminEmail || hasAdminAccess;
    const bodyBackground = AppColors.darkBackgroundBottom;
    final headerBackgroundHeight = MediaQuery.paddingOf(context).top + 318;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.transparent,
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
              child: OheyProfileHeaderBackdrop(
                avatar: user?.avatar ?? OheyAvatar.defaultAvatar,
              ),
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
                        const SizedBox(height: 6),
                        _SimpleHero(
                          isWhite: headerIsWhite,
                          name: user?.name ?? 'ユーザー名',
                          avatar: user?.avatar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                      child: ColoredBox(
                        color: bodyBackground,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (incomingInvites.isNotEmpty)
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
                                    onAccept: (invite) => _respondInvite(
                                      context,
                                      ref,
                                      invite,
                                      accept: true,
                                    ),
                                    onReject: (invite) => _respondInvite(
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
                                friendsCount: friends.length,
                                joinedYurubos: joinedYurubos,
                                isYuruboLoading: yurubosAsync.isLoading,
                                wishItems: wishItems,
                                isWishLoading: wishItemsAsync.isLoading,
                                onCreateYuruboTap: () =>
                                    _showProfileCreateYuruboSheet(context, ref),
                                onOpenYuruboTap: onOpenYurubo,
                                onOpenWishListTap: () =>
                                    _openProfileWishListScreen(context),
                                onAddFriendsTap: () =>
                                    showFriendAddSheet(context, ref),
                                onChangeStatusTap: () =>
                                    _showProfileStatusSheet(context, ref, user),
                              ),
                            ),
                          ],
                        ),
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

class _ProfileColors {
  const _ProfileColors._();
  static const line = AppColors.c1EFFFFFF;
  static const sub = AppColors.cFF8F9BAB;
  static const lime = AppColors.cFF9AF21A;
  static const pink = AppColors.cFFFF5EA8;
}

Future<void> _respondInvite(
  BuildContext context,
  WidgetRef ref,
  OheyInvite invite, {
  required bool accept,
}) async {
  try {
    final controller = ref.read(inviteControllerProvider);
    final status = accept
        ? OheyInviteStatus.accepted
        : OheyInviteStatus.rejected;
    if (status.isAccepted) {
      await controller.accept(invite.id);
    } else {
      await controller.reject(invite.id);
    }
    if (!context.mounted) return;
    OheyToast.show(context, status.responseToastMessage);
  } catch (error) {
    if (!context.mounted) return;
    OheyToast.show(context, '返信できなかったよ。あとでもう一度試してね');
  }
}

Future<void> _showProfileStatusSheet(
  BuildContext context,
  WidgetRef ref,
  OheyUser? user,
) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => OheyBottomSheetShell(
      title: 'この日の気分',
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      maxHeightFactor: .86,
      child: _ProfileStatusSheetContent(
        selected: user?.dailyStatus ?? OheyDailyStatus.unselected,
        ref: ref,
      ),
    ),
  );
}

Future<void> _showProfileCreateWishItemSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _ProfileCreateWishItemSheet(ref: ref),
  );
}

class _ProfileCreateWishItemSheet extends StatefulWidget {
  const _ProfileCreateWishItemSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_ProfileCreateWishItemSheet> createState() =>
      _ProfileCreateWishItemSheetState();
}

class _ProfileCreateWishItemSheetState
    extends State<_ProfileCreateWishItemSheet> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  String _visibility = OheyVisibility.private.key;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(wishItemControllerProvider.notifier)
          .createWishItem(
            WishItemCreateDraft(
              title: title,
              placeText: _placeController.text.trim(),
              visibility: _visibility,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(context, 'やりたいことを追加しました', icon: CupertinoIcons.sparkles);
    } catch (_) {
      if (mounted) OheyToast.show(context, '追加できなかったよ。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.light
        ? AppColors.cFF17212B
        : AppColors.white;
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'やりたいことリストに追加',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileYuruboInput(
            controller: _titleController,
            placeholder: '焼肉行きたい / サウナ開拓したい',
          ),
          const SizedBox(height: 10),
          _ProfileYuruboInput(
            controller: _placeController,
            placeholder: '場所・店名（任意）',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProfileYuruboChoice(
                  label: '自分だけ',
                  selected: _visibility == OheyVisibility.private.key,
                  onTap: () =>
                      setState(() => _visibility = OheyVisibility.private.key),
                  selectedColor: AppColors.cFF20B9FF,
                  selectedBottomColor: AppColors.cFF0B78B7,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileYuruboChoice(
                  label: '友達に公開',
                  selected: _visibility == OheyVisibility.friends.key,
                  onTap: () =>
                      setState(() => _visibility = OheyVisibility.friends.key),
                  selectedColor: AppColors.cFF20B9FF,
                  selectedBottomColor: AppColors.cFF0B78B7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Ohey3DButton(
            label: _saving ? '追加中...' : '追加する',
            onTap: _saving ? null : _submit,
            height: 50,
            radius: 22,
            color: AppColors.cFF20B9FF,
            foregroundColor: AppColors.cFF06111D,
            shadowColor: AppColors.cFF0B78B7,
          ),
        ],
      ),
    );
  }
}

Future<void> _showProfileCreateYuruboSheet(
  BuildContext context,
  WidgetRef ref, {
  WishItem? wish,
}) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _ProfileCreateYuruboSheet(ref: ref, initialWish: wish),
  );
}

class _ProfileCreateYuruboSheet extends StatefulWidget {
  const _ProfileCreateYuruboSheet({required this.ref, this.initialWish});

  final WidgetRef ref;
  final WishItem? initialWish;

  @override
  State<_ProfileCreateYuruboSheet> createState() =>
      _ProfileCreateYuruboSheetState();
}

class _ProfileCreateYuruboSheetState extends State<_ProfileCreateYuruboSheet> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _timeController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _groupsFuture;
  String _visibility = OheyVisibility.friends.key;
  String? _groupId;
  String? _wishItemId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialWish = widget.initialWish;
    if (initialWish != null) {
      _titleController.text = initialWish.title;
      _placeController.text = initialWish.placeText;
      _wishItemId = initialWish.id;
    }
    _groupsFuture = widget.ref
        .read(friendRepositoryProvider)
        .fetchFriendGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    if (_visibility.requiresVisibilityGroup &&
        (_groupId == null || _groupId!.isEmpty)) {
      OheyToast.show(context, 'グループを選んでね');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(yuruboControllerProvider.notifier)
          .createYurubo(
            YuruboCreateDraft(
              title: title,
              placeText: _profileYuruboPlaceOrDefault(_placeController.text),
              timeLabel: _profileYuruboTimeOrDefault(_timeController.text),
              visibility: _visibility,
              groupId: _visibility.requiresVisibilityGroup ? _groupId : null,
              wishItemId: _wishItemId,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(context, 'ゆるぼしました', icon: CupertinoIcons.plus_bubble_fill);
    } catch (_) {
      if (mounted) OheyToast.show(context, 'ゆるぼできなかったよ。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF17212B : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .62);
    final wishItems =
        widget.ref.watch(wishItemControllerProvider).asData?.value ??
        const <WishItem>[];
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_visibility.requiresVisibilityGroup &&
              _groupId == null &&
              groups.isNotEmpty) {
            _groupId =
                (groups.first['row_id'] ?? groups.first['id']) as String?;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '誰に募集する？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ProfileYuruboChoice(
                      label: '全フレンズ',
                      selected: _visibility == OheyVisibility.friends.key,
                      onTap: () => setState(
                        () => _visibility = OheyVisibility.friends.key,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileYuruboChoice(
                      label: 'グループ',
                      selected: _visibility == OheyVisibility.group.key,
                      onTap: () => setState(
                        () => _visibility = OheyVisibility.group.key,
                      ),
                    ),
                  ),
                ],
              ),
              if (_visibility.requiresVisibilityGroup) ...[
                const SizedBox(height: 12),
                if (groups.isEmpty)
                  Text(
                    '先にフレンズ画面でグループを作ってね',
                    style: TextStyle(color: sub, fontWeight: FontWeight.w800),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in groups)
                        _ProfileYuruboGroupChip(
                          label: (group['name'] as String?) ?? 'グループ',
                          selected:
                              _groupId ==
                              ((group['row_id'] ?? group['id']) as String?),
                          onTap: () => setState(
                            () => _groupId =
                                (group['row_id'] ?? group['id']) as String?,
                          ),
                        ),
                    ],
                  ),
              ],
              const SizedBox(height: 14),
              if (wishItems.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'やりたいことリストから選ぶ',
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: wishItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final wish = wishItems[index];
                      final selected = _wishItemId == wish.id;
                      return _ProfileYuruboGroupChip(
                        label: wish.title,
                        selected: selected,
                        onTap: () => setState(() {
                          _wishItemId = wish.id;
                          _titleController.text = wish.title;
                          _placeController.text = wish.placeText;
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _ProfileYuruboInput(
                controller: _titleController,
                placeholder: '今日夜、ご飯いける人いる？',
              ),
              const SizedBox(height: 10),
              _ProfileYuruboInput(
                controller: _placeController,
                placeholder: '場所（未入力ならどこでも）',
              ),
              const SizedBox(height: 10),
              _ProfileYuruboInput(
                controller: _timeController,
                placeholder: 'いつ（未入力ならいつでも）',
              ),
              const SizedBox(height: 16),
              Ohey3DButton(
                label: _saving ? '送信中...' : 'ゆるぼする',
                onTap: _saving ? null : _submit,
                height: 50,
                radius: 22,
                color: AppColors.cFFC08BFF,
                foregroundColor: AppColors.cFF101820,
                shadowColor: AppColors.cFF7F51C9,
              ),
            ],
          );
        },
      ),
    );
  }
}

String _profileYuruboPlaceOrDefault(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'どこでも' : trimmed;
}

String _profileYuruboTimeOrDefault(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'いつでも' : trimmed;
}

class _ProfileYuruboChoice extends StatelessWidget {
  const _ProfileYuruboChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.cFFC08BFF,
    this.selectedBottomColor = AppColors.cFF7F51C9,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedBottomColor;
  @override
  Widget build(BuildContext context) => Ohey3DButtonSurface(
    onTap: onTap,
    height: 46,
    radius: 20,
    color: selected ? selectedColor : AppColors.cFF263348,
    bottomColor: selected ? selectedBottomColor : AppColors.cFF151D2A,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.cFF101820 : AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class _ProfileYuruboGroupChip extends StatelessWidget {
  const _ProfileYuruboGroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (selected ? AppColors.cFFC08BFF : AppColors.white).withValues(
          alpha: selected ? .26 : .08,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.cFFC08BFF.withValues(alpha: selected ? .7 : .25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _ProfileYuruboInput extends StatelessWidget {
  const _ProfileYuruboInput({
    required this.controller,
    required this.placeholder,
  });
  final TextEditingController controller;
  final String placeholder;
  @override
  Widget build(BuildContext context) => CupertinoTextField(
    controller: controller,
    placeholder: placeholder,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.white.withValues(alpha: .13)),
    ),
    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
    placeholderStyle: TextStyle(
      color: AppColors.white.withValues(alpha: .42),
      fontWeight: FontWeight.w700,
    ),
  );
}
