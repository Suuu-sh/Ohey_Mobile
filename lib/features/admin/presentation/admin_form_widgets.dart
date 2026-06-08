part of 'admin_screen.dart';

class _AdminOwnerField extends StatelessWidget {
  const _AdminOwnerField({
    required this.users,
    required this.ownerUserId,
    required this.ownerController,
    required this.onOwnerTextChanged,
    required this.onOwnerSelected,
  });

  final List<AdminUserProfile> users;
  final String ownerUserId;
  final TextEditingController ownerController;
  final ValueChanged<String> onOwnerTextChanged;
  final ValueChanged<String?> onOwnerSelected;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _AdminInput(
        label: 'owner_user_id',
        controller: ownerController,
        onChanged: onOwnerTextChanged,
      );
    }
    return _AdminDropdown(
      value: ownerUserId,
      users: users,
      onChanged: onOwnerSelected,
    );
  }
}

Future<void> _showNotificationSheet(BuildContext context, WidgetRef ref) async {
  final users =
      ref.read(adminUsersProvider).asData?.value ?? const <AdminUserProfile>[];
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final keyController = TextEditingController();
  var sendToAll = true;
  final selectedUserIds = <String>{};
  var saving = false;
  var didSave = false;
  AdminNotificationResult? result;
  String? error;

  try {
    await showOheyBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => _AdminSheet(
          title: 'System通知作成',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminInput(controller: titleController, label: 'タイトル'),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: messageController,
                  label: '本文',
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: keyController,
                  label: 'system_key（任意・重複防止キー）',
                ),
                const SizedBox(height: 10),
                _AdminSwitchRow(
                  label: '全ユーザーに送る',
                  value: sendToAll,
                  onChanged: (value) => setState(() => sendToAll = value),
                ),
                if (!sendToAll) ...[
                  const SizedBox(height: 10),
                  _AdminRecipientSelector(
                    users: users,
                    selectedUserIds: selectedUserIds,
                    onChanged: () => setState(() {}),
                  ),
                ],
                if (result != null) ...[
                  const SizedBox(height: 10),
                  _AdminInfoBox(
                    title: '送信しました',
                    message:
                        '${result!.createdCount}/${result!.recipientCount} 件の通知を作成しました。',
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: _AdminColors.pink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _AdminPrimaryButton(
                  label: '通知を送る',
                  busy: saving,
                  onTap: () async {
                    setState(() {
                      saving = true;
                      error = null;
                      result = null;
                    });
                    try {
                      final sent = await ref
                          .read(adminControllerProvider)
                          .createSystemNotification(
                            title: titleController.text.trim(),
                            message: messageController.text.trim(),
                            sendToAll: sendToAll,
                            recipientUserIds: selectedUserIds.toList(),
                            systemKey: keyController.text.trim(),
                          );
                      didSave = true;
                      setState(() {
                        saving = false;
                        result = sent;
                      });
                    } on BackendApiException catch (e) {
                      setState(() {
                        saving = false;
                        error = e.message;
                      });
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = '$e';
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
  } finally {
    await WidgetsBinding.instance.endOfFrame;
    titleController.dispose();
    messageController.dispose();
    keyController.dispose();
  }
  if (didSave && context.mounted) {
    _invalidateAdminOutboxProviders(ref);
    OheyToast.show(context, 'System通知を送信しました。');
  }
}

class _AdminRecipientSelector extends StatelessWidget {
  const _AdminRecipientSelector({
    required this.users,
    required this.selectedUserIds,
    required this.onChanged,
  });

  final List<AdminUserProfile> users;
  final Set<String> selectedUserIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '送信先ユーザー',
          style: TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        if (users.isEmpty)
          const Text(
            'ユーザー一覧を取得できていません。',
            style: TextStyle(color: _AdminColors.sub),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final user in users)
                _AdminStatusChip(
                  label: user.displayName,
                  selected: selectedUserIds.contains(user.id),
                  onTap: () {
                    if (!selectedUserIds.remove(user.id)) {
                      selectedUserIds.add(user.id);
                    }
                    onChanged();
                  },
                ),
            ],
          ),
      ],
    ),
  );
}

Future<void> _confirmDeleteUser(
  BuildContext context,
  WidgetRef ref,
  AdminUserProfile user,
) async {
  final ok = await _confirmDestructive(
    context,
    title: 'ユーザーを削除しますか？',
    message: '${user.displayName} と関連データが削除されます。',
  );
  if (ok != true) return;
  try {
    await ref.read(adminControllerProvider).deleteUser(user.id);
    ref.invalidate(adminUsersProvider);
    _invalidateAdminYuruboProviders(ref);
    if (context.mounted) OheyToast.show(context, 'ユーザーを削除しました。');
  } catch (e) {
    if (context.mounted) OheyToast.show(context, '削除できませんでした: $e');
  }
}

Future<void> _confirmDeleteYurubo(
  BuildContext context,
  WidgetRef ref,
  AdminYurubo yurubo,
) async {
  final ok = await _confirmDestructive(
    context,
    title: 'ゆるぼを削除しますか？',
    message: yurubo.title.isEmpty ? yurubo.id : yurubo.title,
  );
  if (ok != true) return;
  try {
    await ref.read(adminControllerProvider).deleteYurubo(yurubo.id);
    _invalidateAdminYuruboProviders(ref);
    if (context.mounted) OheyToast.show(context, 'ゆるぼを削除しました。');
  } catch (e) {
    if (context.mounted) OheyToast.show(context, '削除できませんでした: $e');
  }
}

Future<bool?> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showOheyConfirmSheet(
    context,
    title: title,
    message: message,
    confirmLabel: '削除',
    destructive: true,
    icon: CupertinoIcons.trash_fill,
    accent: _AdminColors.pink,
  );
}
