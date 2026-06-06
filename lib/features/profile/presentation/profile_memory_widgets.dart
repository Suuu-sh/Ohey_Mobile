part of 'profile_screen.dart';

Future<void> _showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  OheyUser? user,
) async {
  final controller = TextEditingController(text: user?.name ?? '');
  final userIdController = TextEditingController(text: user?.userId ?? '');
  final userController = ref.read(oheyUserProvider.notifier);
  final initialName = user?.name ?? '';
  final initialUserId = user?.userId ?? '';
  final initialAvatar = user?.avatar ?? OheyAvatar.defaultAvatar;
  var avatar = user?.avatar ?? OheyAvatar.defaultAvatar;
  final gender = user?.gender ?? OheyGender.unspecified;
  var saving = false;
  var closing = false;
  var didUpdateProfile = false;
  String? error;

  await showOheyBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetBuildContext, setState) {
        final sheetIsWhite =
            Theme.of(sheetBuildContext).brightness == Brightness.light;
        final inputInk = sheetIsWhite ? AppColors.cFF101820 : AppColors.white;
        final inputSub = sheetIsWhite
            ? AppColors.cFF8B96A3
            : AppColors.white.withValues(alpha: .45);

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
            didUpdateProfile = true;
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
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
                                ).push<OheyAvatar>(
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

  if (didUpdateProfile && context.mounted) {
    _showSnack(context, 'プロフィールを更新しました。');
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
    userIdController.dispose();
  });
}

enum _UnsavedProfileAction { save, discard, cancel }

class _UnsavedProfileSheet extends StatelessWidget {
  const _UnsavedProfileSheet();

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(brightness: Brightness.dark),
    child: OheyBottomSheetShell(
      showHandle: false,
      showBottomCloseButton: false,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      radius: 34,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '変更を保存しますか？',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              OheyCloseButton(
                onTap: () =>
                    Navigator.of(context).pop(_UnsavedProfileAction.cancel),
                iconColor: _ProfileColors.sub,
                size: 44,
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: 18),
          OheyActionTile(
            icon: CupertinoIcons.check_mark_circled_solid,
            title: '保存して閉じる',
            subtitle: '変更をプロフィールに残す',
            accent: AppColors.cFF20D0B4,
            onTap: () => Navigator.of(context).pop(_UnsavedProfileAction.save),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.arrow_uturn_left,
            title: '変更を戻す',
            subtitle: '変更前のプロフィールに戻す',
            accent: AppColors.cFFB78CFF,
            onTap: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.discard),
          ),
          const SizedBox(height: 12),
          _UnsavedProfileCancelButton(
            label: '編集を続ける',
            onTap: () =>
                Navigator.of(context).pop(_UnsavedProfileAction.cancel),
          ),
        ],
      ),
    ),
  );
}

