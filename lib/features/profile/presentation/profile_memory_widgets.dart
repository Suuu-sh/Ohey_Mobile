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
  var showingUnsavedPrompt = false;
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

        void closeSheet() {
          if (closing || !sheetContext.mounted) return;
          closing = true;
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(sheetContext).pop();
        }

        Future<void> requestClose() async {
          if (saving || closing || showingUnsavedPrompt) return;
          FocusManager.instance.primaryFocus?.unfocus();
          if (!hasChanges()) {
            closeSheet();
            return;
          }

          showingUnsavedPrompt = true;
          final action = await showCupertinoModalPopup<_UnsavedProfileAction>(
            context: context,
            builder: (context) => const _UnsavedProfileSheet(),
          );
          showingUnsavedPrompt = false;
          if (!sheetContext.mounted || action == null) return;
          switch (action) {
            case _UnsavedProfileAction.save:
              await saveProfile();
            case _UnsavedProfileAction.discard:
              closeSheet();
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1D2B), Color(0xFF06131F)],
        ),
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
                      '閉じる前にプロフィールの変更を保存できます',
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
              color: Colors.white.withValues(alpha: .055),
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
            shadowColor: Colors.black.withValues(alpha: .30),
            height: 48,
            radius: 21,
            fontSize: 14,
            useGradient: false,
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
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
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
