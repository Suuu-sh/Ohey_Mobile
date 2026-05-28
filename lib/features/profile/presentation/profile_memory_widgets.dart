part of 'profile_screen.dart';

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
  final gender = user?.gender ?? NomoGender.unspecified;
  var saving = false;
  var closing = false;
  String? error;

  await showNomoBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetBuildContext, setState) {
        final sheetIsWhite =
            Theme.of(sheetBuildContext).brightness == Brightness.light;
        final inputInk = sheetIsWhite ? const Color(0xFF101820) : Colors.white;
        final inputSub = sheetIsWhite
            ? const Color(0xFF8B96A3)
            : Colors.white.withValues(alpha: .45);

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
              error = '保存できなかったよ。あとでもう一度試してね';
            });
          }
        }

        bool hasChanges() =>
            controller.text.trim() != initialName.trim() ||
            userIdController.text.trim() != initialUserId.trim() ||
            avatar.encode() != initialAvatar.encode();

        Future<void> closeSheet() async {
          if (closing || !sheetContext.mounted) return;
          closing = true;
          FocusManager.instance.primaryFocus?.unfocus();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
        }

        Future<void> requestClose() async {
          if (saving || closing) return;
          FocusManager.instance.primaryFocus?.unfocus();
          if (!hasChanges()) {
            await closeSheet();
            return;
          }

          final action = await showCupertinoModalPopup<_UnsavedProfileAction>(
            context: sheetContext,
            useRootNavigator: true,
            builder: (context) => const _UnsavedProfileSheet(),
          );
          if (!sheetContext.mounted || action == null) return;
          switch (action) {
            case _UnsavedProfileAction.save:
              await saveProfile();
            case _UnsavedProfileAction.discard:
              await closeSheet();
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
                    style: TextStyle(
                      color: inputInk,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _profileInputDecoration(
                      '表示名',
                      isWhite: sheetIsWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userIdController,
                    enabled: !saving,
                    style: TextStyle(
                      color: inputInk,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration:
                        _profileInputDecoration(
                          'ユーザーID',
                          isWhite: sheetIsWhite,
                        ).copyWith(
                          prefixText: '@',
                          prefixStyle: TextStyle(
                            color: inputSub,
                            fontWeight: FontWeight.w900,
                          ),
                          helperText: '半角英数字と_で3〜24文字',
                          helperStyle: TextStyle(
                            color: inputSub,
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
                            FocusManager.instance.primaryFocus?.unfocus();
                            final result =
                                await Navigator.of(
                                  sheetBuildContext,
                                  rootNavigator: true,
                                ).push<NomoAvatar>(
                                  CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => AvatarBuilderScreen(
                                      initialAvatar: avatar,
                                      gender: gender,
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
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
    userIdController.dispose();
  });
}

enum _UnsavedProfileAction { save, discard, cancel }

class _UnsavedProfileSheet extends StatelessWidget {
  const _UnsavedProfileSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .34),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.person_crop_circle_fill,
                color: Color(0xFF20D0B4),
                size: 48,
                iconSize: 25,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '変更を保存しますか？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '閉じる前に、変更を残しておけるよ。',
                      style: TextStyle(
                        color: _ProfileColors.sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                const NomoGeneratedIcon(
                  CupertinoIcons.info_circle_fill,
                  color: Color(0xFF20D0B4),
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '保存しない場合は、変更前のプロフィールに戻ります。',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Nomo3DButton(
            label: '保存して閉じる',
            icon: CupertinoIcons.check_mark_circled_solid,
            color: const Color(0xFF20D0B4),
            foregroundColor: Colors.white,
            shadowColor: const Color(0xFF0C8B7A),
            height: 52,
            radius: 22,
            fontSize: 15,
            onTap: () => Navigator.of(context).pop(_UnsavedProfileAction.save),
          ),
          const SizedBox(height: 10),
          Nomo3DButton(
            label: '変更を戻す',
            icon: CupertinoIcons.arrow_uturn_left,
            color: Colors.white.withValues(alpha: .07),
            foregroundColor: Colors.white,
            shadowColor: const Color(0xFF315A62).withValues(alpha: .70),
            height: 48,
            radius: 21,
            fontSize: 14,
            useGradient: false,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.discard),
          ),
          const SizedBox(height: 10),
          Nomo3DButton.secondary(
            label: '編集を続ける',
            icon: CupertinoIcons.pencil,
            color: Colors.white.withValues(alpha: .055),
            foregroundColor: _ProfileColors.sub,
            shadowColor: const Color(0xFF4A3D68).withValues(alpha: .66),
            height: 46,
            radius: 20,
            fontSize: 14,
            useGradient: false,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.cancel),
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
  final rootContext = context;
  final user = ref.read(nomoUserProvider);
  await showNomoBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final currentAuthUserId = ref
            .watch(supabaseClientProvider)
            .auth
            .currentUser
            ?.id;
        final logs =
            ref.watch(drinkLogControllerProvider).asData?.value ??
            const <DrinkLog>[];
        final photoLogs = _photoArchiveLogs(logs, currentAuthUserId);
        return _SettingsSheetShell(
          user: user,
          onClose: () => Navigator.of(sheetContext).pop(),
          children: [
            _SettingsTile(
              icon: CupertinoIcons.person_crop_circle,
              label: 'プロフィール編集',
              subtitle: '名前・ID・アバターを変更',
              accent: const Color(0xFF21D6C4),
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                // Wait until the settings sheet has finished popping. Opening
                // another bottom sheet in the same tap while the first route is
                // still closing can drop the tap on iOS.
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!context.mounted) return;
                await _showEditProfileSheet(
                  context,
                  ref,
                  ref.read(nomoUserProvider),
                );
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.photo_fill_on_rectangle_fill,
              label: 'フォトアーカイブ',
              subtitle: photoLogs.isEmpty
                  ? '写真付きの思い出を見返す'
                  : '${photoLogs.length}件の思い出を見返す',
              accent: const Color(0xFFFF7AB8),
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await Navigator.of(rootContext).push<void>(
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => PhotoArchiveScreen(logs: photoLogs),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.play_circle_fill,
              label: 'はじめてのデモ',
              subtitle: 'Nomoの使い方をもう一度見る',
              accent: const Color(0xFF9AF21A),
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
              icon: CupertinoIcons.person_2_fill,
              label: '申請管理',
              subtitle: '送信中・受信中のフレンズ申請',
              accent: const Color(0xFFB7F15B),
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _showFriendRequestManagementSheet(rootContext);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.shield_lefthalf_fill,
              label: 'ブロック・ミュート管理',
              subtitle: '解除したい相手を確認',
              accent: const Color(0xFF65D6FF),
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _showSafetyCenterSheet(rootContext);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.delete_solid,
              label: 'アカウント削除',
              subtitle: '退会してデータを削除します',
              accent: const Color(0xFFFF5C7A),
              destructive: true,
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _confirmDeleteAccount(rootContext, ref);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.square_arrow_right,
              label: 'ログアウト',
              subtitle: 'この端末からログアウトします',
              accent: _ProfileColors.pink,
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
        );
      },
    ),
  );
}

Future<void> _showFriendRequestManagementSheet(BuildContext context) {
  return showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (_) => const _FriendRequestManagementSheet(),
  );
}

class _FriendRequestManagementSheet extends ConsumerStatefulWidget {
  const _FriendRequestManagementSheet();

  @override
  ConsumerState<_FriendRequestManagementSheet> createState() =>
      _FriendRequestManagementSheetState();
}

class _FriendRequestManagementSheetState
    extends ConsumerState<_FriendRequestManagementSheet> {
  final Set<String> _busyRequestIds = <String>{};

  Future<void> _respond(NomoFriendRequestItem request, String status) async {
    if (!_busyRequestIds.add(request.id)) return;
    setState(() {});
    try {
      await ref
          .read(friendRepositoryProvider)
          .updateFriendRequest(request.id, status);
      ref.invalidate(pendingFriendRequestsProvider);
      ref.invalidate(notificationControllerProvider);
      if (status == 'accepted') {
        ref.invalidate(friendsProvider);
      }
      if (!mounted) return;
      NomoToast.show(context, switch (status) {
        'accepted' => '申請を承認しました',
        'rejected' => '申請を見送りました',
        _ => '申請を取り消しました',
      }, icon: CupertinoIcons.checkmark_circle_fill);
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        '操作できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      _busyRequestIds.remove(request.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelAll(List<NomoFriendRequestItem> requests) async {
    final targets = [
      for (final request in requests)
        if (!_busyRequestIds.contains(request.id)) request,
    ];
    if (targets.isEmpty) return;
    setState(() {
      for (final request in targets) {
        _busyRequestIds.add(request.id);
      }
    });
    try {
      final repository = ref.read(friendRepositoryProvider);
      for (final request in targets) {
        await repository.cancelFriendRequest(request.id);
      }
      ref.invalidate(pendingFriendRequestsProvider);
      ref.invalidate(notificationControllerProvider);
      if (!mounted) return;
      NomoToast.show(
        context,
        '${targets.length}件の申請を取り消しました',
        icon: CupertinoIcons.arrow_uturn_left_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        '一括取消に失敗しました。残りはあとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      for (final request in targets) {
        _busyRequestIds.remove(request.id);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingFriendRequestsProvider);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? const Color(0xFF64717D)
        : Colors.white.withValues(alpha: .64);

    return NomoBottomSheetShell(
      title: '申請管理',
      topSafeArea: true,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      radius: 28,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '送信中の申請を確認・取消し、受信中の申請を承認 / 見送りできます。',
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              requestsAsync.when(
                data: (requests) {
                  final outgoing = [
                    for (final request in requests)
                      if (request.isOutgoing) request,
                  ];
                  final incoming = [
                    for (final request in requests)
                      if (request.isIncoming) request,
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FriendRequestSection(
                        title: '送信中',
                        emptyMessage: '送信中の申請はありません。',
                        requests: outgoing,
                        accent: const Color(0xFFB7F15B),
                        busyRequestIds: _busyRequestIds,
                        onCancelAll: outgoing.isEmpty
                            ? null
                            : () => _cancelAll(outgoing),
                        rowBuilder: (request) => _FriendRequestRow(
                          request: request,
                          accent: const Color(0xFFB7F15B),
                          busy: _busyRequestIds.contains(request.id),
                          onCancel: () => _respond(request, 'cancelled'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FriendRequestSection(
                        title: '受信中',
                        emptyMessage: '受信中の申請はありません。',
                        requests: incoming,
                        accent: const Color(0xFF8A62FF),
                        busyRequestIds: _busyRequestIds,
                        rowBuilder: (request) => _FriendRequestRow(
                          request: request,
                          accent: const Color(0xFF8A62FF),
                          busy: _busyRequestIds.contains(request.id),
                          onAccept: () => _respond(request, 'accepted'),
                          onReject: () => _respond(request, 'rejected'),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '申請を読み込めませんでした。時間をおいて再度お試しください。',
                    style: TextStyle(
                      color: _ProfileColors.pink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRequestSection extends StatelessWidget {
  const _FriendRequestSection({
    required this.title,
    required this.emptyMessage,
    required this.requests,
    required this.accent,
    required this.busyRequestIds,
    required this.rowBuilder,
    this.onCancelAll,
  });

  final String title;
  final String emptyMessage;
  final List<NomoFriendRequestItem> requests;
  final Color accent;
  final Set<String> busyRequestIds;
  final Widget Function(NomoFriendRequestItem request) rowBuilder;
  final VoidCallback? onCancelAll;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7884)
        : Colors.white.withValues(alpha: .64);
    final allBusy =
        requests.isNotEmpty &&
        requests.every((request) => busyRequestIds.contains(request.id));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF5F8FB)
            : Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.person_2_fill,
                color: accent,
                size: 34,
                iconSize: 18,
                showBubble: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title${requests.isEmpty ? '' : ' ${requests.length}件'}',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onCancelAll != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  onPressed: allBusy ? null : onCancelAll,
                  child: Text(
                    allBusy ? '取消中' : 'すべて取消',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  rowBuilder(requests[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FriendRequestRow extends StatelessWidget {
  const _FriendRequestRow({
    required this.request,
    required this.accent,
    required this.busy,
    this.onCancel,
    this.onAccept,
    this.onReject,
  });

  final NomoFriendRequestItem request;
  final Color accent;
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF111820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7884)
        : Colors.white.withValues(alpha: .62);
    final profile = request.otherUser;
    final handle = profile.userId.trim().isEmpty
        ? 'ID未設定'
        : '@${profile.userId}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE2E8EF)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          NomoAvatarView(avatar: profile.avatar, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$handle ・ ${_friendRequestDateLabel(request.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onCancel != null)
            SizedBox(
              width: 82,
              child: Nomo3DButton.secondary(
                label: busy ? '取消中' : '取消',
                onTap: busy ? null : onCancel,
                height: 40,
                radius: 18,
                color: accent.withValues(alpha: .18),
                foregroundColor: accent,
                shadowColor: accent.withValues(alpha: .18),
                fontSize: 13,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 68,
                  child: Nomo3DButton.secondary(
                    label: '見送り',
                    onTap: busy ? null : onReject,
                    height: 40,
                    radius: 18,
                    color: const Color(0xFF3A2231),
                    foregroundColor: const Color(0xFFFF8AA8),
                    shadowColor: const Color(0xFF1E121B),
                    fontSize: 12,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Nomo3DButton(
                    label: busy ? '処理中' : '承認',
                    onTap: busy ? null : onAccept,
                    height: 40,
                    radius: 18,
                    color: accent,
                    foregroundColor: Colors.white,
                    shadowColor: const Color(0xFF4A2BBF),
                    fontSize: 12,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _friendRequestDateLabel(DateTime? date) {
  if (date == null) return '申請日不明';
  final local = date.toLocal();
  return '${local.month}/${local.day} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

Future<void> _showSafetyCenterSheet(BuildContext context) {
  return showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (_) => const _SafetyCenterSheet(),
  );
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('アカウントを削除しますか？'),
      content: const Text('プロフィール、フレンズ、投稿などのデータが削除されます。この操作は取り消せません。'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('削除する'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(nomoUserProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    NomoToast.show(
      context,
      'アカウントを削除しました',
      icon: CupertinoIcons.checkmark_circle_fill,
    );
  } catch (_) {
    if (!context.mounted) return;
    _showSnack(context, 'アカウントを削除できませんでした。あとでもう一度試してね');
  }
}

class _SafetyCenterSheet extends ConsumerStatefulWidget {
  const _SafetyCenterSheet();

  @override
  ConsumerState<_SafetyCenterSheet> createState() => _SafetyCenterSheetState();
}

class _SafetyCenterSheetState extends ConsumerState<_SafetyCenterSheet> {
  final Set<String> _releasingUserIds = <String>{};

  Future<void> _releaseUser(NomoSafetyUser user, {required bool block}) async {
    if (user.id.isEmpty || !_releasingUserIds.add(user.id)) return;
    setState(() {});
    try {
      final repository = ref.read(userSafetyRepositoryProvider);
      if (block) {
        await repository.unblockUser(user.id);
        ref.invalidate(blockedUsersProvider);
      } else {
        await repository.unmuteUser(user.id);
        ref.invalidate(mutedUsersProvider);
      }
      ref.invalidate(homeFeedControllerProvider);
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      NomoToast.show(
        context,
        block ? 'ブロックを解除しました' : 'ミュートを解除しました',
        icon: CupertinoIcons.checkmark_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        '解除できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      _releasingUserIds.remove(user.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedUsersProvider);
    final muted = ref.watch(mutedUsersProvider);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? const Color(0xFF64717D)
        : Colors.white.withValues(alpha: .64);

    return NomoBottomSheetShell(
      title: '安全センター',
      topSafeArea: true,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      radius: 28,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ブロック・ミュートした相手をここから解除できます。',
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _SafetyUserSection(
                title: 'ブロック中',
                emptyMessage: 'ブロック中のユーザーはいません。',
                usersAsync: blocked,
                releasingUserIds: _releasingUserIds,
                accent: const Color(0xFFFF7A9E),
                actionLabel: '解除',
                onRelease: (user) => _releaseUser(user, block: true),
              ),
              const SizedBox(height: 14),
              _SafetyUserSection(
                title: 'ミュート中',
                emptyMessage: 'ミュート中のユーザーはいません。',
                usersAsync: muted,
                releasingUserIds: _releasingUserIds,
                accent: const Color(0xFF65D6FF),
                actionLabel: '解除',
                onRelease: (user) => _releaseUser(user, block: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyUserSection extends StatelessWidget {
  const _SafetyUserSection({
    required this.title,
    required this.emptyMessage,
    required this.usersAsync,
    required this.releasingUserIds,
    required this.accent,
    required this.actionLabel,
    required this.onRelease,
  });

  final String title;
  final String emptyMessage;
  final AsyncValue<List<NomoSafetyUser>> usersAsync;
  final Set<String> releasingUserIds;
  final Color accent;
  final String actionLabel;
  final ValueChanged<NomoSafetyUser> onRelease;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7884)
        : Colors.white.withValues(alpha: .64);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF5F8FB)
            : Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.shield_fill,
                color: accent,
                size: 34,
                iconSize: 18,
                showBubble: false,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                  child: Text(
                    emptyMessage,
                    style: TextStyle(
                      color: sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < users.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _SafetyUserRow(
                      user: users[i],
                      accent: accent,
                      actionLabel: actionLabel,
                      isReleasing: releasingUserIds.contains(users[i].id),
                      onRelease: () => onRelease(users[i]),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Text(
                '読み込めませんでした。時間をおいて再度お試しください。',
                style: TextStyle(
                  color: _ProfileColors.pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyUserRow extends StatelessWidget {
  const _SafetyUserRow({
    required this.user,
    required this.accent,
    required this.actionLabel,
    required this.isReleasing,
    required this.onRelease,
  });

  final NomoSafetyUser user;
  final Color accent;
  final String actionLabel;
  final bool isReleasing;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF111820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7884)
        : Colors.white.withValues(alpha: .62);
    final handle = user.userId.trim().isEmpty ? 'ID未設定' : '@${user.userId}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE2E8EF)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          NomoAvatarView(avatar: user.avatar, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Nomo3DButton.secondary(
              label: isReleasing ? '解除中' : actionLabel,
              onTap: isReleasing ? null : onRelease,
              height: 40,
              radius: 18,
              color: accent.withValues(alpha: .18),
              foregroundColor: accent,
              shadowColor: accent.withValues(alpha: .18),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child, this.onClose});

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => NomoBottomSheetShell(
    title: title,
    onClose: onClose,
    topSafeArea: true,
    margin: const EdgeInsets.all(14),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    radius: 28,
    child: child,
  );
}