class _UnsavedProfileCancelButton extends StatelessWidget {
  const _UnsavedProfileCancelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onTap,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white.withValues(alpha: .12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cFFB78CFF.withValues(alpha: .12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.cFFCF9BFF,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
      ),
    );
  }
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
  final user = ref.read(oheyUserProvider);
  await showOheyBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);
        final pendingRequestBadgeCount = pendingRequestsAsync.maybeWhen(
          data: (requests) =>
              requests.where((request) => request.isIncoming).length,
          orElse: () => 0,
        );
        return _SettingsSheetShell(
          user: user,
          onClose: () => Navigator.of(sheetContext).pop(),
          children: [
            _SettingsTile(
              icon: CupertinoIcons.pencil_circle_fill,
              label: 'プロフィール編集',
              subtitle: '名前・ユーザーID・アバターを変更',
              accent: AppColors.primaryAction,
              onTap: () async {
                final currentUser = ref.read(oheyUserProvider);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _showEditProfileSheet(rootContext, ref, currentUser);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.play_circle_fill,
              label: 'はじめてのデモ',
              subtitle: 'Oheyの使い方をもう一度見る',
              accent: AppColors.cFF9AF21A,
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                if (!context.mounted) return;
                await Navigator.of(context).push<void>(
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const OheyDemoScreen(),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.person_2_fill,
              label: '管理',
              subtitle: '申請・ブロック・ミュートを確認',
              accent: AppColors.cFF65D6FF,
              badgeCount: pendingRequestBadgeCount,
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _showProfileManagementSheet(rootContext);
                if (!rootContext.mounted) return;
                await _showSettingsSheet(rootContext, ref);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.doc_text_fill,
              label: 'サポート・法務',
              subtitle: '問い合わせ・利用規約・プライバシー',
              accent: AppColors.cFFFFD166,
              onTap: () async {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!rootContext.mounted) return;
                await _showSupportLegalSheet(rootContext);
                if (!rootContext.mounted) return;
                await _showSettingsSheet(rootContext, ref);
              },
            ),
            _SettingsTile(
              icon: CupertinoIcons.delete_solid,
              label: 'アカウント削除',
              subtitle: '退会してデータを削除します',
              accent: AppColors.cFFFF5C7A,
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
                  await ref.read(oheyUserProvider.notifier).signOut();
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

String _friendRequestSettingsSubtitle(
  AsyncValue<List<OheyFriendRequestItem>> requestsAsync,
) {
  return requestsAsync.maybeWhen(
    data: (requests) {
      final incoming = requests.where((request) => request.isIncoming).length;
      final outgoing = requests.where((request) => request.isOutgoing).length;
      final total = incoming + outgoing;
      if (total == 0) return '送信中・受信中のフレンズ申請';
      if (incoming > 0 && outgoing > 0) {
        return '未処理$total件（受信$incoming・送信$outgoing）';
      }
      if (incoming > 0) return '受信中$incoming件を確認';
      return '送信中$outgoing件を確認・取消';
    },
    loading: () => '申請件数を確認中',
    orElse: () => '送信中・受信中のフレンズ申請',
  );
}

const _oheySupportEmail = String.fromEnvironment(
  'OHEY_SUPPORT_EMAIL',
  defaultValue: 'support@ohey.app',
);
const _oheyTermsUrl = String.fromEnvironment(
  'OHEY_TERMS_URL',
  defaultValue:
      'https://pwifgddolctqghygwxwj.supabase.co/storage/v1/object/public/legal/terms.txt',
);
const _oheyPrivacyUrl = String.fromEnvironment(
  'OHEY_PRIVACY_URL',
  defaultValue:
      'https://pwifgddolctqghygwxwj.supabase.co/storage/v1/object/public/legal/privacy-policy.txt',
);

Future<void> _showSupportLegalSheet(BuildContext context) {
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => const _SupportLegalSheet(),
  );
}

class _SupportLegalSheet extends StatelessWidget {
  const _SupportLegalSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? AppColors.cFF64717D
        : AppColors.white.withValues(alpha: .64);

    return OheyBottomSheetShell(
      title: 'サポート・法務',
      topSafeArea: true,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '問い合わせ先と、公開前に確認しておきたいポリシーへの導線です。タップすると値をコピーできます。',
            style: TextStyle(
              color: sub,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _SupportLegalRow(
            icon: CupertinoIcons.mail_solid,
            title: '問い合わせ',
            subtitle: 'サポート窓口メール',
            value: _oheySupportEmail,
            accent: AppColors.cFFFFD166,
          ),
          const SizedBox(height: 10),
          _SupportLegalRow(
            icon: CupertinoIcons.doc_text_fill,
            title: '利用規約',
            subtitle: 'Terms of Service URL',
            value: _oheyTermsUrl,
            accent: AppColors.cFF65D6FF,
          ),
          const SizedBox(height: 10),
          _SupportLegalRow(
            icon: CupertinoIcons.lock_shield_fill,
            title: 'プライバシーポリシー',
            subtitle: 'Privacy Policy URL',
            value: _oheyPrivacyUrl,
            accent: AppColors.cFFFF7AB8,
          ),
          const SizedBox(height: 14),
          Text(
            '正式なURLやメールはビルド時の dart-define で差し替え可能です。',
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportLegalRow extends StatelessWidget {
  const _SupportLegalRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .62);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          OheyToast.show(context, '$titleをコピーしました');
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: isWhite
              ? AppColors.cFFF5F8FB
              : AppColors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: .26)),
        ),
        child: Row(
          children: [
            OheyPopIcon(
              icon: icon,
              color: accent,
              size: 42,
              iconSize: 22,
              showBubble: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: sub,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OheyGeneratedIcon(
              CupertinoIcons.doc_on_clipboard,
              color: sub,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showFriendRequestManagementSheet(BuildContext context) {
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => const _FriendRequestManagementSheet(),
  );
}

Future<void> _showProfileManagementSheet(BuildContext context) {
  final rootContext = context;
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);
        final pendingRequestBadgeCount = pendingRequestsAsync.maybeWhen(
          data: (requests) =>
              requests.where((request) => request.isIncoming).length,
          orElse: () => 0,
        );

        return OheyBottomSheetShell(
          title: '管理',
          topSafeArea: true,
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          radius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsTile(
                icon: CupertinoIcons.person_2_fill,
                label: '申請管理',
                subtitle: _friendRequestSettingsSubtitle(pendingRequestsAsync),
                accent: AppColors.cFFB7F15B,
                badgeCount: pendingRequestBadgeCount,
                onTap: () async {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 180));
                  if (!rootContext.mounted) return;
                  await _showFriendRequestManagementSheet(rootContext);
                  if (!rootContext.mounted) return;
                  await _showSettingsSheet(rootContext, ref);
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                label: 'ブロック・ミュート管理',
                subtitle: '解除したい相手を確認',
                accent: AppColors.cFF65D6FF,
                onTap: () async {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 180));
                  if (!rootContext.mounted) return;
                  await _showSafetyCenterSheet(rootContext);
                  if (!rootContext.mounted) return;
                  await _showSettingsSheet(rootContext, ref);
                },
              ),
            ],
          ),
        );
      },
    ),
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

  Future<void> _respond(
    OheyFriendRequestItem request,
    OheyFriendRequestStatus status,
  ) async {
    if (!_busyRequestIds.add(request.id)) return;
    setState(() {});
    try {
      await ref
          .read(friendRepositoryProvider)
          .updateFriendRequest(request.id, status);
      ref.invalidate(pendingFriendRequestsProvider);
      ref.invalidate(notificationControllerProvider);
      if (status.isAccepted) {
        ref.invalidate(friendsProvider);
        ref.invalidate(friendsForDateProvider);
      }
      if (!mounted) return;
      OheyToast.show(
        context,
        status.responseToastMessage,
        icon: CupertinoIcons.checkmark_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        '操作できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      _busyRequestIds.remove(request.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelAll(List<OheyFriendRequestItem> requests) async {
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
      OheyToast.show(
        context,
        '${targets.length}件の申請を取り消しました',
        icon: CupertinoIcons.arrow_uturn_left_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
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
        ? AppColors.cFF64717D
        : AppColors.white.withValues(alpha: .64);

    return OheyBottomSheetShell(
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
                        accent: AppColors.cFFB7F15B,
                        busyRequestIds: _busyRequestIds,
                        onCancelAll: outgoing.isEmpty
                            ? null
                            : () => _cancelAll(outgoing),
                        rowBuilder: (request) => _FriendRequestRow(
                          request: request,
                          accent: AppColors.cFFB7F15B,
                          busy: _busyRequestIds.contains(request.id),
                          onCancel: () => _respond(
                            request,
                            OheyFriendRequestStatus.cancelled,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FriendRequestSection(
                        title: '受信中',
                        emptyMessage: '受信中の申請はありません。',
                        requests: incoming,
                        accent: AppColors.cFF8A62FF,
                        busyRequestIds: _busyRequestIds,
                        rowBuilder: (request) => _FriendRequestRow(
                          request: request,
                          accent: AppColors.cFF8A62FF,
                          busy: _busyRequestIds.contains(request.id),
                          onAccept: () => _respond(
                            request,
                            OheyFriendRequestStatus.accepted,
                          ),
                          onReject: () => _respond(
                            request,
                            OheyFriendRequestStatus.rejected,
                          ),
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
  final List<OheyFriendRequestItem> requests;
  final Color accent;
  final Set<String> busyRequestIds;
  final Widget Function(OheyFriendRequestItem request) rowBuilder;
  final VoidCallback? onCancelAll;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .64);
    final allBusy =
        requests.isNotEmpty &&
        requests.every((request) => busyRequestIds.contains(request.id));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.cFFF5F8FB
            : AppColors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OheyPopIcon(
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

  final OheyFriendRequestItem request;
  final Color accent;
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF111820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .62);
    final profile = request.otherUser;
    final handle = profile.userId.trim().isEmpty
        ? 'ID未設定'
        : '@${profile.userId}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWhite ? AppColors.white : AppColors.darkBackgroundBottom,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? AppColors.cFFE2E8EF
              : AppColors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          OheyAvatarView(avatar: profile.avatar, size: 46),
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
              child: Ohey3DButton.secondary(
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
                  child: Ohey3DButton.secondary(
                    label: '見送り',
                    onTap: busy ? null : onReject,
                    height: 40,
                    radius: 18,
                    color: AppColors.cFF3A2231,
                    foregroundColor: AppColors.cFFFF8AA8,
                    shadowColor: AppColors.cFF1E121B,
                    fontSize: 12,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Ohey3DButton(
                    label: busy ? '処理中' : '承認',
                    onTap: busy ? null : onAccept,
                    height: 40,
                    radius: 18,
                    color: accent,
                    foregroundColor: AppColors.white,
                    shadowColor: AppColors.cFF4A2BBF,
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
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => const _SafetyCenterSheet(),
  );
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showOheyConfirmSheet(
    context,
    title: 'アカウントを削除しますか？',
    message: 'プロフィール、フレンズ、ゆるぼなどのデータが削除されます。この操作は取り消せません。',
    confirmLabel: '削除する',
    destructive: true,
    icon: CupertinoIcons.trash_fill,
  );
  if (confirmed != true) return;

  try {
    await ref.read(oheyUserProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    OheyToast.show(
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

  Future<void> _releaseUser(OheySafetyUser user, {required bool block}) async {
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
      OheyToast.show(
        context,
        block ? 'ブロックを解除しました' : 'ミュートを解除しました',
        icon: CupertinoIcons.checkmark_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
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
        ? AppColors.cFF64717D
        : AppColors.white.withValues(alpha: .64);

    return OheyBottomSheetShell(
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
                accent: AppColors.cFFFF7A9E,
                actionLabel: '解除',
                onRelease: (user) => _releaseUser(user, block: true),
              ),
              const SizedBox(height: 14),
              _SafetyUserSection(
                title: 'ミュート中',
                emptyMessage: 'ミュート中のユーザーはいません。',
                usersAsync: muted,
                releasingUserIds: _releasingUserIds,
                accent: AppColors.cFF65D6FF,
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
  final AsyncValue<List<OheySafetyUser>> usersAsync;
  final Set<String> releasingUserIds;
  final Color accent;
  final String actionLabel;
  final ValueChanged<OheySafetyUser> onRelease;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .64);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.cFFF5F8FB
            : AppColors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OheyPopIcon(
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

  final OheySafetyUser user;
  final Color accent;
  final String actionLabel;
  final bool isReleasing;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF111820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .62);
    final handle = user.userId.trim().isEmpty ? 'ID未設定' : '@${user.userId}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWhite ? AppColors.white : AppColors.darkBackgroundBottom,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? AppColors.cFFE2E8EF
              : AppColors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          OheyAvatarView(avatar: user.avatar, size: 46),
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
            child: Ohey3DButton.secondary(
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
  Widget build(BuildContext context) => OheyBottomSheetShell(
    title: title,
    onClose: onClose,
    topSafeArea: true,
    margin: const EdgeInsets.all(14),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    radius: 28,
    child: child,
  );
}
