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
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
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
          if (gender == NomoGender.unspecified) {
            setState(() => error = '性別を選択してください。');
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
  final rootContext = context;
  final user = ref.read(nomoUserProvider);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(nomoThemeModeProvider);
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
              icon: themeMode.isWhite
                  ? CupertinoIcons.moon_stars_fill
                  : CupertinoIcons.sun_max_fill,
              label: themeMode.isWhite ? 'ダークモード' : 'ホワイトモード',
              subtitle: themeMode.isWhite
                  ? '夜でも見やすい配色に切り替え'
                  : '明るい場所で見やすい配色に切り替え',
              accent: themeMode.isWhite
                  ? const Color(0xFFC08BFF)
                  : const Color(0xFFFFC857),
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
                  ? '写真付きの飲みログを見返す'
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
